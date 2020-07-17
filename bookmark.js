const fs = require('fs')
const {db} = require('./db')

const action = process.argv[2] || 'export'
const filepath = process.argv[3] || 'bookmarks.json'

if (action === 'export') {
  const bookmarks = db.prepare('select * from bookmark').all()
  fs.writeFileSync(filepath, JSON.stringify(bookmarks))
  console.log('bookmarks exported', filepath)
} else if (action === 'import') {
  let bookmarks = fs.readFileSync(filepath, 'utf8')
  bookmarks = JSON.parse(bookmarks)
  bookmarks.forEach(v => {
    const {alias, target} = v
    const exist = db.prepare('select alias from bookmark where alias=?').get(alias)
    if (exist) {
      db.prepare('update bookmark set target=? where alias=?').run(target, alias)
    } else {
      db.prepare('INSERT INTO bookmark (alias, target) VALUES (?, ?)').run(alias, target)
    }
  })
  console.log('bookmarks imported', bookmarks)
} else {
  console.log('[help info]')
  console.log('export: node bookmark.js export bm.json')
  console.log('import: node bookmark.js import bm.json')
}
