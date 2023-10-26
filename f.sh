#!/bin/bash

#====================================================
#	System Request: Centos 7+ Debian 8+
#	Author: songwqs
#	* Frps 一键安装脚本，Frpc Windows 便捷脚本！Frp 远程桌面！
#	* 开源地址：https://github.com/songwqs/frpspro
#	Blog: https://songw.top/
#====================================================

# 获取frps最新版本号
get_version(){
api_url="https://api.github.com/repos/fatedier/frp/releases/latest"	
new_ver=`curl ${PROXY} -s ${api_url} --connect-timeout 10| grep 'tag_name' | cut -d\" -f4`

touch ./version.txt
cat <<EOF > ./version.txt
${new_ver}
EOF
	
sed -i 's/v//g' ./version.txt
get_releases=$(cat ./version.txt)
echo -e "最新版本是:$get_releases"
if [ ! -n "$get_releases" ]; then
    echo "拉取默认版本"
    new_ver="v0.50.0"
    get_releases="0.50.0"
fi
check_url="https://ghproxy.com/"
if curl --output /dev/null --silent --head --fail "$check_url"; then
    ghproxy="https://ghproxy.com/"
else
    ghproxy="https://git.songw.top/"
fi	
releases_url=${ghproxy}https://github.com/fatedier/frp/releases/download/${new_ver}/frp_${get_releases}_linux_amd64.tar.gz
windows_url=${ghproxy}https://github.com/fatedier/frp/releases/download/${new_ver}/frp_${get_releases}_windows_amd64.zip
rm -rf ./version.txt

}

# 安装frps
install_frps(){
wget -N --no-check-certificate ${releases_url}
tar -zxvf frp*.tar.gz
rm -rf /usr/local/frps
mkdir /usr/local/frps
mv ./frp*/frps /usr/local/frps/frps
touch /usr/local/frps/frps.ini	
cat <<EOF > /usr/local/frps/frps.ini
# [common] 完整的配置参数
[common]
#IPv6的文字地址或主机名必须包含在内
#方括号中，如“[：：1]：80”、“[ipv6-host]：http”或“[ipv6host%zone]：80”
bind_addr=0.0.0.0
bind_port=7000
#用于kcp协议的udp端口，它可以与“bind_port”相同
#如果未设置，则在frp中禁用kcp
kcp_bind_port=7000
#如果要通过仪表板配置或重新加载frp，则必须设置dashboard_port
dashboard_port=7500
#仪表板资产目录（仅适用于调试模式）
dashboard_user=admin
dashboard_pwd=admin123
# assets_dir = ./static
# 由于服务器Nginx之类的占用了默认不占用80和443 
vhost_http_port=81
vhost_https_port=8443
#控制台或真实日志文件路径类似/frps.log
log_file = ./frps.log
#调试，信息，警告，错误（debug, info, warn, error）
log_level = info
log_max_days=3
#身份验证令牌(token)
token = pAnRjG9mznLQ
#当许多人一起使用一个frps服务器时，使用http、https类型的子域配置是很方便的。自定义二级域名
#subdomain_host = my.abc.com
# 只允许frpc使用指定的端口，如果您不设置任何设置，则不会有任何限制。
#allow_ports = 1-65535
#如果超过最大值，则每个代理中的pool_count将更改为max_pool_count
max_pool_count=50
#如果使用tcp流复用，则默认值为true
tcp_mux = true
EOF

	rm -rf ./frp*
}

# 添加开机自启动
add_auto_run(){
	touch /etc/systemd/system/frps.service
	cat <<EOF > /etc/systemd/system/frps.service
[Unit]
Description=frps server
After=network.target
Wants=network.target
[Service]
Type=simple
PIDFile=/var/run/frps.pid
ExecStart=/usr/local/frps/frps -c /usr/local/frps/frps.ini
RestartPreventExitStatus=23
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF
}


# 启动frps
run_frps(){
	systemctl daemon-reload
	systemctl enable frps >/dev/null 2>&1
	systemctl start frps
	systemctl restart frps
}


# 卸载frps
set_uninstall(){
	systemctl stop frps
	systemctl disable frps
	rm -rf /usr/local/frps
	rm -rf /etc/systemd/system/frps.service >/dev/null 2>&1
	echo -e "卸载成功！"
}


# 展示菜单
load_menu(){
local_ip=`curl -4 ip.sb`
clear
echo ""
echo -e "--------------------安装完成----------------------"
echo -e "管理面板：http://${local_ip}:7500"
echo -e "用户名：admin  密码：admin"
echo -e "默认 bind_port：7000"
echo -e "默认 token：12345678"
echo ""
echo -e "默认 vhost_http_port：81"
echo -e "默认 vhost_https_port：8443"
echo ""
echo -e "默认 bind_udp_port：7001"
echo -e "默认 kcp_bind_port：7000"
echo -e "默认 allow_ports = 1-65535"
echo ""
echo -e "Windows 便捷脚本：https://github.com/songwqs/frpspro/raw/master/FrpsPro.zip"
echo -e "Windows 最新内核：${windows_url}"
echo -e "--------------------------------------------------"
}


# 各种设置项
# ====================================

set_bind_port(){
	get_value=""
	echo -e "你正在设置 bind_port "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_bind_port
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^bind_port/c\bind_port = '"${get_value}"'' /usr/local/frps/frps.ini
	systemctl restart frps
	echo -e "设置成功！"
}


set_bind_udp_port(){
	get_value=""
	echo -e "你正在设置 bind_udp_port "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_bind_udp_port
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^bind_udp_port/c\bind_udp_port = '"${get_value}"'' /usr/local/frps/frps.ini
	systemctl restart frps
	echo -e "设置成功！"
}


set_kcp_bind_port(){
	get_value=""
	echo -e "你正在设置 kcp_bind_port "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_kcp_bind_port
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^kcp_bind_port/c\kcp_bind_port = '"${get_value}"'' /usr/local/frps/frps.ini
	systemctl restart frps
	echo -e "设置成功！"
}


set_vhost_http_port(){
	get_value=""
	echo -e "你正在设置 vhost_http_port "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_vhost_http_port
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^vhost_http_port/c\vhost_http_port = '"${get_value}"'' /usr/local/frps/frps.ini
	systemctl restart frps
	echo -e "设置成功！"
}


set_vhost_https_port(){
	get_value=""
	echo -e "你正在设置 vhost_https_port "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_vhost_https_port
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^vhost_https_port/c\vhost_https_port = '"${get_value}"'' /usr/local/frps/frps.ini
	systemctl restart frps
	echo -e "设置成功！"
}


set_dashboard_port(){
	get_value=""
	echo -e "你正在设置 dashboard_port "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_dashboard_port
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^dashboard_port/c\dashboard_port = '"${get_value}"'' /usr/local/frps/frps.ini
	systemctl restart frps
	echo -e "设置成功！"
}


set_dashboard_user(){
	get_value=""
	echo -e "你正在设置 dashboard_user "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_dashboard_user
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^dashboard_user/c\dashboard_user = '"${get_value}"'' /usr/local/frps/frps.ini
	systemctl restart frps
	echo -e "设置成功！"
}



set_dashboard_pwd(){
	get_value=""
	echo -e "你正在设置 dashboard_pwd "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_dashboard_pwd
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^dashboard_pwd/c\dashboard_pwd = '"${get_value}"'' /usr/local/frps/frps.ini
	systemctl restart frps
	echo -e "设置成功！"
}


set_token(){
	get_value=""
	echo -e "你正在设置 token "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_token
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^token/c\token = '"${get_value}"'' /usr/local/frps/frps.ini
	systemctl restart frps
	echo -e "设置成功！"
}


set_subdomain_host(){
	get_value=""
	echo -e "你正在设置 subdomain_host "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_subdomain_host
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^subdomain_host/c\subdomain_host = '"${get_value}"'' /usr/local/frps/frps.ini
	systemctl restart frps
	echo -e "设置成功！"
}

# ====================================
# 关闭apache2 释放80端口
set_unapache2(){
	systemctl disable httpd >/dev/null 2>&1
	systemctl stop httpd >/dev/null 2>&1
	killall -9 httpd >/dev/null 2>&1

	systemctl disable apache2 >/dev/null 2>&1
	systemctl stop apache2 >/dev/null 2>&1
	killall -9 apache2 >/dev/null 2>&1

	systemctl disable firewalld >/dev/null 2>&1
	systemctl stop firewalld >/dev/null 2>&1
	killall -9 firewalld >/dev/null 2>&1

	systemctl disable iptables >/dev/null 2>&1
	systemctl stop iptables >/dev/null 2>&1
	killall -9 iptables >/dev/null 2>&1

	echo -e "关闭 apache2 成功！"
	echo -e "关闭 防火墙 成功！"
}

# 安装流程
set_install(){
	get_version
	install_frps
	add_auto_run
	run_frps
	load_menu
}


# 脚本菜单
case "$1" in
	bind_port|bind_udp_port|kcp_bind_port|vhost_http_port|vhost_https_port|dashboard_port|dashboard_user|dashboard_pwd|token|subdomain_host|install|uninstall|unapache2)
	set_$1
	;;
	*)
	echo -e "缺少参数,更多教程请访问：https://github.com/fatedier/frp/blob/master/README_zh.md"
	;;
esac
