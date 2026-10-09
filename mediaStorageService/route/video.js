const express = require("express");
const s3 = require("../services/s3Client");

const router = express.Router();
const validId = /^[a-f\d]{24}$/i;
const validVideoId = /^[a-f\d]{24}$/i;
const maxSize = 5_000_000_000;

router.use("/:userId/:projectId/:videoId", (req, res, next) => {
  if (!process.env.INTERNAL_VIDEO_KEY || req.get("X-Internal-Video-Key") !== process.env.INTERNAL_VIDEO_KEY) {
    return res.status(403).json({ error: "Forbidden" });
  }
  const { userId, projectId, videoId } = req.params;
  if (![userId, projectId].every((id) => validId.test(id)) || !validVideoId.test(videoId)) {
    return res.status(400).json({ error: "Invalid identifier" });
  }
  next();
});

const location = (req) => ({
  Bucket: `user-${req.params.userId}`,
  Key: `${req.params.projectId}/video/${req.params.videoId}.mp4`,
});

router.put("/:userId/:projectId/:videoId", async (req, res) => {
  const size = Number(req.get("Content-Length"));
  if (!Number.isSafeInteger(size) || size < 1 || size > maxSize || req.get("Content-Type") !== "video/mp4") {
    req.resume();
    return res.status(400).json({ error: "Invalid video upload" });
  }
  const target = location(req);
  try {
    try {
      await s3.headBucket({ Bucket: target.Bucket }).promise();
    } catch (error) {
      if (error.statusCode !== 404 && error.code !== "NoSuchBucket") throw error;
      await s3.createBucket({ Bucket: target.Bucket }).promise();
    }
    await s3.upload({ ...target, Body: req, ContentType: "video/mp4" }, {
      partSize: 16 * 1024 * 1024,
      queueSize: 2,
      leavePartsOnError: false,
    }).promise();
    return res.status(201).json({ key: target.Key });
  } catch (error) {
    console.error("Video storage failed:", error);
    return res.status(502).json({ error: "Video storage failed" });
  }
});

router.delete("/:userId/:projectId/:videoId", async (req, res) => {
  try {
    await s3.deleteObject(location(req)).promise();
    return res.sendStatus(204);
  } catch (error) {
    console.error("Video cleanup failed:", error);
    return res.status(502).json({ error: "Video cleanup failed" });
  }
});

router.get("/:userId/:projectId/:videoId/url", async (req, res) => {
  try {
    const url = await s3.getSignedUrlPromise("getObject", { ...location(req), Expires: 900 });
    return res.json({ url, expiresIn: 900 });
  } catch (error) {
    return res.status(502).json({ error: "Could not create video URL" });
  }
});

module.exports = router;
