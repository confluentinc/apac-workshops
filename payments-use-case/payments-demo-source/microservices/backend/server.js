let mq = require('./db-connect/mq')
let mysql = require('./db-connect/mysql')
let sftp = require('./db-connect/sftp')
let oracle = require('./db-connect/oracle')

let dg = require('./datagen')
let fs = require('fs')
let axios = require('axios')
let cors = require('cors')
let uuid = require('uuid')

const express = require('express')
const app = express()
const port = 3010

let clientErrorHandler = (err, req, res, next) => {
  console.log('error')
  if (req.xhr) {
    res.status(500).send({ error: 'Something failed!' })
  } else {
    next(err)
  }
}

process.on("uncaughException", () => {
  console.log('error')
})

process.on('SIGINT', function() {
  console.log( "\nGracefully shutting down from SIGINT (Ctrl-C)" );
  // some other closing procedures go here
  process.exit(1);
});

app.use(clientErrorHandler);

app.use(cors())

app.get('/transit', (req, res) => {
  try {
    axios({
      method: 'post',
      headers: {
        'Content-Type': 'application/vnd.kafka.avro.v2+json'
      },
      url: `http://${process.env.REST_PROXY_HOST || 'localhost'}:8082/topics/demo_transit_raw`,
      data: {
        "value_schema": "{\"type\":\"record\",\"name\":\"transit\",\"fields\":[{\"name\":\"transaction_id\",\"type\":\"string\"},{\"name\":\"user_id\",\"type\":\"string\"},{\"name\":\"transport_id\",\"type\":\"string\"},{\"name\":\"type\",\"type\":\"string\"},{\"name\":\"fare\",\"type\":\"string\"}]}",
        "records":[
          {
            "value": dg.generateTransitData()
          }
        ]
      }
    }).then((response) => {
      console.log(response.data);
    }, (error) => {
      res.end('err')
      console.log(error.response.data);
    })

    res.send('ok')
  }
  catch (e) {
    console.log("REST API produce failed.")
  }
})

app.get('/retail', (req, res) => {
  try{
    let data = dg.generateRetailData()

    if (dg.randomInRange(1, 100) > 90) {
      delete data.paid
    }

    console.log(data)

    sftp().append(Buffer.from(`${JSON.stringify(data)}\n`), `/upload/data-${Date.now()}.json`)
    .catch(err => {
      res.end('err')
      console.log("SFTP produce failed.")
    })
    res.send('ok')
  }
  catch (e) {
    console.log("SFTP produce failed.")
  }
})

let tollUser = 0

app.get('/toll', (req, res) => {
  try {
    let queue = 'demo_toll'

    let data = dg.generateTollData(tollUser++)

    if (dg.randomInRange(1, 100) > 90) {
      if (dg.randomInRange(1, 100) > 60) {
        let fraudData = JSON.parse(JSON.stringify(data))
        fraudData.fare = dg.randomInRange(200000,500000) / 100
        fraudData.transaction_id = uuid.v4()

        let fraudMsg = JSON.stringify(fraudData)

        setTimeout(() => {
          mq().sendToQueue(queue, Buffer.from(fraudMsg))
          console.log(" [x] Sent payment fraud %s", fraudMsg);
        }, 10000)
      }
      else{
        let fraudData = JSON.parse(JSON.stringify(data))
        fraudData.lat = dg.randomInRange(5359727, 5361906) / 1000000
        fraudData.long = dg.randomInRange(1004018373,1004029213) / 10000000
        fraudData.fare = dg.randomInRange(120,450) / 100
        fraudData.transaction_id = uuid.v4()

        let fraudMsg = JSON.stringify(fraudData)

        setTimeout(() => {
          mq().sendToQueue(queue, Buffer.from(fraudMsg))
          console.log(" [x] Sent location fraud %s", fraudMsg);
        }, 10000)
      }
    }

    let msg = JSON.stringify(data)

    mq().sendToQueue(queue, Buffer.from(msg))

    console.log(" [x] Sent %s", msg);
    res.send('ok')
  }
  catch (e) {
    console.log(e);
    console.log("RabbitMQ produce failed.")
    res.send('error')
  }
})

app.get('/parking', (req, res) => {
  try {
    let data = dg.generateParkingData()
    console.log(data);

    let sql = `INSERT INTO parking (transaction_id, user_id, carpark_id, fare, lat, longd) VALUES ('${data.transaction_id}', '${data.user_id}', '${data.carpark_id}', ${data.fare}, ${data.lat}, ${data.longd})`;

    mysql().query(sql, function (err, result) {
      if (err) {
        console.log("MySQL produce failed.")
        res.send('error')
      }
    })

    res.send('ok')
  }
  catch (e) {
    console.log("MySQL produce failed.")
  }
})

let generateOracleSql = (data) => {
  return `INSERT INTO card_transactions (transaction_id, card_id, paid, lat, longd) VALUES ('${data.transaction_id}', '${data.user_id}', '${data.paid}', '${data.lat}', '${data.long}')`
}

let transactionUser = 0

app.get('/transaction', (req, res) => {
  try {
    let data = dg.generateTransactionData(transactionUser++)

    let sql = generateOracleSql(data)

    if (dg.randomInRange(1, 100) > 90) {
      let fraudData = JSON.parse(JSON.stringify(data))
      fraudData.lat = dg.randomInRange(5359727, 5361906) / 1000000
      fraudData.long = dg.randomInRange(1004018373,1004029213) / 10000000
      fraudData.paid = dg.randomInRange(271,27135) + " INR"
      fraudData.transaction_id = uuid.v4()

      let fraudSql = generateOracleSql(fraudData)

      setTimeout(() => {
        oracle().execute(fraudSql)
        .catch(err => {
          console.log(err);
          res.end('err')
          console.log("Oracle produce failed.")
        })

        console.log(`sent fraud to oracle_transactions ${fraudSql}`)
      }, 10000)
    }

    oracle().execute(sql)
    .catch(err => {
      console.log(err);
      res.end('err')
      console.log("Oracle produce failed.")
    })

    console.log(`sent to oracle_transactions ${sql}`)

    res.send('ok')
  }
  catch (e) {
    console.log(e);
    console.log("Oracle produce failed.")
  }
})

app.listen(port, () => {
  console.log(`Confluent Demo Server listening at http://localhost:${port}`)
})
