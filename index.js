const TeleBot = require('telebot');
const { spawn } = require('child_process');

const { db } = require('./db');
const { validate_fid, gen_count_body, count } = require('./src/gd');
const { send_count, send_help, send_choice, send_task_info, sm, extract_fid, extract_from_text, reply_cb_query, tg_copy, send_all_tasks, send_bm_help, get_target_by_alias, gen_bookmark_choices, send_all_bookmarks, set_bookmark, unset_bookmark, clear_tasks, send_task_help, rm_task, clear_button } = require('./src/tg')

const { AUTH, ROUTER_PASSKEY, TG_IPLIST } = require('./config')
const { tg_whitelist } = AUTH
const { tg_token } = AUTH
const { adminUsers } = AUTH
const bot = new TeleBot(tg_token);

const COPYING_FIDS = {}
const counting = {}

bot.on('text', (msg) => {

    const chat_id = msg && msg.chat && msg.chat.id
    // console.log(msg);
    // console.log('chat_id:   '+ chat_id);
    // let prex = String(msg.text).substring(0,1);
    // console.log(prex);

    const text = msg && msg.text && msg.text.trim() || ''
    const message_str = text
    // let username = msg && msg.from && msg.from.username
    // msgs = username && String(username).toLowerCase()
    // let user_id = msgs && msgs.from && msgs.from.id
    // user_id = user_id && String(user_id).toLowerCase()
    const id = msg.from.id;
    if(adminUsers.indexOf(id) < 0){
        msg.reply.text('您的用户名或ID不在机器人的白名单中，如果是您配置的机器人，请先到config.js中配置自己的username');
        return console.warn('收到非白名单用户的请求')
    }
    // if (!chat_id || !tg_whitelist.some(v => {
    //   v = String(v).toLowerCase()
    //   return v === username || v === user_id
    // })) {
    //   chat_id && sm({ chat_id, text: '您的用户名或ID不在机器人的白名单中，如果是您配置的机器人，请先到config.js中配置自己的username' })
    //   return console.warn('收到非白名单用户的请求')
    // }
      const fid = extract_fid(text) || extract_from_text(text) || extract_from_text(message_str)
      const no_fid_commands = ['/task', '/help', '/bm']
      if (!no_fid_commands.some(cmd => text.startsWith(cmd)) && !validate_fid(fid)) {
        sm({ chat_id, text: '未识别出分享ID' })
        is_shell = true
      }
      if (text.startsWith('/help')) return send_help(chat_id)
      if (text.startsWith('/bm')) {
        const [cmd, action, alias, target] = text.split(' ').map(v => v.trim()).filter(v => v)
        if (!action) return send_all_bookmarks(chat_id)
        if (action === 'set') {
          if (!alias || !target) return sm({ chat_id, text: '别名和目标ID不能为空' })
          if (alias.length > 24) return sm({ chat_id, text: '别名不要超过24个英文字符长度' })
          if (!validate_fid(target)) return sm({ chat_id, text: '目标ID格式有误' })
          set_bookmark({ chat_id, alias, target })
        } else if (action === 'unset') {
          if (!alias) return sm({ chat_id, text: '别名不能为空' })
          unset_bookmark({ chat_id, alias })
        } else {
          send_bm_help(chat_id)
        }
      } else if (text.startsWith('/count')) {
        if (counting[fid]) return sm({ chat_id, text: fid + ' 正在统计，请稍等片刻' })
        try {
          counting[fid] = true
          const update = text.endsWith(' -u')
          send_count({ fid, chat_id, update })
        } catch (err) {
          console.error(err)
          sm({ chat_id, text: fid + ' 统计失败：' + err.message })
        } finally {
          delete counting[fid]
        }
      } else if (text.startsWith('/copy')) {
        let target = text.replace('/copy', '').replace(' -u', '').trim().split(' ').map(v => v.trim()).filter(v => v)[1]
        target = get_target_by_alias(target) || target
        if (target && !validate_fid(target)) return sm({ chat_id, text: `目标ID ${target} 格式不正确` })
        const update = text.endsWith(' -u')
        tg_copy({ fid, target, chat_id, update }).then(task_id => {
          task_id && sm({ chat_id, text: `开始复制，任务ID: ${task_id} 可输入 /task ${task_id} 查询进度` })
        })
      } else if (text.startsWith('/task')) {
        let task_id = text.replace('/task', '').trim()
        if (task_id === 'all') {
          return send_all_tasks(chat_id)
        } else if (task_id === 'clear') {
          return clear_tasks(chat_id)
        } else if (task_id === '-h') {
          return send_task_help(chat_id)
        } else if (task_id.startsWith('rm')) {
          task_id = task_id.replace('rm', '')
          task_id = parseInt(task_id)
          if (!task_id) return send_task_help(chat_id)
          return rm_task({ task_id, chat_id })
        }
        task_id = parseInt(task_id)
        if (!task_id) {
          const running_tasks = db.prepare('select id from task where status=?').all('copying')
          if (!running_tasks.length) return sm({ chat_id, text: '当前暂无运行中的任务' })
          return running_tasks.forEach(v => send_task_info({ chat_id, task_id: v.id }).catch(console.error))
        }
        send_task_info({ task_id, chat_id }).catch(console.error)
      } else if (message_str.includes('drive.google.com/') || validate_fid(text)) {
        return send_choice({ fid: fid || text, chat_id })
      } 
});

// Inline button callback
bot.on('callbackQuery', msg => {
    // User message alert
    const id = msg.from.id;
    if(adminUsers.indexOf(id) < 0){
        msg.reply.text('您的用户名或ID不在机器人的白名单中，如果是您配置的机器人，请先到config.js中配置自己的username')
        return console.warn('收到非白名单用户的请求')
    }

    if (msg) {
    const { id, message, data } = msg
    const chat_id = msg.from.id
    //let [action, fid] = String(data).split(' ')
    const [action, fid, target] = data.split(' ').filter(v => v)
    //console.log("id:"+id);
    //console.log("chat_id:"+chat_id);
    //console.log("data:"+data);
    //console.log("action:"+action);console.log("fid:"+fid);
    if (action === 'count') {
      if (counting[fid]) return sm({ chat_id, text: fid + ' 正在统计，请稍等片刻' })
      counting[fid] = true
      send_count({ fid, chat_id }).catch(err => {
        console.error(err)
        sm({ chat_id, text: fid + ' 统计失败：' + err.message })
      }).finally(() => {
        delete counting[fid]
      })
    } else if (action === 'copy') {
      console.log("copy id:"+id);
      if (COPYING_FIDS[fid]) return sm({ chat_id, text: `正在处理 ${fid} 的复制命令` })
      COPYING_FIDS[fid] = true
      tg_copy({ fid, target: get_target_by_alias(target), chat_id }).then(task_id => {
        task_id && sm({ chat_id, text: `开始复制，任务ID: ${task_id} 可输入 /task ${task_id} 查询进度` })
      }).finally(() => COPYING_FIDS[fid] = false)
    } else if (action === 'update') {
      if (counting[fid]) return sm({ chat_id, text: fid + ' 正在统计，请稍等片刻' })
      counting[fid] = true
      send_count({ fid, chat_id, update: true }).finally(() => {
        delete counting[fid]
      })
    } else if (action === 'clear_button') {
      const { message_id, text } = message || {}
      if (message_id) clear_button({ message_id, text, chat_id })
    }
    return reply_cb_query({ id, data }).catch(console.error)
  }
    return bot.answerCallbackQuery(msg.id, `Inline button callback: ${ msg.data }`, true);
});

//bot.sendMessage(854331334,"you gdutils_bot ins online!") 

bot.on('/start', (msg) => {
  const id = msg.from.id;
  if(adminUsers.indexOf(id) < 0){
      msg.reply.text('您的用户名或ID不在机器人的白名单中，如果是您配置的机器人，请先到config.js中配置自己的username');
      return console.warn('收到非白名单用户的请求')
  }
  msg.reply.text(`your chat id:\n ${msg.from.id}`);
  return bot.sendMessage(msg.from.id, "You gdutils_bot ins online!!");
});

bot.on('/restart', (msg) => {
  const id = msg.from.id;
  if(adminUsers.indexOf(id) < 0){
      msg.reply.text('您的用户名或ID不在机器人的白名单中，如果是您配置的机器人，请先到config.js中配置自己的username');
      return console.warn('收到非白名单用户的请求')
  }
  console.log('run restart')
  msg.reply.text('run restart');
  const shell = spawn('pm2',['restart','all',]).on('error', function( err ){
      msg.reply.text(err);
  });
  if(shell){
     shell.stdout.on('data', (data) => {
      msg.reply.text(`stdout:\n ${data}`);
     });
  }
});

bot.on('/update', msg => {
  const id = msg.from.id;
  if(adminUsers.indexOf(id) < 0){
      msg.reply.text('您的用户名或ID不在机器人的白名单中，如果是您配置的机器人，请先到config.js中配置自己的username');
      return console.warn('收到非白名单用户的请求')
  }
  console.log('run update and restart')
  msg.reply.text('run update and restart');
  const shell = spawn('git',['pull',]).on('error', function( err ){
      msg.reply.text(err);
  });

  if(shell){
     shell.stdout.on('data', (data) => {
      msg.reply.text(`stdout:\n ${data}`);
     });
  }

});

bot.on(/^!.*/, (msg, props) => {
  // let prex = String(msg.text).substring(0,1);
  // console.log(prex);
  const id = msg.from.id;
  if(adminUsers.indexOf(id) < 0){
      msg.reply.text('您的用户名或ID不在机器人的白名单中，如果是您配置的机器人，请先到config.js中配置自己的username');
      return console.warn('收到非白名单用户的请求')
  }

  let words = String(msg.text).split(" ");
  let len = words.length;
  let args = [];
  if (len > 2 ){
      args = words.slice(2, len);

  }
    console.log('run shell2    ')
    msg.reply.text('$: '+words[1] + "  " + args);
    const shell = spawn(words[1],args).on('error', function( err ){
        msg.reply.text('error while executing:'+words[1]);
        msg.reply.text(err);
    });

    if(shell){

       shell.stdout.on('data', (data) => {
        msg.reply.text(`stdout:\n ${data}`);
       });

       shell.stderr.on('data', (data) => {
        msg.reply.text(`stderr: ${data}`);
       });

       shell.on('close', (code) => {
        msg.reply.text(`shell exited with code ${code}`);
       });
}

});

bot.start();