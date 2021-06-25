let Client = require('ssh2-sftp-client');
let sftp = new Client();

sftp.connect({
  host: process.env.SFTP_HOST || 'localhost',
  port: process.env.SFTP_PORT || 2222,
  username: process.env.SFTP_USER || 'demo',
  password: process.env.SFTP_PASS || 'example'
}).then(() => {
  sftp.list('/upload')
  .then (data => {
    if (!(data.length > 0)) {
      sftp.mkdir('/upload/error')
      sftp.mkdir('/upload/finished')
    }
  })
}).catch((err) => {
  console.log('SFTP not connected')
})

let getSftp = () => {
  return sftp
}

module.exports = getSftp
