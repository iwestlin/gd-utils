const { ls_folder } = require('./src/gd')

ls_folder({ fid: 'root' }).then(console.log).catch(console.error)
