#!/bin/bash
echo
echo -e "\033[1;32m===== <<gdutils项目一键部署脚本之“TG机器人”>> =====\033[0m"
echo -e "\033[1;32m----------------[ v2.1 by oneking ]----------------\033[0m"
echo -e "\033[32m 01.\033[0m 本脚本是针对TG大神@viegg的gdutils项目“TG机器人”部分一键部署脚本;"
echo -e "\033[32m 02.\033[0m 准备工作一：部署完成gdutils项目TD查询转存部分;"
echo -e "\033[32m 03.\033[0m 准备工作二：在TG上注册好机器人取得并记录下该机器人TOKEN"
echo -e "\033[32m 04.\033[0m 准备工作三：拥有一个域名绑定到cloudflare解析到该机器人所在服务器IP"
echo -e "\033[32m 05.\033[0m 准备工作四：向机器人@userinfobot获取个人TG账号ID并记录"
echo -e "\033[32m 06.\033[0m 准备工作五：注册好一个Google team drive加入sa并记录下该盘ID"
echo -e "\033[32m 07.\033[0m 本脚本适应CentOS/Debian/Ubuntu三种操作系统，自动识别、自动匹配参数一键部署"
echo -e "\033[32m 08.\033[0m 由于本脚本涉及到依赖软件较多，避免中断建议使用screen窗口安装"
echo -e "\033[32m 09.\033[0m 经测试可用完美安装系统：Centos 7/8 debian 9/10 ubuntu 16.04/18.04/19.10/20.04"
echo -e "\033[32m 10.\033[0m 部署过程中有任何问题请把“错误截图”“部署VPS系统名称版本”信息发给TG：onekings 或 vitaminor@gmail.com"
echo -e "\033[1;32m------------------------------------------------\033[0m"
read -s -n1 -p "★★★ 如已做好以上[2/3/4/5/6]准备请按任意键开始部署，如未做好准备请按“Ctrl+c”终止部署 ★★★"
echo
echo -e "\033[1;32m------------------------------------------------\033[0m"

# 识别操作系统
aNAME="$(uname -a)"
bNAME="$(cat /proc/version)"
cNAME="$(lsb_release -a)"
if [ -f "/etc/redhat-release" ]; then
    if [[ $(cat /etc/redhat-release) =~ "CentOS" ]]; then
        os="CentOS"
    fi
elif [ "$aNAME"=~"Debian" -o "$bNAME"=~"Debian" -o "$cNAME"=~"Debian" ]; then
    os="Debian"
elif [ "$aNAME"=~"Ubuntu" -o "$bNAME"=~"Ubuntu" -o "$cNAME"=~"Ubuntu" ]; then
    os="Debian"
elif [ "$aNAME"=~"CentOS" -o "$bNAME"=~"CentOS" -o "$cNAME"=~"CentOS" ]; then
    os="CentOS"
elif [ "$aNAME"=~"Darwin" -o "$bNAME"=~"Darwin" -o "$cNAME"=~"Darwin" ]; then
    os="mac"
else
    os="$bNAME"
fi

#根据操作系统设置变量
if [[ "$os" = "Debian" ]]; then
    cmd_install="apt-get"                                     #安装命令
    nginx_conf="/etc/nginx/sites-enabled/"                    #nginx配置文件存放路径
    rm_nginx_default="rm -f /etc/nginx/sites-enabled/default" #删除default
    echo
    echo -e "\033[1;32m★★★★★ 您的操作系统为Debian，即将为你开始自动部署gdutils项目“TG机器人”部分 ★★★★★\033[0m"
elif [[ "$os" = "Ubuntu" ]]; then
    cmd_install="sudo apt-get"
    nginx_conf="/etc/nginx/sites-enabled/"
    rm_nginx_default="rm -f /etc/nginx/sites-enabled/default"
    echo
    echo -e "\033[1;32m★★★★★ 您的操作系统为Ubuntu，即将为你开始自动部署gdutils项目“TG机器人”部分 ★★★★★\033[0m"
elif [[ "$os" = "CentOS" ]]; then
    cmd_install="yum"
    nginx_conf="/etc/nginx/conf.d/"
    rm_nginx_default=""
    echo
    echo -e "\033[1;32m★★★★★ 您的操作系统为Centos，即将为你开始自动部署gdutils项目“TG机器人”部分 ★★★★★\033[0m"
elif [[ "$os" = "mac" ]]; then
    echo
    echo -e "\033[1;32m★★★★★ 您的操作系统为MacOS，请在图形界面手动部署 ★★★★★\033[0m"
    exit
    echo
    echo
else
    echo
    echo -e "\033[1;32m unknow os $OS, exit! \033[0m"
    exit
    echo
    echo
fi
echo -e "\033[1;32m----------------------------------------------------------\033[0m"

#输入“机器人token/TG账号ID/域名/转存目的盘ID”
read -p """请输入机器人token并回车
    Your Bot Token =>:""" YOUR_BOT_TOKEN
#判断token是否输入正确
while [[ "${#YOUR_BOT_TOKEN}" != 46 ]]; do
    echo -e "\033[1;32m★★★ 机器人TOKEN输入不正确，请重新输入或按“Ctrl+C”结束安装！ ★★★\033[0m"
    read -p """请输入机器人token并回车
    Your Bot Token =>:""" YOUR_BOT_TOKEN
done

read -p """请输入你的域名(在cloudflare上解析到你机器人所在VPS的域名，格式：bot.abc.com)并回车
    Your Domain Name =>:""" YOUR_DOMAIN_NAME
#判断域名是否正确
while [[ "$YOUR_DOMAIN_NAME" =~ "http" ]]; do
    echo -e "\033[1;32m★★★ “Your Domain Name”输入错误，应该输入你在cloudflare上解析的域名且不包含“http”，请重新输入或按“Ctrl+C”结束安装！ ★★★\033[0m"
    read -p """请输入你的域名(在cloudflare上解析到你机器人所在VPS的域名，格式：bot.abc.com)并回车
    Your Domain Name =>:""" YOUR_DOMAIN_NAME
done

read -p """请输入使用机器人的telegram账号ID(获取ID机器人@userinfobot)并回车
    Your Telegram ID =>:""" YOUR_TELEGRAM_ID
#判断telegram ID是否正确(通过判断是不是纯数字)
until [[ $YOUR_TELEGRAM_ID =~ ^-?[0-9]+$ ]]; do
    echo -e "\033[1;32m★★★ 您的TG账号ID输入不正确，请重新输入或按“Ctrl+C”结束安装！ ★★★\033[0m"
    read -p """请输入使用机器人的telegram账号ID(获取ID机器人@userinfobot)并回车
    Your Telegram ID =>:""" YOUR_TELEGRAM_ID
done

read -p """请输入转存默认目的地团队盘ID(不指定转存目的地默认改地址，脚本强制要求输入团队盘ID)并回车
    Your Google Team Drive ID =>:""" YOUR_GOOGLE_TEAM_DRIVE_ID
#判断google team drive ID是否正确（团队盘ID长度19位）
while [[ "${#YOUR_GOOGLE_TEAM_DRIVE_ID}" != 19 ]]; do
    echo -e "\033[1;32m★★★ 您的Google team drive ID输入不正确，请重新输入或按“Ctrl+C”结束安装！ ★★★\033[0m"
    read -p """请输入转存默认目的地ID(不指定转存目的地默认该地址，脚本强制要求输入团队盘ID)并回车
    Your Google Team Drive ID =>:""" YOUR_GOOGLE_TEAM_DRIVE_ID
done

cd ~ &&
    sed -i "s/bot_token/$YOUR_BOT_TOKEN/g" ./gd-utils/config.js &&
    sed -i "s/your_tg_username/$YOUR_TELEGRAM_ID/g" ./gd-utils/config.js && 
    sed -i "s/DEFAULT_TARGET = ''/DEFAULT_TARGET = '$YOUR_GOOGLE_TEAM_DRIVE_ID'/g" ./gd-utils/config.js
echo -e "\033[1;32m----------------------------------------------------------\033[0m"

echo -e "\033[1;32m“进程守护程序pm2”开始安装......\033[0m"
cd /root/gd-utils &&
    npm i pm2 -g && pm2 l
echo -e "\033[1;32m启动守护进程......\033[0m"
pm2 start server.js
echo -e "\033[1;32m----------------------------------------------------------\033[0m"

echo -e "\033[1;32m“nginx”开始安装......\033[0m"
cd ~ &&
    $cmd_install install nginx -y
echo
echo -e "\033[1;32m===== <<配置nginx服务>> ===== \033[0m"
echo
echo -e "\033[1;32m“nginx”起一个web服务......\033[0m"

cd $nginx_conf
echo "server {
    listen 80;
    server_name ecbot.nctu.me;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    ssl on;
    ssl_certificate    /etc/ssl/certificate-all.crt;
    ssl_certificate_key    /etc/ssl/private.key;
    server_name $YOUR_DOMAIN_NAME;
    location / {
         proxy_pass http://127.0.0.1:23333/;
    }
}" >${nginx_conf}gdutilsbot.conf &&
    $rm_nginx_default

ls &&
    nginx -t &&
    nginx -c /etc/nginx/nginx.conf &&
    nginx -s reload &&
    netstat -tulpen
echo -e "\033[1;32m----------------------------------------------------------\033[0m"

echo -e "\033[1;32m“检查网站是否部署成功”......\033[0m"
curl $YOUR_DOMAIN_NAME/api/gdurl/count\?fid=124pjM5LggSuwI1n40bcD5tQ13wS0M6wg
echo
echo -e "\033[1;32m设置Webhook服务......\033[0m"
print_webhook=$(curl -F "url=https://$YOUR_DOMAIN_NAME/api/gdurl/tgbot" "https://api.telegram.org/bot$YOUR_BOT_TOKEN/setWebhook")
echo

# 判断反向代理是否部署成功
if [[ $print_webhook =~ "true" ]]; then
    echo -e "\033[1;32m★★★ 恭喜你！GoogleDrive查询转存机器人部署成功，请回到TG界面给bot发送个“/help”获取使用帮助 ★★★\033[0m"
else
    echo -e "\033[32m★★★ 很遗憾！机器人设置失败，请返回检查网站是否部署成功，并重复本安装过程 ★★★\033[0m", exit!
fi
nginx -t && nginx -s reload
echo
echo

cd ~
rm -f gdutilsbotinstall.sh
