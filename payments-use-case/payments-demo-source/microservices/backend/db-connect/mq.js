const amqp = require('amqplib/callback_api');

let mqChannel

let connect = () => {
  amqp.connect(`amqp://${process.env.RABBITMQ_USER || 'root'}:${process.env.RABBITMQ_PASS || 'example'}@${process.env.RABBITMQ_HOST || 'localhost'}`, (err1, connection) => {
    if (err1) {
      console.log('RabbitMQ connect failed.')
    }
    else {
      connection.createChannel((err2, channel) => {
        mqChannel = channel

        channel.assertQueue("demo_toll")
        channel.assertQueue("demo_toll_sink")
        channel.assertQueue("demo_toll_file")
        channel.assertExchange("demo_toll_exchange", "topic")
        channel.bindQueue("demo_toll_sink", "demo_toll_exchange", "demo_toll_sink")
        channel.bindQueue("demo_toll_file", "demo_toll_exchange", "demo_toll_file")
      })
    }
  })
}

connect()

let getMq = () => {
  return mqChannel
}

module.exports = getMq
