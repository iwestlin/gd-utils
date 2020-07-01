#!/bin/bash
echo
echo -e "\033[1;32m===== <<gdutils项目一键部署脚本之“TD查询转存”>> =====\033[0m"
echo -e "\033[1;32m-----------------[ v2.1 by oneking ]-----------------\033[0m"
echo -e "\033[32m 1.\033[0m 本脚本是针对TG大神@viegg的gdutils项目“TD查询转存”部分一键部署脚本;"
echo -e "\033[32m 2.\033[0m 本脚本适应CentOS/Debian/Ubuntu三种操作系统，自动识别、自动匹配参数一键部署"
echo -e "\033[32m 3.\033[0m 由于本脚本涉及到系统升级和依赖软件较多，避免中断建议使用screen窗口安装"
echo -e "\033[32m 4.\033[0m 经测试可用完美安装系统：Centos 7/8 debian 9/10 ubuntu 16.04/18.04/19.10/20.04"
echo -e "\033[32m 5.\033[0m 部署过程中有任何问题请把“错误截图”“部署VPS系统名称版本”信息发给TG：onekings 或 vitaminor@gmail.com"
echo -e "\033[1;32m------------------------------------------------\033[0m"
read -s -n1 -p "★★★ 请按任意键开始部署，按“Ctrl+c”终止部署 ★★★"
echo
echo -e "\033[1;32m------------------------------------------------\033[0m"

# 需要安装的软件工具及依赖
insofts=(epel-release update upgrade wget curl git unzip zip python3-distutils python3 python3-pip)

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
    cmd_install="apt-get"                               #安装命令
    cmd_install_rely="build-essential"                  #c++编译环境
    nodejs_curl="https://deb.nodesource.com/setup_10.x" #nodejs下载链接
    cmd_install_rpm_build=""                            #安装rpm-build
    echo
    echo -e "\033[1;32m★★★★★ 您的操作系统为Debian，即将为你开始部署gdutils项目“TD查询转存”部分 ★★★★★\033[0m"
elif [[ "$os" = "Ubuntu" ]]; then
    cmd_install="sudo apt-get"
    cmd_install_rely="build-essential"
    nodejs_curl="https://deb.nodesource.com/setup_10.x"
    cmd_install_rpm_build=""
    echo
    echo -e "\033[1;32m★★★★★ 您的操作系统为Ubuntu，即将为你开始部署gdutils项目“TD查询转存”部分 ★★★★★\033[0m"
elif [[ "$os" = "CentOS" ]]; then
    cmd_install="yum"
    cmd_install_rely="gcc-c++ make"
    nodejs_curl="https://rpm.nodesource.com/setup_10.x"
    cmd_install_rpm_build="yum install rpm-build -y"
    echo
    echo -e "\033[1;32m★★★★★ 您的操作系统为Centos，即将为你开始部署gdutils项目“TD查询转存”部分 ★★★★★\033[0m"
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

echo
echo -e "\033[1;32m===== <<升级系统/更新软件/安装工具/安装依赖>> =====\033[0m"
echo

# 检查which和sudo是否安装，如已安装跳过，未安装先装
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
echo -e "\033[1;32m★★★ 恭喜您!gdutils项目“TD查询转存”部分已部署完成，请上传sa到“./gd-utils/sa/”目录下完成最后的配置 ★★★\033[0m"
echo

cd ~
rm -f gdutilscs.sh

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
