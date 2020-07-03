const path = require('path')
const db_location = path.join(__dirname, 'gdurl.sqlite')
const db = require('better-sqlite3')(db_location)

db.pragma('journal_mode = WAL')

module.exports = { db }

create_table_copied()
function create_table_copied () {
  const [exists] = db.prepare('PRAGMA table_info(copied)').all()
  // console.log('exists', exists)
  if (exists) return
  const create_table = `CREATE TABLE "copied" (
  "taskid"  INTEGER,
  "fileid"  TEXT
)`
  db.prepare(create_table).run()
  const create_index = `CREATE INDEX "copied_taskid" ON "copied" ("taskid");`
  db.prepare(create_index).run()
}
