const test = require('node:test');
const assert = require('node:assert/strict');
const { VIDEO_LIMITS, validateVideo } = require('../utils/video');

const mib = 1024 * 1024;
const valid = {
  duration: 10,
  size_bytes: 8 * mib,
  width: 1280,
  height: 720,
  video_codec: 'h264',
};

function check(overrides = {}, filename = 'clip.mp4', mime = 'video/mp4', profile = 'free') {
  return validateVideo({ ...valid, ...overrides }, filename, mime, profile);
}

test('free account accepts supported MP4, MOV and WebM videos', () => {
  for (const [name, mime, codec] of [
    ['clip.mp4', 'video/mp4', 'h264'],
    ['clip.mov', 'video/quicktime', 'hevc'],
    ['clip.webm', 'video/webm', 'vp9'],
  ]) {
    assert.equal(check({ video_codec: codec }, name, mime), null, name);
  }
});

test('free duration limit accepts the boundary and rejects the next second', () => {
  const limit = VIDEO_LIMITS.free.maxDurationS;
  assert.equal(check({ duration: limit }), null);
  assert.match(check({ duration: limit + 1 }), /profile limit/);
});

test('free size limit accepts the boundary and rejects one extra byte', () => {
  const limit = VIDEO_LIMITS.free.maxSizeMB * mib;
  assert.equal(check({ size_bytes: limit }), null);
  assert.match(check({ size_bytes: limit + 1 }), /profile limit/);
});

test('free resolution limit accepts landscape and portrait boundaries but rejects overflow', () => {
  const { maxWidth, maxHeight } = VIDEO_LIMITS.free;
  assert.equal(check({ width: maxWidth, height: maxHeight }), null);
  assert.equal(check({ width: maxHeight, height: maxWidth }), null);
  assert.match(check({ width: maxWidth + 1, height: maxHeight }), /Resolution/);
  assert.match(check({ width: maxHeight, height: maxWidth + 1 }), /Resolution/);
});

test('premium accepts a video over free limits when within premium limits', () => {
  const meta = {
    duration: VIDEO_LIMITS.free.maxDurationS + 1,
    size_bytes: (VIDEO_LIMITS.free.maxSizeMB + 1) * mib,
    width: VIDEO_LIMITS.premium.maxWidth,
    height: VIDEO_LIMITS.premium.maxHeight,
  };
  assert.match(check(meta), /profile limit/);
  assert.equal(check(meta, 'clip.mp4', 'video/mp4', 'premium'), null);
});

test('premium limits accept exact boundaries and reject each overflow', () => {
  const { maxDurationS, maxSizeMB, maxWidth, maxHeight } = VIDEO_LIMITS.premium;
  const atLimit = { duration: maxDurationS, size_bytes: maxSizeMB * mib, width: maxWidth, height: maxHeight };
  assert.equal(check(atLimit, 'clip.mp4', 'video/mp4', 'premium'), null);
  for (const overflow of [
    { duration: maxDurationS + 1 },
    { size_bytes: maxSizeMB * mib + 1 },
    { width: maxWidth + 1 },
    { height: maxHeight + 1 },
  ]) {
    assert.match(check({ ...atLimit, ...overflow }, 'clip.mp4', 'video/mp4', 'premium'), /limit/);
  }
});

test('anonymous account cannot upload an otherwise valid video', () => {
  assert.match(check({}, 'clip.mp4', 'video/mp4', 'anonymous'), /Anonymous users cannot upload videos/);
});

test('unsupported extension and MIME combination is rejected', () => {
  assert.match(check({}, 'clip.avi', 'application/octet-stream'), /Unsupported video format/);
});

test('unsupported video codec is rejected for a supported container', () => {
  assert.match(check({ video_codec: 'theora' }, 'clip.mp4', 'video/mp4'), /Unsupported video codec/);
});

test('zero or missing duration is rejected', () => {
  assert.match(check({ duration: 0 }), /Could not determine the video duration/);
  assert.match(check({ duration: undefined }), /Could not determine the video duration/);
});
