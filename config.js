// 单次请求多少毫秒未响应以后超时（基准值，若连续超时则下次调整为上次的2倍）
const TIMEOUT_BASE = 7000
// 最大超时设置，比如某次请求，第一次7s超时，第二次14s，第三次28s，第四次56s，第五次不是112s而是60s，后续同理
const TIMEOUT_MAX = 60000

const LOG_DELAY = 5000 // 日志输出时间间隔，单位毫秒
const PAGE_SIZE = 1000 // 每次网络请求读取目录下的文件数，数值越大，越有可能超时，不得超过1000

const RETRY_LIMIT = 7 // 如果某次请求失败，允许其重试的最大次数
const PARALLEL_LIMIT = 20 // 网络请求的并行数量，可根据网络环境调整

const DEFAULT_TARGET = '' // 必填，拷贝默认目的地ID，如果不指定target，则会复制到此处，建议填写团队盘ID

const AUTH = { // 如果您拥有service account的json授权文件，可将其拷贝至 sa 目录中以代替 client_id/secret/refrest_token
  client_id: 'your_client_id',
  client_secret: 'your_client_secret',
  refresh_token: 'your_refrest_token',
  expires: 0, // 可以留空
  access_token: '', // 可以留空
  tg_token: 'bot_token', // 你的 telegram robot 的 token，获取方法参见 https://core.telegram.org/bots#6-botfather
  tg_whitelist: ['your_tg_username'] // 你的tg username(t.me/username)，bot只会执行这个列表里的用户所发送的指令
}

//-------------------MOD-------------------
const SA_PATH = '../sa' //sa路徑配置, 給定絕對路徑或是以src為當前路徑給定相對路徑
const COPY_TARGET2 = ''
const COPY_TARGET3 = ''

module.exports = { AUTH, PARALLEL_LIMIT, RETRY_LIMIT, TIMEOUT_BASE, TIMEOUT_MAX, LOG_DELAY, PAGE_SIZE, DEFAULT_TARGET, SA_PATH, COPY_TARGET2, COPY_TARGET3 }
