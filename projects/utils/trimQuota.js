const axios = require('axios');
const https = require('https');
const Job = require('../models/trimJob');
const httpsAgent = new https.Agent({ rejectUnauthorized: false });
async function quota(userId, jobId, action) {
  try {
    const response = await axios.post(`https://users:10001/internal/trim/${userId}/${jobId}/${action}`, {},
      { httpsAgent, headers: { 'X-Internal-Video-Key': process.env.INTERNAL_VIDEO_KEY }, timeout: 10000 });
    return response.data;
  } catch (cause) {
    throw Object.assign(new Error(`TRIM_QUOTA_${cause.response?.status || 'UNAVAILABLE'}`),
      { status: cause.response?.status });
  }
}
async function settleQuota(job, action) {
  if (!job.quotaReserved || job.quotaSettled) return;
  try { await quota(String(job.requestedBy), String(job.id), action); }
  catch (error) {
    if (!(action === 'refund' && [403, 404].includes(error.status))) throw error;
  }
  await Job.updateOne({ _id: job.id, quotaSettled: false }, { $set: { quotaSettled: true } });
}
module.exports = { quota, settleQuota };
