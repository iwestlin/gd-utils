#!"C:\Program Files\Git\usr\bin\bash"
#/bin/bash
#颜色变量，因为颜色字符复杂，定义一个函数表示其代码字符串能够很好容错，更改也方便
color_yellow='\033[1;32m'
color_end='\033[0m'

echo -e "\n$color_yellow===== <<gdutils项目一件部署脚本要求及说明>> =====$color_end"
echo -e "$color_yellow---------------[ v2.1 by oneking ]---------------$color_end"
echo -e "$color_yellow 01.$color_end 本脚本是魔改的gdutils项目一键部署脚本;"
echo -e "$color_yellow 02.$color_end 脚本包括“TD盘VPS上查询转存部署”和“Telegram机器人部署”两部分"
echo -e "$color_yellow 03.$color_end 本脚本适应CentOS/Debian/Ubuntu三种操作系统，自动识别、自动选择对应分支一键安装部署"
echo -e "$color_yellow 04.$color_end 三步即可完成部署：上传脚本到VPS → 设置脚本执行权限 → 运行"
echo -e "$color_yellow 05.$color_end 准备工作一：在TG上注册好机器人取得并记录下该机器人TOKEN"
echo -e "$color_yellow 06.$color_end 准备工作二：拥有一个域名绑定到cloudflare解析到该机器人所在服务器IP"
echo -e "$color_yellow 07.$color_end 准备工作三：向机器人@userinfobot获取个人TG账号ID并记录"
echo -e "$color_yellow 08.$color_end 准备工作四：注册好一个Google team drive加入sa并记录下该盘ID"
echo -e "$color_yellow 09.$color_end 经测试可用完美安装系统：Centos 7/8 debian 9/10 ubuntu 16.04/18.04/19.10/20.04"
echo -e "$color_yellow------------------------------------------------$color_end"
read -s -n1 -p "★★★ 如已做好以上[5/6/7/8]准备或不需要安装Telegram机器人请按任意键开始部署，如未做好准备请按“Ctrl+c”终止脚本 ★★★"
echo -e "\n$color_yellow------------------------------------------------$color_end"

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
    echo -e "$color_yellow★★★★★ 您的操作系统为Debian，即将为你开始部署gdutils项目 ★★★★★$color_end"
elif [[ "$os" = "Ubuntu" ]]; then
    cmd_install="sudo apt-get"
    cmd_install_rely="build-essential"
    nodejs_curl="https://deb.nodesource.com/setup_10.x"
    cmd_install_rpm_build=""
    nginx_conf="/etc/nginx/sites-enabled/"
    rm_nginx_default="rm -f /etc/nginx/sites-enabled/default"
    echo -e "\n$color_yellow★★★★★ 您的操作系统为Ubuntu，即将为你开始部署gdutils项目 ★★★★★$color_end"
elif [[ "$os" = "CentOS" ]]; then
    cmd_install="yum"
    cmd_install_rely="gcc-c++ make"
    nodejs_curl="https://rpm.nodesource.com/setup_10.x"
    cmd_install_rpm_build="yum install rpm-build -y"
    nginx_conf="/etc/nginx/conf.d/"
    rm_nginx_default=""
    echo -e "\n$color_yellow★★★★★ 您的操作系统为Centos，即将为你开始部署gdutils项目 ★★★★★$color_end"
elif [[ "$os" = "mac" ]]; then
    echo -e "\n$color_yellow★★★★★ 您的操作系统为MacOS，请在图形界面手动安装 ★★★★★$color_end\n" && exit
else
    echo -e "\n$color_yellow unknow os $OS, exit! $color_end" && exit
fi

echo -e "\n$color_yellow===== <<升级系统/更新软件/安装工具/安装依赖>> =====$color_end\n"

#安装which和sudo
if [[ "$(which which)" == "" ]]; then
    echo -e "$color_yellow“which”开始安装......$color_end"
    $cmd_install install which -y
    echo -e "$color_yellow------------------------------------------------$color_end"
elif [[ "$(which sudo)" == "" ]]; then
    echo -e "$color_yellow“sudo”开始安装......$color_end"
    $cmd_install install sudo -y
    echo -e "$color_yellow------------------------------------------------$color_end"
fi

#安装工具和依赖
for ((aloop = 0; aloop < ${#insofts[@]}; aloop++)); do
    if [ ${insofts[$aloop]} = "update" -o ${insofts[$aloop]} = "upgrade" ]; then
        echo -e "$color_yellow“${insofts[$aloop]}”开始安装......$color_end"
        $cmd_install ${insofts[$aloop]} -y
        echo -e "$color_yellow------------------------------------------------$color_end"
    else
        echo -e "$color_yellow“${insofts[$aloop]}”开始安装......$color_end"
        $cmd_install install ${insofts[$aloop]} -y
        echo -e "$color_yellow------------------------------------------------$color_end"
    fi
done

echo -e "\n$color_yellow===== <<安装gdutils依赖-nodejs和npm/安装配置gdutils>> =====$color_end\n"

$cmd_install install $cmd_install_rely -y
curl -sL $nodejs_curl | bash -
$cmd_install install nodejs -y
#wget https://cdn.npm.taobao.org/dist/node/v14.6.0/node-v14.6.0-linux-x64.tar.xz
#tar xvf node-v14.6.0-linux-x64.tar.xz && mv node-v14.6.0-linux-x64 ~/node && rm -rf node-v14.6.0-linux-x64.tar.xz
#export PATH=$PATH:~/node/bin/npm

$cmd_install_rpm_build
git clone https://github.com/dissipator/gd-utils.git gd-utils && cd gd-utils
npm config set unsafe-perm=true
npm i

echo -e "\n$color_yellow★★★ 恭喜您!gdutils统计转存系统已经正确安装完成，请上传sa到“./gd-utils/sa/”目录下完成最后的配置 ★★★$color_end\n"

#################################################################################################

echo -e "$color_yellow----------------------------------------------------------$color_end"
read -s -n1 -p "★★★ 下面将部署Telegram机器人，请确保准备所需条件已准备好，按任意键开始部署机器人；如未做好准备请按“Ctrl+c”终止部署机器人 ★★★"

echo -e "\n$color_yellow----------------------------------------------------------$color_end"

echo -e "\n$color_yellow  ===== <<开始部署gdutils查询转存TG机器人>> =====  $color_end\n"

#输入“机器人token/TG账号ID/域名/转存目的盘ID”
read -p """请输入机器人token并回车
    Your Bot Token =>:""" YOUR_BOT_TOKEN
#判断token是否输入正确
# while [[ "${#YOUR_BOT_TOKEN}" != 46 ]]; do
#     echo -e "$color_yellow★★★ 机器人TOKEN输入不正确，请重新输入或按“Ctrl+C”结束安装！ ★★★$color_end"
#     read -p """请输入机器人token并回车
#     Your Bot Token =>:""" YOUR_BOT_TOKEN
# done


read -p """请输入使用机器人的telegram账号ID(获取ID机器人@userinfobot)并回车
    Your Telegram ID =>:""" YOUR_TELEGRAM_ID
#判断telegram ID是否正确(通过判断是不是纯数字)
# until [[ $YOUR_TELEGRAM_ID =~ ^-?[0-9]+$ ]]; do
#     echo -e "$color_yellow★★★ 您的TG账号ID输入不正确，请重新输入或按“Ctrl+C”结束安装！ ★★★$color_end"
#     read -p """请输入使用机器人的telegram账号ID(获取ID机器人@userinfobot)并回车
#     Your Telegram ID =>:""" YOUR_TELEGRAM_ID
# done

read -p """请输入使用机器人的telegram账号NAME(获取NAME机器人@userinfobot)并回车
    Your Telegram NAME =>:""" YOUR_TELEGRAM_NAME
#判断telegram NAME是否正确(通过判断是不是纯数字)
# until [[ $YOUR_TELEGRAM_NAME =~ ^-?[0-9]+$ ]]; do
#     echo -e "$color_yellow★★★ 您的TG账号NAME输入不正确，请重新输入或按“Ctrl+C”结束安装！ ★★★$color_end"
#     read -p """请输入使用机器人的telegram账号NAME(获取NAME机器人@userinfobot)并回车
#     Your Telegram NAME =>:""" YOUR_TELEGRAM_NAME
# done

read -p """请输入转存默认目的地团队盘ID(不指定转存目的地默认改地址，脚本强制要求输入团队盘ID)并回车
    Your Google Team Drive ID =>:""" YOUR_GOOGLE_TEAM_DRIVE_ID
#判断google team drive ID是否正确（团队盘ID长度19位）
# while [[ "${#YOUR_GOOGLE_TEAM_DRIVE_ID}" != 19 ]]; do
#     echo -e "$color_yellow★★★ 您的Google team drive ID输入不正确，请重新输入或按“Ctrl+C”结束安装！ ★★★$color_end"
#     read -p """请输入转存默认目的地ID(不指定转存目的地默认该地址，脚本强制要求输入团队盘ID)并回车
#     Your Google Team Drive ID =>:""" YOUR_GOOGLE_TEAM_DRIVE_ID
# done
cd ../
#cd ./gd-utils &&
    sed -i "s/bot_token/$YOUR_BOT_TOKEN/g" ./gd-utils/config.js &&
    sed -i "s/your_tg_userid/$YOUR_TELEGRAM_ID/g" ./gd-utils/config.js &&
    sed -i "s/your_tg_username/$YOUR_TELEGRAM_NAME/g" ./gd-utils/config.js &&
    sed -i "s/DEFAULT_TARGET = ''/DEFAULT_TARGET = '$YOUR_GOOGLE_TEAM_DRIVE_ID'/g" ./gd-utils/config.js
echo -e "$color_yellow----------------------------------------------------------$color_end"

echo -e "$color_yellow“进程守护程序pm2”开始安装......$color_end"
sudo npm i pm2 -g && pm2 l
echo -e "$color_yellow启动守护进程......$color_end"
cd ./gd-utils
pm2 start  index.js --node-args="--max-old-space-size=500"
echo -e "$color_yellow----------------------------------------------------------$color_end"

cd ~
#rm -f gdutilsinstall.sh

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
