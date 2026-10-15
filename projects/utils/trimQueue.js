const amqp = require('amqplib');
const queue = 'video_trim_queue';
const url = `amqp://${process.env.RABBITMQ_USER}:${process.env.RABBITMQ_PASS}@${process.env.RABBITMQ_HOST}:${process.env.RABBITMQ_PORT}`;
async function publish(jobId) {
  const connection = await amqp.connect(url);
  try {
    const channel = await connection.createConfirmChannel();
    await channel.assertExchange('picturas', 'direct', { durable: true });
    await channel.assertQueue(queue, { durable: true });
    await channel.bindQueue(queue, 'picturas', queue);
    channel.publish('picturas', queue, Buffer.from(JSON.stringify({ jobId })), { persistent: true });
    await channel.waitForConfirms();
    await channel.close();
  } finally { await connection.close(); }
}
module.exports = { publish };
