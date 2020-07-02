const path = require('path')
const db_location = path.join(__dirname, 'gdurl.sqlite')
const db = require('better-sqlite3')(db_location)

db.pragma('journal_mode = WAL')

module.exports = { db }
