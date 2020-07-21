const { db } = require('./db')

const record = db.prepare('select count(*) as c from gd').get()
db.prepare('delete from gd').run()
console.log('已删除', record.c, '条数据')

db.exec('vacuum')
db.close()
