const Table = require('cli-table3')
const dayjs = require('dayjs')
const axios = require('@viegg/axios')
const HttpsProxyAgent = require('https-proxy-agent')

const { db } = require('../db')
const { gen_count_body, validate_fid, real_copy, get_name_by_id } = require('./gd')
const { AUTH, DEFAULT_TARGET } = require('../config')
const { tg_token } = AUTH
const gen_link = (fid, text) => `<a href="https://drive.google.com/drive/folders/${fid}">${text || fid}</a>`

if (!tg_token) throw new Error('請先在auth.js中設定tg_token')
const { https_proxy } = process.env
const axins = axios.create(https_proxy ? { httpsAgent: new HttpsProxyAgent(https_proxy) } : {})

const FID_TO_NAME = {}

async function get_folder_name (fid) {
  let name = FID_TO_NAME[fid]
  if (name) return name
  name = await get_name_by_id(fid)
  return FID_TO_NAME[fid] = name
}

module.exports = { send_count, send_help, sm, extract_fid, reply_cb_query, send_choice, send_task_info, send_all_tasks, tg_copy, extract_from_text }

function send_help (chat_id) {
  const text = `<pre>[使用說明]
***不支持單檔分享***
命令 ｜ 說明

/help | 返回本使用說明

/count sourceID [-u] | 返回sourceID的文件統計資訊, sourceID可以是共享網址本身，也可以是共享ID。如果命令最后加上 -u，則無視快取記錄強制從線上獲取，適合一段時候後才更新完畢的分享連結。

/copy sourceID targetID(選填) [-u] | 將sourceID的文件複製到targetID裡（會新建一個資料夾），若無targetID，則會複製到預設位置（config.js中的DEFAULT_TARGET）。如果命令最後加上 -u，則無視快取記錄強制從線上獲取源資料夾資訊。返回拷貝任務的taskID

/task taskID(選填) | 返回對應任務的進度信息，若不填taskID則返回所有正在運行的任務進度，若填 all 則返回所有任務列表(歷史紀錄)
</pre>`
  return sm({ chat_id, text, parse_mode: 'HTML' })
}

function send_choice ({ fid, chat_id }) {
  return sm({
    chat_id,
    text: `辨識到分享ID ${fid}，請選擇動作`,
    reply_markup: {
      inline_keyboard: [
        [
          { text: '文件統計', callback_data: `count ${fid}` }
        ],
        [
          { text: '開始複製(預設)', callback_data: `copy ${fid}` }
        ],
        [
          { text: '開始複製(1)', callback_data: `copy2 ${fid}` }
        ],
        [
          { text: '開始複製(2)', callback_data: `copy3 ${fid}` }
        ]
      ]
    }
  })
}

async function send_all_tasks (chat_id) {
  let records = db.prepare('select id, status, ctime from task').all()
  if (!records.length) return sm({ chat_id, text: '資料庫中沒有任務記錄' })
  const tb = new Table({ style: { head: [], border: [] } })
  const headers = ['ID', 'status', 'ctime']
  records = records.map(v => {
    const { id, status, ctime } = v
    return [id, status, dayjs(ctime).format('YYYY-MM-DD HH:mm:ss')]
  })
  tb.push(headers, ...records)
  const text = tb.toString().replace(/─/g, '—')
  const url = `https://api.telegram.org/bot${tg_token}/sendMessage`
  return axins.post(url, {
    chat_id,
    parse_mode: 'HTML',
    text: `所有拷貝任務：\n<pre>${text}</pre>`
  }).catch(err => {
    // const description = err.response && err.response.data && err.response.data.description
    // if (description && description.includes('message is too long')) {
    if (true) {
      const text = [headers].concat(records).map(v => v.join('\t')).join('\n')
      return sm({ chat_id, parse_mode: 'HTML', text: `所有拷貝任務：\n<pre>${text}</pre>` })
    }
    console.error(err)
  })
}

async function get_task_info (task_id) {
  const record = db.prepare('select * from task where id=?').get(task_id)
  if (!record) return {}
  const { source, target, status, copied, mapping, ctime, ftime } = record
  const folder_mapping = mapping && mapping.trim().split('\n')
  const new_folder = folder_mapping && folder_mapping[0].split(' ')[1]
  const { summary } = db.prepare('select summary from gd where fid=?').get(source) || {}
  const { file_count, folder_count, total_size } = summary ? JSON.parse(summary) : {}
  const copied_files = copied ? copied.trim().split('\n').length : 0
  const copied_folders = folder_mapping ? (folder_mapping.length - 1) : 0
  let text = '任務ID：' + task_id + '\n'
  const folder_name = await get_folder_name(source)
  text += '源資料夾：' + gen_link(source, folder_name) + '\n'
  text += '目的位置：' + gen_link(target) + '\n'
  text += '新資料夾：' + (new_folder ? gen_link(new_folder) : '尚未創建') + '\n'
  text += '任務狀態：' + status + '\n'
  text += '創建時間：' + dayjs(ctime).format('YYYY-MM-DD HH:mm:ss') + '\n'
  text += '完成時間：' + (ftime ? dayjs(ftime).format('YYYY-MM-DD HH:mm:ss') : '未完成') + '\n'
  var pct = copied_folders/(folder_count === undefined ? '未知數量' : folder_count)*100
  pct = pct.toFixed(2);
  text += '目錄進度：' + copied_folders + '/' + (folder_count === undefined ? '未知數量' : folder_count) + ' - ' + pct + '%\n'
  pct = copied_files/(file_count === undefined ? '未知數量' : file_count)*100
  pct = pct.toFixed(2);
  text += '文件進度：' + copied_files + '/' + (file_count === undefined ? '未知數量' : file_count) + ' - ' + pct + '%\n'
  text += '合計大小：' + (total_size || '未知大小')
  const total_count = (folder_count || 0) + (file_count || 0)
  return { text, status, total_count }
}

async function send_task_info ({ task_id, chat_id }) {
  const { text, status, total_count } = await get_task_info(task_id)
  if (!text) return sm({ chat_id, text: '資料庫查無此任務ID：' + task_id })
  const url = `https://api.telegram.org/bot${tg_token}/sendMessage`
  let message_id
  try {
    const { data } = await axins.post(url, { chat_id, text, parse_mode: 'HTML' })
    message_id = data && data.result && data.result.message_id
  } catch (e) {
    console.log('fail to send message to tg', e.message)
  }
  // get_task_info 在task文件数超大时比较吃cpu，如果超5万就不每10秒更新了
  if (!message_id || status !== 'copying' || total_count > 50000) return
  const loop = setInterval(async () => {
    const url = `https://api.telegram.org/bot${tg_token}/editMessageText`
    const { text, status } = await get_task_info(task_id)
    if (status !== 'copying') clearInterval(loop)
    axins.post(url, { chat_id, message_id, text, parse_mode: 'HTML' }).catch(e => console.error(e.message))
  }, 10 * 1000)
}

async function tg_copy ({ fid, target, chat_id, update }) { // return task_id
  target = target || DEFAULT_TARGET
  if (!target) {
    sm({ chat_id, text: '請輸入目的地ID或先在config.js中設定預設複製的目的地ID(DEFAULT_TARGET)' })
    return
  }

  let record = db.prepare('select id, status from task where source=? and target=?').get(fid, target)
  if (record) {
    if (record.status === 'copying') {
      sm({ chat_id, text: '已有相同源ID和目的ID的任務正在進行，查詢進度可輸入 /task ' + record.id })
      return
    } else if (record.status === 'finished') {
      sm({ chat_id, text: `檢測到已存在的任務 ${record.id}，開始繼續拷貝` })
    }
  }

  real_copy({ source: fid, update, target, service_account: !USE_PERSONAL_AUTH, is_server: true })
    .then(async info => {
      if (!record) record = {} // 防止无限循环
      if (!info) return
      const { task_id } = info
      const row = db.prepare('select * from task where id=?').get(task_id)
      const { source, target, status, copied, mapping, ctime, ftime } = row
      const { summary } = db.prepare('select summary from gd where fid=?').get(source) || {}
      const { file_count, folder_count, total_size } = summary ? JSON.parse(summary) : {}
      const copied_files = copied ? copied.trim().split('\n').length : 0
      const copied_folders = mapping ? (mapping.trim().split('\n').length - 1) : 0

      let text = `任務 ${task_id} 完成\n`
      const name = await get_folder_name(source)
      text += '源資料夾：' + gen_link(source, name) + '\n'
      text += '目錄完成數：' + copied_folders + '/' + folder_count + '\n'
      text += '文件完成數：' + copied_files + '/' + file_count + '\n'
      text += '合計大小：' + (total_size || '未知大小') + '\n'
      sm({ chat_id, text, parse_mode: 'HTML' })
    })
    .catch(err => {
      if (!record) record = {}
      console.error('複製失敗', fid, '-->', target)
      console.error(err)
      sm({ chat_id, text: '複製失敗，失敗訊息：' + err.message })
    })

  while (!record) {
    record = db.prepare('select id from task where source=? and target=?').get(fid, target)
    await sleep(1000)
  }
  return record.id
}

function sleep (ms) {
  return new Promise((resolve, reject) => {
    setTimeout(resolve, ms)
  })
}

function reply_cb_query ({ id, data }) {
  const url = `https://api.telegram.org/bot${tg_token}/answerCallbackQuery`
  return axins.post(url, {
    callback_query_id: id,
    text: '開始執行 ' + data
  })
}

async function send_count ({ fid, chat_id, update }) {
  const table = await gen_count_body({ fid, update, type: 'tg', service_account: true })
  if (!table) return sm({ chat_id, parse_mode: 'HTML', text: gen_link(fid) + ' 資訊獲取失敗' })
  const url = `https://api.telegram.org/bot${tg_token}/sendMessage`
  const gd_link = `https://drive.google.com/drive/folders/${fid}`
  const name = await get_folder_name(fid)
  return axins.post(url, {
    chat_id,
    parse_mode: 'HTML',
    text: `<pre>源資料夾名稱：${name}
源連結：${gd_link}
${table}</pre>`
  }).catch(async err => {
    // const description = err.response && err.response.data && err.response.data.description
    // const too_long_msgs = ['request entity too large', 'message is too long']
    // if (description && too_long_msgs.some(v => description.toLowerCase().includes(v))) {
    if (true) {
      const smy = await gen_count_body({ fid, type: 'json', service_account: true })
      const { file_count, folder_count, total_size } = JSON.parse(smy)
      return sm({
        chat_id,
        parse_mode: 'HTML',
        text: `連結：<a href="https://drive.google.com/drive/folders/${fid}">${fid}</a>\n<pre>
表格太長超出telegram訊息限制，僅顯示概要：
目錄名稱：${name}
文件總數：${file_count}
目錄總數：${folder_count}
合計大小：${total_size}
</pre>`
      })
    }
    throw err
  })
}

function sm (data) {
  const url = `https://api.telegram.org/bot${tg_token}/sendMessage`
  return axins.post(url, data).catch(err => {
    // console.error('fail to post', url, data)
    console.error('fail to send message to tg:', err.message)
  })
}

function extract_fid (text) {
  text = text.replace(/^\/count/, '').replace(/^\/copy/, '').replace(/\\/g, '').trim()
  const [source, target] = text.split(' ').map(v => v.trim())
  if (validate_fid(source)) return source
  try {
    if (!text.startsWith('http')) text = 'https://' + text
    const u = new URL(text)
    if (u.pathname.includes('/folders/')) {
      const reg = /[^\/?]+$/
      const match = u.pathname.match(reg)
      return match && match[0]
    }
    return u.searchParams.get('id')
  } catch (e) {
    return ''
  }
}

function extract_from_text (text) {
  const reg = /https?:\/\/drive.google.com\/[^\s]+/g
  const m = text.match(reg)
  return m && extract_fid(m[0])
}
