const fs = require('fs')
const path = require('path')
const dayjs = require('dayjs')

const ID_DIR_MAPPING = {}
/*
  Data format:
    Each index in "dirs" array is an array representing a directory:
      First item: "directory path*always 0*directory modified date"
        Note that forward slashes are used instead of (Windows style) backslashes
      Then, for each each file in the directory: "filename*size of file*file modified date"
      Seconds to last item tells the total size of directory content
      Last item refrences IDs to all subdirectories of this dir (if any).
        ID is the item index in dirs array.
const dirs = [
  [
    `C:/WordPress/wp-admin*0*1597318033`,
    `widgets.php*18175*1597318033`,
    743642,
    // "2*11*12*13*14*15*16"
    "1"
  ],
  [
    `C:/WordPress/wp-admin/test*0*1597318033`,
    `test.php*12175*1597318033`,
    12175,
    ""
  ]
] */

function snap2html ({ root, data }) {
  const total_size = sum_size(data)
  const template = fs.readFileSync(path.join(__dirname, '../static/snap2html.template'), 'utf8')
  let html = template.replace('var dirs = []', 'var dirs = ' + JSON.stringify(trans(data, root)))
  html = html.replace(/\[TITLE\]/g, root.name)
  html = html.replace('[GEN DATE]', dayjs().format('YYYY-MM-DD HH:mm:ss'))
  const file_numbers = data.filter(v => !is_folder(v)).length
  const folder_numbers = data.filter(v => is_folder(v)).length
  html = html.replace(/\[NUM FILES\]/g, file_numbers)
  html = html.replace('[NUM DIRS]', folder_numbers)
  html = html.replace('[TOT SIZE]', total_size)
  return html
}

function sum_size (arr) {
  let total = 0
  arr.forEach(v => total += Number(v.size) || 0)
  return total
}

function is_folder (v) {
  return v.mimeType === 'application/vnd.google-apps.folder'
}

function unix_time (t) {
  if (!t) return 0
  t = +new Date(t)
  return parseInt(t / 1000, 10)
}

function escape_name (name) {
  return name.replace(/\*/g, '&#42;')
}

function trans (arr, root) {
  if (!arr.length) return arr
  const first = arr[0]
  get_size(root, arr)
  let dirs = arr.filter(is_folder)
  dirs.unshift(root)
  dirs = dirs.map(dir => {
    const { name, id, size, modifiedTime } = dir
    const dir_path = root.name + get_path(id, arr)
    let result = [`${escape_name(dir_path)}*0*${unix_time(modifiedTime)}`]
    const children = arr.filter(v => v.parent === id)
    const child_files = children.filter(v => !is_folder(v)).map(file => {
      return `${escape_name(file.name)}*${file.size}*${unix_time(file.modifiedTime)}`
    })
    result = result.concat(child_files)
    result.push(size)
    const sub_folders = children.filter(is_folder).map(v => dirs.findIndex(vv => vv.id === v.id))
    result.push(sub_folders.join('*'))
    return result
  })
  return dirs
}

function get_size (node, arr) {
  if (node.size !== undefined) return node.size
  const children = arr.filter(v => v.parent === node.id)
  const sizes = children.map(child => get_size(child, arr))
  const total_size = sizes.reduce((acc, val) => Number(acc) + Number(val), 0)
  return node.size = total_size
}

function get_path (id, folders) {
  let result = ID_DIR_MAPPING[id]
  if (result !== undefined) return result
  result = ''
  let temp = id
  let folder = folders.filter(v => v.id === temp)[0]
  while (folder) {
    result = `/${folder.name}` + result
    temp = folder.parent
    if (ID_DIR_MAPPING[temp]) {
      result = ID_DIR_MAPPING[temp] + result
      return ID_DIR_MAPPING[id] = result
    }
    folder = folders.filter(v => v.id === temp)[0]
  }
  return ID_DIR_MAPPING[id] = result
}

module.exports = { snap2html }
