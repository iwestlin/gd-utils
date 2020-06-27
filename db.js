const path = require('path')
const db_location = path.join(__dirname, 'gdurl.sqlite')
const db = require('better-sqlite3')(db_location)

module.exports = { db }
