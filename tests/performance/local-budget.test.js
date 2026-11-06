const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { request, success, project, fixtures, fixture } = require('../helpers/live');

test('[PERF-01] bounded local API load and small image processing stay within recorded budgets', { timeout: 120000 }, async () => {
  const p = await project(), durations = [];
  const maxP95 = Number(process.env.TEST_API_P95_MS || 2000);
  const maxProcess = Number(process.env.TEST_IMAGE_PROCESS_MS || 30000);
  for (let batch = 0; batch < 5; batch++) { 
    await Promise.all(Array.from({ length: 4 }, async () => {
      const start = performance.now();
      const value = success(await request('GET', p.route, { token: p.user.token }));
      assert.equal(value._id, p.id); durations.push(performance.now() - start);
    }));
  }
  success(await p.upload(fixture('pattern.png')));
  await p.tools([{ procedure: 'resize', params: { width: 80, height: 60 } }]);
  const start = performance.now(), result = await p.process(), processMs = performance.now() - start;
  assert.equal(result.imgs.length, 1);
  const p95 = [...durations].sort((a, b) => a - b)[18];
  fs.writeFileSync('tests/reports/performance.json', JSON.stringify({ timestamp: new Date().toISOString(), node: process.version, cpu: os.cpus()[0].model, logicalCpus: os.cpus().length, totalMemory: os.totalmem(), fixture: '160x120 PNG', concurrency: 4, samples: 20, durations, p95, processMs, maxP95, maxProcess }, null, 2));
  assert.ok(p95 <= maxP95, `API p95 ${p95.toFixed(1)} ms exceeds ${maxP95} ms`);
  assert.ok(processMs <= maxProcess, `Processing ${processMs.toFixed(1)} ms exceeds ${maxProcess} ms`);
});
