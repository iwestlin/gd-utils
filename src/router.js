const Router = require('@koa/router')

const { db } = require('../db')
const { validate_fid, gen_count_body } = require('./gd')
const { send_count, send_help, send_choice, send_task_info, sm, extract_fid, extract_from_text, reply_cb_query, tg_copy, send_all_tasks } = require('./tg')

const { AUTH, ROUTER_PASSKEY, TG_IPLIST } = require('../config')
const { tg_whitelist } = AUTH

const counting = {}
const router = new Router()

router.get('/api/gdurl/count', async ctx => {
  if (!ROUTER_PASSKEY) return ctx.body = 'gd-utils 成功啟動'
  const { query, headers } = ctx.request
  let { fid, type, update, passkey } = query
  if (passkey !== ROUTER_PASSKEY) return ctx.body = 'invalid passkey'
  if (!validate_fid(fid)) throw new Error('無效的分享ID')

  let ua = headers['user-agent'] || ''
  ua = ua.toLowerCase()
  type = (type || '').toLowerCase()
  // todo type=tree
  if (!type) {
    if (ua.includes('curl')) {
      type = 'curl'
    } else if (ua.includes('mozilla')) {
      type = 'html'
    } else {
      type = 'json'
    }
  }
  if (type === 'html') {
    ctx.set('Content-Type', 'text/html; charset=utf-8')
  } else if (['json', 'all'].includes(type)) {
    ctx.set('Content-Type', 'application/json; charset=UTF-8')
  }
  ctx.body = await gen_count_body({ fid, type, update, service_account: true })
})

router.post('/api/gdurl/tgbot', async ctx => {
  const { body } = ctx.request
  console.log('ctx.ip', ctx.ip) // 可以只允许tg服务器的ip
  console.log('tg message:', body)
  if (TG_IPLIST && !TG_IPLIST.includes(ctx.ip)) return ctx.body = 'invalid ip'
  ctx.body = '' // 早点释放连接
  const message = body.message || body.edited_message

  const { callback_query } = body
  if (callback_query) {
    const { id, data } = callback_query
    const chat_id = callback_query.from.id
    const [action, fid] = data.split(' ')
    if (action === 'count') {
      if (counting[fid]) return sm({ chat_id, text: fid + ' 正在統計，請稍候' })
      counting[fid] = true
      send_count({ fid, chat_id }).catch(err => {
        console.error(err)
        sm({ chat_id, text: fid + ' 統計失敗：' + err.message })
      }).finally(() => {
        delete counting[fid]
      })
    } else if (action === 'copy') {
      tg_copy({ fid, chat_id }).then(task_id => {
        task_id && sm({ chat_id, text: `開始複製，任務ID: ${task_id} 可輸入 /task ${task_id} 查詢進度` })
      })
    } else if (action === 'disCopy') {
      const target = '11231'  //儲存目的地2
      tg_copy({ fid, target, chat_id }).then(task_id => {
        task_id && sm({ chat_id, text: `開始複製，任務ID: ${task_id} 可輸入 /task ${task_id} 查詢進度` })
      })
    }
    return reply_cb_query({ id, data }).catch(console.error)
  }

  const chat_id = message && message.chat && message.chat.id
  const text = message && message.text && message.text.trim()
  let username = message && message.from && message.from.username
  username = username && String(username).toLowerCase()
  let user_id = message && message.from && message.from.id
  user_id = user_id && String(user_id).toLowerCase()
  if (!chat_id || !text || !tg_whitelist.some(v => {
    v = String(v).toLowerCase()
    return v === username || v === user_id
  })) return console.warn('異常請求')

  const fid = extract_fid(text) || extract_from_text(text)
  const no_fid_commands = ['/task', '/help']
  if (!no_fid_commands.some(cmd => text.startsWith(cmd)) && !validate_fid(fid)) {
    return sm({ chat_id, text: '未辨識到分享ID' })
  }
  if (text.startsWith('/help')) return send_help(chat_id)
  if (text.startsWith('/count')) {
    if (counting[fid]) return sm({ chat_id, text: fid + ' 正在統計，請稍候' })
    try {
      counting[fid] = true
      const update = text.endsWith(' -u')
      await send_count({ fid, chat_id, update })
    } catch (err) {
      console.error(err)
      sm({ chat_id, text: fid + ' 統計失敗：' + err.message })
    } finally {
      delete counting[fid]
    }
  } else if (text.startsWith('/copy')) {
    const target = text.replace('/copy', '').replace(' -u', '').trim().split(' ').map(v => v.trim())[1]
    if (target && !validate_fid(target)) return sm({ chat_id, text: `目標ID ${target} 格式不正確` })
    const update = text.endsWith(' -u')
    tg_copy({ fid, target, chat_id, update }).then(task_id => {
      task_id && sm({ chat_id, text: `開始複製，任務ID: ${task_id} 可輸入 /task ${task_id} 查詢進度` })
    })
  } else if (text.startsWith('/task')) {
    let task_id = text.replace('/task', '').trim()
    if (task_id === 'all') {
      return send_all_tasks(chat_id)
    }
    task_id = parseInt(task_id)
    if (!task_id) {
      const running_tasks = db.prepare('select id from task where status=?').all('copying')
      if (!running_tasks.length) return sm({ chat_id, text: '当前暂无运行中的任务' })
      return running_tasks.forEach(v => send_task_info({ chat_id, task_id: v.id }).catch(console.error))
    }
    send_task_info({ task_id, chat_id }).catch(console.error)
  } else if (text.includes('drive.google.com/') || validate_fid(text)) {
    return send_choice({ fid: fid || text, chat_id }).catch(console.error)
  } else {
    sm({ chat_id, text: '暫不支持此命令' })
  }
})

module.exports = router
