#!"C:\Program Files\Git\usr\bin\bash"
#/bin/bash
#颜色变量，因为颜色字符复杂，定义一个函数表示其代码字符串能够很好容错，更改也方便
color_yellow='\033[1;32m'
color_end='\033[0m'

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

export PATH=$PATH:$(pwd)/node/bin/

pm2 stop all
pwd
git pull 
echo -e "$color_yellow启动守护进程......$color_end"
pm2 start all
pwd

#################################################################################################

echo -e "$color_yellow----------------------------------------------------------$color_end"


cd ~
