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
const { storeVideo, discardVideo } = require("../utils/videoStorage");

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

async function authorize(req, res, next) {
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
      (link) => link.id === req.query.share && !link.revoked && link.permission === "edit"
    );
    if (!owner && !share) return fail(res, 403, "EDIT_FORBIDDEN", "Edit permission required");
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

module.exports = router;
