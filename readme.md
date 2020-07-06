# gd-utils-cht

> 不只是最快的 google drive 拷貝工具 [與其他工具的對比](./compare.md)

> 我的readme可能不夠完全, 主要寫上我更新、修改的內容, 具體說明還是看[這邊](https://github.com/iwestlin/gd-utils)和[這邊](https://github.com/vitaminx/gd-utils)吧
## 更新紀錄
### 2020.07.07
  - 整體繁體化, 介面部分
  - 新增用戶可以在config.js自訂按鈕顯示的個數(每列), 可設定為1或2
### 2020.07.06以前
  - 部分繁體中文化
  - 執行/task命令時, 會回傳完成度百分比
  - 複製完成時, 跳出的通知會顯示文件大小
## tg_bot 修改部分
- 執行/task命令時, 會回傳完成度百分比
  
  ![](./pic/example2.png)
- 複製完成時, 跳出的通知會顯示文件大小

  ![](./pic/example3.png)
> 這邊說一下我用的服務及配置(免費配置): always-free gcp Compute Engine + zerossl + 免費的domain hosting 
>注意我的配置沒有用到cloudflare
## 一鍵安裝腳本(感謝 腳本製作者 [@vitaminx](https://github.com/vitaminx))
- 這邊的安裝腳本我有稍作修改 與fork過來的原版不一樣
  - 不使用cloudflare解析
  - ssl另外配置在nginx服務當中(後面會說明證書放置路徑)
- 具體安裝條件、限制請去參考[腳本原作者的專案](https://github.com/vitaminx/gd-utils)
- 這邊放了貼上就能用的命令
  - gdutils項目一鍵部署腳本（包括“查詢轉存”和“TG機器人”兩部分）
  ```    
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/liaojack8/gd-utils-cht/master/gdutilsinstall.sh)"
  ```    
  - gdutils項目一鍵部署腳本之“轉存查詢部分”    
  ```    
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/liaojack8/gd-utils-cht/master/gdutilscsinstall.sh)"
  ```    
  - gdutils項目一鍵部署腳本之“TG機器人部分”    
  ```    
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/liaojack8/gd-utils-cht/master/gdutilsbotinstall.sh)"
  ```  
- 安裝過程中需要輸入一下四個參數：    
  - 機器人TOKEN：這個在Telegram裡面找“@BotFather”註冊即可獲得    
  - Telegram用戶ID：在Telegram裡面向機器人@userinfobot发送消息即可獲得
  - Google team drive ID：即為你轉存文件的預設地址，腳本強制要求寫Google小組雲端硬碟ID     
  - 域名：你在cloudflare上解析到VPS的域名（格式：abc.34513.com）    
  - 腳本安裝問題請信息發給TG：onekings 或 vitaminor@gmail.com    
  - 系統使用問題（如無法轉存、重啟連不上機器人等等）請聯系項目作者@vegg
- 測試可用完美安裝系統：    
  - Centos 7/8    
  - debian 9/10
  - ubuntu 16.04/18.04/19.10/20.04

## 搭建步驟
1. 啟用一台主機, VPS、私人伺服器都行(私人伺服器如果沒有設定硬撥, 必須去路由器設定端口對應)
2. 確認固定ip, 或是用ddns服務 都行
3. 使用domain hosting服務解析到動態域名, 或新增A record指定到固定ip
4. 用domain hosting設定好的固定域名, 去申請ssl證書
5. 將證書放到對應路徑 /etc/ssl/certificate.crt 和 /etc/ssl/private.key
6. 設定完成後, 確認主機的端口開放
7. 執行安裝腳本, 就會自動以nginx起動服務, 特別設定了http轉https的跳轉

## 功能簡介
本工具目前支持以下功能：
- 統計任意（您擁有相關權限的，下同，不再贅述）目錄的文件信息，且支持以各種形式（html, table, json）導出。  
支持中斷恢覆，且統計過的目錄（包括其所有子孫目錄）信息會記錄在本地數據庫文件中（gdurl.sqlite）
請在本項目目錄下命令行輸入 `./count -h` 查看使用幫助

- 拷貝任意目錄所有文件到您指定目錄，同樣支持中斷恢覆。
支持根據文件大小過濾，可輸入 `./copy -h` 查看使用幫助

- 對任意目錄進行去重，刪除同一目錄下的md5值相同的文件（只保留一個），刪除空目錄。
命令行輸入 `./dedupe -h` 查看使用幫助

- 在 config.js 里完成相關配置後，可以將本項目部署在（可正常訪問Google服務的）服務器上，提供 http api 文件統計接口

- 支持 telegram bot，配置完成後，上述功能均可通過 bot 進行操作

## 環境配置
本工具需要安裝nodejs，客戶端安裝請訪問[https://nodejs.org/zh-cn/download/](https://nodejs.org/zh-cn/download/)，服務器安裝可參考[https://github.com/nodesource/distributions/blob/master/README.md#debinstall](https://github.com/nodesource/distributions/blob/master/README.md#debinstall)

建議選擇v12版本的node，以防接下來安裝依賴出錯。

如果你的網絡環境無法正常訪問Google服務，需要先在命令行進行一些配置：（如果可以正常訪問則跳過此節）
```
http_proxy="YOUR_PROXY_URL" && https_proxy=$http_proxy && HTTP_PROXY=$http_proxy && HTTPS_PROXY=$http_proxy
```
請把`YOUR_PROXY_URL`替換成你自己的代理地址

## 依賴安裝
- 命令行執行`git clone https://github.com/iwestlin/gd-utils && cd gd-utils` 克隆並切換到本項目文件夾下
- **執行 `npm install --unsafe-perm=true --allow-root` 安裝依賴**，部分依賴可能需要代理環境才能下載，所以需要上一步的配置

如果在安裝過程中发生報錯，請切換nodejs版本到v12再試。如果報錯信息里有`Error: not found: make`之類的消息，說明你的命令行環境缺少make命令，可參考[這里](https://askubuntu.com/questions/192645/make-command-not-found)或直接google搜索`Make Command Not Found`

如果報錯信息里有 `better-sqlite3`，先執行 `npm config set unsafe-perm=true`
然後 `rm -rf node_module` 刪掉依賴目錄，最後再執行下`npm i`安裝試試。

依賴安裝完成後，項目文件夾下會多出個`node_modules`目錄，請不要刪除它，接下來進行下一步配置。

## Service Account 配置
強烈建議使用service account（後稱SA）, 獲取方法請參見 [https://gsuitems.com/index.php/archives/13/](https://gsuitems.com/index.php/archives/13/#%E6%AD%A5%E9%AA%A42%E7%94%9F%E6%88%90serviceaccounts)
獲取到 SA 的 json 文件後，請將其拷貝到 `sa` 目錄下

配置好 SA 以後，如果你不需要對個人盤下的文件進行操作，可跳過[個人帳號配置]這節，而且執行命令的時候，記得帶上 `-S` 參數告訴程序使用SA授權進行操作。

## 個人帳號配置
- 命令行執行 `rclone config file` 找到 rclone 的配置文件路徑
- 打開這個配置文件 `rclone.conf`, 找到 `client_id`, `client_secret` 和 `refresh_token` 這三個變量，將其分別填入本項目下的 `config.js` 中，需要注意這三個值必須被成對的英文引號包裹，且引號後以英文逗號結尾，也就是需要符合JavaScript的[對象語法](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Operators/Object_initializer)

如果你沒有配置過rclone，可以搜索`rclone google drive 教程`完成相關配置。  

如果你的`rclone.conf`里沒有`client_id`和`client_secret`，說明你配置rclone的時候默認用了rclone自己的client_id，連rclone自己[都不建議這樣做](https://github.com/rclone/rclone/blob/8d55367a6a2f47a1be7e360a872bd7e56f4353df/docs/content/drive.md#making-your-own-client_id)，因為大家共享了它的接口調用限額，在使用高峰期可能會觸发限制。

獲取自己的clinet_id可以參見這兩篇文章：[Cloudbox/wiki/Google-Drive-API-Client-ID-and-Client-Secret](https://github.com/Cloudbox/Cloudbox/wiki/Google-Drive-API-Client-ID-and-Client-Secret) 和 [https://p3terx.com/archives/goindex-google-drive-directory-index.html#toc_2](https://p3terx.com/archives/goindex-google-drive-directory-index.html#toc_2)

獲取到client_id和client_secret後，再次執行一遍`rclone config`，創建一個新的remote，**在配置過程中一定要填入你新獲取的clinet_id和client_secret**，就能在`rclone.conf`里看到新獲取的`refresh_token`了。**注意，不能使用之前的refrest_token**，因為它對應的是rclone自帶的client_id

參數配置好以後，在命令行執行 `node check.js`，如果命令返回了你的Google雲端硬碟根目錄的數據，說明配置成功，可以開始使用本工具了。

## Bot配置
如果要使用 telegram bot 功能，需要進一步配置。

首先在 [https://core.telegram.org/bots#6-botfather](https://core.telegram.org/bots#6-botfather) 根據指示拿到 bot 的 token，然後填入 config.js 中的 `tg_token` 變量。

然後獲取自己的 telegram username，這個username不是顯示的名稱，而是tg個人網址後面的那串字符，比如，我的tg個人網址是 `https://t.me/viegg` ，用戶名就是 `viegg`，獲取用戶名的目的是在代碼里配置白名單，只允許特定的用戶調用機器人。將username填入 `config.js`里的配置，像這樣：
`tg_whitelist: ['viegg']`，就代表只允許我自己使用這個機器人了。

如果想把機器人的使用權限分享給別的用戶，只需要改成這樣子： `tg_whitelist: ['viegg', '其他人的username']`

## 補充說明
在`config.js`文件里，還有另外的幾個參數：
```
// 單次請求多少毫秒未響應以後超時（基準值，若連續超時則下次調整為上次的2倍）
const TIMEOUT_BASE = 7000

// 最大超時設置，比如某次請求，第一次7s超時，第二次14s，第三次28s，第四次56s，第五次不是112s而是60s，後續同理
const TIMEOUT_MAX = 60000

const LOG_DELAY = 5000 // 日志輸出時間間隔，單位毫秒
const PAGE_SIZE = 1000 // 每次網絡請求讀取目錄下的文件數，數值越大，越有可能超時，不得超過1000

const RETRY_LIMIT = 7 // 如果某次請求失敗，允許其重試的最大次數
const PARALLEL_LIMIT = 20 // 網絡請求的並行數量，可根據網絡環境調整

const DEFAULT_TARGET = '' // 必填，拷貝默認目的地ID，如果不指定target，則會拷貝到此處，建議填寫團隊盤ID，注意要用英文引號包裹
```
讀者可根據各自情況進行調整

## 注意事項
程序的原理是調用了[google drive官方接口](https://developers.google.com/drive/api/v3/reference/files/list)，遞歸獲取目標文件夾下所有文件及其子文件夾信息，粗略來講，某個目錄下包含多少個文件夾，就至少需要這麽多次請求才能統計完成。

目前尚不知道google是否會對接口做頻率限制，也不知道會不會影響google賬號本身的安全。

**請勿濫用，後果自負**
