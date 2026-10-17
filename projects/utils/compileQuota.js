const CompileJob = require('../models/compileJob');
const { quota } = require('./trimQuota');

async function settleCompileQuota(job, action) {
  if (!job.quotaReserved || job.quotaSettled) return;
  try { await quota(String(job.requestedBy), String(job.id), action); }
  catch (error) {
    if (!(action === 'refund' && [403, 404].includes(error.status))) throw error;
  }
  await CompileJob.updateOne({ _id: job.id, quotaSettled: false }, { $set: { quotaSettled: true } });
}

module.exports = { settleCompileQuota };
