const assert = require("node:assert/strict");
const { once } = require("node:events");
const { before, after, beforeEach, test, mock } = require("node:test");
const express = require("express");
const jwt = require("jsonwebtoken");
const axios = require("axios");

const ownerId = "a".repeat(24);
const projectId = "b".repeat(24);
const videoId = "c".repeat(24);
process.env.JWT_SECRET_KEY = "video-speed-gateway-test-secret";
const token = jwt.sign({ id: ownerId }, process.env.JWT_SECRET_KEY, { expiresIn: "1h" });
const callerToken = jwt.sign({ id: "e".repeat(24) }, process.env.JWT_SECRET_KEY, { expiresIn: "1h" });
let upstream;
let server;
let baseUrl;
const post = mock.method(axios, "post", async () => upstream);
const router = require("../routes/projects");

before(async () => {
  const app = express();
  app.use(express.json());
  app.use("/projects", router);
  server = app.listen(0, "127.0.0.1");
  await once(server, "listening");
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
});

beforeEach(() => {
  upstream = { status: 202, data: { messageId: "queued-test", status: "queued" }, headers: {} };
  post.mock.resetCalls();
  post.mock.mockImplementation(async () => upstream);
});

async function submit(operation, options = {}) {
  const body = operation === "trim" ? { startTime: 1, endTime: 3 } : {
    intervals: [{ startTime: 1, endTime: 3.5, speed: 0.5 }], newName: "changed.mp4",
  };
  const headers = { "Content-Type": "application/json", "X-Project-Version": "7",
    Authorization: `Bearer ${token}`, ...options.headers };
  for (const [name, value] of Object.entries(headers)) {
    if (value === undefined) delete headers[name];
  }
  const response = await fetch(
    `${baseUrl}/projects/${ownerId}/${projectId}/video/${videoId}/${operation}${options.query || ""}`,
    { method: "POST", headers, body: JSON.stringify(body) },
  );
  return { status: response.status, headers: response.headers, body: await response.json(), submitted: body };
}

for (const operation of ["trim", "speed"]) {
  test(`${operation} proxy forwards the body, authorization, version and share`, async () => {
    upstream.headers["x-project-version"] = "8";
    const response = await submit(operation, { query: "?share=test-share",
      headers: { Authorization: `Bearer ${callerToken}` } });
    assert.equal(response.status, 202);
    assert.deepEqual(response.body, upstream.data);
    assert.equal(response.headers.get("x-project-version"), "8");
    assert.equal(post.mock.callCount(), 1);
    const [url, body, config] = post.mock.calls[0].arguments;
    assert.equal(url, `https://projects:9001/${ownerId}/${projectId}/video/${videoId}/${operation}`);
    assert.deepEqual(body, response.submitted);
    assert.deepEqual(config.params, { share: "test-share" });
    assert.deepEqual(config.headers, {
      Authorization: `Bearer ${callerToken}`, "X-Project-Version": "7", "Content-Type": "application/json",
    });
    assert.equal(config.httpsAgent.options.rejectUnauthorized, false);
  });
}

test("speed proxy omits sharing parameters when there is no share", async () => {
  await submit("speed");
  assert.equal(post.mock.calls[0].arguments[2].params, undefined);
});

test("speed proxy forwards Projects errors and conflict version headers", async () => {
  post.mock.mockImplementation(async () => {
    throw { response: { status: 409, data: { code: "PROJECT_CONFLICT" },
      headers: { "x-project-version": "9" } } };
  });
  const response = await submit("speed");
  assert.equal(response.status, 409);
  assert.deepEqual(response.body, { code: "PROJECT_CONFLICT" });
  assert.equal(response.headers.get("x-project-version"), "9");
});

test("speed proxy handles an unavailable Projects service", async () => {
  post.mock.mockImplementation(async () => { throw { code: "ECONNREFUSED" }; });
  const response = await submit("speed");
  assert.equal(response.status, 500);
  assert.equal(response.body, "Projects service unavailable");
});

test("speed proxy rejects absent, invalid and mismatched authentication before forwarding", async () => {
  for (const Authorization of [undefined, "Bearer invalid", `Bearer ${callerToken}`]) {
    const response = await submit("speed", { headers: { Authorization } });
    assert.equal(response.status, 401);
  }
  assert.equal(post.mock.callCount(), 0);
});
