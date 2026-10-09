const axios = require("axios");
const fs = require("fs");
const Project = require("../models/project");

const base = "http://img_storage:11000/video";
const headers = () => ({ "X-Internal-Video-Key": process.env.INTERNAL_VIDEO_KEY });

async function storeVideo(ownerId, projectId, videoId, filePath, size) {
  const stream = fs.createReadStream(filePath);
  try {
    const response = await axios.put(`${base}/${ownerId}/${projectId}/${videoId}`, stream, {
      headers: { ...headers(), "Content-Type": "video/mp4", "Content-Length": size },
      maxBodyLength: Infinity,
      timeout: 0,
    });
    return response.data.key;
  } finally {
    stream.destroy();
  }
}

async function discardVideo(ownerId, projectId, videoId) {
  await axios.delete(`${base}/${ownerId}/${projectId}/${videoId}`, { headers: headers() });
}

// Pass a persisted video _id, never an arbitrary SeaweedFS key.
async function getVideoInternalUrl(ownerId, projectId, videoId) {
  const project = await Project.findOne({ user_id: ownerId, _id: projectId, "videos._id": videoId });
  if (!project) throw new Error("Video is not associated with this project");
  const response = await axios.get(`${base}/${ownerId}/${projectId}/${videoId}/url`, {
    headers: headers(),
  });
  return response.data.url;
}

module.exports = { storeVideo, discardVideo, getVideoInternalUrl };
