#!/usr/bin/env node

const fs = require('fs')
const {get_name_by_id, get_sa_token, get_access_token, walk_and_save, validate_fid} = require('./src/gd')

const ID_DIR_MAPPING = {}
const FOLDER_TYPE = 'application/vnd.google-apps.folder'

const { argv } = require('yargs')
  .usage('用法: ./$0 <folder-id> [options]')
  .alias('o', 'output')
  .describe('output', '指定输出文件，不填默认为uri.txt')
  .alias('u', 'update')
  .describe('u', '不使用本地缓存，强制从线上获取源文件夹信息')
  .alias('S', 'service_account')
  .describe('S', '使用service account进行操作，前提是必须在 ./sa 目录下放置sa授权json文件')
  .help('h')
  .alias('h', 'help')

const [fid] = argv._
if (validate_fid(fid)) {
  let { update, service_account, output } = argv
  output = output || 'uri.txt'
  gen_input_file({ fid, update, service_account, output }).then(() => console.log('已生成', output)).catch(console.error)
} else {
  console.warn('目录ID缺失或格式错误')
}

async function gen_input_file ({fid, service_account, update, output}) {
  const root = await get_name_by_id(fid, service_account)
  const data = await walk_and_save({fid, service_account, update})
  const files = data.filter(v => v.mimeType !== FOLDER_TYPE)
  const folders = data.filter(v => v.mimeType === FOLDER_TYPE)
  const access_token = service_account ? (await get_sa_token()).access_token : await get_access_token()
  let result = [`# aria2c -c -s10 -k1M --enable-rpc=false --header "Authorization: Bearer ${access_token}" -i ${output}`]
  result = result.concat(files.map(v => {
    const {id, name, parent} = v
    const dir = get_dir(parent, folders)
    return `https://www.googleapis.com/drive/v3/files/${id}?alt=media
  dir=${root}${dir}
  out=${name}`
  }))
  fs.writeFileSync(output, result.join('\n'))
}

function get_dir (id, folders) {
  let result = ID_DIR_MAPPING[id]
  if (result !== undefined) return result
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
  return ID_DIR_MAPPING[id] = result || ''
}
