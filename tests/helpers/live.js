const https = require('node:https');
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { execFileSync } = require('node:child_process');

const base = process.env.TEST_BASE_URL || 'https://localhost:8080';
const fixtures = path.resolve(__dirname, '../fixtures');
const fixture = name => path.join(fixtures, ['invalid.png', 'corrupt.mp4'].includes(name) ? 'invalid' : /\.(mp4|mov|webm)$/.test(name) ? 'videos' : 'images', name);
const registry = process.env.TEST_REGISTRY_PATH || path.resolve(__dirname, '../reports/created-users.jsonl');

function request(method, route, { token, body, headers = {}, raw } = {}) {
  const url = new URL(route, base);
  const data = raw || (body === undefined ? undefined : Buffer.from(JSON.stringify(body)));
  return new Promise((resolve, reject) => {
    const req = (url.protocol === 'https:' ? https : http).request(url, {
      method, rejectUnauthorized: false,
      headers: { ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(data ? { 'Content-Length': data.length } : {}), ...headers },
    }, res => {
      const chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => {
        const buffer = Buffer.concat(chunks);
        let value = buffer.toString();
        try { value = JSON.parse(value); } catch {}
        resolve({ status: res.statusCode, data: value, buffer, headers: res.headers });
      });
      res.on('error', reject);
    });
    req.setTimeout(30000, () => req.destroy(new Error(`${method} ${url.pathname} timed out`)));
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

function success(response, statuses = [200, 201, 204]) {
  assert.ok(statuses.includes(response.status), `Expected ${statuses}, got ${response.status}: ${JSON.stringify(response.data).slice(0, 300)}`);
  return response.data;
}

async function account(type = 'free') {
  const email = `regression-${randomUUID()}@example.invalid`;
  const password = `Test-${randomUUID()}`;
  const value = success(await request('POST', '/api-gateway/users/', {
    body: { name: 'Regression Test', email, password, type },
  }));
  assert.ok(value.user?._id && value.jwt, 'Registration must return user and JWT');
  fs.mkdirSync(path.dirname(registry), { recursive: true });
  fs.appendFileSync(registry, JSON.stringify({ id: value.user._id, email, createdAt: new Date().toISOString() }) + '\n');
  return { id: value.user._id, token: value.jwt, user: value.user, email, password };
}

class Project {
  constructor(user, id) { this.user = user; this.id = id; this.route = `/api-gateway/projects/${user.id}/${id}`; }
  async get() { return success(await request('GET', this.route, { token: this.user.token })); }
  async mutate(method, suffix = '', body, extra = {}) {
    const current = await this.get();
    return request(method, this.route + suffix, {
      token: this.user.token, body, ...extra,
      headers: { 'X-Project-Version': String(current.version), ...extra.headers },
    });
  }
  async upload(file, kind = 'img', name = path.basename(file)) {
    const field = kind === 'video' ? 'video' : 'image';
    const mime = { '.png': 'image/png', '.jpg': 'image/jpeg', '.mp4': 'video/mp4', '.mov': 'video/quicktime', '.webm': 'video/webm' }[path.extname(file)] || 'application/octet-stream';
    const boundary = `test-${randomUUID()}`;
    const raw = Buffer.concat([Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="${field}"; filename="${name}"\r\nContent-Type: ${mime}\r\n\r\n`), fs.readFileSync(file), Buffer.from(`\r\n--${boundary}--\r\n`)]);
    return this.mutate('POST', `/${kind}`, undefined, { raw, headers: { 'Content-Type': `multipart/form-data; boundary=${boundary}` } });
  }
  async tools(tools) { success(await this.mutate('POST', '/reorder', tools.map((t, position) => ({ ...t, position })))); }
  async process(timeout) {
    const before = success(await request('GET', this.route + '/process/url', { token: this.user.token }));
    const previous = new Set([...before.imgs, ...before.texts].map(x => x.result_id || x.name));
    success(await this.mutate('POST', '/process', {}));
    return until(async () => {
      const result = success(await request('GET', this.route + '/process/url', { token: this.user.token }));
      const items = [...result.imgs, ...result.texts];
      return items.length > 0 && items.every(x => !previous.has(x.result_id || x.name)) ? result : false;
    }, timeout);
  }
}

async function project(user = null, name = 'Regression project') {
  user ||= await account();
  const p = success(await request('POST', `/api-gateway/projects/${user.id}`, { token: user.token, body: { name } }));
  return new Project(user, p._id);
}

async function until(fn, timeout = Number(process.env.TEST_PROCESS_TIMEOUT_MS || 90000)) {
  const end = Date.now() + timeout;
  while (Date.now() < end) {
    const value = await fn();
    if (value) return value;
    await new Promise(resolve => setTimeout(resolve, 200));
  }
  throw new Error(`Expected state was not reached within ${timeout} ms`);
}

function dockerNode(service, code, args = []) {
  return execFileSync('docker', ['compose', 'exec', '-T', service, 'node', '-e', code, ...args], { encoding: 'utf8', timeout: 120000 });
}

function db(collection, userId, operation = 'findOne', value = null, service = 'users') {
  assert.match(userId, /^[a-f0-9]{24}$/);
  const connections = { users: 'mongodb://users_mongoDB:27019/user', projects: 'mongodb://projects_mongoDB:27018/project', subscriptions: 'mongodb://subscriptions_mongoDB:27017/subscription' };
  const code = `const m=require('mongoose'); (async()=>{await m.connect(process.argv[1]); const c=m.connection.db.collection(process.argv[2]);const id=new m.Types.ObjectId(process.argv[3]); const filter=process.argv[2]==='users'?{_id:id}:{user_id:id}; const op=process.argv[4];const result=op==='findOne'?await c.findOne(filter):await c.updateOne(filter,{$set:JSON.parse(process.argv[5])}); console.log(JSON.stringify(result));await m.disconnect();})().catch(e=>{console.error(e.message);process.exit(1)})`;
  return JSON.parse(dockerNode(service, code, [connections[service], collection, userId, operation, JSON.stringify(value)]).trim());
}

async function download(url, filename) {
  const r = await request('GET', url); success(r);
  fs.writeFileSync(filename, r.buffer); return r.buffer;
}

module.exports = { request, success, account, project, Project, until, fixtures, fixture, base, registry, dockerNode, db, download };
