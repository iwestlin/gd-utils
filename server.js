const dayjs = require('dayjs')
const Koa = require('koa')
const bodyParser = require('koa-bodyparser')

const router = require('./src/router')

const app = new Koa()
app.proxy = true

app.use(catcher)
app.use(bodyParser())
app.use(router.routes())
app.use(router.allowedMethods())

app.use(ctx => {
  ctx.status = 404
  ctx.body = 'not found'
})

const PORT = 23333
app.listen(PORT, '127.0.0.1', console.log('http://127.0.0.1:' + PORT))

async function catcher (ctx, next) {
  try {
    return await next()
  } catch (e) {
    console.error(e)
    ctx.status = 500
    ctx.body = e.message
  }
}
