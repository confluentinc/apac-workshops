let kafka = require('kafka-node')
let axios = require('axios')

const client = new kafka.KafkaClient({kafkaHost: `${process.env.BROKER_HOST || 'localhost'}:${process.env.BROKER_PORT || 9092}`});

var offset = new kafka.Offset(client);

offset.fetch([{ topic: 'demo_transactions_potential_fraud', partition: 0, time: -1 }], (err, data) => {
    let latestOffset = (data) ? data['demo_transactions_potential_fraud']['0'][0] : 0
    console.log("Consumer current offset: " + latestOffset);

    let consumer = new kafka.Consumer(
      client,
      [{ topic: 'demo_transactions_potential_fraud', offset: latestOffset }],
      { fromOffset: 'true' }
    )

    consumer.on('ready', () => {
      console.log('ready');
    })

    consumer.on('message', (message) => {
      let str = JSON.parse(JSON.stringify(message)).value
      let transactionId = str.substring(7, 43)

      console.log(transactionId)

      if (process.env.PD_ROUTING_KEY) {
        console.log(`Sending alert for ${transactionId} to PD.`)
        let payload = { "payload":{"summary":`Potential fraud in transaction ${transactionId}`,"severity":"info","source":"Confluent Demo - Alerts Microservice","component":"","group":"","class":""},"routing_key":process.env.PD_ROUTING_KEY,"event_action":"trigger","dedup_key":""}
        axios({
          method: 'post',
          headers: {
            'Content-Type': 'application/json'
          },
          url: 'https://events.pagerduty.com/v2/enqueue',
          data: payload
        }).then((response) => {
          // console.log(response.data);
        }, (error) => {
          console.log(error.response.data);
        })
      }
    })

    consumer.on('error', (error) => {
      console.log(error);

    })
});
