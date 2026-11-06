const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const { io } = require('socket.io-client');
const { base, request, success } = require('./live');

function temp(t) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'picturas-regression-'));
  t.after(() => fs.rmSync(dir, { recursive: true, force: true }));
  return dir;
}
function imageInfo(file) {
  return JSON.parse(execFileSync('.venv/bin/python', ['-c', "import json,sys;from PIL import Image,ImageStat;im=Image.open(sys.argv[1]);im.load();print(json.dumps({'size':im.size,'format':im.format,'mean':ImageStat.Stat(im.convert('RGB')).mean,'corner':im.convert('RGB').getpixel((0,0))}))", file], { encoding: 'utf8' }));
}
function probe(file) {
  return JSON.parse(execFileSync('ffprobe', ['-v', 'error', '-show_format', '-show_streams', '-of', 'json', file], { encoding: 'utf8' }));
}
function event(socket, name, timeout = 90000) {
  const pending = new Promise((resolve, reject) => {
    const timer = setTimeout(() => { socket.off(name, receive); reject(new Error(`No ${name} event within ${timeout}ms`)); }, timeout);
    timer.unref();
    function receive(value) { clearTimeout(timer); resolve(value); }
    socket.once(name, receive);
  });
  pending.catch(() => {});
  return pending;
}
async function socket(t, token) {
  const s = io(base, { auth: { token }, rejectUnauthorized: false, transports: ['websocket'], reconnection: false, autoConnect: false });
  t.after(() => s.disconnect());
  const connected = event(s, 'connect', 10000); s.connect(); await connected;
  return s;
}
async function preview(t, p, id) {
  const s = await socket(t, p.user.token);
  const ready = event(s, 'preview-ready');
  success(await request('POST', p.route + '/preview/' + id, { token: p.user.token, body: {} }));
  const value = await ready;
  s.disconnect();
  return typeof value === 'string' ? JSON.parse(value) : value;
}
module.exports = { temp, imageInfo, probe, socket, event, preview };
