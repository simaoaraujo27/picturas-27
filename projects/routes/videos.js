const express = require("express");
const jwt = require("jsonwebtoken");
const axios = require("axios");
const https = require("https");
const fs = require("fs");
const os = require("os");
const path = require("path");
const crypto = require("crypto");
const multer = require("multer");
const { execFile } = require("child_process");
const { promisify } = require("util");
const mongoose = require("mongoose");
const Project = require("../models/project");
const { storeVideo, discardVideo, getVideoInternalUrl } = require("../utils/videoStorage");
const { send_rabbit_msg, read_rabbit_msg } = require("../utils/rabbit_mq");
const { send_msg_project_op } = require("../utils/project_msg");

const VideoJob = require("../models/videoJob");
const VideoAudit = require("../models/videoAudit");
const videoQuota = require("../utils/videoQuota");

const router = express.Router();
const execFileAsync = promisify(execFile);
const httpsAgent = new https.Agent({ rejectUnauthorized: false });
const sizes = { free: 1_000_000_000, premium: 5_000_000_000 };

async function getUserVideoStorage(userId) {
  const userProjects = await Project.find({ user_id: userId }, "videos.size");
  let total = 0;
  for (const proj of userProjects) {
    for (const vid of proj.videos || []) {
      total += (vid.size || 0);
    }
  }
  return total;
}

function fail(res, status, code, message) {
  return res.status(status).json({ code, message });
}

function validName(name) {
  return typeof name === "string" && name.length > 0 && name.length <= 255 &&
    path.basename(name) === name && !/[\\/\x00-\x1f\x7f]/.test(name) &&
    name.toLowerCase().endsWith(".mp4");
}

function authorizeAccess(requireEdit) { return async function (req, res, next) {
  try {
    const token = /^Bearer (.+)$/.exec(req.get("Authorization") || "")?.[1];
    if (!token) return fail(res, 401, "AUTH_REQUIRED", "Authentication required");
    const payload = jwt.verify(token, process.env.JWT_SECRET_KEY);
    if (!mongoose.isValidObjectId(payload.id) ||
        !mongoose.isValidObjectId(req.params.user) || !mongoose.isValidObjectId(req.params.project)) {
      return fail(res, 400, "INVALID_ID", "Invalid identifier");
    }
    const project = await Project.findOne({ _id: req.params.project, user_id: req.params.user });
    if (!project) return fail(res, 404, "PROJECT_NOT_FOUND", "Project not found");
    const owner = String(payload.id) === String(project.user_id);
    const share = req.query.share && (project.sharedLinks || []).find(
      (link) => link.id === req.query.share && !link.revoked &&
        (!requireEdit || link.permission === "edit")
    );
    if (!owner && !share) return fail(res, 403, "ACCESS_FORBIDDEN", "Project permission required");
    req.videoProject = project;
    req.videoCallerId = payload.id;
    next();
  } catch (error) {
    if (error.name === "JsonWebTokenError" || error.name === "TokenExpiredError") {
      return fail(res, 401, "INVALID_TOKEN", "Invalid or expired token");
    }
    console.error("Video authorization failed:", error);
    return fail(res, 503, "PROJECT_UNAVAILABLE", "Project lookup failed");
  }
}; }
const authorize = authorizeAccess(true);
const authorizeRead = authorizeAccess(false);

function associatedVideo(req, res, next) {
  if (!mongoose.isValidObjectId(req.params.videoId)) {
    return fail(res, 400, "INVALID_ID", "Invalid video identifier");
  }
  const video = req.videoProject.videos.id(req.params.videoId);
  if (!video) return fail(res, 404, "VIDEO_NOT_FOUND", "Video not found in this project");
  const expectedKey = `${req.params.project}/video/${req.params.videoId}.mp4`;
  if (video.key !== expectedKey) return fail(res, 409, "VIDEO_KEY_MISMATCH", "Video storage reference is inconsistent");
  req.videoRecord = video.toObject();
  next();
}

async function checkUpload(req, res, next) {
  const name = req.videoName;
  const size = req.videoSize;
  if (!validName(name) || !Number.isSafeInteger(size) || size < 1) {
    return fail(res, 400, "INVALID_VIDEO", "A single MP4 file name and size are required");
  }
  try {
    const type = await axios.get(`https://users:10001/${req.videoCallerId}/type`, { httpsAgent });
    const maxSize = sizes[type.data?.type];
    if (!maxSize) return fail(res, 403, "PLAN_FORBIDDEN", "Video upload requires a Free or Premium plan");
    if (size > maxSize) return fail(res, 413, "VIDEO_TOO_LARGE", "Video exceeds the plan limit");
    if ((req.videoProject.videos || []).some((video) => video.name === name)) {
      return fail(res, 409, "VIDEO_NAME_EXISTS", "Change the file name: a video with this complete name already exists in this project");
    }
    req.videoLimit = maxSize;
    next();
  } catch (error) {
    console.error("Video plan lookup failed:", error);
    return fail(res, 503, "PLAN_UNAVAILABLE", "Plan lookup failed");
  }
}

function checkVersion(req, res, next) {
  const version = Number(req.get("X-Project-Version"));
  if (!Number.isSafeInteger(version) || version < 0) {
    return fail(res, 428, "VERSION_REQUIRED", "X-Project-Version is required");
  }
  if (version !== req.videoProject.version) {
    return fail(res, 409, "PROJECT_CONFLICT", "Project version conflict");
  }
  req.videoVersion = version;
  next();
}

router.post("/:user/:project/video/check", express.json(), authorize, checkVersion, (req, res, next) => {
  req.videoName = req.body?.name;
  req.videoSize = req.body?.size;
  next();
}, checkUpload, (req, res) => res.json({ accepted: true, maxSize: req.videoLimit }));

router.get("/:user/:project/video/:videoId", authorizeRead, associatedVideo, async (req, res) => {
  try {
    const url = await getVideoInternalUrl(req.params.user, req.params.project, req.params.videoId);
    const response = await axios.get(url, { responseType: "stream", timeout: 0 });
    res.set({
      "Content-Type": "video/mp4",
      "Content-Length": String(req.videoRecord.size),
      "Content-Disposition": `attachment; filename*=UTF-8''${encodeURIComponent(req.videoRecord.name)}`,
      "Cache-Control": "private, no-store",
      "X-Content-Type-Options": "nosniff",
    });
    response.data.on("error", (error) => { console.error("Video stream failed:", error); res.destroy(error); });
    res.on("close", () => response.data.destroy());
    response.data.pipe(res);
  } catch (error) {
    console.error("Video download failed:", error.message);
    if (!res.headersSent) return fail(res, 502, "VIDEO_DOWNLOAD_FAILED", "Video could not be read");
    res.destroy(error);
  }
});

// A short-lived playback URL lets the HTML5 player use HTTP Range without
// exposing the internal SeaweedFS address or requiring an Authorization header.
router.get('/:user/:project/video/:videoId/playback', authorizeRead, associatedVideo, (req, res) => {
  const token = jwt.sign({ purpose: 'video-playback', owner: req.params.user,
    project: req.params.project, videoId: req.params.videoId,
    caller: String(req.videoCallerId), share: req.query.share || null },
  process.env.JWT_SECRET_KEY, { expiresIn: '5m' });
  res.set('Cache-Control', 'private, no-store');
  const playbackPath = `/api-gateway/projects/${req.params.user}/${req.params.project}/video/${req.params.videoId}/play`;
  res.cookie('picturas_playback', token, { httpOnly: true, secure: true, sameSite: 'strict',
    maxAge: 300000, path: playbackPath });
  res.json({ url: playbackPath, expiresIn: 300 });
});

router.get('/:user/:project/video/:videoId/play', async (req, res) => {
  try {
    const payload = jwt.verify(String(req.cookies.picturas_playback || ''), process.env.JWT_SECRET_KEY);
    if (payload.purpose !== 'video-playback' || payload.owner !== req.params.user ||
      payload.project !== req.params.project || payload.videoId !== req.params.videoId) {
      return fail(res, 403, 'INVALID_PLAYBACK_TOKEN', 'Invalid playback token');
    }
    const project = await Project.findOne({ _id: req.params.project, user_id: req.params.user });
    if (!project) return fail(res, 404, 'PROJECT_NOT_FOUND', 'Project not found');
    const owner = String(project.user_id) === payload.caller;
    const shared = (project.sharedLinks || []).some(x => x.id === payload.share && !x.revoked);
    if (!owner && !shared) return fail(res, 403, 'ACCESS_FORBIDDEN', 'Project permission required');
    const video = project.videos.id(req.params.videoId);
    if (!video || video.key !== `${req.params.project}/video/${req.params.videoId}.mp4`) {
      return fail(res, 404, 'VIDEO_NOT_FOUND', 'Video not found');
    }
    const url = await getVideoInternalUrl(req.params.user, req.params.project, req.params.videoId);
    const response = await axios.get(url, { responseType: 'stream', timeout: 0,
      headers: req.get('Range') ? { Range: req.get('Range') } : {},
      validateStatus: status => status === 200 || status === 206 || status === 416 });
    res.status(response.status);
    for (const header of ['content-length', 'content-range', 'accept-ranges']) {
      if (response.headers[header]) res.set(header, response.headers[header]);
    }
    res.set({ 'Content-Type': 'video/mp4', 'Cache-Control': 'private, no-store',
      'X-Content-Type-Options': 'nosniff',
      'Content-Disposition': req.query.download === '1' ?
        `attachment; filename*=UTF-8''${encodeURIComponent(video.name)}` : 'inline' });
    response.data.on('error', error => { console.error('Playback stream failed:', error.message); res.destroy(error); });
    res.on('close', () => response.data.destroy());
    response.data.pipe(res);
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return fail(res, 403, 'INVALID_PLAYBACK_TOKEN', 'Expired or invalid playback token');
    }
    console.error('Video playback failed:', error.message);
    if (!res.headersSent) return fail(res, 502, 'PLAYBACK_FAILED', 'Video playback failed');
    res.destroy(error);
  }
});

router.delete("/:user/:project/video/:videoId", authorize, checkVersion, associatedVideo, async (req, res) => {
  const { user, project, videoId } = req.params;
  const video = req.videoRecord;
  try {
    const updated = await Project.findOneAndUpdate(
      { _id: project, user_id: user, version: req.videoVersion,
        videos: { $elemMatch: { _id: video._id, key: video.key, name: video.name } } },
      { $pull: { videos: { _id: video._id, key: video.key, name: video.name } }, $inc: { version: 1 } },
      { new: true }
    );
    if (!updated) return fail(res, 409, "PROJECT_CONFLICT", "Project or video changed");
    let storageError;
    for (let attempt = 0; attempt < 2; attempt++) {
      try { await discardVideo(user, project, videoId); storageError = null; break; }
      catch (error) { storageError = error; }
    }
    if (storageError) {
      // A storage failure must not leave a successful-looking deletion.
      // Restore only if this exact video is still absent; preserve concurrent edits.
      let restored = null;
      try {
        restored = await Project.findOneAndUpdate(
          { _id: project, user_id: user, "videos._id": { $ne: video._id },
            "videos.name": { $ne: video.name } },
          { $push: { videos: video }, $inc: { version: 1 } },
          { new: true }
        );
      } catch (restoreError) { console.error("Video restore failed:", restoreError); }
      console.error("Video storage delete failed:", { user, project, videoId, error: storageError.message, restored: !!restored });
      if (restored) res.set("X-Project-Version", String(restored.version));
      return fail(res, 502, restored ? "VIDEO_DELETE_FAILED" : "VIDEO_DELETE_INCOMPLETE",
        restored ? "Video storage deletion failed" : "Video deletion needs operator cleanup");
    }
    await videoQuota.release(user, videoId).catch(error => console.error('Video quota release failed:', error));
    res.set("X-Project-Version", String(updated.version));
    return res.sendStatus(204);
  } catch (error) {
    console.error("Video deletion failed:", error);
    return fail(res, 503, "PROJECT_UNAVAILABLE", "Video deletion failed");
  }
});

// Video bodies are always spooled to disk. Do not replace this with
// memoryStorage: the upload may be as large as 5 GB and must stay backpressured.
const disk = multer.diskStorage({
  destination: os.tmpdir(),
  filename: (_req, _file, cb) => cb(null, `picturas-video-${crypto.randomUUID()}`),
});

function receive(req, res, next) {
  const upload = multer({
    storage: disk,
    // Busboy marks a file as truncated when it reaches fileSize exactly.
    // Read one extra byte so a file exactly at the plan limit is accepted;
    // the route below rejects any actual size above the limit.
    limits: { fileSize: req.videoLimit + 1, files: 1, fields: 0 },
    fileFilter: (_req, file, cb) => {
      if (file.fieldname !== "video" || file.mimetype !== "video/mp4" || !validName(file.originalname)) {
        return cb(new Error("INVALID_VIDEO"));
      }
      cb(null, true);
    },
  }).single("video");
  upload(req, res, (error) => {
    if (error) {
      console.error("Video multipart rejected:", error.code, error.message);
      if (req.file?.path) fs.promises.unlink(req.file.path).catch(() => {});
      if (error.code === "LIMIT_FILE_SIZE") return fail(res, 413, "VIDEO_TOO_LARGE", "Video exceeds the plan limit");
      return fail(res, 400, "INVALID_VIDEO", "Expected exactly one MP4 file in field video");
    }
    next();
  });
}

async function inspectMp4(filePath) {
  const handle = await fs.promises.open(filePath, "r");
  const header = Buffer.alloc(12);
  try {
    await handle.read(header, 0, 12, 0);
  } finally {
    await handle.close();
  }
  const brand = header.toString("ascii", 8, 12);
  if (header.toString("ascii", 4, 8) !== "ftyp" ||
      !/^(iso.|mp4.|avc1|M4V |MSNV|dash)$/.test(brand)) {
    throw new Error("INVALID_MP4");
  }
  let info;
  try {
    const { stdout } = await execFileAsync("ffprobe", [
      "-v", "error", "-show_entries", "format=format_name,duration:stream=codec_name,codec_type,width,height",
      "-of", "json", filePath,
    ], { maxBuffer: 1024 * 1024 });
    info = JSON.parse(stdout);
  } catch (error) {
    if (error.code === "ENOENT") throw error;
    throw new Error("INVALID_MP4");
  }
  if (!info.format?.format_name?.includes("mp4") ||
      !info.streams?.some((stream) => stream.codec_type === "video" && stream.codec_name === "h264")) {
    throw new Error("INVALID_MP4");
  }
  const video = info.streams.find((stream) => stream.codec_type === "video" && stream.codec_name === "h264");
  const duration = Number(info.format.duration);
  if (!Number.isFinite(duration) || duration <= 0) throw new Error("INVALID_MP4");
  return { duration, width: video.width, height: video.height };
}

router.post("/:user/:project/video", authorize, checkVersion, (req, res, next) => {
  try {
    req.videoName = decodeURIComponent(req.get("X-Video-Name") || "");
  } catch (_) {
    return fail(res, 400, "INVALID_VIDEO", "Invalid video name header");
  }
  req.videoSize = Number(req.get("X-Video-Size"));
  next();
}, checkUpload, receive, async (req, res) => {
  const file = req.file;
  let needsCleanup = false;
  const videoId = new mongoose.Types.ObjectId();
  try {
    if (file && file.size > req.videoLimit) {
      return fail(res, 413, "VIDEO_TOO_LARGE", "Video exceeds the plan limit");
    }
    if (!file || file.originalname !== req.videoName || file.size !== req.videoSize) {
      return fail(res, 400, "INVALID_VIDEO", "Video name or size does not match the request");
    }
    const videoInfo = await inspectMp4(file.path);
    needsCleanup = true;
    await videoQuota.reserve(req.params.user, String(videoId), file.size);
    const key = await storeVideo(req.params.user, req.params.project, String(videoId), file.path, file.size);
    const video = {
      _id: videoId, name: file.originalname, key, size: file.size,
      codec: "h264", contentType: "video/mp4", uploadedBy: req.videoCallerId,
      duration: videoInfo.duration, width: videoInfo.width, height: videoInfo.height,
      createdAt: new Date(),
    };
    const updated = await Project.findOneAndUpdate(
      { _id: req.params.project, user_id: req.params.user, version: req.videoVersion, "videos.name": { $ne: video.name } },
      { $push: { videos: video }, $inc: { version: 1 } },
      { new: true }
    );
    if (!updated) return fail(res, 409, "PROJECT_CONFLICT", "Project changed or video name already exists");
    needsCleanup = false;
    await videoQuota.commit(req.params.user, String(videoId)).catch(error => console.error('Video quota commit failed:', error));
    res.set("X-Project-Version", String(updated.version));
    return res.status(201).json({
      id: String(videoId), projectId: String(updated._id), name: video.name,
      size: video.size, codec: video.codec, contentType: video.contentType,
      createdAt: video.createdAt,
    });
  } catch (error) {
    if (error.status === 507) return fail(res, 507, 'STORAGE_QUOTA_EXCEEDED', 'Account video storage quota exceeded');
    if (error.status === 403) return fail(res, 403, 'PLAN_FORBIDDEN', 'Account cannot store videos');
    if (error.message === "INVALID_MP4") {
      return fail(res, 415, "INVALID_MP4", "The file must contain MP4 video encoded with H.264");
    }
    console.error("Video upload failed:", error.message, error.response?.status);
    return fail(res, 502, "VIDEO_UPLOAD_FAILED", "Video storage or project association failed");
  } finally {
    if (needsCleanup) {
      try { await discardVideo(req.params.user, req.params.project, String(videoId)); }
      catch (error) { console.error("Could not remove unassociated video:", error); }
      await videoQuota.release(req.params.user, String(videoId)).catch(error => console.error('Could not release video quota:', error));
    }
    if (file?.path) {
      try { await fs.promises.unlink(file.path); }
      catch (error) { console.error("Could not remove temporary video:", error); }
    }
  }
});

router.get("/:user/video-storage", async (req, res) => {
  try {
    const token = /^Bearer (.+)$/.exec(req.get("Authorization") || "")?.[1];
    if (!token) return fail(res, 401, "AUTH_REQUIRED", "Authentication required");
    const payload = jwt.verify(token, process.env.JWT_SECRET_KEY);
    if (String(payload.id) !== String(req.params.user)) {
      return fail(res, 403, "ACCESS_FORBIDDEN", "Forbidden");
    }
    let userType = "free";
    try {
      const typeResp = await axios.get(`https://users:10001/${req.params.user}/type`, { httpsAgent });
      userType = typeResp.data?.type || "free";
    } catch (_) {}

    const usedBytes = await getUserVideoStorage(req.params.user);
    const maxBytes = sizes[userType] || sizes.free;
    const percentage = Math.min(100, Math.round((usedBytes / maxBytes) * 100));

    return res.json({
      user: req.params.user,
      plan: userType,
      usedBytes,
      maxBytes,
      percentage,
    });
  } catch (err) {
    if (err.name === "JsonWebTokenError" || err.name === "TokenExpiredError") {
      return fail(res, 401, "INVALID_TOKEN", "Invalid or expired token");
    }
    return fail(res, 500, "STORAGE_CHECK_FAILED", err.message);
  }
});

router.get("/:user/:project/video/trim/:jobId", authorizeRead, async (req, res) => {
  try {
    const job = await VideoJob.findOne({ jobId: req.params.jobId, projectId: req.params.project });
    if (!job) return fail(res, 404, "JOB_NOT_FOUND", "Trim job not found");
    return res.json({
      jobId: job.jobId,
      status: job.status,
      progress: job.progress || 0,
      error: job.error,
      newVideoId: String(job.newVideoId),
      newVideoName: job.newVideoName,
    });
  } catch (err) {
    return fail(res, 500, "JOB_LOOKUP_FAILED", err.message);
  }
});

router.post("/:user/:project/video/trim/:jobId/cancel", authorize, async (req, res) => {
  const { user, project, jobId } = req.params;
  try {
    const job = await VideoJob.findOne({ jobId, projectId: project });
    if (!job) return fail(res, 404, "JOB_NOT_FOUND", "Trim job not found");
    if (job.status === "completed") {
      return fail(res, 400, "JOB_ALREADY_COMPLETED", "Cannot cancel an already completed job");
    }
    if (job.status === "cancelled") {
      return res.json({ status: "cancelled", jobId });
    }

    job.status = "cancelled";
    job.completedAt = new Date();
    await job.save();

    // Notificar worker sobre o cancelamento
    send_rabbit_msg({ messageId: `cancel-${jobId}`, jobId, procedure: "video_trim_cancel" }, "video_trim_queue");

    // Estorno de quota diária para utilizador free
    if (job.userType === "free") {
      try {
        await axios.post(`https://users:10001/${job.callerId}/process/refund/1`, {}, { httpsAgent });
        console.log(`[VIDEO-TRIM] Refunded 1 daily operation for user ${job.callerId} due to cancellation`);
      } catch (refundErr) {
        console.error("[VIDEO-TRIM] Failed to refund operation on cancel:", refundErr.message);
      }
    }

    // Registo de auditoria de cancelamento (REQ-VID-TRIM-020)
    const executionTimeMs = job.createdAt ? Date.now() - job.createdAt.getTime() : 0;
    await VideoAudit.create({
      userId: job.userId,
      jobId: job.jobId,
      projectId: job.projectId,
      videoId: job.videoId,
      newVideoId: job.newVideoId,
      startTime: job.startTime,
      endTime: job.endTime,
      fastTrim: job.fastTrim,
      executionTimeMs,
      status: "cancelled",
      error: "CANCELLED_BY_USER",
    });

    // Purgar artefacto em storage se já tiver sido enviado
    try {
      await discardVideo(user, project, String(job.newVideoId));
    } catch (_) {}

    send_msg_project_op({
      projectId: project,
      ownerId: user,
      op: { type: "video-trim-cancelled", jobId },
    });

    return res.json({ status: "cancelled", jobId });
  } catch (err) {
    console.error("Cancel video trim failed:", err);
    return fail(res, 500, "CANCEL_FAILED", "Failed to cancel video trim task");
  }
});

router.post("/:user/:project/video/:videoId/trim", authorize, checkVersion, associatedVideo, async (req, res) => {
  const { user, project, videoId } = req.params;
  const startTime = Number(req.body?.startTime);
  const endTime = Number(req.body?.endTime);
  let newName = req.body?.newName;

  // 1. Verificar plano do utilizador e bloquear anónimos (RN7, REQ-VID-TRIM-019)
  let callerType = "free";
  try {
    const typeResp = await axios.get(`https://users:10001/${req.videoCallerId}/type`, { httpsAgent });
    callerType = typeResp.data?.type || "free";
  } catch (err) {
    console.error("Could not fetch user plan:", err.message);
  }

  if (callerType === "anonymous") {
    return fail(
      res,
      403,
      "ANONYMOUS_NOT_ALLOWED",
      "O processamento de vídeo requer uma conta PictuRAS. Crie uma conta gratuita (free) com 5 operações diárias e 1 GB de armazenamento ou inicie sessão para continuar."
    );
  }

  // 2. Validação temporal e duração mínima (RN3, REQ-VID-TRIM-004)
  if (!Number.isFinite(startTime) || !Number.isFinite(endTime) || startTime < 0 || endTime <= startTime || (endTime - startTime) < 1.0) {
    return fail(res, 400, "INVALID_TIME_BOUNDS", "O instante final deve ser estritamente superior ao inicial e o intervalo mínimo permitido é de 1.0 segundo.");
  }

  const snippetDuration = endTime - startTime;
  // Limites de duração por perfil (RN2, REQ-VID-TRIM-006)
  if (callerType === "free" && snippetDuration > 180) {
    return fail(res, 400, "DURATION_LIMIT_EXCEEDED", "A duração do excerto excede o limite de 3 minutos permitido para o seu perfil. Reduza o intervalo ou efetue upgrade para Premium.");
  }
  if (callerType === "premium" && snippetDuration > 3600) {
    return fail(res, 400, "DURATION_LIMIT_EXCEEDED", "A duração do excerto excede o limite máximo de 60 minutos suportado pela plataforma.");
  }

  // 3. Validação prévia da quota de armazenamento da conta (RN6, REQ-VID-TRIM-021)
  const currentStorage = await getUserVideoStorage(user);
  const maxStorage = sizes[callerType] || sizes.free;
  if (currentStorage >= maxStorage) {
    return fail(res, 403, "STORAGE_QUOTA_EXCEEDED", "Espaço de armazenamento insuficiente: a sua biblioteca atingiu o limite de quota da conta (1 GB para free / 5 GB para Premium). Elimine vídeos existentes ou subscreva o plano Premium para obter 5 GB.");
  }

  // 4. Débito provisório da quota diária para free (RN1, REQ-VID-TRIM-005, REQ-VID-TRIM-007)
  let debited = false;
  if (callerType === "free") {
    try {
      const opResp = await axios.get(`https://users:10001/${req.videoCallerId}/process/1`, { httpsAgent });
      if (!opResp.data) {
        return fail(res, 403, "DAILY_QUOTA_EXCEEDED", "Atingiu o limite diário de 5 operações gratuitas. Faça upgrade para Premium para utilização ilimitada ou tente novamente amanhã.");
      }
      debited = true;
    } catch (err) {
      if (err.response?.status === 701 || (typeof err.response?.data === "string" && err.response?.data?.includes("daily_operations"))) {
        return fail(res, 403, "DAILY_QUOTA_EXCEEDED", "Atingiu o limite diário de 5 operações gratuitas. Faça upgrade para Premium para utilização ilimitada ou tente novamente amanhã.");
      }
      console.error("Error checking/debiting free quota:", err.message);
      return fail(res, 503, "QUOTA_CHECK_FAILED", "Falha ao verificar a quota diária de operações.");
    }
  }

  // 5. Suporte a Recorte Rápido para Premium (FA2, REQ-VID-TRIM-011)
  const fastTrim = Boolean(req.body?.fastTrim && callerType === "premium");

  const existingNames = new Set((req.videoProject.videos || []).map((v) => v.name));
  const cleanBaseName = req.videoRecord.name
    .replace(/\.mp4$/i, "")
    .replace(/-trimmed(-\d+)?$/i, "");

  if (!newName || typeof newName !== "string" || !newName.trim()) {
    let candidate = `${cleanBaseName}-trimmed.mp4`;
    let counter = 2;
    while (existingNames.has(candidate)) {
      candidate = `${cleanBaseName}-trimmed-${counter}.mp4`;
      counter++;
    }
    newName = candidate;
  } else {
    newName = newName.trim();
    if (!newName.toLowerCase().endsWith(".mp4")) {
      newName = `${newName}.mp4`;
    }
    if (existingNames.has(newName)) {
      const base = newName.replace(/\.mp4$/i, "").replace(/-trimmed(-\d+)?$/i, "");
      let candidate = `${base}-trimmed.mp4`;
      let counter = 2;
      while (existingNames.has(candidate)) {
        candidate = `${base}-trimmed-${counter}.mp4`;
        counter++;
      }
      newName = candidate;
    }
  }

  if (!validName(newName)) {
    if (debited) {
      await axios.post(`https://users:10001/${req.videoCallerId}/process/refund/1`, {}, { httpsAgent }).catch(() => {});
    }
    return fail(res, 400, "INVALID_VIDEO_NAME", "Invalid video file name");
  }

  const newVideoId = new mongoose.Types.ObjectId();
  const messageId = `request-trim-${crypto.randomUUID()}`;

  // Criar registo do Job para monitorização e cancelamento (REQ-VID-TRIM-008, REQ-VID-TRIM-022)
  try {
    await VideoJob.create({
      jobId: messageId,
      userId: new mongoose.Types.ObjectId(user),
      callerId: new mongoose.Types.ObjectId(req.videoCallerId),
      userType: callerType,
      projectId: new mongoose.Types.ObjectId(project),
      videoId: new mongoose.Types.ObjectId(videoId),
      newVideoId,
      newVideoName: newName,
      startTime,
      endTime,
      fastTrim,
      status: "queued",
      progress: 0,
    });
  } catch (jobErr) {
    console.error("Failed to persist VideoJob:", jobErr);
    if (debited) {
      await axios.post(`https://users:10001/${req.videoCallerId}/process/refund/1`, {}, { httpsAgent }).catch(() => {});
    }
    return fail(res, 500, "JOB_CREATION_FAILED", "Failed to initialize video trim job");
  }

  const message = {
    messageId,
    timestamp: new Date().toISOString(),
    procedure: "video_trim",
    parameters: {
      ownerId: user,
      projectId: project,
      videoId,
      newVideoId: String(newVideoId),
      newVideoName: newName,
      startTime,
      endTime,
      fastTrim,
      size: req.videoRecord.size,
      callerId: String(req.videoCallerId),
      callerType,
      projectVersion: req.videoVersion,
    },
  };

  try {
    send_rabbit_msg(message, "video_trim_queue");
    return res.status(202).json({
      messageId,
      jobId: messageId,
      newVideoId: String(newVideoId),
      newVideoName: newName,
      status: "queued",
    });
  } catch (error) {
    console.error("Failed to enqueue video trim task:", error);
    if (debited) {
      await axios.post(`https://users:10001/${req.videoCallerId}/process/refund/1`, {}, { httpsAgent }).catch(() => {});
    }
    await VideoJob.findOneAndUpdate({ jobId: messageId }, { status: "failed", error: "QUEUE_ERROR" }).catch(() => {});
    return fail(res, 500, "QUEUE_ERROR", "Failed to enqueue video trim task");
  }
});

function enqueueVideoSpeedTask(req, res, parameters) {
  const operation = "speed";
  const { user, project, videoId } = req.params;
  let newName = req.body?.newName;
  const suffix = "speed";
  const suffixPattern = new RegExp(`-${suffix}(-\\d+)?$`, "i");
  const existingNames = new Set((req.videoProject.videos || []).map((v) => v.name));
  const cleanBaseName = req.videoRecord.name
    .replace(/\.mp4$/i, "")
    .replace(suffixPattern, "");

  if (!newName || typeof newName !== "string" || !newName.trim()) {
    let candidate = `${cleanBaseName}-${suffix}.mp4`;
    let counter = 2;
    while (existingNames.has(candidate)) {
      candidate = `${cleanBaseName}-${suffix}-${counter}.mp4`;
      counter++;
    }
    newName = candidate;
  } else {
    newName = newName.trim();
    if (!newName.toLowerCase().endsWith(".mp4")) {
      newName = `${newName}.mp4`;
    }
    if (existingNames.has(newName)) {
      const base = newName.replace(/\.mp4$/i, "").replace(suffixPattern, "");
      let candidate = `${base}-${suffix}.mp4`;
      let counter = 2;
      while (existingNames.has(candidate)) {
        candidate = `${base}-${suffix}-${counter}.mp4`;
        counter++;
      }
      newName = candidate;
    }
  }

  if (!validName(newName)) {
    return fail(res, 400, "INVALID_VIDEO_NAME", "Invalid video file name");
  }

  const newVideoId = new mongoose.Types.ObjectId();
  const messageId = `request-${operation}-${crypto.randomUUID()}`;

  const message = {
    messageId,
    timestamp: new Date().toISOString(),
    procedure: `video_${operation}`,
    parameters: {
      ownerId: user,
      projectId: project,
      videoId,
      newVideoId: String(newVideoId),
      newVideoName: newName,
      ...parameters,
      size: req.videoRecord.size,
      callerId: String(req.videoCallerId),
      projectVersion: req.videoVersion,
    },
  };

  try {
    send_rabbit_msg(message, `video_${operation}_queue`);
    return res.status(202).json({
      messageId,
      newVideoId: String(newVideoId),
      newVideoName: newName,
      status: "queued",
    });
  } catch (error) {
    console.error(`Failed to enqueue video ${operation} task:`, error);
    return fail(res, 500, "QUEUE_ERROR", `Failed to enqueue video ${operation} task`);
  }
}

router.post("/:user/:project/video/:videoId/speed", authorize, checkVersion, associatedVideo, async (req, res) => {
  const intervals = req.body?.intervals;
  if (!Array.isArray(intervals) || intervals.length === 0) {
    return fail(res, 400, "INVALID_INTERVALS", "A non-empty list of intervals is required");
  }
  const normalized = [];
  for (const interval of intervals) {
    if (!interval || !Number.isFinite(interval.startTime) || !Number.isFinite(interval.endTime) ||
        interval.startTime < 0 || interval.endTime <= interval.startTime ||
        ![0.5, 1, 2].includes(interval.speed)) {
      return fail(res, 400, "INVALID_INTERVALS", "Intervals require valid time bounds and a speed of 0.5, 1 or 2");
    }
    normalized.push({ startTime: interval.startTime, endTime: interval.endTime, speed: interval.speed });
  }
  normalized.sort((a, b) => a.startTime - b.startTime);
  for (let i = 1; i < normalized.length; i++) {
    if (normalized[i].startTime < normalized[i - 1].endTime) {
      return fail(res, 400, "INVALID_INTERVALS", "Intervals must not overlap");
    }
  }
  if (req.body.newName !== undefined && typeof req.body.newName !== "string") {
    return fail(res, 400, "INVALID_VIDEO_NAME", "Invalid video file name");
  }
  return enqueueVideoSpeedTask(req, res, { intervals: normalized });
});

async function processVideoSpeedResult(data) {
  const { ownerId, projectId, newVideoId, newVideoName, size, callerId } = data.parameters || {};

  if (data.status === "success") {
    const video = {
      _id: new mongoose.Types.ObjectId(newVideoId),
      name: newVideoName,
      key: `${projectId}/video/${newVideoId}.mp4`,
      size,
      codec: "h264",
      contentType: "video/mp4",
      uploadedBy: callerId ? new mongoose.Types.ObjectId(callerId) : new mongoose.Types.ObjectId(ownerId),
      createdAt: new Date(),
    };

    const association = { _id: projectId, user_id: ownerId, "videos._id": newVideoId };
    let needsCleanup = true;
    try {
      if (await Project.findOne(association)) {
        needsCleanup = false;
        await videoQuota.commit(ownerId, String(newVideoId));
        return;
      }
      await videoQuota.reserve(ownerId, String(newVideoId), size);
      const updated = await Project.findOneAndUpdate(
        { _id: projectId, user_id: ownerId, "videos.name": { $ne: video.name } },
        { $push: { videos: video }, $inc: { version: 1 } },
        { new: true }
      );
      if (!updated) {
        console.warn(`[VIDEO-SPEED] Project not found or duplicate video name: ${newVideoName}`);
        return;
      }
      // Once associated, keep the bytes charged even if finalizing the entry fails.
      needsCleanup = false;
      await videoQuota.commit(ownerId, String(newVideoId)).catch(error => {
        console.error("[VIDEO-SPEED] Video quota commit failed:", error);
      });
      send_msg_project_op({
        projectId,
        ownerId,
        op: { type: "add-video", video },
      });
      console.log(`[VIDEO-SPEED] Successfully added speed-adjusted video ${newVideoName} (${newVideoId}) to project ${projectId}`);
    } catch (error) {
      console.error("[VIDEO-SPEED] Could not register speed-adjusted video:", {
        code: error.status === 507 ? "STORAGE_QUOTA_EXCEEDED" : error.message,
        ownerId, projectId, newVideoId,
      });
    } finally {
      if (needsCleanup) {
        // A repeated result or an ambiguous MongoDB write must not delete a linked video.
        const associated = await Project.findOne(association);
        if (!associated) {
          await discardVideo(ownerId, projectId, String(newVideoId)).catch(error => {
            console.error("[VIDEO-SPEED] Could not remove unassociated video:", error);
          });
          await videoQuota.release(ownerId, String(newVideoId)).catch(error => {
            console.error("[VIDEO-SPEED] Could not release video quota:", error);
          });
        }
      }
    }
  } else {
    console.error(`[VIDEO-SPEED] Video speed failed:`, data.error);
  }
}

function process_video_results() {
  try {
    read_rabbit_msg("video_results_queue", async (msg) => {
      try {
        const data = JSON.parse(msg.content.toString());
        if (data.procedure === "video_speed") {
          await processVideoSpeedResult(data);
          return;
        }
        if (data.procedure !== "video_trim") return;

        const jobId = data.correlationId || data.messageId;
        const {
          ownerId,
          projectId,
          newVideoId,
          newVideoName,
          size,
          callerId,
          callerType,
          startTime,
          endTime,
          fastTrim,
        } = data.parameters || {};

        // 1. Atualizações periódicas de progresso percentual (REQ-VID-TRIM-009)
        if (data.status === "progress") {
          const progress = Math.min(100, Math.max(0, Math.round(Number(data.progress) || 0)));
          await VideoJob.findOneAndUpdate(
            { jobId, status: { $in: ["queued", "processing"] } },
            { status: "processing", progress, startedAt: new Date() }
          );
          if (projectId && ownerId) {
            send_msg_project_op({
              projectId,
              ownerId,
              op: { type: "video-trim-progress", jobId, progress },
            });
          }
          return;
        }

        const job = await VideoJob.findOne({ jobId });
        // Se a tarefa foi cancelada voluntariamente, descartar artefacto (REQ-VID-TRIM-022)
        if (job && job.status === "cancelled") {
          console.log(`[VIDEO-TRIM] Job ${jobId} was cancelled; discarding any produced artifacts`);
          if (newVideoId && ownerId && projectId) {
            await discardVideo(ownerId, projectId, String(newVideoId)).catch(() => {});
          }
          return;
        }

        const effectiveCallerType = callerType || job?.userType || "free";
        const effectiveCallerId = callerId || (job ? String(job.callerId) : ownerId);

        if (data.status === "success") {
          // 2. Validação final da quota de armazenamento (REQ-VID-TRIM-021)
          const currentStorage = await getUserVideoStorage(ownerId);
          const maxStorage = sizes[effectiveCallerType] || sizes.free;
          if (currentStorage + (size || 0) > maxStorage) {
            console.warn(`[VIDEO-TRIM] Video ${newVideoName} exceeds account storage limit (${currentStorage + (size || 0)} > ${maxStorage})`);
            await discardVideo(ownerId, projectId, String(newVideoId)).catch(() => {});
            if (effectiveCallerType === "free") {
              await axios.post(`https://users:10001/${effectiveCallerId}/process/refund/1`, {}, { httpsAgent }).catch(() => {});
            }
            if (job) {
              job.status = "failed";
              job.error = "STORAGE_QUOTA_EXCEEDED";
              job.completedAt = new Date();
              await job.save();
            }
            const executionTimeMs = job?.createdAt ? Date.now() - job.createdAt.getTime() : 0;
            await VideoAudit.create({
              userId: new mongoose.Types.ObjectId(ownerId),
              jobId,
              projectId: new mongoose.Types.ObjectId(projectId),
              videoId: new mongoose.Types.ObjectId(job?.videoId || data.parameters?.videoId),
              newVideoId: new mongoose.Types.ObjectId(newVideoId),
              startTime: startTime ?? job?.startTime ?? 0,
              endTime: endTime ?? job?.endTime ?? 0,
              fastTrim: Boolean(fastTrim ?? job?.fastTrim),
              executionTimeMs,
              status: "failed",
              error: "STORAGE_QUOTA_EXCEEDED",
            });
            send_msg_project_op({
              projectId,
              ownerId,
              op: {
                type: "video-trim-error",
                jobId,
                error: "Espaço de armazenamento insuficiente: a sua biblioteca atingiu o limite de quota da conta (1 GB para free / 5 GB para Premium). Elimine vídeos existentes ou subscreva o plano Premium para obter 5 GB.",
              },
            });
            return;
          }

          const video = {
            _id: new mongoose.Types.ObjectId(newVideoId),
            name: newVideoName,
            key: `${projectId}/video/${newVideoId}.mp4`,
            size,
            codec: "h264",
            contentType: "video/mp4",
            uploadedBy: effectiveCallerId ? new mongoose.Types.ObjectId(effectiveCallerId) : new mongoose.Types.ObjectId(ownerId),
            createdAt: new Date(),
          };

          const updated = await Project.findOneAndUpdate(
            { _id: projectId, user_id: ownerId, "videos.name": { $ne: video.name } },
            { $push: { videos: video }, $inc: { version: 1 } },
            { new: true }
          );

          if (updated) {
            if (job) {
              job.status = "completed";
              job.progress = 100;
              job.completedAt = new Date();
              await job.save();
            }

            const executionTimeMs = job?.createdAt ? Date.now() - job.createdAt.getTime() : 0;
            await VideoAudit.create({
              userId: new mongoose.Types.ObjectId(ownerId),
              jobId,
              projectId: new mongoose.Types.ObjectId(projectId),
              videoId: new mongoose.Types.ObjectId(job?.videoId || data.parameters?.videoId),
              newVideoId: new mongoose.Types.ObjectId(newVideoId),
              startTime: startTime ?? job?.startTime ?? 0,
              endTime: endTime ?? job?.endTime ?? 0,
              fastTrim: Boolean(fastTrim ?? job?.fastTrim),
              executionTimeMs,
              status: "success",
            });

            send_msg_project_op({
              projectId,
              ownerId,
              op: { type: "add-video", video },
            });
            send_msg_project_op({
              projectId,
              ownerId,
              op: { type: "video-trim-completed", jobId, video },
            });
            console.log(`[VIDEO-TRIM] Successfully added trimmed video ${newVideoName} (${newVideoId}) to project ${projectId}`);
          } else {
            console.warn(`[VIDEO-TRIM] Project not found or duplicate video name: ${newVideoName}`);
          }
        } else {
          // Falha: estornar quota se perfil free (REQ-VID-TRIM-016, REQ-VID-TRIM-017)
          if (effectiveCallerType === "free") {
            try {
              await axios.post(`https://users:10001/${effectiveCallerId}/process/refund/1`, {}, { httpsAgent });
              console.log(`[VIDEO-TRIM] Refunded 1 daily operation to user ${effectiveCallerId} due to trim failure`);
            } catch (errRefund) {
              console.error("[VIDEO-TRIM] Error refunding operation on failure:", errRefund.message);
            }
          }

          if (job) {
            job.status = "failed";
            job.error = data.error?.message || "TRIM_FAILED";
            job.completedAt = new Date();
            await job.save();
          }

          const executionTimeMs = job?.createdAt ? Date.now() - job.createdAt.getTime() : 0;
          await VideoAudit.create({
            userId: new mongoose.Types.ObjectId(ownerId),
            jobId,
            projectId: new mongoose.Types.ObjectId(projectId),
            videoId: new mongoose.Types.ObjectId(job?.videoId || data.parameters?.videoId),
            newVideoId: newVideoId ? new mongoose.Types.ObjectId(newVideoId) : undefined,
            startTime: startTime ?? job?.startTime ?? 0,
            endTime: endTime ?? job?.endTime ?? 0,
            fastTrim: Boolean(fastTrim ?? job?.fastTrim),
            executionTimeMs,
            status: "failed",
            error: data.error?.message || "TRIM_FAILED",
          });

          send_msg_project_op({
            projectId,
            ownerId,
            op: {
              type: "video-trim-error",
              jobId,
              error: data.error?.message || "Não foi possível processar o vídeo: fluxo de dados ilegível ou formato incompatível.",
            },
          });
          console.error(`[VIDEO-TRIM] Video trim failed:`, data.error);
        }
      } catch (err) {
        console.error("[VIDEO-TRIM] Error handling video result message:", err);
      }
    });
  } catch (err) {
    console.error("[VIDEO-TRIM] Error subscribing to video_results_queue:", err);
  }
}

module.exports = { router, process_video_results };
