const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const axios = require('axios');
const https = require('https');
const Project = require('../models/project');
const Job = require('../models/trimJob');
const { publish } = require('../utils/trimQueue');
const { discardVideo } = require('../utils/videoStorage');
const { quota, settleQuota } = require('../utils/trimQuota');
const videoQuota = require('../utils/videoQuota');
const router = express.Router();
const httpsAgent = new https.Agent({ rejectUnauthorized: false });
const fail = (res, status, code) => res.status(status).json({ code });
const oid = mongoose.isValidObjectId;
const base = '/:user/:project/video';
async function access(req, res, next) {
  try {
    const token = /^Bearer (.+)$/.exec(req.get('Authorization') || '')?.[1];
    if (!token) return fail(res, 401, 'AUTH_REQUIRED');
    const caller = jwt.verify(token, process.env.JWT_SECRET_KEY).id;
    if (![caller, req.params.user, req.params.project].every(oid)) return fail(res, 400, 'INVALID_ID');
    const project = await Project.findOne({ _id: req.params.project, user_id: req.params.user });
    if (!project) return fail(res, 404, 'PROJECT_NOT_FOUND');
    const owner = String(project.user_id) === String(caller);
    const share = (project.sharedLinks || []).find(x => x.id === req.query.share && !x.revoked);
    if (!owner && !share) return fail(res, 403, 'ACCESS_FORBIDDEN');
    req.trim = { project, caller, canEdit: owner || share.permission === 'edit' };
    next();
  } catch (e) {
    if (e.name === 'JsonWebTokenError' || e.name === 'TokenExpiredError') return fail(res, 401, 'INVALID_TOKEN');
    console.error('Trim access:', e); return fail(res, 503, 'PROJECT_UNAVAILABLE');
  }
}
function edit(req, res, next) { return req.trim.canEdit ? next() : fail(res, 403, 'EDIT_REQUIRED'); }
function internal(req, res, next) {
  if (!process.env.INTERNAL_VIDEO_KEY || req.get('X-Internal-Video-Key') !== process.env.INTERNAL_VIDEO_KEY) return fail(res, 403, 'FORBIDDEN');
  next();
}
function present(job) {
  return { id: String(job.id), state: job.state, progress: job.progress, attempt: job.attempt,
    sourceId: String(job.sourceId),
    resultId: job.state === 'COMPLETED' ? String(job.resultId) : null,
    result: job.state === 'COMPLETED' && job.result ? {
      id: String(job.resultId), duration: job.result.duration,
      width: job.result.width, height: job.result.height,
      sourceVideoId: String(job.sourceId), jobId: String(job.id),
    } : null,
    start: job.start, end: job.end, mode: job.mode, error: job.error || null,
    requestedBy: String(job.requestedBy), createdAt: job.createdAt,
    startedAt: job.startedAt || null, finishedAt: job.finishedAt || null };
}
router.get(`${base}/storage`, access, async (req, res) => {
  try { res.json(await videoQuota.usage(req.params.user)); }
  catch (error) { fail(res, error.status || 503, error.message || 'STORAGE_UNAVAILABLE'); }
});
router.get(`${base}/trim/jobs`, access, async (req, res) => {
  const jobs = await Job.find({ projectId: req.params.project, ownerId: req.params.user }).sort({ createdAt: -1 }).limit(50);
  res.json(jobs.map(present));
});
router.post(`${base}/:videoId/trim`, access, edit, async (req, res) => {
  const { project, caller } = req.trim;
  if (!oid(req.params.videoId)) return fail(res, 400, 'INVALID_ID');
  const source = project.videos.id(req.params.videoId);
  if (!source) return fail(res, 404, 'VIDEO_NOT_FOUND');
  if (source.codec !== 'h264' || source.contentType !== 'video/mp4') return fail(res, 415, 'UNSUPPORTED_VIDEO');
  const { start, end, mode = 'precise' } = req.body || {};
  if (typeof start !== 'number' || typeof end !== 'number' || !Number.isFinite(start) || !Number.isFinite(end) || start < 0 || end - start < 1 ||
    Math.abs(Math.round(start * 100) - start * 100) > 1e-7 ||
    Math.abs(Math.round(end * 100) - end * 100) > 1e-7) return fail(res, 400, 'INVALID_INTERVAL');
  if (!['precise', 'fast'].includes(mode)) return fail(res, 400, 'INVALID_MODE');
  try {
    const response = await axios.get(`https://users:10001/${caller}/type`, { httpsAgent });
    const plan = response.data?.type;
    if (!['free', 'premium'].includes(plan)) return fail(res, 403, 'PLAN_FORBIDDEN');
    if (end - start > (plan === 'premium' ? 3600 : 180)) return fail(res, 422, 'CLIP_TOO_LONG');
    if (mode === 'fast' && plan !== 'premium') return fail(res, 403, 'PREMIUM_REQUIRED');
    if (source.duration != null && end > source.duration + 0.01) return fail(res, 422, 'OUTSIDE_VIDEO');
    const storage = await videoQuota.usage(req.params.user);
    if (storage.used >= storage.limit) return fail(res, 507, 'STORAGE_QUOTA_EXCEEDED');
    const jobId = new mongoose.Types.ObjectId();
    const resultId = new mongoose.Types.ObjectId();
    const name = `trim-${jobId}.mp4`;
    const job = await Job.create({ _id: jobId, ownerId: req.params.user, projectId: req.params.project,
      sourceId: source.id, resultId, requestedBy: caller, name, start, end, mode,
      quotaReserved: plan === 'free' });
    if (plan === 'free') {
      try { await quota(String(caller), String(job.id), 'reserve'); }
      catch (error) {
        await Job.updateOne({ _id: job.id }, { $set: { state: 'FAILED', error: 'QUOTA_UNAVAILABLE', finishedAt: new Date() } });
        if (error.status === 429) return fail(res, 429, 'DAILY_QUOTA_EXHAUSTED');
        throw error;
      }
    }
    try {
      await publish(String(job.id));
      await Job.updateOne({ _id: job.id }, { $set: { lastPublishedAt: new Date() } });
    }
    catch (error) {
      await Job.updateOne({ _id: job.id, state: 'QUEUED' },
        { $set: { state: 'FAILED', error: 'QUEUE_UNAVAILABLE', finishedAt: new Date() } });
      if (plan === 'free') await settleQuota(job, 'refund').catch(console.error);
      throw error;
    }
    return res.status(202).json(present(job));
  } catch (error) { console.error('Trim submit:', error.message); return fail(res, 503, 'TRIM_UNAVAILABLE'); }
});
router.get(`${base}/trim/jobs/:jobId`, access, async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await Job.findOne({ _id: req.params.jobId, projectId: req.params.project, ownerId: req.params.user });
  return job ? res.json(present(job)) : fail(res, 404, 'JOB_NOT_FOUND');
});
router.delete(`${base}/trim/jobs/:jobId`, access, edit, async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await Job.findOneAndUpdate({ _id: req.params.jobId, projectId: req.params.project, ownerId: req.params.user,
    state: { $in: ['QUEUED', 'PROCESSING'] } },
    { $set: { state: 'CANCELLED', finishedAt: new Date() } }, { new: true });
  if (job) {
    await settleQuota(job, 'refund').catch(console.error);
    await videoQuota.release(String(job.ownerId), String(job.resultId)).catch(console.error);
    return res.json(present(job));
  }
  const existing = await Job.findOne({ _id: req.params.jobId, projectId: req.params.project, ownerId: req.params.user });
  return fail(res, existing ? 409 : 404, existing ? 'JOB_NOT_CANCELLABLE' : 'JOB_NOT_FOUND');
});
router.get('/internal/trim/:jobId', internal, async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await Job.findById(req.params.jobId);
  if (!job) return fail(res, 404, 'JOB_NOT_FOUND');
  res.json({ ...present(job), ownerId: String(job.ownerId), projectId: String(job.projectId),
    resultId: String(job.resultId), sourceId: String(job.sourceId) });
});
router.post('/internal/trim/:jobId/claim', internal, async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await Job.findOneAndUpdate({ _id: req.params.jobId, state: 'QUEUED' },
    { $set: { state: 'PROCESSING', progress: 0, startedAt: new Date(),
      leaseUntil: new Date(Date.now() + 600000) }, $inc: { attempt: 1 } }, { new: true });
  return job ? res.json({ ...present(job), attempt: job.attempt, ownerId: String(job.ownerId), projectId: String(job.projectId), resultId: String(job.resultId) }) : fail(res, 409, 'NOT_QUEUED');
});
router.post('/internal/trim/:jobId/progress', internal, async (req, res) => {
  const progress = Number(req.body?.progress);
  if (!Number.isFinite(progress) || progress < 0 || progress > 99) return fail(res, 400, 'INVALID_PROGRESS');
  const job = await Job.findOneAndUpdate({ _id: req.params.jobId, state: 'PROCESSING', attempt: req.body?.attempt },
    { $max: { progress }, $set: { leaseUntil: new Date(Date.now() + 600000) } });
  return job ? res.sendStatus(204) : fail(res, 409, 'NOT_PROCESSING');
});
router.post('/internal/trim/:jobId/storage/reserve', internal, async (req, res) => {
  const job = await Job.findOne({ _id: req.params.jobId, state: 'PROCESSING', attempt: req.body?.attempt });
  if (!job) return fail(res, 409, 'NOT_PROCESSING');
  try {
    await videoQuota.reserve(String(job.ownerId), String(job.resultId), req.body?.size);
    return res.sendStatus(204);
  } catch (error) {
    return fail(res, error.status || 503, error.message || 'STORAGE_UNAVAILABLE');
  }
});
router.post('/internal/trim/:jobId/storage/release', internal, async (req, res) => {
  const job = await Job.findById(req.params.jobId);
  if (!job) return fail(res, 404, 'JOB_NOT_FOUND');
  await videoQuota.release(String(job.ownerId), String(job.resultId));
  res.sendStatus(204);
});
router.post('/internal/trim/:jobId/complete', internal, async (req, res) => {
  const job = await Job.findOne({ _id: req.params.jobId, state: 'PROCESSING', attempt: req.body?.attempt });
  if (!job) return fail(res, 409, 'NOT_PROCESSING');
  const { size, duration, width, height } = req.body || {};
  if (!Number.isSafeInteger(size) || size < 1 || ![duration, width, height].every(x => Number.isFinite(x) && x > 0)) return fail(res, 400, 'INVALID_RESULT');
  const video = { _id: job.resultId, name: job.name, key: `${job.projectId}/video/${job.resultId}.mp4`, size,
    codec: 'h264', contentType: 'video/mp4', uploadedBy: job.requestedBy,
    duration, width, height, sourceVideoId: job.sourceId, trimJobId: job.id, createdAt: new Date() };
  const updated = await Project.findOneAndUpdate({ _id: job.projectId, user_id: job.ownerId,
    'videos._id': job.sourceId, 'videos.name': { $ne: job.name } },
    { $push: { videos: video }, $inc: { version: 1 } });
  if (!updated) return fail(res, 409, 'PROJECT_CHANGED');
  const done = await Job.findOneAndUpdate({ _id: job.id, state: 'PROCESSING', attempt: req.body?.attempt },
    { $set: { state: 'COMPLETED', progress: 100, result: video, finishedAt: new Date() } }, { new: true });
  if (!done) {
    await Project.updateOne({ _id: job.projectId }, { $pull: { videos: { _id: job.resultId } }, $inc: { version: 1 } });
    await discardVideo(String(job.ownerId), String(job.projectId), String(job.resultId)).catch(console.error);
    await videoQuota.release(String(job.ownerId), String(job.resultId)).catch(console.error);
    return fail(res, 409, 'JOB_CANCELLED');
  }
  await videoQuota.commit(String(done.ownerId), String(done.resultId)).catch(console.error);
  await settleQuota(done, 'confirm').catch(console.error);
  res.json(present(done));
});
router.post('/internal/trim/:jobId/fail', internal, async (req, res) => {
  const retry = req.body?.recoverable === true;
  const job = await Job.findOneAndUpdate({ _id: req.params.jobId, state: 'PROCESSING', attempt: req.body?.attempt },
    { $set: { state: retry && req.body.attempt < 2 ? 'QUEUED' : 'FAILED',
      progress: 0, error: String(req.body?.error || 'PROCESSING_FAILED').slice(0, 120),
      finishedAt: retry && req.body.attempt < 2 ? null : new Date() } }, { new: true });
  if (!job) return fail(res, 409, 'NOT_PROCESSING');
  await videoQuota.release(String(job.ownerId), String(job.resultId)).catch(console.error);
  if (job.state === 'QUEUED') {
    try {
      await publish(String(job.id));
      await Job.updateOne({ _id: job.id }, { $set: { lastPublishedAt: new Date() } });
    }
    catch (error) {
      await Job.updateOne({ _id: job.id, state: 'QUEUED' },
        { $set: { state: 'FAILED', error: 'QUEUE_UNAVAILABLE', finishedAt: new Date() } });
      return fail(res, 503, 'QUEUE_UNAVAILABLE');
    }
  }
  if (job.state === 'FAILED') await settleQuota(job, 'refund').catch(console.error);
  return res.sendStatus(204);
});
module.exports = router;
