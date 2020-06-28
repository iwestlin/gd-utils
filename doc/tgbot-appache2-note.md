# 几个坑
* Telegram Bot API 提供了两种方式， webhook 和 long polling，目前项目只支持 webhook 方式。
* webhook 方式必须要用HTTPS 也就是需要准备**个人域名**和**一个有效证书**
* 证书一定要单独域名证书(泛域名证书不能用)



# 原理/思路
TG创建bot，要起一个服务支持BOT的功能， 所以需要配置webhook 让tg 和服务器建立连接。webhook 需要有HTTPS的外网域名并且修改DNS指向你所配置的服务器IP，这样就能保证TG的请求可以顺利到达并且验证BOT。
在服务器内部如果如果是单BOT， 可以直接用nodje 配合 PM2 直接起服务,然后修改server.js端口号443。 如果服务器上有多个服务，那么就需要用反向代理，反代简单说就是一个服务+映射规则 (ngnix或者apache后者其他都可以) 侦听80或者443端口，如果有指定的映射请求， 就转发到内部映射的各个服务。 

例如 
```
aaa.domain.com <=> locahost:3001
bbb.domain.com <=> locahost:3002
domain.com/ccc <=> localhost:3003
```



# 步骤
1. 需要去tg 创建一个bot，会得到token 和bot的tgurl
2. BOT服务：
   1. 服务器上clone 项目，安装node, npm install
   2. 如果需要配置多个BOT, clone不同目录, server.js里修改配置port，和config.js
   3. 安装PM2，在每个bot目录下 PM2 start server.js
   4. ``` pm2 status``` 确认服务跑起来了
      1. 如果没起来， 查log文件（见底部）
   5. curl 检查本地连接, curl 检查远端连接， not found 就对了 
3. 外部连接 
   1. 修改DNS，我是用cloudflare 把添加A record， 直接把静态IP 绑定
   2. 绑定以后， 本地开个terminal, ping 刚添加域名，直到解析的IP是你绑定的，这步确保连接上是畅通的
4. apache2开启SSL和反代
   1. 复制证书到任意位置
   2. 运行底部命令
   3. /etc/apache2/sites-available 下找到默认的.conf，或者自己建个conf也行
   4. 修改底部配置信息
   5. 保存重启 ```service apache2 restart```
5. 剩下的就是配置和检查webhook，这里面也有不少坑，在反代配置文件部分。。记不清了。。
6. 如果一切顺利 /help 会弹出目录







 ```
 pm2 部分

 tail -200 ~/.pm2/logs/server-error.log
 tail -200 ~/.pm2/logs/server-out.log
 
 curl "localhost:23333"
 curl "domain:23333"

SSL+反代

sudo a2enmod ssl
sudo a2enmod proxy
sudo a2enmod proxy_balancer
sudo a2enmod proxy_http


/etc/apache2/sites-available/xxx.conf

<VirtualHost *:443>
    SSLEngine on
    SSLProtocol all
    SSLCertificateFile {{CERT_DIR}}/{{domain.cer}}
    SSLCertificateKeyFile {{CERT_DIR}}/{{domain.key}}
    SSLCACertificateFile {{CERT_DIR}}/{{domain.ca.cer}}
    
    ServerName {{domain}}
    
    ProxyRequests Off
    ProxyPreserveHost On
    ProxyVia Full

    <Proxy *>
        Require all granted
    </Proxy>
    # 这里我用的是子目录映射方式。懒得再申请一个证书。。domain.com/ccc <=> localhost:3003
    ProxyPass /{{bot1url}}/ http://127.0.0.1:23334/  # bot1
    ProxyPassReverse /{{bot1url}}/ http://127.0.0.1:23334/ # bot1
    ProxyPass /{{bot2url}}/ http://127.0.0.1:23333/ # bot2
    ProxyPassReverse /{{bot2url}}/ http://127.0.0.1:23333/ # bot2
</VirtualHost>


something for verify and DEBUG

Apache command:
service apache2 restart
service apache2 stop
service apache2 status
service apache2 reload
tail -100 /var/log/apache2/error.log


验证一下SSL:
https://www.ssllabs.com/ssltest/analyze.html 确保Trusted和In trust store是绿的（反正我这两个绿的就TG就能找到的到）

SET webhook

curl -F "url=https://{{domain}}/{{bot1url}}/api/gdurl/tgbot" 'https://api.telegram.org/bot{{BOT_TOKEN}}/setWebhook'

delete webhook
curl -F "url=" https://api.telegram.org/bot{{BOT_TOKEN}}/setWebhook


check webhook
curl "https://api.telegram.org/bot{{BOT_TOKEN}}/getWebhookInfo"



 ```


![avatar](/doc/bot-worked.png)


# Reference Link

https://core.telegram.org/bots

https://core.telegram.org/bots/api

https://www.jianshu.com/p/ca804497afa0
