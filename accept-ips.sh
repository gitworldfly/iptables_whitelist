#! /bin/bash
#Block-IPs-from-countries
#Github:https://github.com/iiiiiii1/Block-IPs-from-countries
#Blog:https://www.moerats.com/

Green="\033[32m"
Font="\033[0m"

#root权限
root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}


#3-查看白名单列表
accept_list(){
    iptables -L | grep match-set
}

#检查系统版本
check_release(){
    if [ -f /etc/redhat-release ]; then
        release="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    fi
}

#检查ipset是否安装
check_ipset(){
    if [ -f /sbin/ipset ]; then
        echo -e "${Green}检测到ipset已存在，并跳过安装步骤！${Font}"
    elif [ "${release}" == "centos" ]; then
        yum -y install ipset
    else
        apt-get -y install ipset
    fi
}

#设置内网
pri_ipset(){
    lookuplist=`ipset list | grep "Name:" | grep "pri"`
    if [ -n "$lookuplist" ]; then
        iptables -D INPUT -p tcp -m set --match-set "pri" src -j ACCEPT
        iptables -D INPUT -p udp -m set --match-set "pri" src -j ACCEPT
        ipset destroy pri
        echo -e "${Green}私有ip白名单解除成功，并删除其对应的规则！${Font}"
    else
        ipset -N pri hash:net
        for i in $(cat ./whitelist.zone); do ipset -A pri $i; done
        iptables -I INPUT -p tcp -m set --match-set "pri" src -j ACCEPT
        iptables -I INPUT -p udp -m set --match-set "pri" src -j ACCEPT
        echo -e "${Green}已设置私有网段(pri)${Font}"
    fi
}

#开始菜单
main(){
root_need
check_release
check_ipset
pri_ipset
clear
echo -e "———————————————————————————————————————"
echo -e "${Green}Linux VPS一键屏蔽指定国家所有的IP访问${Font}"
echo -e "${Green}1-添加放通ip${Font}"
echo -e "${Green}2-关闭放通规则${Font}"
echo -e "${Green}3-查看白名单列表${Font}"
echo -e "———————————————————————————————————————"
read -p "请输入数字 [1-3]:" num
case "$num" in
    1)
    accept_ipset
    ;;
    2)
    unblock_ipset
    ;;
    3)
    accept_list
    ;;
    *)
    clear
    echo -e "${Green}请输入正确数字 [1-3]${Font}"
    sleep 2s
    main
    ;;
    esac
}
main
