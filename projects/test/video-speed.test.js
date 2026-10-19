const assert = require("node:assert/strict");
const fs = require("node:fs");
const { spawnSync } = require("node:child_process");
const { once } = require("node:events");
const { before, after, beforeEach, test, mock } = require("node:test");
const express = require("express");
const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");
const axios = require("axios");
const Project = require("../models/project");
const VideoJob = require("../models/videoJob");
const VideoAudit = require("../models/videoAudit");
const StorageAccount = require("../models/videoStorageAccount");
const videoQuota = require("../utils/videoQuota");
const videoStorage = require("../utils/videoStorage");
const rabbit = require("../utils/rabbit_mq");

const ownerId = "a".repeat(24);
const projectId = "b".repeat(24);
const videoId = "c".repeat(24);
const callerId = "e".repeat(24);
process.env.JWT_SECRET_KEY = "video-speed-test-secret";
const ownerToken = jwt.sign({ id: ownerId }, process.env.JWT_SECRET_KEY, { expiresIn: "1h" });
const callerToken = jwt.sign({ id: callerId }, process.env.JWT_SECRET_KEY, { expiresIn: "1h" });
const messages = [];
let resultCallback;
let project;
let server;
let baseUrl;
let queueFailure;
let callerType;
let dailyAllowed;
let storageAccount;
let projectUpdateFailure;
let commitFailure;
const jobs = new Map();

function queryResult(value) {
  const query = Promise.resolve(value);
  query.select = () => query;
  query.lean = async () => Array.isArray(value)
    ? value.map(item => item.toObject ? item.toObject() : item) : value;
  return query;
}

mock.method(StorageAccount, "findOne", (filter) => {
  const account = storageAccount && String(storageAccount.ownerId) === String(filter.ownerId) &&
    (!filter["entries.videoId"] || storageAccount.entries.some(entry =>
      String(entry.videoId) === String(filter["entries.videoId"]))) ? storageAccount : null;
  return queryResult(account);
});
mock.method(StorageAccount, "create", async (data) => {
  storageAccount = { ...data, entries: data.entries.map(entry => ({ ...entry })) };
  return storageAccount;
});
mock.method(StorageAccount, "findOneAndUpdate", async (filter, change) => {
  if (!storageAccount || storageAccount.used > filter.used.$lte ||
      storageAccount.entries.some(entry => String(entry.videoId) === String(filter["entries.videoId"].$ne))) return null;
  storageAccount.used += change.$inc.used;
  storageAccount.entries.push({ ...change.$push.entries });
  return storageAccount;
});
mock.method(StorageAccount, "updateOne", async (filter, change) => {
  if (commitFailure && change.$set["entries.$.state"] === "committed") throw commitFailure;
  const match = filter.entries.$elemMatch;
  const entry = storageAccount?.entries.find(item =>
    String(item.videoId) === String(match.videoId) && item.state === match.state);
  if (!entry || (filter.used && storageAccount.used > filter.used.$lte)) return { modifiedCount: 0 };
  storageAccount.used += change.$inc?.used || 0;
  entry.state = change.$set["entries.$.state"];
  if (change.$set["entries.$.size"] !== undefined) entry.size = change.$set["entries.$.size"];
  return { modifiedCount: 1 };
});
const reserve = mock.method(videoQuota, "reserve", videoQuota.reserve);
const commit = mock.method(videoQuota, "commit", videoQuota.commit);
const release = mock.method(videoQuota, "release", videoQuota.release);

const createJob = mock.method(VideoJob, "create", async (data) => {
  const job = { ...data, createdAt: new Date(), async save() { return this; } };
  jobs.set(data.jobId, job);
  return job;
});
const findJob = mock.method(VideoJob, "findOne", async ({ jobId, projectId: pid }) => {
  const job = jobs.get(jobId);
  return job && (!pid || String(job.projectId) === pid) ? job : null;
});
const updateJob = mock.method(VideoJob, "findOneAndUpdate", async ({ jobId }, change) => {
  const job = jobs.get(jobId);
  if (job) Object.assign(job, change);
  return job;
});
const audit = mock.method(VideoAudit, "create", async (data) => data);
const discard = mock.method(videoStorage, "discardVideo", async () => {});
const store = mock.method(videoStorage, "storeVideo", async (_owner, pid, id, filePath, size) => {
  assert.equal(fs.statSync(filePath).size, size);
  return `${pid}/video/${id}.mp4`;
});

mock.method(rabbit, "send_rabbit_msg", (message, queue) => {
  if (queueFailure) throw new Error("Queue unavailable");
  messages.push({ message, queue });
});
mock.method(rabbit, "read_rabbit_msg", (queue, callback) => {
  assert.equal(queue, "video_results_queue");
  resultCallback = callback;
});
const lookup = mock.method(Project, "findOne", async (filter) => {
  return project && String(project._id) === filter._id && String(project.user_id) === filter.user_id
    && (!filter["videos._id"] || project.videos.some(video => String(video._id) === String(filter["videos._id"])))
    ? project : null;
});
const update = mock.method(Project, "findOneAndUpdate", async (filter, change) => {
  if (projectUpdateFailure) throw projectUpdateFailure;
  if (!project || String(project._id) !== filter._id || String(project.user_id) !== filter.user_id ||
      project.videos.some((video) => video.name === filter["videos.name"].$ne)) return null;
  project.videos.push(change.$push.videos);
  project.version += change.$inc.version;
  return project;
});
mock.method(Project, "find", () => queryResult(project ? [project] : []));
const externalGet = mock.method(axios, "get", async (url) => {
  if (url.endsWith("/type")) return { data: { type: callerType } };
  if (url.endsWith("/process/1")) return { data: dailyAllowed };
  throw new Error("Unexpected external GET: " + url);
});
const refund = mock.method(axios, "post", async (url) => {
  assert.ok(url.endsWith("/process/refund/1"));
  return { data: true };
});
const { router, process_video_results } = require("../routes/videos");

before(async () => {
  const app = express();
  app.use(express.json());
  app.use(router);
  server = app.listen(0, "127.0.0.1");
  await once(server, "listening");
  baseUrl = `http://127.0.0.1:${server.address().port}`;
  process_video_results();
  assert.equal(typeof resultCallback, "function");
});

after(async () => {
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
});

beforeEach(() => {
  project = new Project({
    _id: projectId, user_id: ownerId, name: "Test project", version: 7,
    videos: [{
      _id: videoId, name: "original.mp4", key: `${projectId}/video/${videoId}.mp4`,
      size: 12345, codec: "h264", contentType: "video/mp4", uploadedBy: ownerId,
    }],
  });
  messages.length = 0;
  queueFailure = false;
  callerType = "free";
  dailyAllowed = true;
  storageAccount = {
    ownerId, used: 12345,
    entries: [{ videoId, size: 12345, state: "committed" }],
  };
  projectUpdateFailure = null;
  commitFailure = null;
  jobs.clear();
  for (const method of [createJob, findJob, updateJob, audit, discard, store, refund, reserve, commit, release]) method.mock.resetCalls();
  lookup.mock.resetCalls();
  update.mock.resetCalls();
  externalGet.mock.resetCalls();
});

function interval(startTime, endTime, speed) {
  return { startTime, endTime, speed };
}

async function speedResult(parameters = {}) {
  await resultCallback({ content: Buffer.from(JSON.stringify({
    messageId: "result-quota-test", correlationId: "request-speed-quota-test",
    procedure: "video_speed", status: "success",
    parameters: {
      ownerId, projectId, videoId, newVideoId: "d".repeat(24),
      newVideoName: "output.mp4", size: 20, callerId: ownerId, ...parameters,
    },
  })) });
}

async function submit(body, options = {}) {
  const headers = { "Content-Type": "application/json", "X-Project-Version": "7",
    Authorization: `Bearer ${ownerToken}`, ...options.headers };
  for (const [name, value] of Object.entries(headers)) {
    if (value === undefined) delete headers[name];
  }
  const url = options.path || `/${ownerId}/${projectId}/video/${videoId}/${options.operation || "speed"}`;
  const response = await fetch(baseUrl + url, {
    method: "POST", headers, body: options.rawBody === undefined ? JSON.stringify(body) : options.rawBody,
  });
  return { status: response.status, body: await response.json() };
}

for (const speed of [0.5, 1, 2]) {
  test(`speed endpoint accepts ${speed} and publishes the worker contract`, async () => {
    const intervals = [interval(1, 3.5, speed)];
    const original = project.videos[0].toObject();
    const response = await submit({ intervals, newName: "changed.mp4" });
    assert.equal(response.status, 202);
    assert.equal(response.body.status, "queued");
    assert.match(response.body.messageId, /^request-speed-/);
    assert.equal(mongoose.isValidObjectId(response.body.newVideoId), true);
    assert.notEqual(response.body.newVideoId, videoId);
    assert.equal(response.body.newVideoName, "changed.mp4");
    assert.equal(messages.length, 1);
    const { message, queue } = messages[0];
    assert.equal(queue, "video_speed_queue");
    assert.equal(message.procedure, "video_speed");
    assert.equal(message.messageId, response.body.messageId);
    assert.equal(Number.isFinite(Date.parse(message.timestamp)), true);
    assert.deepEqual(message.parameters, {
      ownerId, projectId, videoId, newVideoId: response.body.newVideoId,
      newVideoName: "changed.mp4", intervals, size: 12345, callerId: ownerId, projectVersion: 7,
    });
    assert.equal(project.version, 7);
    assert.equal(project.videos.length, 1);
    assert.deepEqual(project.videos[0].toObject(), original);
    assert.equal(update.mock.callCount(), 0);
    assert.equal(externalGet.mock.callCount(), 0);
    assert.equal(createJob.mock.callCount(), 0);
    assert.equal(refund.mock.callCount(), 0);
  });
}

const invalidIntervals = [
  ["speed 0.25", [interval(1, 3, 0.25)]],
  ["speed 4", [interval(1, 3, 4)]],
  ["overlap", [interval(2, 5, 2), interval(4, 7, 0.5)]],
  ["overlap in reverse order", [interval(4, 7, 0.5), interval(2, 5, 2)]],
  ["equal bounds", [interval(2, 2, 2)]],
  ["reversed bounds", [interval(3, 2, 2)]],
  ["negative start", [interval(-1, 2, 2)]],
  ["empty list", []], ["missing list", undefined], ["non-list", {}],
  ["null interval", [null]], ["missing speed", [{ startTime: 1, endTime: 2 }]],
  ["string start", [interval("1", 2, 2)]], ["string end", [interval(1, "2", 2)]],
  ["string speed", [interval(1, 2, "2")]], ["boolean speed", [interval(1, 2, true)]],
  ["null start", [interval(null, 2, 2)]], ["null end", [interval(1, null, 2)]],
  ["non-finite start", [interval(Infinity, 2, 2)]],
  ["non-finite end", [interval(1, NaN, 2)]],
];
for (const [description, intervals] of invalidIntervals) {
  test(`speed endpoint rejects ${description}`, async () => {
    const response = await submit({ intervals });
    assert.equal(response.status, 400);
    assert.equal(response.body.code, "INVALID_INTERVALS");
    assert.equal(messages.length, 0);
    assert.equal(update.mock.callCount(), 0);
  });
}

test("speed endpoint rejects a numeric overflow parsed from JSON", async () => {
  const response = await submit({}, {
    rawBody: '{"intervals":[{"startTime":1,"endTime":1e999,"speed":2}]}',
  });
  assert.equal(response.status, 400);
  assert.equal(response.body.code, "INVALID_INTERVALS");
  assert.equal(messages.length, 0);
});

test("speed endpoint normalizes unsorted adjacent intervals without adding time limits", async () => {
  const response = await submit({ intervals: [interval(500, 500.1, 1), interval(0, 500, 2)] });
  assert.equal(response.status, 202);
  assert.deepEqual(messages[0].message.parameters.intervals,
    [interval(0, 500, 2), interval(500, 500.1, 1)]);
});

for (const newName of ["../unsafe.mp4", "folder/unsafe.mp4", "bad\u0000.mp4", "x".repeat(256), 42, null]) {
  test(`speed endpoint rejects invalid name ${JSON.stringify(newName)}`, async () => {
    const response = await submit({ intervals: [interval(1, 3, 2)], newName });
    assert.equal(response.status, 400);
    assert.equal(response.body.code, "INVALID_VIDEO_NAME");
    assert.equal(messages.length, 0);
  });
}

test("speed endpoint generates a unique default name and accepts an extensionless name", async () => {
  project.videos.push({ ...project.videos[0].toObject(), _id: new mongoose.Types.ObjectId(), name: "original-speed.mp4" });
  const response = await submit({ intervals: [interval(1, 3, 2)] });
  assert.equal(response.status, 202);
  assert.equal(response.body.newVideoName, "original-speed-2.mp4");
  const explicit = await submit({ intervals: [interval(1, 3, 2)], newName: " other " });
  assert.equal(explicit.body.newVideoName, "other.mp4");
  const collision = await submit({ intervals: [interval(1, 3, 2)], newName: "original.mp4" });
  assert.equal(collision.body.newVideoName, "original-speed-2.mp4");
});

test("speed endpoint keeps trim authentication and version checks", async () => {
  const body = { intervals: [interval(1, 3, 2)] };
  for (const [headers, status, code] of [
    [{ Authorization: undefined }, 401, "AUTH_REQUIRED"],
    [{ Authorization: "Bearer invalid" }, 401, "INVALID_TOKEN"],
    [{ Authorization: `Bearer ${callerToken}` }, 403, "ACCESS_FORBIDDEN"],
    [{ "X-Project-Version": "invalid" }, 428, "VERSION_REQUIRED"],
    [{ "X-Project-Version": "6" }, 409, "PROJECT_CONFLICT"],
  ]) {
    const response = await submit(body, { headers });
    assert.equal(response.status, status);
    assert.equal(response.body.code, code);
  }
  assert.equal(messages.length, 0);
});

test("speed endpoint requires an associated video with a consistent storage key", async () => {
  const body = { intervals: [interval(1, 3, 2)] };
  const invalidId = await submit(body, { path: `/${ownerId}/${projectId}/video/invalid/speed` });
  assert.equal(invalidId.body.code, "INVALID_ID");
  const absent = await submit(body, { path: `/${ownerId}/${projectId}/video/${"d".repeat(24)}/speed` });
  assert.equal(absent.status, 404);
  assert.equal(absent.body.code, "VIDEO_NOT_FOUND");
  project.videos[0].key = "wrong-key";
  const mismatch = await submit(body);
  assert.equal(mismatch.status, 409);
  assert.equal(mismatch.body.code, "VIDEO_KEY_MISMATCH");
  assert.equal(messages.length, 0);
});

test("speed endpoint allows edit shares and rejects read or revoked shares", async () => {
  project.sharedLinks.push({ id: "test-share", permission: "read" });
  const options = { headers: { Authorization: `Bearer ${callerToken}` },
    path: `/${ownerId}/${projectId}/video/${videoId}/speed?share=test-share` };
  const body = { intervals: [interval(1, 3, 2)] };
  assert.equal((await submit(body, options)).status, 403);
  project.sharedLinks[0].permission = "edit";
  assert.equal((await submit(body, options)).status, 202);
  assert.equal(messages[0].message.parameters.callerId, callerId);
  project.sharedLinks[0].revoked = true;
  assert.equal((await submit(body, options)).status, 403);
});

test("speed endpoint handles synchronous queue errors without modifying the project", async () => {
  queueFailure = true;
  const response = await submit({ intervals: [interval(1, 3, 2)] });
  assert.equal(response.status, 500);
  assert.equal(response.body.code, "QUEUE_ERROR");
  assert.equal(project.videos.length, 1);
  assert.equal(project.version, 7);
});

for (const operation of ["trim", "speed"]) {
  test(`${operation} success result appends a video, increments version and publishes project-op`, async () => {
    const body = operation === "trim" ? { startTime: 1, endTime: 3 } : { intervals: [interval(1, 3, 2)] };
    await submit(body, { operation });
    const request = messages[0].message;
    const original = project.videos[0].toObject();
    messages.length = 0;
    await resultCallback({ content: Buffer.from(JSON.stringify({
      messageId: "result-test", correlationId: request.messageId, timestamp: new Date().toISOString(),
      procedure: `video_${operation}`, status: "success", parameters: { ...request.parameters, size: 54321 },
    })) });
    assert.equal(project.videos.length, 2);
    assert.equal(project.version, 8);
    assert.deepEqual(project.videos[0].toObject(), original);
    const output = project.videos[1];
    assert.equal(String(output._id), request.parameters.newVideoId);
    assert.equal(output.key, `${projectId}/video/${output._id}.mp4`);
    assert.equal(output.name, request.parameters.newVideoName);
    assert.equal(output.size, 54321);
    assert.equal(output.codec, "h264");
    assert.equal(output.contentType, "video/mp4");
    assert.equal(String(output.uploadedBy), ownerId);
    assert.ok(output.createdAt instanceof Date);
    const call = update.mock.calls[0].arguments;
    assert.deepEqual(call[0], { _id: projectId, user_id: ownerId, "videos.name": { $ne: output.name } });
    assert.equal(call[1].$inc.version, 1);
    assert.deepEqual(call[2], { new: true });
    assert.equal(messages.length, operation === "trim" ? 2 : 1);
    assert.equal(messages[0].queue, "ws_queue");
    assert.equal(messages[0].message.type, "project-op");
    assert.equal(messages[0].message.projectId, projectId);
    assert.equal(messages[0].message.ownerId, ownerId);
    assert.equal(messages[0].message.op.type, "add-video");
    assert.equal(String(messages[0].message.op.video._id), String(output._id));
    if (operation === "trim") {
      assert.equal(messages[1].message.op.type, "video-trim-completed");
      assert.equal(jobs.get(request.messageId).status, "completed");
      assert.equal(audit.mock.callCount(), 1);
    } else {
      assert.equal(externalGet.mock.callCount(), 1);
      assert.equal(externalGet.mock.calls[0].arguments[0], `https://users:10001/${ownerId}/type`);
      assert.deepEqual(reserve.mock.calls[0].arguments, [ownerId, request.parameters.newVideoId, 54321]);
      assert.equal(commit.mock.callCount(), 1);
      assert.equal(storageAccount.used, 12345 + 54321);
      assert.equal(storageAccount.entries[1].state, "committed");
      assert.equal(refund.mock.callCount(), 0);
      assert.equal(findJob.mock.callCount(), 0);
      assert.equal(audit.mock.callCount(), 0);
    }
  });

  test(`${operation} error result does not add a partial video or modify the original`, async () => {
    const body = operation === "trim" ? { startTime: 1, endTime: 3 } : { intervals: [interval(1, 3, 2)] };
    assert.equal((await submit(body, { operation })).status, 202);
    const request = messages[0].message;
    messages.length = 0;
    const original = project.toObject();
    const log = mock.method(console, "error", () => {});
    try {
      await resultCallback({ content: Buffer.from(JSON.stringify({
        procedure: `video_${operation}`, status: "error",
        correlationId: request.messageId,
        error: { code: "PROCESSING_FAILED", message: "Failed" }, parameters: request.parameters,
      })) });
      assert.equal(log.mock.callCount(), 1);
      assert.deepEqual(project.toObject(), original);
      assert.equal(update.mock.callCount(), 0);
      assert.equal(messages.length, operation === "trim" ? 1 : 0);
      assert.equal(refund.mock.callCount(), operation === "trim" ? 1 : 0);
      assert.equal(audit.mock.callCount(), operation === "trim" ? 1 : 0);
      if (operation === "trim") {
        assert.equal(messages[0].message.op.type, "video-trim-error");
        assert.equal(jobs.get(request.messageId).status, "failed");
      } else {
        assert.equal(findJob.mock.callCount(), 0);
        assert.equal(externalGet.mock.callCount(), 0);
      }
    } finally { log.mock.restore(); }
  });
}

test("speed duplicate name result follows trim behavior without adding a video", async () => {
  await resultCallback({ content: Buffer.from(JSON.stringify({
    procedure: "video_speed", status: "success", parameters: {
      ownerId, projectId, newVideoId: "d".repeat(24), newVideoName: "original.mp4", size: 54321,
    },
  })) });
  assert.equal(project.videos.length, 1);
  assert.equal(project.version, 7);
  assert.equal(messages.length, 0);
  assert.equal(storageAccount.used, 12345);
  assert.equal(storageAccount.entries[1].state, "released");
  assert.equal(commit.mock.callCount(), 0);
  assert.equal(release.mock.callCount(), 1);
  assert.deepEqual(discard.mock.calls[0].arguments, [ownerId, projectId, "d".repeat(24)]);
});

for (const [description, plan, used, accepted] of [
  ["sufficient free storage", "free", 999999970, true],
  ["insufficient free storage", "free", 999999990, false],
  ["exact free storage limit", "free", 999999980, true],
  ["exact premium storage limit", "premium", 4999999980, true],
]) {
  test(`speed quota handles ${description} using the real quota helper`, async () => {
    callerType = plan;
    storageAccount.used = used;
    storageAccount.entries[0].size = used;
    project.videos[0].size = used;
    const original = project.toObject();
    const log = mock.method(console, "error", () => {});
    try {
      await speedResult();
      assert.deepEqual(reserve.mock.calls[0].arguments, [ownerId, "d".repeat(24), 20]);
      assert.equal(storageAccount.used, used + (accepted ? 20 : 0));
      assert.equal(project.version, accepted ? 8 : 7);
      assert.equal(project.videos.length, accepted ? 2 : 1);
      assert.equal(commit.mock.callCount(), accepted ? 1 : 0);
      assert.equal(release.mock.callCount(), accepted ? 0 : 1);
      assert.equal(discard.mock.callCount(), accepted ? 0 : 1);
      assert.equal(messages.length, accepted ? 1 : 0);
      if (accepted) {
        assert.equal(storageAccount.entries[1].size, 20);
        assert.equal(storageAccount.entries[1].state, "committed");
        assert.equal(messages[0].message.op.type, "add-video");
        assert.equal(project.videos[1].size, 20);
      } else {
        assert.deepEqual(project.toObject(), original);
        assert.equal(storageAccount.entries.length, 1);
        assert.equal(log.mock.calls[0].arguments[1].code, "STORAGE_QUOTA_EXCEEDED");
        assert.deepEqual(discard.mock.calls[0].arguments, [ownerId, projectId, "d".repeat(24)]);
      }
      assert.equal(refund.mock.callCount(), 0);
    } finally { log.mock.restore(); }
  });
}

test("speed quota bootstraps an account from existing videos and charges output bytes", async () => {
  storageAccount = null;
  await speedResult();
  assert.equal(storageAccount.used, 12345 + 20);
  assert.equal(storageAccount.entries[0].state, "committed");
  assert.equal(storageAccount.entries[1].state, "committed");
  assert.equal(storageAccount.entries[1].size, 20);
  assert.notEqual(storageAccount.entries[1].size, project.videos[0].size);
});

test("speed quota belongs to the project owner, not the shared caller", async () => {
  await speedResult({ callerId });
  assert.equal(externalGet.mock.calls[0].arguments[0], `https://users:10001/${ownerId}/type`);
  assert.equal(String(project.videos[1].uploadedBy), callerId);
  assert.equal(storageAccount.used, 12365);
  assert.equal(refund.mock.callCount(), 0);
});

test("speed releases its reservation when project association throws", async () => {
  const original = project.toObject();
  projectUpdateFailure = new Error("Mongo write failed");
  const log = mock.method(console, "error", () => {});
  try {
    await speedResult();
    assert.deepEqual(project.toObject(), original);
    assert.equal(storageAccount.used, 12345);
    assert.equal(storageAccount.entries[1].state, "released");
    assert.equal(commit.mock.callCount(), 0);
    assert.equal(release.mock.callCount(), 1);
    assert.equal(discard.mock.callCount(), 1);
    assert.equal(messages.length, 0);
  } finally { log.mock.restore(); }
});

test("speed releases its reservation when the project disappeared", async () => {
  project = null;
  await speedResult();
  assert.equal(storageAccount.used, 12345);
  assert.equal(storageAccount.entries[1].state, "released");
  assert.equal(commit.mock.callCount(), 0);
  assert.equal(release.mock.callCount(), 1);
  assert.equal(discard.mock.callCount(), 1);
  assert.equal(messages.length, 0);
});

test("speed releases quota even if removing the unassociated output fails", async () => {
  projectUpdateFailure = new Error("Mongo write failed");
  discard.mock.mockImplementationOnce(async () => { throw new Error("Storage unavailable"); });
  const original = project.toObject();
  const log = mock.method(console, "error", () => {});
  try {
    await speedResult();
    assert.deepEqual(project.toObject(), original);
    assert.equal(storageAccount.used, 12345);
    assert.equal(storageAccount.entries[1].state, "released");
    assert.equal(release.mock.callCount(), 1);
    assert.equal(commit.mock.callCount(), 0);
    assert.equal(messages.length, 0);
    assert.equal(log.mock.callCount(), 2);
  } finally { log.mock.restore(); }
});

test("a repeated speed result keeps its associated output and charges quota only once", async () => {
  await speedResult();
  await speedResult();
  assert.equal(project.videos.length, 2);
  assert.equal(project.version, 8);
  assert.equal(storageAccount.used, 12365);
  assert.equal(storageAccount.entries.length, 2);
  assert.equal(reserve.mock.callCount(), 1);
  assert.equal(messages.length, 1);
  assert.equal(release.mock.callCount(), 0);
  assert.equal(discard.mock.callCount(), 0);
});

test("speed keeps associated bytes charged if commit fails, and can finalize on retry", async () => {
  commitFailure = new Error("Quota commit unavailable");
  const log = mock.method(console, "error", () => {});
  try {
    await speedResult();
    assert.equal(project.videos.length, 2);
    assert.equal(project.version, 8);
    assert.equal(storageAccount.used, 12365);
    assert.equal(storageAccount.entries[1].state, "reserved");
    assert.equal(discard.mock.callCount(), 0);
    assert.equal(release.mock.callCount(), 0);
    commitFailure = null;
    await speedResult();
    assert.equal(storageAccount.entries[1].state, "committed");
    assert.equal(storageAccount.used, 12365);
    assert.equal(project.version, 8);
    assert.equal(messages.length, 1);
  } finally { log.mock.restore(); }
});

for (const size of [undefined, 0, -1, 1.5, "20", null, Number.MAX_SAFE_INTEGER + 1]) {
  test(`speed rejects invalid output size ${String(size)} without modifying project or quota`, async () => {
    const original = project.toObject();
    const log = mock.method(console, "error", () => {});
    try {
      await speedResult({ size });
      assert.deepEqual(project.toObject(), original);
      assert.equal(storageAccount.used, 12345);
      assert.equal(storageAccount.entries.length, 1);
      assert.equal(update.mock.callCount(), 0);
      assert.equal(commit.mock.callCount(), 0);
      assert.equal(discard.mock.callCount(), 1);
      assert.equal(messages.length, 0);
    } finally { log.mock.restore(); }
  });
}

const ffmpegAvailable = spawnSync("ffmpeg", ["-version"], { stdio: "ignore" }).status === 0 &&
  spawnSync("ffprobe", ["-version"], { stdio: "ignore" }).status === 0;
test("upload still inspects MP4/H.264 and reserves, stores, associates and commits bytes", {
  skip: !ffmpegAvailable && "FFmpeg/ffprobe are required for the upload regression test",
}, async () => {
  const generated = spawnSync("ffmpeg", [
    "-v", "error", "-f", "lavfi", "-i", "color=c=black:s=16x16:r=1",
    "-t", "1", "-c:v", "libx264", "-movflags", "frag_keyframe+empty_moov",
    "-f", "mp4", "pipe:1",
  ]);
  assert.equal(generated.status, 0, generated.stderr.toString());
  const body = new FormData();
  body.append("video", new Blob([generated.stdout], { type: "video/mp4" }), "upload.mp4");
  const response = await fetch(`${baseUrl}/${ownerId}/${projectId}/video`, {
    method: "POST", body, headers: {
      Authorization: `Bearer ${ownerToken}`, "X-Project-Version": "7",
      "X-Video-Name": "upload.mp4", "X-Video-Size": String(generated.stdout.length),
    },
  });
  const uploaded = await response.json();
  assert.equal(response.status, 201, JSON.stringify(uploaded));
  assert.equal(uploaded.codec, "h264");
  assert.equal(project.videos.length, 2);
  assert.equal(project.version, 8);
  assert.equal(store.mock.callCount(), 1);
  assert.equal(reserve.mock.callCount(), 1);
  assert.equal(commit.mock.callCount(), 1);
  assert.equal(storageAccount.used, 12345 + generated.stdout.length);
  assert.equal(storageAccount.entries[1].state, "committed");
  assert.equal(release.mock.callCount(), 0);
});

test("unrelated result procedures are ignored", async () => {
  await resultCallback({ content: Buffer.from(JSON.stringify({ procedure: "video_example", status: "success" })) });
  assert.equal(update.mock.callCount(), 0);
  assert.equal(messages.length, 0);
});

test("trim keeps its time validation, coercion, names and message contract", async () => {
  const invalid = await submit({ startTime: 1, endTime: 1.5 }, { operation: "trim" });
  assert.equal(invalid.status, 400);
  assert.equal(invalid.body.code, "INVALID_TIME_BOUNDS");
  project.videos.push({ ...project.videos[0].toObject(), _id: new mongoose.Types.ObjectId(), name: "original-trimmed.mp4" });
  const response = await submit({ startTime: "1", endTime: "3" }, { operation: "trim" });
  assert.equal(response.status, 202);
  assert.match(response.body.messageId, /^request-trim-/);
  assert.equal(response.body.newVideoName, "original-trimmed-2.mp4");
  assert.equal(messages[0].queue, "video_trim_queue");
  assert.equal(messages[0].message.procedure, "video_trim");
  assert.equal(messages[0].message.parameters.startTime, 1);
  assert.equal(messages[0].message.parameters.endTime, 3);
  assert.equal(messages[0].message.parameters.intervals, undefined);
  const collision = await submit({ startTime: 1, endTime: 3, newName: "original" }, { operation: "trim" });
  assert.equal(collision.body.newVideoName, "original-trimmed-2.mp4");
  assert.equal(externalGet.mock.callCount(), 5);
  assert.equal(jobs.size, 2);
  assert.equal(response.body.jobId, response.body.messageId);
  assert.equal(messages[0].message.parameters.callerType, "free");
  assert.equal(messages[0].message.parameters.fastTrim, false);
});

test("trim preserves anonymous, duration and free daily quota restrictions", async () => {
  callerType = "anonymous";
  const anonymous = await submit({ startTime: 1, endTime: 3 }, { operation: "trim" });
  assert.equal(anonymous.status, 403);
  assert.equal(anonymous.body.code, "ANONYMOUS_NOT_ALLOWED");
  callerType = "free";
  const tooLong = await submit({ startTime: 0, endTime: 181 }, { operation: "trim" });
  assert.equal(tooLong.body.code, "DURATION_LIMIT_EXCEEDED");
  dailyAllowed = false;
  const exhausted = await submit({ startTime: 1, endTime: 3 }, { operation: "trim" });
  assert.equal(exhausted.status, 403);
  assert.equal(exhausted.body.code, "DAILY_QUOTA_EXCEEDED");
  assert.equal(messages.length, 0);
  assert.equal(jobs.size, 0);
});

test("trim preserves premium fastTrim without debiting daily quota", async () => {
  callerType = "premium";
  const response = await submit({ startTime: 1, endTime: 3, fastTrim: true }, { operation: "trim" });
  assert.equal(response.status, 202);
  assert.equal(messages[0].message.parameters.fastTrim, true);
  assert.equal(messages[0].message.parameters.callerType, "premium");
  assert.equal(jobs.get(response.body.jobId).fastTrim, true);
  assert.equal(externalGet.mock.callCount(), 1);
  assert.equal(refund.mock.callCount(), 0);
});

test("trim progress, status and cancellation remain independent of speed", async () => {
  const response = await submit({ startTime: 1, endTime: 3 }, { operation: "trim" });
  assert.equal(response.status, 202);
  const request = messages[0].message;
  messages.length = 0;
  await resultCallback({ content: Buffer.from(JSON.stringify({
    procedure: "video_trim", status: "progress", progress: 47,
    correlationId: request.messageId, parameters: request.parameters,
  })) });
  assert.equal(jobs.get(request.messageId).status, "processing");
  assert.equal(messages[0].message.op.type, "video-trim-progress");
  assert.equal(messages[0].message.op.progress, 47);
  const status = await fetch(baseUrl + `/${ownerId}/${projectId}/video/trim/${request.messageId}`, {
    headers: { Authorization: `Bearer ${ownerToken}` },
  });
  assert.equal(status.status, 200);
  assert.equal((await status.json()).progress, 47);
  messages.length = 0;
  const cancelled = await submit({}, {
    path: `/${ownerId}/${projectId}/video/trim/${request.messageId}/cancel`,
  });
  assert.equal(cancelled.status, 200);
  assert.equal(jobs.get(request.messageId).status, "cancelled");
  assert.equal(refund.mock.callCount(), 1);
  assert.equal(discard.mock.callCount(), 1);
  assert.equal(audit.mock.calls[0].arguments[0].status, "cancelled");
  assert.equal(messages[0].message.procedure, "video_trim_cancel");
  assert.equal(messages[1].message.op.type, "video-trim-cancelled");
  messages.length = 0;
  await resultCallback({ content: Buffer.from(JSON.stringify({
    procedure: "video_trim", status: "success", correlationId: request.messageId,
    parameters: { ...request.parameters, size: 54321 },
  })) });
  assert.equal(project.videos.length, 1);
  assert.equal(project.version, 7);
  assert.equal(discard.mock.callCount(), 2);
  assert.equal(messages.length, 0);
});

test("trim queue failure refunds its quota and marks the job as failed", async () => {
  queueFailure = true;
  const response = await submit({ startTime: 1, endTime: 3 }, { operation: "trim" });
  assert.equal(response.status, 500);
  assert.equal(response.body.code, "QUEUE_ERROR");
  assert.equal(refund.mock.callCount(), 1);
  assert.equal([...jobs.values()][0].status, "failed");
  assert.equal(project.videos.length, 1);
  assert.equal(project.version, 7);
});
