const test = require('node:test');
const assert = require('node:assert/strict');
const { imageTools, videoPipeline, videoOps, unsupportedVideoTools } = require('../utils/video');

test('captions apply to all videos, while images skip them and trim stays targeted', () => {
  const project = {
    imgs: [{ _id: 'a', media_type: 'video' }, { _id: 'b', media_type: 'video' }, { _id: 'c', media_type: 'image' }],
    tools: [
      { position: 2, procedure: 'subtitles', params: {} },
      { position: 0, procedure: 'brightness', params: { brightness: 0.5 } },
      { position: 1, procedure: 'trim', params: { imgId: 'a', start: 0, end: 2 } },
    ],
  };
  assert.deepEqual(imageTools(project).map(t => t.procedure), ['brightness']);
  assert.deepEqual(videoPipeline(project, 'a').map(t => t.procedure), ['brightness', 'trim', 'subtitles']);
  assert.deepEqual(videoPipeline(project, 'b').map(t => t.procedure), ['brightness', 'subtitles']);
  assert.equal(videoOps(project), 5);
  assert.deepEqual(unsupportedVideoTools(project), []);
  project.tools = [project.tools[0]];
  assert.deepEqual(imageTools(project), []);
  assert.equal(videoOps(project), 2);
});


// Teste de regressao adicionado para valida os requisitos funcionais apos refatoracao
test('mixed project preserves ordered video stages and skips video-only stages for images', () => {
  const project = {
    imgs: [{ _id: 'video-a', media_type: 'video' }, { _id: 'video-b', media_type: 'video' }, { _id: 'image-a', media_type: 'image' }],
    tools: [
      { position: 4, procedure: 'extract_frames', params: { mode: 'count', count: 2, format: 'png' } },
      { position: 0, procedure: 'brightness', params: { brightness: 1.2 } },
      { position: 3, procedure: 'subtitles', params: {} },
      { position: 2, procedure: 'speed', params: { imgId: 'video-b', factor: 2 } },
      { position: 1, procedure: 'trim', params: { imgId: 'video-a', start: 1, end: 3 } },
    ],
  };
  assert.deepEqual(imageTools(project).map(t => t.procedure), ['brightness']);
  assert.deepEqual(videoPipeline(project, 'video-a').map(t => t.procedure),
    ['brightness', 'trim', 'subtitles', 'extract_frames']);
  assert.deepEqual(videoPipeline(project, 'video-b').map(t => t.procedure),
    ['brightness', 'speed', 'subtitles', 'extract_frames']);
  assert.equal(videoOps(project), 8);
});
