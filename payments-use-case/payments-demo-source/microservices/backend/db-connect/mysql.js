let mysql      = require('mysql');

let connection = mysql.createConnection({
  host     : process.env.MYSQL_HOST || 'localhost',
  user     : process.env.MYSQL_USER || 'root',
  password : process.env.MYSQL_PASS || 'example',
  database  : process.env.MYSQL_DB || 'demo',
  insecureAuth : true
});

connection.connect((err) => {
  if(!err) {
    let sql = `CREATE TABLE IF NOT EXISTS parking (transaction_id VARCHAR(100) NOT NULL, user_id VARCHAR(100) NOT NULL, carpark_id VARCHAR(100) NOT NULL, fare DOUBLE, lat DOUBLE, longd DOUBLE)`

    connection.query(sql, function (err, result) {
      if (err) {
        console.log("Create parking table failed.")
      }
    })
  }
  else
      console.log('Database not connected! : '+ JSON.stringify(err, undefined,2));
})

let getConnection = () => {
  return connection
}

module.exports = getConnection

// ALTER USER 'root' IDENTIFIED WITH mysql_native_password BY 'example';
// CREATE TABLE parking (
// 	transaction_id VARCHAR(100) NOT NULL,
// 	user_id VARCHAR(100) NOT NULL,
// 	carpark_id VARCHAR(100) NOT NULL,
// 	fare DOUBLE
// )
