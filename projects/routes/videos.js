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

const router = express.Router();
const execFileAsync = promisify(execFile);
const httpsAgent = new https.Agent({ rejectUnauthorized: false });
const sizes = { free: 1_000_000_000, premium: 5_000_000_000 };

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
    res.set("X-Project-Version", String(updated.version));
    return res.sendStatus(204);
  } catch (error) {
    console.error("Video deletion failed:", error);
    return fail(res, 503, "PROJECT_UNAVAILABLE", "Video deletion failed");
  }
});

const disk = multer.diskStorage({
  destination: os.tmpdir(),
  filename: (_req, _file, cb) => cb(null, `picturas-video-${crypto.randomUUID()}`),
});

function receive(req, res, next) {
  const upload = multer({
    storage: disk,
    limits: { fileSize: req.videoLimit, files: 1, fields: 0 },
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
      "-v", "error", "-show_entries", "format=format_name:stream=codec_name,codec_type",
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
    if (!file || file.originalname !== req.videoName || file.size !== req.videoSize) {
      return fail(res, 400, "INVALID_VIDEO", "Video name or size does not match the request");
    }
    await inspectMp4(file.path);
    needsCleanup = true;
    const key = await storeVideo(req.params.user, req.params.project, String(videoId), file.path, file.size);
    const video = {
      _id: videoId, name: file.originalname, key, size: file.size,
      codec: "h264", contentType: "video/mp4", uploadedBy: req.videoCallerId,
      createdAt: new Date(),
    };
    const updated = await Project.findOneAndUpdate(
      { _id: req.params.project, user_id: req.params.user, version: req.videoVersion, "videos.name": { $ne: video.name } },
      { $push: { videos: video }, $inc: { version: 1 } },
      { new: true }
    );
    if (!updated) return fail(res, 409, "PROJECT_CONFLICT", "Project changed or video name already exists");
    needsCleanup = false;
    res.set("X-Project-Version", String(updated.version));
    return res.status(201).json({
      id: String(videoId), projectId: String(updated._id), name: video.name,
      size: video.size, codec: video.codec, contentType: video.contentType,
      createdAt: video.createdAt,
    });
  } catch (error) {
    if (error.message === "INVALID_MP4") {
      return fail(res, 415, "INVALID_MP4", "The file must contain MP4 video encoded with H.264");
    }
    console.error("Video upload failed:", error.message, error.response?.status);
    return fail(res, 502, "VIDEO_UPLOAD_FAILED", "Video storage or project association failed");
  } finally {
    if (needsCleanup) {
      try { await discardVideo(req.params.user, req.params.project, String(videoId)); }
      catch (error) { console.error("Could not remove unassociated video:", error); }
    }
    if (file?.path) {
      try { await fs.promises.unlink(file.path); }
      catch (error) { console.error("Could not remove temporary video:", error); }
    }
  }
});

router.post("/:user/:project/video/:videoId/trim", authorize, checkVersion, associatedVideo, async (req, res) => {
  const { user, project, videoId } = req.params;
  const startTime = Number(req.body?.startTime);
  const endTime = Number(req.body?.endTime);
  let newName = req.body?.newName;

  if (!Number.isFinite(startTime) || !Number.isFinite(endTime) || startTime < 0 || endTime <= startTime || (endTime - startTime) < 1.0) {
    return fail(res, 400, "INVALID_TIME_BOUNDS", "Invalid time bounds: end time must be at least 1.0s after start time");
  }

  if (!newName || typeof newName !== "string" || !newName.trim()) {
    const baseName = req.videoRecord.name.replace(/\.mp4$/i, "");
    newName = `${baseName}-trimmed.mp4`;
  } else {
    newName = newName.trim();
    if (!newName.toLowerCase().endsWith(".mp4")) {
      newName = `${newName}.mp4`;
    }
  }

  if (!validName(newName)) {
    return fail(res, 400, "INVALID_VIDEO_NAME", "Invalid video file name");
  }

  if ((req.videoProject.videos || []).some((v) => v.name === newName)) {
    return fail(res, 409, "VIDEO_NAME_EXISTS", "Change the file name: a video with this complete name already exists in this project");
  }

  const newVideoId = new mongoose.Types.ObjectId();
  const messageId = `request-trim-${crypto.randomUUID()}`;

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
      size: req.videoRecord.size,
      callerId: String(req.videoCallerId),
      projectVersion: req.videoVersion,
    },
  };

  try {
    send_rabbit_msg(message, "video_trim_queue");
    return res.status(202).json({
      messageId,
      newVideoId: String(newVideoId),
      newVideoName: newName,
      status: "queued",
    });
  } catch (error) {
    console.error("Failed to enqueue video trim task:", error);
    return fail(res, 500, "QUEUE_ERROR", "Failed to enqueue video trim task");
  }
});

function process_video_results() {
  try {
    read_rabbit_msg("video_results_queue", async (msg) => {
      try {
        const data = JSON.parse(msg.content.toString());
        if (data.procedure !== "video_trim") return;

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

          const updated = await Project.findOneAndUpdate(
            { _id: projectId, user_id: ownerId, "videos.name": { $ne: video.name } },
            { $push: { videos: video }, $inc: { version: 1 } },
            { new: true }
          );

          if (updated) {
            send_msg_project_op({
              projectId,
              ownerId,
              op: { type: "add-video", video },
            });
            console.log(`[VIDEO-TRIM] Successfully added trimmed video ${newVideoName} (${newVideoId}) to project ${projectId}`);
          } else {
            console.warn(`[VIDEO-TRIM] Project not found or duplicate video name: ${newVideoName}`);
          }
        } else {
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
