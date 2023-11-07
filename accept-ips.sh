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

#1-添加放通ip
accept_ipset(){
#添加ipset规则
echo -e "${Green}请输入需要放通的国家代码，如cn(中国)，注意字母为小写！${Font}"
read -p "请输入国家代码:" GEOIP
echo -e "${Green}正在下载IPs data...${Font}"
wget -P /tmp http://www.ipdeny.com/ipblocks/data/countries/$GEOIP.zone 2> /dev/null
#检查下载是否成功
    if [ -f "/tmp/"$GEOIP".zone" ]; then
     echo -e "${Green}IPs data下载成功！${Font}"
    else
     echo -e "${Green}下载失败，请检查你的输入！${Font}"
     echo -e "${Green}代码查看地址：http://www.ipdeny.com/ipblocks/data/countries/${Font}"
    exit 1
    fi
#创建规则
ipset -N $GEOIP hash:net
for i in $(cat /tmp/$GEOIP.zone ./whitelist.zone); do ipset -A $GEOIP $i; done
rm -f /tmp/$GEOIP.zone
echo -e "${Green}规则添加成功，即将开始放通ip！${Font}"
#封禁全部端口
iptables -P INPUT DROP
#开始放通
iptables -I INPUT -p tcp -m set --match-set "$GEOIP" src -j ACCEPT
iptables -I INPUT -p udp -m set --match-set "$GEOIP" src -j ACCEPT
echo -e "${Green}全端口封禁，指定白名单和国家($GEOIP)的ip放通成功！${Font}"
}

#2-关闭放通规则
unblock_ipset(){
iptables -P INPUT ACCEPT
echo -e "${Green}请输入需要解除的国家代码，如cn(中国)，注意字母为小写！${Font}"
read -p "请输入国家代码:" GEOIP
#判断是否有此国家的规则
lookuplist=`ipset list | grep "Name:" | grep "$GEOIP"`
    if [ -n "$lookuplist" ]; then
        iptables -D INPUT -p tcp -m set --match-set "$GEOIP" src -j ACCEPT
    iptables -D INPUT -p udp -m set --match-set "$GEOIP" src -j ACCEPT
    ipset destroy $GEOIP
    echo -e "${Green}所指定国家($GEOIP)的ip白名单解除成功，并删除其对应的规则！${Font}"
    else
    echo -e "${Green}解除失败，请确认你所输入的国家是否在白名单列表内！${Font}"
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