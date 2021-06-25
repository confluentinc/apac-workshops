const oracledb = require('oracledb')

oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT
oracledb.autoCommit = true

let connection

let run = async () => {
  try {
    connection = await oracledb.getConnection( {
      user          : process.env.ORACLE_USER || `C##MYUSER`,
      password      : process.env.ORACLE_PASS || `mypassword`,
      connectString : `${process.env.ORACLE_HOST || "localhost"}/${process.env.ORACLE_DB || "ORCLCDB"}`
    })

    let sql = `create table card_transactions (transaction_id VARCHAR(100), card_id VARCHAR(100), paid VARCHAR(50), lat VARCHAR(50), longd VARCHAR(50))`
    const result = await connection.execute(sql)
    console.log(result.rows)

  } catch (err) {
    console.error(err)
  }
}

run()

let getConnection = () => {
  return connection
}

module.exports = getConnection
