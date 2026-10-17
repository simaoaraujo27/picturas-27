const { send_rabbit_msg } = require('./rabbit_mq');

async function publish(jobId) {
  await send_rabbit_msg({
    messageId: `compile-${jobId}`,
    timestamp: new Date().toISOString(),
    procedure: 'video_compile',
    jobId,
    parameters: { jobId },
  }, 'video_compile_queue');
}

module.exports = { publish };
