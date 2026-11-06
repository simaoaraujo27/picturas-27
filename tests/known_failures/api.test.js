const { test } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { request, success, account, project, db, fixtures, fixture } = require('../helpers/live');
const { socket, event } = require('../helpers/media');
const { failedPreview } = require('../helpers/assistant-faults');

test('[AUTH-02] an unrelated user cannot read a private account profile', async () => {
  const a = await account(), b = await account();
  const r = await request('GET', `/api-gateway/users/${a.id}`, { token: b.token });
  assert.ok([401, 403].includes(r.status), `Private profile was returned with status ${r.status}`);
});

test('[AUTH-03.1] profile name and email survive a new login', async () => {
  const a = await account(), email = a.email.replace('regression-', 'regression-updated-');
  success(await request('PUT', `/api-gateway/users/${a.id}`, { token: a.token, body: { name: 'Updated Test', email } }));
  const r = success(await request('POST', `/api-gateway/users/${email}/login`, { body: { password: a.password } }));
  assert.equal(r.user.name, 'Updated Test'); assert.equal(r.user.email, email);
});

test('[AUTH-03.4] deleting an account removes projects and original media', async () => {
  const a = await account(), p = await project(a);
  success(await p.upload(fixture('pattern.png')));
  const url = (await p.get()).imgs[0].url;
  success(await request('DELETE', `/api-gateway/users/${a.id}`, { token: a.token }));
  assert.equal(db('projects', a.id, 'findOne', null, 'projects'), null);
  assert.ok((await request('GET', url)).status >= 400);
});

test('[AUTH-04] unauthenticated sockets cannot receive project operations', { timeout: 20000 }, async t => {
  const p = await project(), owner = await socket(t, p.user.token), outsider = await socket(t, undefined);
  owner.emit('join-project', p.id); outsider.emit('join-project', p.id);
  const leaked = []; outsider.on('project-op', msg => leaked.push(msg));
  const received = event(owner, 'project-op', 10000);
  success(await p.mutate('POST', '/tool', { procedure: 'brightness', params: { brightness: 0.5 } }));
  await received;
  // A bounded negative-event observation follows a confirmed delivery to the owner.
  await new Promise(resolve => setTimeout(resolve, 250));
  assert.equal(leaked.length, 0, 'An unauthenticated socket received private project operations');
});

test('[AUTH-04] a valid account cannot subscribe to someone elses project', { timeout: 20000 }, async t => {
  const p = await project(), b = await account(), owner = await socket(t, p.user.token), outsider = await socket(t, b.token);
  owner.emit('join-project', p.id); outsider.emit('join-project', p.id);
  const leaked = []; outsider.on('project-op', msg => leaked.push(msg));
  const received = event(owner, 'project-op', 10000);
  success(await p.mutate('POST', '/tool', { procedure: 'brightness', params: { brightness: 0.5 } }));
  await received; await new Promise(resolve => setTimeout(resolve, 250));
  assert.equal(leaked.length, 0, 'A foreign account received private project operations');
});

test('[STORE-01] exposed storage facade cannot issue a private video URL without authentication', async () => {
  const p = await project(); success(await p.upload(fixture('clip.mp4'), 'video'));
  const img = db('projects', p.user.id, 'findOne', null, 'projects').imgs[0];
  const r = await request('GET', `http://localhost:11000/image/public/${p.user.id}/${p.id}/src/${img.og_img_key}`);
  const downloadStatus = r.status === 200 && r.data?.url ? (await request('GET', r.data.url)).status : null;
  assert.ok([401, 403].includes(r.status), `Storage issued a private signed URL without authentication: ${r.status}; video download: ${downloadStatus}`);
});

test('[UP-01] image endpoint rejects corrupt PNG contents', async () => {
  const p = await project();
  const r = await p.upload(fixture('invalid.png'));
  assert.ok(r.status >= 400 && r.status < 500, `invalid.png: ${r.status}`);
  assert.equal((await p.get()).imgs.length, 0);
});

test('[EDGE-01] Unicode filename survives upload unchanged', async () => {
  const p = await project(), filename = 'imagem teste ç.png';
  success(await p.upload(fixture('pattern.png'), 'img', filename));
  assert.equal((await p.get()).imgs[0].name, filename);
});

test('[PLAN-02] cancelling video restores quota and leaves no partial result', { timeout: 120000 }, async () => {
  // REQ-VID-CANCEL-002: cancellation restores reserved operations and discards partial output.
  const p = await project();
  success(await p.upload(fixture('clip.mp4'), 'video'));
  await p.tools([{ procedure: 'brightness', params: { brightness: 0.5 } }]);
  const quota = () => db('users', p.user.id).operations.reduce((n, x) => n + x.processed, 0);
  const before = quota();
  success(await p.mutate('POST', '/process', {}));
  assert.equal(quota(), before + 1, 'The video operation must be reserved before cancellation');
  success(await p.mutate('DELETE', '/process'));
  const results = success(await request('GET', p.route + '/process/url', { token: p.user.token }));
  assert.equal(results.imgs.length, 0, 'Cancellation must leave no partial video result');
  assert.equal(quota(), before, 'Cancellation must restore the reserved operation');
});

test('[PROJ-02,STORE-02] deleting an image project removes its original image object', async () => {
  const p = await project(); success(await p.upload(fixture('pattern.png')));
  const url = (await p.get()).imgs[0].url;
  success(await p.mutate('DELETE'));
  assert.equal(db('projects', p.user.id, 'findOne', null, 'projects'), null);
  assert.ok((await request('GET', url)).status >= 400, 'Original image remains after deleting its image-only project');
});

test('[PIPE-02] video resize to 1280 by 0 is rejected before processing', async () => {
  const p = await project();
  db('users', p.user.id, 'updateOne', { type: 'premium' });
  success(await p.upload(fixture('clip.mp4'), 'video'));
  const added = await p.mutate('POST', '/tool', { procedure: 'resize', params: { width: 1280, height: 0 } });
  if (added.status >= 400 && added.status < 500) {
    assert.equal((await p.get()).tools.length, 0);
    return;
  }
  success(added);
  const started = await p.mutate('POST', '/process', {});
  assert.ok(started.status >= 400 && started.status < 500,
    `Invalid video resize started processing: HTTP ${started.status}`);
  assert.match(JSON.stringify(started.data), /width|height|dimension|dimens|resize|redimension/i);
});

test('[ASSIST-02] URL-signing failure cleans up uploaded assistant previews', () => {
  const result = failedPreview('sign');
  assert.equal(result.status, 200);
  assert.ok(result.uploaded > 0);
  assert.equal(result.deleted, result.uploaded, 'Failed previews must not remain orphaned in storage');
});
