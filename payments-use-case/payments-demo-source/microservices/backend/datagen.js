let carparks = require('./mock_id/carpark.json')
let shops = require('./mock_id/shop.json')
let products = require('./mock_id/product.json')
let tollgates = require('./mock_id/tollgate.json')
let trains = require('./mock_id/train.json')
let buses = require('./mock_id/bus.json')
let users = require('./mock_id/user.json')

let uuid = require('uuid')

let randomInRange = (from, to) => {
  var r = Math.random();
  return Math.floor(r * (to - from) + from);
}

let generateTransitData = () => {
  let data;

  if (randomInRange(0,2)) {
    data = {
      transaction_id: uuid.v4(),
      user_id: users[randomInRange(0,999)],
      type: "bus",
      transport_id: buses[randomInRange(0,999)],
      fare: `RM${randomInRange(80,200) / 100}`
    }
  }
  else {
    data = {
      transaction_id: uuid.v4(),
      user_id: users[randomInRange(0,999)],
      type: "train",
      transport_id: trains[randomInRange(0,999)],
      fare: "" + randomInRange(120,450) / 100
    }
  }

  return data
}

let generateRetailData = () => {
  let data;

  data = {
    transaction_id: uuid.v4(),
    user_id: users[randomInRange(0,999)],
    shop_id: shops[randomInRange(0,999)],
    paid: randomInRange(200,3500) / 100
  }

  return data
}

let generateTollData = (userId) => {
  let data;

  data = {
    transaction_id: uuid.v4(),
    user_id: users[userId%1000],
    tollgate_id: tollgates[randomInRange(0,999)],
    fare: randomInRange(200,500) / 100,
    lat: randomInRange(2904294, 2908484) / 1000000,
    long: randomInRange(1017604163,1017647403) / 10000000
  }

  return data
}

let generateTransactionData = (userId) => {
  let data;

  data = {
    transaction_id: uuid.v4(),
    user_id: users[userId%1000],
    paid: randomInRange(271,27135) + " INR",
    lat: randomInRange(2904294, 2908484) / 1000000,
    long: randomInRange(1017604163,1017647403) / 10000000
  }

  return data
}

let parkingSpots = [
  {lat:3.1556536186444055, longd: 101.70483753848505}, // Suria KLCC
  {lat:3.206593, longd: 101.7207738}, // Setapak Central
  {lat:3.1860569, longd: 101.6335733} // Plaza Arkadia
]

let generateParkingData = () => {
  let data;

  carparkId = randomInRange(0,3)

  data = {
    transaction_id: uuid.v4(),
    user_id: users[randomInRange(0,999)],
    carpark_id: carparks[carparkId],
    fare: randomInRange(70,2500) / 100,
    lat: parkingSpots[carparkId].lat,
    longd: parkingSpots[carparkId].longd
  }

  return data
}

module.exports = {
  randomInRange: randomInRange,
  generateTransitData: generateTransitData,
  generateRetailData: generateRetailData,
  generateTollData: generateTollData,
  generateParkingData: generateParkingData,
  generateTransactionData: generateTransactionData
}
