#!/usr/bin/env node

const path = require('path')
const {db} = require('./db')

const filepath = path.join(__dirname, 'backup', `${Date.now()}.sqlite`)

db.backup(filepath)
  .then(() => {
    console.log(filepath)
  })
  .catch((err) => {
    console.log('backup failed:', err)
  })
