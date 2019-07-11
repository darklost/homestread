#! /bin/bash
# Check If frpc Has Been Installed
if [ -f /home/vagrant/.homestead-features/frpc ]
then
    echo "frpc already installed."
    exit 0
fi

touch /home/vagrant/.homestead-features/frpc
chown -Rf vagrant:vagrant /home/vagrant/.homestead-features

#===============================================================================================
#   System Required:  CentOS Debian or Ubuntu (32bit/64bit)
#   Description:  A tool to auto-compile & install frpc on Linux
#   Author: darklost
#   Intro:  http://darklost.me
#===============================================================================================
program_name="frpc"
FRPC_VER="0.27.0"
str_program_dir="/usr/local/frp"
program_config_file="frpc.ini"
github_download_url="https://github.com/fatedier/frp/releases/download" #下载地址目录 https://github.com/fatedier/frp/releases/download/v0.27.0/frp_0.27.0_linux_amd64.tar.gz

fun_info(){
    local clear_flag=""
    clear_flag=$1
    if [[ ${clear_flag} == "clear" ]]; then
        clear
    fi
    echo ""
    echo "+---------------------------------------------------------+"
    echo "|     frpc for Linux Server                               |"
    echo "+---------------------------------------------------------+"
    echo "|     A tool to auto-compile & install frpc on Linux      |"
    echo "+---------------------------------------------------------+"
    echo "|     Intro: http://darklost.me                            |"
    echo "+---------------------------------------------------------+"
    echo ""
}
fun_set_text_color(){
    COLOR_RED='\E[1;31m'
    COLOR_GREEN='\E[1;32m'
    COLOR_YELOW='\E[1;33m'
    COLOR_BLUE='\E[1;34m'
    COLOR_PINK='\E[1;35m'
    COLOR_PINKBACK_WHITEFONT='\033[45;37m'
    COLOR_GREEN_LIGHTNING='\033[32m \033[05m'
    COLOR_END='\E[0m'
}
# Check if user is root
rootness(){
    if [[ $EUID -ne 0 ]]; then
        fun_info
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}
get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
# Check OS
checkos(){
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OS=CentOS
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OS=Debian
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OS=Ubuntu
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}
# Get version
getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}
# CentOS version
centosversion(){
    local code=$1
    local version="`getversion`"

    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi
}
# Check OS bit
check_os_bit(){
    ARCHS=""
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
        ARCHS="amd64"
    else
        Is_64bit='n'
        ARCHS="386"
    fi
}
check_centosversion(){
if centosversion 5; then
    echo "Not support CentOS 5.x, please change to CentOS 6,7 or Debian or Ubuntu and try again."
    exit 1
fi
}
# Disable selinux
disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}


pre_install_packs(){
    local wget_flag=''
    local killall_flag=''
    local netstat_flag=''
    wget --version > /dev/null 2>&1
    wget_flag=$?
    killall -V >/dev/null 2>&1
    killall_flag=$?
    netstat --version >/dev/null 2>&1
    netstat_flag=$?
    if [[ ${wget_flag} -gt 1 ]] || [[ ${killall_flag} -gt 1 ]] || [[ ${netstat_flag} -gt 6 ]];then
        echo -e "${COLOR_GREEN} Install support packs...${COLOR_END}"
        if [ "${OS}" == 'CentOS' ]; then
            yum install -y wget psmisc net-tools
        else
            apt-get -y update && apt-get -y install wget psmisc net-tools
        fi
    fi

    ##确认文件安装路径
    program_bin=${str_program_dir}/${program_name} 
}

# Random password
fun_randstr(){
    strNum=$1
    [ -z "${strNum}" ] && strNum="16"
    strRandomPass=""
    strRandomPass=`tr -cd '[:alnum:]' < /dev/urandom | fold -w ${strNum} | head -n1`
    echo ${strRandomPass}
}

fun_getServer(){
    program_download_url=${github_download_url}
    echo "---------------------------------------"
    echo "program_download_url: ${program_download_url}"
    echo "---------------------------------------"
}

fun_getVer(){
   
    program_latest_filename="frp_${FRPC_VER}_linux_${ARCHS}.tar.gz"
    program_latest_file_url="${program_download_url}/v${FRPC_VER}/${program_latest_filename}"
    echo -e "${program_name} Latest release file ${COLOR_GREEN}${program_latest_filename}${COLOR_END}"
    echo -e "${program_name} Latest release file program_latest_file_url ${COLOR_GREEN}${program_latest_file_url}${COLOR_END}"
}
#下载文件
fun_download_file(){
    # download
    
    if [ ! -s ${program_bin} ]; then
        echo -n "download ${program_name} ..."
        rm -rf ${program_latest_filename} frp_${FRPC_VER}_linux_${ARCHS}
        if ! wget --no-check-certificate -q ${program_latest_file_url} -O ${program_latest_filename}; then
            echo -e " ${COLOR_RED}failed${COLOR_END}"
            exit 1
        fi
        tar xzf ${program_latest_filename}
        mv frp_${FRPC_VER}_linux_${ARCHS}/${program_name} ${program_bin}
        rm -rf ${program_latest_filename} frp_${FRPC_VER}_linux_${ARCHS}
    fi
    chown root:root -R ${str_program_dir}
    if [ -s ${program_bin} ]; then
        echo -n "download add Permission ${program_name} ..."
        [ ! -x ${program_bin} ] && chmod 755 ${program_bin}
    else
        echo -e " ${COLOR_RED}failed${COLOR_END}"
        exit 1
    fi
}

# ====== install server ======
install_program_server(){
    [ ! -d ${str_program_dir} ] && mkdir -p ${str_program_dir}
    cd ${str_program_dir}
    echo "${program_name} install path:$PWD"

    echo -n "config file for ${program_name} ..."

    echo " done"

    
    rm -f ${program_bin}  /usr/bin/${program_name}
    fun_download_file
    echo " done"
  
    echo -n "setting ${program_name} boot..."
    [ ! -x ${program_bin} ] && chmod +x ${program_bin}

    echo "add exec Permission done"
    [ -s ${program_bin} ] && ln -s ${program_bin} /usr/bin/${program_name}
    echo "ln -s  done"
    exit 0
}



install(){
    fun_info
    echo -e "Check your computer setting, please wait..."
    disable_selinux
   
    if [ -s program_bin ] ; then
        echo "${program_name} is installed!"
        echo "in ${program_bin} !"
    else
        clear
        fun_info
        fun_getServer
        fun_getVer
     
        install_program_server
    fi
}

uninstall(){
    fun_info
    if [ -s ${program_init} ] || [ -s ${str_program_dir}/${program_name} ] ; then
        echo "============== Uninstall ${program_name} =============="
        rm -f  /usr/bin/${program_name}
        rm -rf ${str_program_dir}
        echo "${program_name} uninstall success!"

    fi
    exit 0
}


clear
strPath=`pwd`
rootness
fun_set_text_color
checkos
check_centosversion
check_os_bit
pre_install_packs


action=$1
[ -z $1 ] && action=install
case "$action" in
install)
    install 
    ;;
uninstall)
    uninstall 
    ;;

*)
    fun_info
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall|update|config}"
    RET_VAL=1
    ;;
esac