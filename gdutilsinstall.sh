#!/bin/bash
echo
echo -e "\033[1;32m===== <<gdutils项目一件部署脚本要求及说明>> =====\033[0m"
echo -e "\033[1;32m---------------[ v2.1 by oneking ]---------------\033[0m"
echo -e "\033[32m 1.\033[0m 本脚本是针对TG大神@viegg的gdutils项目一键部署脚本;"
echo -e "\033[32m 2.\033[0m 脚本包括“TD盘VPS上查询转存部署”和“Telegram机器人部署”两部分"
echo -e "\033[32m 3.\033[0m 本脚本适应CentOS/Debian/Ubuntu三种操作系统，自动识别、自动选择对应分支一键安装部署"
echo -e "\033[32m 4.\033[0m 三步即可完成部署：上传脚本到VPS → 设置脚本执行权限 → 运行"
echo -e "\033[32m 5.\033[0m 在TG上注册好机器人并取得并记录下该机器人TOKEN"
echo -e "\033[32m 6.\033[0m 拥有一个域名绑定到cloudflare解析到该机器人所在服务器IP"
echo -e "\033[32m 7.\033[0m 经测试可用完美安装系统：Centos 7/8 debian 9/10 ubuntu 16.04/18.04/19.10/20.04"
echo -e "\033[32m 8.\033[0m 部署过程中有任何问题请把“错误截图”“部署VPS系统名称版本”信息发给TG：onekings 或 vitaminor@gmail.com"
echo -e "\033[1;32m------------------------------------------------\033[0m"
read -s -n1 -p "★★★ 如已做好以上[5/6]准备或不需要安装Telegram机器人请按任意键开始部署，如未做好准备请按“Ctrl+c”终止脚本 ★★★"
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

# 需要安装的软件工具及依赖
insofts=(epel-release update upgrade wget curl git unzip zip python3-distutils python3 python3-pip)

#根据操作系统设置变量
if [[ "$os" = "Debian" ]]; then
    cmd_install="apt-get"                                     #安装命令
    cmd_install_rely="build-essential"                        #c++编译环境
    nodejs_curl="https://deb.nodesource.com/setup_10.x"       #nodejs下载链接
    cmd_install_rpm_build=""                                  #安装rpm-build
    nginx_conf="/etc/nginx/sites-enabled/"                    #nginx配置文件存放路径
    rm_nginx_default="rm -f /etc/nginx/sites-enabled/default" #删除default
    echo
    echo -e "\033[1;32m★★★★★ 您的操作系统为Debian，即将为你开始部署gdutils项目 ★★★★★\033[0m"
elif [[ "$os" = "Ubuntu" ]]; then
    cmd_install="sudo apt-get"
    cmd_install_rely="build-essential"
    nodejs_curl="https://deb.nodesource.com/setup_10.x"
    cmd_install_rpm_build=""
    nginx_conf="/etc/nginx/sites-enabled/"
    rm_nginx_default="rm -f /etc/nginx/sites-enabled/default"
    echo
    echo -e "\033[1;32m★★★★★ 您的操作系统为Ubuntu，即将为你开始部署gdutils项目 ★★★★★\033[0m"
elif [[ "$os" = "CentOS" ]]; then
    cmd_install="yum"
    cmd_install_rely="gcc-c++ make"
    nodejs_curl="https://rpm.nodesource.com/setup_10.x"
    cmd_install_rpm_build="yum install rpm-build -y"
    nginx_conf="/etc/nginx/conf.d/"
    rm_nginx_default=""
    echo
    echo -e "\033[1;32m★★★★★ 您的操作系统为Centos，即将为你开始部署gdutils项目 ★★★★★\033[0m"
elif [[ "$os" = "mac" ]]; then
    echo
    echo -e "\033[1;32m★★★★★ 您的操作系统为MacOS，请在图形界面手动安装 ★★★★★\033[0m"
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

echo
echo -e "\033[1;32m===== <<升级系统/更新软件/安装工具/安装依赖>> =====\033[0m"
echo

#安装which和sudo
if [[ "$(which which)" == "" ]]; then
    echo -e "\033[1;32m“which”开始安装......\033[0m"
    $cmd_install install which -y
    echo -e "\033[1;32m------------------------------------------------\033[0m"
elif [[ "$(which sudo)" == "" ]]; then
    echo -e "\033[1;32m“sudo”开始安装......\033[0m"
    $cmd_install install sudo -y
    echo -e "\033[1;32m------------------------------------------------\033[0m"
fi

#安装工具和依赖
for ((aloop = 0; aloop < ${#insofts[@]}; aloop++)); do
    if [ ${insofts[$aloop]} = "update" -o ${insofts[$aloop]} = "upgrade" ]; then
        echo -e "\033[1;32m“${insofts[$aloop]}”开始安装......\033[0m"
        $cmd_install ${insofts[$aloop]} -y
        echo -e "\033[1;32m------------------------------------------------\033[0m"
    else
        echo -e "\033[1;32m“${insofts[$aloop]}”开始安装......\033[0m"
        $cmd_install install ${insofts[$aloop]} -y
        echo -e "\033[1;32m------------------------------------------------\033[0m"
    fi
done

echo
echo -e "\033[1;32m===== <<安装gdutils依赖-nodejs和npm/安装配置gdutils>> =====\033[0m"
echo
$cmd_install install $cmd_install_rely -y
curl -sL $nodejs_curl | bash -
$cmd_install install nodejs -y
$cmd_install_rpm_build
git clone https://github.com/iwestlin/gd-utils && cd gd-utils
npm config set unsafe-perm=true
npm i

echo
echo -e "\033[1;32m★★★ 恭喜您!gdutils统计转存系统已经正确安装完成，请上传sa到“./gd-utils/sa/”目录下完成最后的配置 ★★★\033[0m"
echo

#################################################################################################

echo -e "\033[1;32m----------------------------------------------------------\033[0m"
read -s -n1 -p "★★★ 下面将部署Telegram机器人，请确保准备所需条件已准备好，按任意键开始部署机器人；如未做好准备请按“Ctrl+c”终止部署机器人 ★★★"
echo
echo -e "\033[1;32m----------------------------------------------------------\033[0m"

echo
echo -e "\033[1;32m  ===== <<开始部署gdutils查询转存TG机器人>> =====  \033[0m"
echo

#输入“机器人token/telegram账号名/域名”
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

read -p """请输入使用机器人的telegram账号名(“@”后面部分)并回车
    Your Telegram Name =>:""" YOUR_TELEGRAM_NAME

cd ~ &&
    sed -i "s/bot_token/$YOUR_BOT_TOKEN/g" ./gd-utils/config.js
sed -i "s/your_tg_username/$YOUR_TELEGRAM_NAME/g" ./gd-utils/config.js
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
rm -f gdutilsinstall.sh

###########################gdutils功能建议##################################
# 本部分是对gdutils项目的建议，因为我主要用的是查询功能所以以下建议只涉及查询功能
# 1-把以下参数放入配置文件设置：sa存放路径
# 2-改sa“随机”使用为“顺序”分组使用；
# 3-增加输出模式，可以用命令行后带参数选择，具体模式建议：
#   ①按一级或者二级文件夹显示数量大小
#   ②可以一次性统计多个磁盘并且输出单个磁盘文件数和大小以及几个磁盘总和
#   ③获取id对应的文件夹名或者磁盘明保存数据库，给个命令能够查询历史记录汇总或者指定汇总
# 4-查询过程中输出方式不要每次都输出一次，可以固定+数字变化
# 5-命令参数可加在ID前或后，如果非要固定一种的话就加在ID之前
# 6-命令行也改为默认sa模式
############################################################################
