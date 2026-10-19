const amqp = require('amqplib/callback_api');

const rabbit_host = process.env.RABBITMQ_HOST;
const rabbit_port = process.env.RABBITMQ_PORT;
const rabbit_username = process.env.RABBITMQ_USER;
const rabbit_password = process.env.RABBITMQ_PASS;
const exchange = "picturas";

const rabbit_mq_sv = `amqp://${rabbit_username}:${rabbit_password}@${rabbit_host}:${rabbit_port}`;

function send_rabbit_msg(msg, queue) {
    amqp.connect(rabbit_mq_sv, (err_sv, connection) => {
        if (err_sv) throw err_sv;
        
        connection.createChannel( (err_conn, channel) => {
            if (err_conn) throw err_conn;
            
            channel.assertExchange(exchange, 'direct', {
                durable: true
            });

            channel.publish(exchange, queue, Buffer.from(JSON.stringify(msg)));
        });
        
        setTimeout(() => {
            connection.close();
        }, 500);
    });
    
}

function read_rabbit_msg(queue, callback) {
    function tryConnect() {
        amqp.connect(rabbit_mq_sv, (err_sv, connection) => {
            if (err_sv) {
                console.error(`[RabbitMQ] Connection error for queue ${queue}, retrying in 3s...`, err_sv.message);
                return setTimeout(tryConnect, 3000);
            }

            connection.on("error", (err) => {
                console.error(`[RabbitMQ] Connection dropped for queue ${queue}:`, err.message);
            });
            connection.on("close", () => {
                console.warn(`[RabbitMQ] Connection closed for queue ${queue}, reconnecting in 3s...`);
                setTimeout(tryConnect, 3000);
            });

            connection.createChannel((err_conn, channel) => {
                if (err_conn) {
                    console.error(`[RabbitMQ] Channel error for queue ${queue}:`, err_conn.message);
                    return;
                }

                channel.assertExchange(exchange, 'direct', {
                    durable: true
                });

                channel.assertQueue(queue, { durable: true }, (err_queue, q) => {
                    if (err_queue) {
                        console.error(`[RabbitMQ] Queue assert error for ${queue}:`, err_queue.message);
                        return;
                    }

                    channel.consume(q.queue, (msg) => {
                        if (msg != null) {
                            callback(msg);
                            // Acknowledge the message
                            channel.ack(msg);
                        }
                    }, {
                        noAck: false
                    });
                });
            });
        });
    }
    tryConnect();
}

module.exports = { send_rabbit_msg, read_rabbit_msg };
