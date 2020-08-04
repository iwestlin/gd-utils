const Table = require('cli-table3')
const colors = require('colors/safe')
const { escape } = require('html-escaper')

module.exports = { make_table, summary, make_html, make_tg_table, format_size }

function make_html ({ file_count, folder_count, total_size, details }) {
  const head = ['类型', '数量', '大小']
  const th = '<tr>' + head.map(k => `<th>${k}</th>`).join('') + '</tr>'
  const td = details.map(v => '<tr>' + [escape(v.ext), v.count, v.size].map(k => `<td>${k}</td>`).join('') + '</tr>').join('')
  let tail = ['合计', file_count + folder_count, total_size]
  tail = '<tr style="font-weight:bold">' + tail.map(k => `<td>${k}</td>`).join('') + '</tr>'
  const table = `<table border="1" cellpadding="12" style="border-collapse:collapse;font-family:serif;font-size:22px;margin:10px auto;text-align: center">
    ${th}
    ${td}
    ${tail}
  </table>`
  return table
}

function make_table ({ file_count, folder_count, total_size, details }) {
  const tb = new Table()
  const hAlign = 'center'
  const headers = ['Type', 'Count', 'Size'].map(v => ({ content: colors.bold.brightBlue(v), hAlign }))
  const records = details.map(v => [v.ext, v.count, v.size]).map(arr => {
    return arr.map(content => ({ content, hAlign }))
  })
  const total_count = file_count + folder_count
  const tails = ['总计', total_count, total_size].map(v => ({ content: colors.bold(v), hAlign }))
  tb.push(headers, ...records)
  tb.push(tails)
  return tb.toString() + '\n'
}

function make_tg_table ({ file_count, folder_count, total_size, details }) {
  const tb = new Table({
    // chars: {
    //   'top': '═',
    //   'top-mid': '╤',
    //   'top-left': '╔',
    //   'top-right': '╗',
    //   'bottom': '═',
    //   'bottom-mid': '╧',
    //   'bottom-left': '╚',
    //   'bottom-right': '╝',
    //   'left': '║',
    //   'left-mid': '╟',
    //   'right': '║',
    //   'right-mid': '╢'
    // },
    style: {
      head: [],
      border: []
    }
  })
  const hAlign = 'center'
  const headers = ['Type', 'Count', 'Size'].map(v => ({ content: v, hAlign }))
  details.forEach(v => {
    if (v.ext === '文件夹') v.ext = '[Folder]'
    if (v.ext === '无扩展名') v.ext = '[NoExt]'
  })
  const records = details.map(v => [v.ext, v.count, v.size]).map(arr => arr.map(content => ({ content, hAlign })))
  const total_count = file_count + folder_count
  const tails = ['Total', total_count, total_size].map(v => ({ content: v, hAlign }))
  tb.push(headers, ...records)
  tb.push(tails)
  return tb.toString().replace(/─/g, '—') // 防止在手机端表格换行 去掉replace后在pc端更美观
}

function summary (info, sort_by) {
  const files = info.filter(v => v.mimeType !== 'application/vnd.google-apps.folder')
  const file_count = files.length
  const folder_count = info.filter(v => v.mimeType === 'application/vnd.google-apps.folder').length
  let total_size = info.map(v => Number(v.size) || 0).reduce((acc, val) => acc + val, 0)
  total_size = format_size(total_size)
  const exts = {}
  const sizes = {}
  let no_ext = 0; let no_ext_size = 0
  files.forEach(v => {
    let { name, size } = v
    size = Number(size) || 0
    const ext = name.split('.').pop().toLowerCase()
    if (!name.includes('.') || ext.length > 10) { // 若 . 后超过10字符，判断为无扩展名
      no_ext_size += size
      return no_ext++
    }
    if (exts[ext]) {
      exts[ext]++
    } else {
      exts[ext] = 1
    }
    if (sizes[ext]) {
      sizes[ext] += size
    } else {
      sizes[ext] = size
    }
  })
  const details = Object.keys(exts).map(ext => {
    const count = exts[ext]
    const size = sizes[ext]
    return { ext, count, size: format_size(size), raw_size: size }
  })
  if (sort_by === 'size') {
    details.sort((a, b) => b.raw_size - a.raw_size)
  } else if (sort_by === 'name') {
    details.sort((a, b) => (a.ext > b.ext) ? 1 : -1)
  } else {
    details.sort((a, b) => b.count - a.count)
  }
  if (no_ext) details.push({ ext: '无扩展名', count: no_ext, size: format_size(no_ext_size), raw_size: no_ext_size })
  if (folder_count) details.push({ ext: '文件夹', count: folder_count, size: 0, raw_size: 0 })
  return { file_count, folder_count, total_size, details }
}

function format_size (n) {
  n = Number(n)
  if (Number.isNaN(n)) return ''
  if (n < 0) return 'invalid size'
  const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
  let flag = 0
  while (n >= 1024) {
    n = (n / 1024)
    flag++
  }
  return n.toFixed(2) + ' ' + units[flag]
}
