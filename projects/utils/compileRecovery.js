const Job = require('../models/compileJob');
const { publish } = require('./compileQueue');
const { settleCompileQuota } = require('./compileQuota');
const videoQuota = require('./videoQuota');

async function recover() {
  const now = new Date();
  for (let i = 0; i < 20; i++) {
    const failed = await Job.findOneAndUpdate(
      { state: 'PROCESSING', attempt: { $gte: 2 }, leaseUntil: { $lt: now } },
      { $set: { state: 'FAILED', error: 'WORKER_TIMEOUT', finishedAt: now } }, { new: true }
    );
    if (failed) {
      await videoQuota.release(String(failed.ownerId), String(failed.resultId)).catch(console.error);
      continue;
    }
    const retry = await Job.findOneAndUpdate(
      { state: 'PROCESSING', attempt: { $lt: 2 }, leaseUntil: { $lt: now } },
      { $set: { state: 'QUEUED', progress: 0, error: 'WORKER_TIMEOUT' } }, { new: true }
    );
    if (!retry) break;
    await videoQuota.release(String(retry.ownerId), String(retry.resultId)).catch(console.error);
    try { await publish(String(retry.id)); }
    catch (error) {
      console.error('Could not republish Compile job:', retry.id, error);
      await Job.updateOne({ _id: retry.id, state: 'QUEUED' },
        { $set: { state: 'FAILED', error: 'QUEUE_UNAVAILABLE', finishedAt: now } });
    }
    await Job.updateOne({ _id: retry.id, state: 'QUEUED' }, { $set: { lastPublishedAt: now } });
  }
  const oldQueue = await Job.find({ state: 'QUEUED',
    $or: [{ lastPublishedAt: { $lt: new Date(Date.now() - 60000) } },
      { lastPublishedAt: { $exists: false } }] }).limit(20);
  for (const job of oldQueue) {
    const claimed = await Job.updateOne({ _id: job.id, state: 'QUEUED', lastPublishedAt: job.lastPublishedAt },
      { $set: { lastPublishedAt: now } });
    if (claimed.modifiedCount) await publish(String(job.id)).catch(error => console.error('Compile republish failed:', job.id, error));
  }
  const unsettled = await Job.find({ quotaReserved: true, quotaSettled: false,
    state: { $in: ['COMPLETED', 'FAILED', 'CANCELLED'] } }).limit(20);
  for (const job of unsettled) {
    await settleCompileQuota(job, job.state === 'COMPLETED' ? 'confirm' : 'refund')
      .catch(error => console.error('Compile quota reconciliation failed:', job.id, error));
  }
}
function start() {
  const timer = setInterval(() => recover().catch(error => console.error('Compile recovery failed:', error)), 30000);
  timer.unref();
}
module.exports = { start, recover };
