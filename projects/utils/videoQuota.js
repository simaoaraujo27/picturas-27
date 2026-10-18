const axios = require('axios');
const https = require('https');
const Project = require('../models/project');
const Account = require('../models/videoStorageAccount');
const httpsAgent = new https.Agent({ rejectUnauthorized: false });
const limits = { free: 1_000_000_000, premium: 5_000_000_000 };

async function ensure(ownerId) {
  let account = await Account.findOne({ ownerId });
  if (account) return account;
  const projects = await Project.find({ user_id: ownerId }).select('videos').lean();
  const entries = projects.flatMap(project => (project.videos || []).map(video => ({
    videoId: video._id, size: video.size, state: 'committed' })));
  try {
    account = await Account.create({ ownerId, used: entries.reduce((sum, entry) => sum + entry.size, 0), entries });
  } catch (error) {
    if (error.code !== 11000) throw error;
    account = await Account.findOne({ ownerId });
  }
  return account;
}
async function reserve(ownerId, videoId, size) {
  if (!Number.isSafeInteger(size) || size < 1) throw Object.assign(new Error('INVALID_SIZE'), { status: 400 });
  const response = await axios.get(`https://users:10001/${ownerId}/type`, { httpsAgent, timeout: 10000 });
  const limit = limits[response.data?.type];
  if (!limit) throw Object.assign(new Error('PLAN_FORBIDDEN'), { status: 403 });
  const account = await ensure(ownerId);
  const existing = account.entries.find(entry => String(entry.videoId) === String(videoId));
  if (existing) {
    if (existing.state === 'reserved' || existing.state === 'committed') return;
    const restored = await Account.updateOne({ ownerId, used: { $lte: limit - size },
      entries: { $elemMatch: { videoId, state: 'released' } } },
      { $inc: { used: size }, $set: { 'entries.$.state': 'reserved', 'entries.$.size': size } });
    if (!restored.modifiedCount) throw Object.assign(new Error('STORAGE_QUOTA_EXCEEDED'), { status: 507 });
    return;
  }
  const updated = await Account.findOneAndUpdate({ ownerId, 'entries.videoId': { $ne: videoId },
    used: { $lte: limit - size } }, { $inc: { used: size },
    $push: { entries: { videoId, size, state: 'reserved' } } });
  if (!updated) throw Object.assign(new Error('STORAGE_QUOTA_EXCEEDED'), { status: 507 });
}
async function usage(ownerId) {
  const response = await axios.get(`https://users:10001/${ownerId}/type`, { httpsAgent, timeout: 10000 });
  const limit = limits[response.data?.type];
  if (!limit) throw Object.assign(new Error('PLAN_FORBIDDEN'), { status: 403 });
  const account = await ensure(ownerId);
  return { used: account.used, limit };
}
async function commit(ownerId, videoId) {
  await Account.updateOne({ ownerId, entries: { $elemMatch: { videoId, state: 'reserved' } } },
    { $set: { 'entries.$.state': 'committed' } });
}
async function release(ownerId, videoId) {
  const account = await Account.findOne({ ownerId, 'entries.videoId': videoId }).select('entries');
  const entry = account?.entries.find(x => String(x.videoId) === String(videoId));
  if (!entry || entry.state === 'released') return;
  await Account.updateOne({ ownerId, entries: { $elemMatch: { videoId, state: entry.state } } },
    { $inc: { used: -entry.size }, $set: { 'entries.$.state': 'released' } });
}
module.exports = { reserve, commit, release, usage };
