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
const { send_msg_project_op } = require('../utils/project_msg');
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
  const st = (job.state || '').toLowerCase();
  return { id: String(job.id), jobId: String(job.id), state: job.state, status: st, progress: job.progress, attempt: job.attempt,
    sourceId: String(job.sourceId),
    resultId: job.state === 'COMPLETED' ? String(job.resultId) : null,
    newVideoId: job.state === 'COMPLETED' ? String(job.resultId) : null,
    newVideoName: job.name,
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
  let { start, end, mode = 'precise', startTime, endTime, fastTrim } = req.body || {};
  if (start === undefined && startTime !== undefined) start = startTime;
  if (end === undefined && endTime !== undefined) end = endTime;
  if (typeof start === 'string') start = parseFloat(start);
  if (typeof end === 'string') end = parseFloat(end);
  if (typeof start === 'number' && Number.isFinite(start)) start = Math.round(start * 100) / 100;
  if (typeof end === 'number' && Number.isFinite(end)) end = Math.round(end * 100) / 100;
  if (fastTrim && !req.body.mode) mode = 'fast';
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
    return res.status(202).json({ ...present(job), jobId: String(job.id) });
  } catch (error) { console.error('Trim submit:', error.message); return fail(res, 503, 'TRIM_UNAVAILABLE'); }
});
const getJobHandler = async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await Job.findOne({ _id: req.params.jobId, projectId: req.params.project, ownerId: req.params.user });
  return job ? res.json({ ...present(job), jobId: String(job.id) }) : fail(res, 404, 'JOB_NOT_FOUND');
};
router.get(`${base}/trim/jobs/:jobId`, access, getJobHandler);
router.get(`${base}/trim/:jobId`, access, getJobHandler);

const cancelJobHandler = async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await Job.findOneAndUpdate({ _id: req.params.jobId, projectId: req.params.project, ownerId: req.params.user,
    state: { $in: ['QUEUED', 'PROCESSING'] } },
    { $set: { state: 'CANCELLED', finishedAt: new Date() } }, { new: true });
  if (job) {
    await settleQuota(job, 'refund').catch(console.error);
    await videoQuota.release(String(job.ownerId), String(job.resultId)).catch(console.error);
    try {
      send_msg_project_op({
        projectId: String(job.projectId),
        ownerId: String(job.ownerId),
        op: {
          type: 'video-trim-cancelled',
          jobId: String(job.id),
        },
      });
    } catch (e) { console.error('Socket op cancel error:', e); }
    return res.json(present(job));
  }
  const existing = await Job.findOne({ _id: req.params.jobId, projectId: req.params.project, ownerId: req.params.user });
  return fail(res, existing ? 409 : 404, existing ? 'JOB_NOT_CANCELLABLE' : 'JOB_NOT_FOUND');
};
router.delete(`${base}/trim/jobs/:jobId`, access, edit, cancelJobHandler);
router.delete(`${base}/trim/:jobId`, access, edit, cancelJobHandler);
router.post(`${base}/trim/jobs/:jobId/cancel`, access, edit, cancelJobHandler);
router.post(`${base}/trim/:jobId/cancel`, access, edit, cancelJobHandler);
router.get('/internal/trim/:jobId', internal, async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await Job.findById(req.params.jobId);
  if (!job) return fail(res, 404, 'JOB_NOT_FOUND');
  res.json({ ...present(job), jobId: String(job.id), ownerId: String(job.ownerId), projectId: String(job.projectId),
    resultId: String(job.resultId), sourceId: String(job.sourceId) });
});
router.post('/internal/trim/:jobId/claim', internal, async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await Job.findOneAndUpdate({ _id: req.params.jobId, state: 'QUEUED' },
    { $set: { state: 'PROCESSING', progress: 0, startedAt: new Date(),
      leaseUntil: new Date(Date.now() + 600000) }, $inc: { attempt: 1 } }, { new: true });
  return job ? res.json({ ...present(job), jobId: String(job.id), attempt: job.attempt, ownerId: String(job.ownerId), projectId: String(job.projectId), resultId: String(job.resultId) }) : fail(res, 409, 'NOT_QUEUED');
});
router.post('/internal/trim/:jobId/progress', internal, async (req, res) => {
  const progress = Number(req.body?.progress);
  if (!Number.isFinite(progress) || progress < 0 || progress > 99) return fail(res, 400, 'INVALID_PROGRESS');
  const job = await Job.findOneAndUpdate({ _id: req.params.jobId, state: 'PROCESSING', attempt: req.body?.attempt },
    { $max: { progress }, $set: { leaseUntil: new Date(Date.now() + 600000) } });
  if (job) {
    try {
      send_msg_project_op({
        projectId: String(job.projectId),
        ownerId: String(job.ownerId),
        op: {
          type: 'video-trim-progress',
          jobId: String(job.id),
          progress,
        },
      });
    } catch (e) { console.error('Socket op progress error:', e); }
    return res.sendStatus(204);
  }
  return fail(res, 409, 'NOT_PROCESSING');
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
  try {
    send_msg_project_op({
      projectId: String(done.projectId),
      ownerId: String(done.ownerId),
      op: {
        type: 'video-trim-completed',
        jobId: String(done.id),
        video: {
          id: String(video._id),
          _id: String(video._id),
          name: video.name,
          size: video.size,
          duration: video.duration,
          createdAt: video.createdAt,
        },
      },
    });
  } catch (e) { console.error('Socket op complete error:', e); }
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
  if (job.state === 'FAILED') {
    await settleQuota(job, 'refund').catch(console.error);
    try {
      send_msg_project_op({
        projectId: String(job.projectId),
        ownerId: String(job.ownerId),
        op: {
          type: 'video-trim-error',
          jobId: String(job.id),
          error: job.error,
        },
      });
    } catch (e) { console.error('Socket op error broadcast:', e); }
  }
  return res.sendStatus(204);
});
const CompileJob = require('../models/compileJob');
const compileQueue = require('../utils/compileQueue');
const { settleCompileQuota } = require('../utils/compileQuota');
 
const COMPILE_MIN_VIDEOS = 2; // RN1
const COMPILE_MAX_VIDEOS = Number(process.env.COMPILE_MAX_VIDEOS || 10);
// Questão em aberto Q2 do caso de uso: limites de duração total por plano (configuráveis)
const COMPILE_MAX_SECONDS = {
  free: Number(process.env.COMPILE_MAX_SECONDS_FREE || 600),
  premium: Number(process.env.COMPILE_MAX_SECONDS_PREMIUM || 3600),
};
const OBJECT_ID_RE = /^[0-9a-fA-F]{24}$/;
 
function validCompileName(name) {
  return typeof name === 'string' && name.length > 0 && name.length <= 255 &&
    !/[\\/\x00-\x1f\x7f]/.test(name) && name.toLowerCase().endsWith('.mp4');
}
 
function uniqueCompileName(name, taken) {
  if (!taken.has(name)) return name;
  const stem = name.replace(/\.mp4$/i, '');
  let n = 2;
  while (taken.has(`${stem}-${n}.mp4`)) n++;
  return `${stem}-${n}.mp4`;
}
 
function presentCompile(job) {
  return { id: String(job.id), kind: 'compile', state: job.state, progress: job.progress, attempt: job.attempt,
    sourceIds: (job.sourceIds || []).map(String),
    resultId: job.state === 'COMPLETED' ? String(job.resultId) : null,
    result: job.state === 'COMPLETED' && job.result ? {
      id: String(job.resultId), duration: job.result.duration,
      width: job.result.width, height: job.result.height,
      sourceVideoIds: (job.sourceIds || []).map(String), jobId: String(job.id),
    } : null,
    name: job.name, error: job.error || null,
    requestedBy: String(job.requestedBy), createdAt: job.createdAt,
    startedAt: job.startedAt || null, finishedAt: job.finishedAt || null };
}
 
// Criar uma compilação
router.post(`${base}/compile`, access, edit, async (req, res) => {
  const { project, caller } = req.trim;
  const { videoIds, newName } = req.body || {};
 
  // RN1 / FA2: mínimo de dois vídeos
  if (!Array.isArray(videoIds) || videoIds.length < COMPILE_MIN_VIDEOS) return fail(res, 400, 'MIN_VIDEOS');
  if (videoIds.length > COMPILE_MAX_VIDEOS) return fail(res, 400, 'TOO_MANY_VIDEOS');
  if (!videoIds.every(id => typeof id === 'string' && OBJECT_ID_RE.test(id))) return fail(res, 400, 'INVALID_ID');
 
  // Todos os vídeos têm de existir neste projeto
  const sources = [];
  for (const id of videoIds) {
    const video = project.videos.id(id);
    if (!video) return fail(res, 404, 'VIDEO_NOT_FOUND');
    if (video.codec !== 'h264' || video.contentType !== 'video/mp4') return fail(res, 415, 'UNSUPPORTED_VIDEO');
    sources.push(video);
  }
 
  try {
    const response = await axios.get(`https://users:10001/${caller}/type`, { httpsAgent });
    const plan = response.data?.type;
    if (!['free', 'premium'].includes(plan)) return fail(res, 403, 'PLAN_FORBIDDEN');
 
    // Limite de duração total (só se todas as durações forem conhecidas; o worker volta a verificar)
    if (sources.every(v => Number.isFinite(v.duration))) {
      const total = sources.reduce((sum, v) => sum + v.duration, 0);
      if (total > COMPILE_MAX_SECONDS[plan]) return fail(res, 422, 'COMPILE_TOO_LONG');
    }
 
    // REQ-006: espaço de armazenamento (a reserva exata é feita pelo worker com o tamanho real)
    const storage = await videoQuota.usage(req.params.user);
    if (storage.used >= storage.limit) return fail(res, 507, 'STORAGE_QUOTA_EXCEEDED');
 
    // Nome do vídeo novo: nunca sobrepõe um existente (RN4)
    const jobId = new mongoose.Types.ObjectId();
    const resultId = new mongoose.Types.ObjectId();
    const taken = new Set((project.videos || []).map(v => v.name));
    let name = typeof newName === 'string' ? newName.trim() : '';
    if (name) {
      if (!/\.mp4$/i.test(name)) name += '.mp4';
      if (!validCompileName(name)) return fail(res, 400, 'INVALID_VIDEO_NAME');
      name = uniqueCompileName(name, taken);
    } else {
      name = uniqueCompileName('compilation.mp4', taken);
    }
 
    const job = await CompileJob.create({ _id: jobId, ownerId: req.params.user, projectId: req.params.project,
      sourceIds: videoIds, resultId, requestedBy: caller, name, quotaReserved: plan === 'free' });
 
    // REQ-005: quota diária de operações (utilizadores free), igual ao trim
    if (plan === 'free') {
      try { await quota(String(caller), String(job.id), 'reserve'); }
      catch (error) {
        await CompileJob.updateOne({ _id: job.id }, { $set: { state: 'FAILED', error: 'QUOTA_UNAVAILABLE', finishedAt: new Date() } });
        if (error.status === 429) return fail(res, 429, 'DAILY_QUOTA_EXHAUSTED');
        throw error;
      }
    }
    try {
      await compileQueue.publish(String(job.id));
      await CompileJob.updateOne({ _id: job.id }, { $set: { lastPublishedAt: new Date() } });
    } catch (error) {
      await CompileJob.updateOne({ _id: job.id, state: 'QUEUED' },
        { $set: { state: 'FAILED', error: 'QUEUE_UNAVAILABLE', finishedAt: new Date() } });
      if (plan === 'free') await settleCompileQuota(job, 'refund').catch(console.error);
      throw error;
    }
    return res.status(202).json(presentCompile(job));
  } catch (error) {
    console.error('Compile submit:', error.message);
    return fail(res, 503, 'COMPILE_UNAVAILABLE');
  }
});
 
router.get(`${base}/compile/jobs`, access, async (req, res) => {
  const jobs = await CompileJob.find({ projectId: req.params.project, ownerId: req.params.user })
    .sort({ createdAt: -1 }).limit(50);
  res.json(jobs.map(presentCompile));
});
 
router.get(`${base}/compile/jobs/:jobId`, access, async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await CompileJob.findOne({ _id: req.params.jobId, projectId: req.params.project, ownerId: req.params.user });
  return job ? res.json(presentCompile(job)) : fail(res, 404, 'JOB_NOT_FOUND');
});
 
// Exceção 6: cancelar durante o processamento
router.delete(`${base}/compile/jobs/:jobId`, access, edit, async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await CompileJob.findOneAndUpdate({ _id: req.params.jobId, projectId: req.params.project,
    ownerId: req.params.user, state: { $in: ['QUEUED', 'PROCESSING'] } },
    { $set: { state: 'CANCELLED', finishedAt: new Date() } }, { new: true });
  if (job) {
    await settleCompileQuota(job, 'refund').catch(console.error);
    await videoQuota.release(String(job.ownerId), String(job.resultId)).catch(console.error);
    return res.json(presentCompile(job));
  }
  const existing = await CompileJob.findOne({ _id: req.params.jobId, projectId: req.params.project, ownerId: req.params.user });
  return fail(res, existing ? 409 : 404, existing ? 'JOB_NOT_CANCELLABLE' : 'JOB_NOT_FOUND');
});
 
// ---------- Endpoints internos (usados só pelo worker) ----------
router.get('/internal/compile/:jobId', internal, async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await CompileJob.findById(req.params.jobId);
  if (!job) return fail(res, 404, 'JOB_NOT_FOUND');
  res.json({ ...presentCompile(job), ownerId: String(job.ownerId), projectId: String(job.projectId),
    resultId: String(job.resultId) });
});
 
router.post('/internal/compile/:jobId/claim', internal, async (req, res) => {
  if (!oid(req.params.jobId)) return fail(res, 400, 'INVALID_ID');
  const job = await CompileJob.findOneAndUpdate({ _id: req.params.jobId, state: 'QUEUED' },
    { $set: { state: 'PROCESSING', progress: 0, startedAt: new Date(),
      leaseUntil: new Date(Date.now() + 1800000) }, $inc: { attempt: 1 } }, { new: true });
  return job
    ? res.json({ ...presentCompile(job), attempt: job.attempt, ownerId: String(job.ownerId),
        projectId: String(job.projectId), resultId: String(job.resultId) })
    : fail(res, 409, 'NOT_QUEUED');
});
 
router.post('/internal/compile/:jobId/progress', internal, async (req, res) => {
  const progress = Number(req.body?.progress);
  if (!Number.isFinite(progress) || progress < 0 || progress > 99) return fail(res, 400, 'INVALID_PROGRESS');
  const job = await CompileJob.findOneAndUpdate({ _id: req.params.jobId, state: 'PROCESSING', attempt: req.body?.attempt },
    { $max: { progress }, $set: { leaseUntil: new Date(Date.now() + 1800000) } });
  return job ? res.sendStatus(204) : fail(res, 409, 'NOT_PROCESSING');
});
 
router.post('/internal/compile/:jobId/storage/reserve', internal, async (req, res) => {
  const job = await CompileJob.findOne({ _id: req.params.jobId, state: 'PROCESSING', attempt: req.body?.attempt });
  if (!job) return fail(res, 409, 'NOT_PROCESSING');
  try {
    await videoQuota.reserve(String(job.ownerId), String(job.resultId), req.body?.size);
    return res.sendStatus(204);
  } catch (error) {
    return fail(res, error.status || 503, error.message || 'STORAGE_UNAVAILABLE');
  }
});
 
router.post('/internal/compile/:jobId/storage/release', internal, async (req, res) => {
  const job = await CompileJob.findById(req.params.jobId);
  if (!job) return fail(res, 404, 'JOB_NOT_FOUND');
  await videoQuota.release(String(job.ownerId), String(job.resultId));
  res.sendStatus(204);
});
 
router.post('/internal/compile/:jobId/complete', internal, async (req, res) => {
  const job = await CompileJob.findOne({ _id: req.params.jobId, state: 'PROCESSING', attempt: req.body?.attempt });
  if (!job) return fail(res, 409, 'NOT_PROCESSING');
  const { size, duration, width, height } = req.body || {};
  if (!Number.isSafeInteger(size) || size < 1 || ![duration, width, height].every(x => Number.isFinite(x) && x > 0)) {
    return fail(res, 400, 'INVALID_RESULT');
  }
  const video = { _id: job.resultId, name: job.name, key: `${job.projectId}/video/${job.resultId}.mp4`, size,
    codec: 'h264', contentType: 'video/mp4', uploadedBy: job.requestedBy,
    duration, width, height, sourceVideoIds: job.sourceIds, compileJobId: job.id, createdAt: new Date() };
  // Os vídeos de origem têm de continuar no projeto (RN3: nunca são alterados) e o nome não pode ter sido tomado
  const distinctSources = [...new Set((job.sourceIds || []).map(String))];
  const updated = await Project.findOneAndUpdate({ _id: job.projectId, user_id: job.ownerId,
    'videos.name': { $ne: job.name },
    $and: distinctSources.map(id => ({ 'videos._id': id })) },
    { $push: { videos: video }, $inc: { version: 1 } });
  if (!updated) return fail(res, 409, 'PROJECT_CHANGED');
  const done = await CompileJob.findOneAndUpdate({ _id: job.id, state: 'PROCESSING', attempt: req.body?.attempt },
    { $set: { state: 'COMPLETED', progress: 100, result: video, finishedAt: new Date() } }, { new: true });
  if (!done) {
    await Project.updateOne({ _id: job.projectId }, { $pull: { videos: { _id: job.resultId } }, $inc: { version: 1 } });
    await discardVideo(String(job.ownerId), String(job.projectId), String(job.resultId)).catch(console.error);
    await videoQuota.release(String(job.ownerId), String(job.resultId)).catch(console.error);
    return fail(res, 409, 'JOB_CANCELLED');
  }
  await videoQuota.commit(String(done.ownerId), String(done.resultId)).catch(console.error);
  await settleCompileQuota(done, 'confirm').catch(console.error);
  try {
      send_msg_project_op({
        projectId: String(done.projectId),
        ownerId: String(done.ownerId),
        op: {
          type: 'video-compile-completed',
          jobId: String(done.id),
          video: { id: String(video._id), _id: String(video._id), name: video.name, size: video.size,
            duration: video.duration, createdAt: video.createdAt },
        },
      });
    } catch (e) { console.error('Socket op complete error:', e); }
  res.json(presentCompile(done));
});
 
router.post('/internal/compile/:jobId/fail', internal, async (req, res) => {
  const retry = req.body?.recoverable === true;
  const job = await CompileJob.findOneAndUpdate({ _id: req.params.jobId, state: 'PROCESSING', attempt: req.body?.attempt },
    { $set: { state: retry && req.body.attempt < 2 ? 'QUEUED' : 'FAILED',
      progress: 0, error: String(req.body?.error || 'PROCESSING_FAILED').slice(0, 120),
      finishedAt: retry && req.body.attempt < 2 ? null : new Date() } }, { new: true });
  if (!job) return fail(res, 409, 'NOT_PROCESSING');
  await videoQuota.release(String(job.ownerId), String(job.resultId)).catch(console.error);
  if (job.state === 'QUEUED') {
    try {
      await compileQueue.publish(String(job.id));
      await CompileJob.updateOne({ _id: job.id }, { $set: { lastPublishedAt: new Date() } });
    } catch (error) {
      await CompileJob.updateOne({ _id: job.id, state: 'QUEUED' },
        { $set: { state: 'FAILED', error: 'QUEUE_UNAVAILABLE', finishedAt: new Date() } });
      return fail(res, 503, 'QUEUE_UNAVAILABLE');
    }
  }
  if (job.state === 'FAILED') await settleCompileQuota(job, 'refund').catch(console.error);
  return res.sendStatus(204);
});
module.exports = router;
