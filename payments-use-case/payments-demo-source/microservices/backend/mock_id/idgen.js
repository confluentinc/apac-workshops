let uuid = require('uuid')
let fs = require('fs');

let array = []

for (let i = 0; i < 1000; i++) {
  array.push(uuid.v4())
}

console.log(JSON.stringify(array))
