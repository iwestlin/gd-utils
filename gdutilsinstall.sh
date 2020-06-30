#!/bin/bash
echo
echo -e "\033[1;32m===== <<gdutils项目一件部署脚本要求及说明>> =====\033[0m"
echo -e "\033[1;32m---------------[ v1.0 by oneking ]---------------\033[0m"
echo -e "\033[32m 1.\033[0m 本脚本是针对TG大神@viegg的gdutils项目一键部署脚本;"
echo -e "\033[32m 2.\033[0m 脚本包括“TD盘VPS上查询转存部署”和“Telegram机器人部署”两部分"
echo -e "\033[32m 3.\033[0m 本脚本适应CentOS/Debian/Ubuntu三种操作系统，自动识别、自动选择对应分支一键安装部署"
echo -e "\033[32m 4.\033[0m 三步即可完成部署：上传脚本到VPS → 设置脚本执行权限 → 运行"
echo -e "\033[32m 5.\033[0m 在TG上注册好机器人并取得并记录下该机器人TOKEN"
echo -e "\033[32m 6.\033[0m 拥有一个域名绑定到cloudflare解析到该机器人所在服务器IP"
echo -e "\033[1;32m------------------------------------------------\033[0m"
read -s -n1 -p "★★★ 如已做好以上准备或不需要安装Telegram机器人请按任意键继续，如未做好准备请按“Ctrl+c”终止脚本 ★★★"
echo
echo -e "\033[1;32m------------------------------------------------\033[0m"

# 识别操作系统
aNAME=`uname -a`
if [ -f "/etc/redhat-release" ];then
	if [[ `cat /etc/redhat-release` =~ "CentOS" ]];then
		os="CentOS"
	fi
elif [[ $aNAME =~ "Debian" ]];then
    os="Debian"
elif [[ $aNAME =~ "CentOS" ]];then
    os="CentOS"
elif [[ $aNAME =~ "Ubuntu" ]];then
    os="Ubuntu"
elif [[ $aNAME =~ "Darwin" ]];then
    os="mac"
else
    os=$aNAME
fi

# insofts为软件数组,里面的元数为你需要安装的软件
insofts=(epel-release update upgrade wget curl git unzip zip sudo python3-distutils python3 python3-pip)

# 具体业务逻辑
os_debian(){
    echo
    echo -e "\033[1;32m===== <<升级系统/更新软件/安装工具/安装依赖>> =====\033[0m"
    echo
    for(( aloop=0;aloop<${#insofts[@]};aloop++ )) do
        if [ ${insofts[$aloop]} = "update" -o ${insofts[$aloop]} = "upgrade" ];then
            echo -e "\033[1;32m“${insofts[$aloop]}”开始安装......\033[0m"
            sudo apt-get ${insofts[$aloop]} -y
            echo -e "\033[1;32m------------------------------------------------\033[0m"
        else
            echo -e "\033[1;32m“${insofts[$aloop]}”开始安装......\033[0m"
            sudo apt-get install ${insofts[$aloop]} -y
            echo -e "\033[1;32m------------------------------------------------\033[0m"
        fi
    done

    echo
    echo -e "\033[1;32m===== <<安装gdutils依赖-nodejs和npm/安装配置gdutils>> =====\033[0m"
    echo
    sudo apt-get install build-essential -y
    curl -sL https://deb.nodesource.com/setup_10.x | bash -
    sudo apt-get install -y nodejs
    git clone https://github.com/iwestlin/gd-utils && cd gd-utils
    npm config set unsafe-perm=true
    npm i

    echo
    echo -e "\033[1;32m★★★ 恭喜您!gdutils统计转存系统已经正确安装完成，请上传sa到“./gd-utils/sa/”目录下完成最后的部署 ★★★\033[0m"
    echo

    #################################################################################################

    echo -e "\033[1;32m----------------------------------------------------------\033[0m"
    read -s -n1 -p "★★★ 下面将部署Telegram机器人，请确保准备所需条件已准备好，请按任意键继续；如未做好准备请按“Ctrl+c”终止部署机器人 ★★★"
    echo
    echo -e "\033[1;32m----------------------------------------------------------\033[0m"

    echo
    echo -e "\033[1;32m  ===== <<开始部署gdutils查询转存TG机器人>> =====  \033[0m"
    echo
    read -p """请输入机器人token并回车
        Your Bot Token =>:""" YOUR_BOT_TOKEN
    read -p """请输入使用机器人的telegram账号名(“@”后面部分)并回车
        Your Telegram Name =>:""" YOUR_TELEGRAM_NAME
    read -p """请为WEB服务设置一个名称(填写你的域名格式:***.***.com)并回车
        Your Bot Server Name =>:""" YOUR_BOT_SERVER_NAME
    read -p """请输入在cloudflare上设置的网址(填写你的完整域名网址以“https”开头)并回车
        Your Website =>:""" YOUR_WEBSITE
    echo

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
    sudo apt-get install nginx -y
    echo   
    echo -e "\033[1;32m===== <<配置nginx服务>> ===== \033[0m"
    echo
    echo -e "\033[1;32m“nginx”起一个web服务......\033[0m"
    cd /etc/nginx/sites-enabled/
    echo "server {
    listen 80;
    server_name $YOUR_BOT_SERVER_NAME;
    location / {
        proxy_pass http://127.0.0.1:23333/;
    }
    }" > /etc/nginx/sites-enabled/gdutilsbot && 
    rm -f /etc/nginx/sites-enabled/default
    ls && 
    nginx -t &&  
    nginx -c /etc/nginx/nginx.conf && 
    nginx -s reload && 
    netstat -tulpen
    echo -e "\033[1;32m----------------------------------------------------------\033[0m"

    echo -e "\033[1;32m“检查网站是否部署成功”......\033[0m"
    curl $YOUR_WEBSITE/api/gdurl/count\?fid=124pjM5LggSuwI1n40bcD5tQ13wS0M6wg
    echo
    echo -e "\033[1;32m设置Webhook服务......\033[0m"
    print_webhook=`curl -F "url=$YOUR_WEBSITE/api/gdurl/tgbot" "https://api.telegram.org/bot$YOUR_BOT_TOKEN/setWebhook"`
    echo

    # 判断反向代理是否部署成功
    if [[ $print_webhook =~ "true" ]];then
        echo -e "\033[1;32m★★★ 恭喜你！GoogleDrive查询转存机器人部署成功，请回到TG界面给bot发送个“/help”获取使用帮助 ★★★\033[0m"
    else
        echo -e "\033[32m★★★ 很遗憾！机器人设置失败，请返回检查网站是否部署成功，并重复本安装过程 ★★★\033[0m", exit!
    fi

    cd ~
    rm -f gdutils.sh

}

os_ubuntu(){
    echo
    echo -e "\033[1;32m===== <<升级系统/更新软件/安装工具/安装依赖>> =====\033[0m"
    echo
    for(( aloop=0;aloop<${#insofts[@]};aloop++ )) do
        if [ ${insofts[$aloop]} = "update" -o ${insofts[$aloop]} = "upgrade" ];then
            echo -e "\033[1;32m“${insofts[$aloop]}”开始安装......\033[0m"
            sudo apt-get ${insofts[$aloop]} -y
            echo -e "\033[1;32m------------------------------------------------\033[0m"
        else
            echo -e "\033[1;32m“${insofts[$aloop]}”开始安装......\033[0m"
            sudo apt-get install ${insofts[$aloop]} -y
            echo -e "\033[1;32m------------------------------------------------\033[0m"
        fi
    done

    echo
    echo -e "\033[1;32m===== <<安装gdutils依赖-nodejs和npm/安装配置gdutils>> =====\033[0m"
    echo
    sudo apt-get install build-essential -y
    curl -sL https://deb.nodesource.com/setup_10.x | bash -
    sudo apt-get install -y nodejs
    git clone https://github.com/iwestlin/gd-utils && cd gd-utils
    npm config set unsafe-perm=true
    npm i

    echo
    echo -e "\033[1;32m★★★ 恭喜您!gdutils统计转存系统已经正确安装完成，请上传sa到“./gd-utils/sa/”目录下完成最后的部署 ★★★\033[0m"
    echo

    #################################################################################################

    echo -e "\033[1;32m----------------------------------------------------------\033[0m"
    read -s -n1 -p "★★★ 下面将部署Telegram机器人，请确保准备所需条件已准备好，请按任意键继续；如未做好准备请按“Ctrl+c”终止部署机器人 ★★★"
    echo
    echo -e "\033[1;32m----------------------------------------------------------\033[0m"

    echo
    echo -e "\033[1;32m  ===== <<开始部署gdutils查询转存TG机器人>> =====  \033[0m"
    echo
    read -p """请输入机器人token并回车
        Your Bot Token =>:""" YOUR_BOT_TOKEN
    read -p """请输入使用机器人的telegram账号名(“@”后面部分)并回车
        Your Telegram Name =>:""" YOUR_TELEGRAM_NAME
    read -p """请为WEB服务设置一个名称(填写你的域名格式:***.***.com)并回车
        Your Bot Server Name =>:""" YOUR_BOT_SERVER_NAME
    read -p """请输入在cloudflare上设置的网址(填写你的完整域名网址以“https”开头)并回车
        Your Website =>:""" YOUR_WEBSITE
    echo

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
    sudo apt-get install nginx -y
    echo   
    echo -e "\033[1;32m===== <<配置nginx服务>> ===== \033[0m"
    echo
    echo -e "\033[1;32m“nginx”起一个web服务......\033[0m"
    cd /etc/nginx/sites-enabled/
    echo "server {
    listen 80;
    server_name $YOUR_BOT_SERVER_NAME;
    location / {
        proxy_pass http://127.0.0.1:23333/;
    }
    }" > /etc/nginx/sites-enabled/gdutilsbot && 
    rm -f /etc/nginx/sites-enabled/default
    ls && 
    nginx -t &&  
    nginx -c /etc/nginx/nginx.conf && 
    nginx -s reload && 
    netstat -tulpen
    echo -e "\033[1;32m----------------------------------------------------------\033[0m"

    echo -e "\033[1;32m“检查网站是否部署成功”......\033[0m"
    curl $YOUR_WEBSITE/api/gdurl/count\?fid=124pjM5LggSuwI1n40bcD5tQ13wS0M6wg
    echo
    echo -e "\033[1;32m设置Webhook服务......\033[0m"
    print_webhook=`curl -F "url=$YOUR_WEBSITE/api/gdurl/tgbot" "https://api.telegram.org/bot$YOUR_BOT_TOKEN/setWebhook"`
    echo

    # 判断反向代理是否部署成功
    if [[ $print_webhook =~ "true" ]];then
        echo -e "\033[1;32m★★★ 恭喜你！GoogleDrive查询转存机器人部署成功，请回到TG界面给bot发送个“/help”获取使用帮助 ★★★\033[0m"
    else
        echo -e "\033[32m★★★ 很遗憾！机器人设置失败，请返回检查网站是否部署成功，并重复本安装过程 ★★★\033[0m", exit!
    fi

    cd ~
    rm -f gdutils.sh

}

os_centos(){
    echo
    echo -e "\033[1;32m===== <<升级系统/更新软件/安装工具/安装依赖>> =====\033[0m"
    echo
    for(( aloop=0;aloop<${#insofts[@]};aloop++ )) do
        if [ ${insofts[$aloop]} = "update" -o ${insofts[$aloop]} = "upgrade" ];then
            echo -e "\033[1;32m“${insofts[$aloop]}”开始安装......\033[0m"
            yum ${insofts[$aloop]} -y
            echo -e "\033[1;32m------------------------------------------------\033[0m"
        else
            echo -e "\033[1;32m“${insofts[$aloop]}”开始安装......\033[0m"
            yum install ${insofts[$aloop]} -y
            echo -e "\033[1;32m------------------------------------------------\033[0m"
        fi
    done

    echo
    echo -e "\033[1;32m===== <<安装gdutils依赖-nodejs和npm/安装配置gdutils>> =====\033[0m"
    echo
    yum install gcc-c++ make -y
    curl -sL https://rpm.nodesource.com/setup_10.x | bash -
    yum install nodejs -y
    yum install rpm-build -y
    git clone https://github.com/iwestlin/gd-utils && cd gd-utils
    npm config set unsafe-perm=true
    npm i
    
    echo
    echo -e "\033[1;32m★★★ 恭喜您!gdutils统计转存系统已经正确安装完成，请上传sa到“./gd-utils/sa/”目录下完成最后的部署 ★★★\033[0m"
    echo

    #################################################################################################
    echo -e "\033[1;32m------------------------------------------------\033[0m"
    read -s -n1 -p "★★★ 下面将部署Telegram机器人，请确保准备所需条件已准备好，请按任意键继续；如未做好准备请按“Ctrl+c”终止部署机器人 ★★★"
    echo
    echo -e "\033[1;32m------------------------------------------------\033[0m"

    echo
    echo -e "\033[1;32m===== <<开始部署gdutils查询转存TG机器人>> =====\033[0m"
    echo

    read -p """请输入机器人token并回车
        Your Bot Token =>:""" YOUR_BOT_TOKEN
    read -p """请输入使用机器人的telegram账号名(“@”后面部分)并回车
        Your Telegram Name =>:""" YOUR_TELEGRAM_NAME
    read -p """请为WEB服务设置一个名称(填写你的域名格式:***.***.com)并回车
        Your Bot Server Name =>:""" YOUR_BOT_SERVER_NAME
    read -p """请输入在cloudflare上设置的网址(填写你的完整域名网址以“https”开头)并回车
        Your Website =>:""" YOUR_WEBSITE
    echo
    echo -e "\033[1;32m------------------------------------------------\033[0m"

    cd ~ && 
    sed -i "s/bot_token/$YOUR_BOT_TOKEN/g" ./gd-utils/config.js
    sed -i "s/your_tg_username/$YOUR_TELEGRAM_NAME/g" ./gd-utils/config.js

    echo -e "\033[1;32m“进程守护程序pm2”开始安装......\033[0m"
    cd /root/gd-utils && 
    npm i pm2 -g && pm2 l

    echo -e "\033[1;32m启动守护进程......\033[0m"
    pm2 start server.js
    echo -e "\033[1;32m------------------------------------------------\033[0m"

    echo -e "\033[1;32m“nginx”开始安装......\033[0m"
    cd ~ && 
    #yum install -y pcre pcre-devel && 
    #yum install -y zlib zlib-devel && 
    #yum install -y openssl openssl-devel && 
    yum install nginx -y
    echo -e "\033[1;32m------------------------------------------------\033[0m"
    echo
    echo -e "\033[1;32m===== <<配置nginx服务>> =====\033[0m"
    echo

    echo -e "\033[1;32m“nginx”起一个web服务......\033[0m"
    cd /etc/nginx/conf.d/

    # nginx起一个web服务
    echo "server {
        listen 80;
        server_name $YOUR_BOT_SERVER_NAME;
        
        location / {
            proxy_pass http://127.0.0.1:23333/;
        }
    }" > /etc/nginx/conf.d/gdutilsbot.conf && 

    ls && 
    nginx -t && 
    nginx -c /etc/nginx/nginx.conf && 
    nginx -s reload && 
    netstat -tulpen
    echo -e "\033[1;32m------------------------------------------------\033[0m"

    echo -e "\033[1;32m检查网站是否部署成功......\033[0m"
    curl $YOUR_WEBSITE/api/gdurl/count\?fid=124pjM5LggSuwI1n40bcD5tQ13wS0M6wg
    echo

    echo -e "\033[1;32m设置Webhook服务......\033[0m"
    print_webhook=`curl -F "url=$YOUR_WEBSITE/api/gdurl/tgbot" "https://api.telegram.org/bot$YOUR_BOT_TOKEN/setWebhook"`
    echo

    # 判断反向代理是否部署成功
    if [[ $print_webhook =~ "true" ]];then
        echo -e "\033[1;32m★★★ 恭喜你！GoogleDrive查询转存机器人部署成功，请回到TG界面给bot发送个“/help”获取使用帮助 ★★★\033[0m"
    else
        echo -e "\033[32m★★★ 很遗憾！机器人设置失败，请返回检查网站是否部署成功，并重复本安装过程 ★★★\033[0m", exit!
    fi

    cd ~
    rm -f gdutils.sh

}

# 不同的操作系统选择执行不同的分支
case "$os" in
    Ubuntu)
        echo
        echo -e "\033[1;32m==<<您的操作系统为Ubuntu，即将为你开始部署gdutils项目>>==\033[0m"
        os_ubuntu
        ;;
    CentOS)
        echo
        echo -e "\033[1;32m==<<您的操作系统为Centos，即将为你开始部署gdutils项目>>==\033[0m"
        os_centos
        ;;
    Debian)
        echo
        echo -e "\033[1;32m==<<您的操作系统为Debian，即将为你开始部署gdutils项目>>==\033[0m"
        os_debian
        ;;
    mac)
        echo
        echo -e "\033[1;32m==<<您的操作系统为MacOS，请在图形界面手动安装>>==\033[0m"
        echo
        ;;
    *)
        echo -e "\033[1;32m unknow os $OS, exit! \033[0m"
        ;;
esac
