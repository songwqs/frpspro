#!/bin/bash
#====================================================
#	System Request: Centos 7+ Debian 8+
#	Author: songwqs
#	* Frps 一键安装脚本，Frpc Windows 便捷脚本！Frp 远程桌面！
#	* 开源地址：https://github.com/songwqs/frpspro
#	Blog: https://songw.top/
#====================================================
file_path="/usr/local/frps"
api_url="https://api.github.com/repos/fatedier/frp/releases/latest"
ghproxy="https://ghproxy.com/"
check_url1="https://ghproxy.com/"
check_url2="https://git.songw.top/"
version=${file_path}/version.txt
def_version="v0.50.0"
get_releases=""
new_ver=""
# 获取frps最新版本号
get_version(){
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
    new_ver=$def_version
    get_releases=$def_version
fi

if curl --output /dev/null --silent --head --fail "$check_url1"; then
    ghproxy=$check_url1
else
    ghproxy=$check_url2
fi	
releases_url=${ghproxy}https://github.com/fatedier/frp/releases/download/${new_ver}/frp_${get_releases}_linux_amd64.tar.gz
windows_url=${ghproxy}https://github.com/fatedier/frp/releases/download/${new_ver}/frp_${get_releases}_windows_amd64.zip
rm -rf ./version.txt
}
# 安装frps
install_frps(){
wget -N --no-check-certificate ${releases_url}
tar -zxvf frp*.tar.gz
rm -rf ${file_path}
mkdir ${file_path}
mv ./frp*/frps ${file_path}/frps
def_dashboard_pwd=`fun_randstr 8`
def_dashboard_token=`fun_randstr 10`
touch ${file_path}/frps.ini	
cat <<EOF > ${file_path}/frps.ini
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
#身份验证令牌(token)
token =${def_dashboard_token}
#仪表板资产目录（仅适用于调试模式）
dashboard_user=admin
dashboard_pwd=${def_dashboard_pwd}
# assets_dir = ./static
# 由于服务器Nginx之类的占用了默认不占用80和443 
vhost_http_port=81
vhost_https_port=8443
#控制台或真实日志文件路径类似/frps.log
log_file = ./frps.log
#调试，信息，警告，错误（debug, info, warn, error）
log_level = info
log_max_days=3
#当许多人一起使用一个frps服务器时，使用http、https类型的子域配置是很方便的。自定义二级域名
#subdomain_host = my.abc.com
# 只允许frpc使用指定的端口，如果您不设置任何设置，则不会有任何限制。
#allow_ports = 1-65535
#如果超过最大值，则每个代理中的pool_count将更改为max_pool_count
max_pool_count=50
#如果使用tcp流复用，则默认值为true
tcp_mux = true
EOF

touch $version
cat <<EOF > $version
${new_ver}
EOF

rm -rf ./frp*
}
# 随机密码
fun_randstr(){
    strNum=$1
    [ -z "${strNum}" ] && strNum="16"
    strRandomPass=""
    strRandomPass=`tr -cd '[:alnum:]' < /dev/urandom | fold -w ${strNum} | head -n1`
    echo ${strRandomPass}
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
ExecStart=${file_path}/frps -c ${file_path}/frps.ini
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
	rm -rf ${file_path}
	rm -rf /etc/systemd/system/frps.service >/dev/null 2>&1
	echo -e "卸载成功！"
}
set_update(){

   if [ -d ${file_path} ]; then
		new_ver=`curl ${PROXY} -s ${api_url} --connect-timeout 10| grep 'tag_name' | cut -d\" -f4`
		sed -i 's/v//g' $version
		get_releases=$(cat $version)
			
			if [[!$get_releases == *"$new_ver"* ]]; then
			    echo "最新版本:${get_releases}|本地版本:${new_ver}需要更新frps"				
			  releases_url=${ghproxy}https://github.com/fatedier/frp/releases/download/${new_ver}/frp_${get_releases}_linux_amd64.tar.gz     
				wget -N --no-check-certificate ${releases_url}
					tar -zxvf frp*.tar.gz
					mv ./frp*/frps ${file_path}/frps
					rm -rf ./frp*
					run_frps
			   		echo -e "更新成功！"
			else
			    echo "最新版本:${get_releases}|本地版本:${new_ver}不需要更新 frps"
			fi	
		   		echo "${new_ver}" > "$version"		
  else
  echo "目录 /usr/local/frps 不存在，重新安装"
  install_frps
  add_auto_run
  run_frps
  load_menu
   fi   
}
# 展示菜单
load_menu(){
local_ip=`curl -4 ip.sb`
clear
echo ""
echo -e "--------------------安装完成----------------------"
echo -e "管理面板：http://${local_ip}:7500"
echo -e "用户名：admin  密码：${def_dashboard_pwd}"
echo -e "默认 bind_port：7000"
echo -e "默认 token：${def_dashboard_token}"
echo ""
echo -e "默认 vhost_http_port：81"
echo -e "默认 vhost_https_port：8443"
echo ""
echo -e "默认 bind_udp_port：7001"
echo -e "默认 kcp_bind_port：7000"
echo -e "默认 allow_ports ：1-65535"
echo -e "----------------- 一键命令 ------------------------"
echo -e "一键修改token ：bash f.sh token"
echo -e "一键修改bind_port ：bash f.sh bind_port"
echo -e "一键修改vhost_http_port：bash f.sh vhost_http_port"
echo -e "一键修改vhost_https_port：bash f.sh vhost_https_port"
echo -e "一键修改dashboard_port：bash f.sh dashboard_port"
echo -e "一键修改dashboard_user：bash f.sh dashboard_user"
echo -e "一键修改dashboard_pwd：bash f.sh dashboard_pwd"
echo -e "一键修改bind_udp_port：bash f.sh bind_udp_port"
echo -e "一键修改kcp_bind_port：bash f.sh kcp_bind_port"
echo -e "一键修改subdomain_host(用于泛解析子域名)：bash f.sh subdomain_host"
echo -e "一键卸载frps：bash f.sh uninstall"
echo -e "一键更新frps：bash f.sh update"
echo -e "--------------------------------------------------"
echo -e "Linux 最新内核：${releases_url}"
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

	sed -i '/^bind_port/c\bind_port = '"${get_value}"'' ${file_path}/frps.ini
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

	sed -i '/^bind_udp_port/c\bind_udp_port = '"${get_value}"'' ${file_path}/frps.ini
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

	sed -i '/^kcp_bind_port/c\kcp_bind_port = '"${get_value}"'' ${file_path}/frps.ini
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

	sed -i '/^vhost_http_port/c\vhost_http_port = '"${get_value}"'' ${file_path}/frps.ini
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
	sed -i '/^vhost_https_port/c\vhost_https_port = '"${get_value}"'' ${file_path}/frps.ini
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
	sed -i '/^dashboard_port/c\dashboard_port = '"${get_value}"'' ${file_path}/frps.ini
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

	sed -i '/^dashboard_user/c\dashboard_user = '"${get_value}"'' ${file_path}/frps.ini
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

	sed -i '/^dashboard_pwd/c\dashboard_pwd = '"${get_value}"'' ${file_path}/frps.ini
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

	sed -i '/^token/c\token = '"${get_value}"'' ${file_path}/frps.ini
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

	sed -i '/^subdomain_host/c\subdomain_host = '"${get_value}"'' ${file_path}/frps.ini
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
	bind_port|bind_udp_port|kcp_bind_port|vhost_http_port|vhost_https_port|dashboard_port|dashboard_user|dashboard_pwd|token|subdomain_host|install|uninstall|unapache2|update)
	set_$1
	;;
	*)
	echo -e "缺少参数,更多教程请访问：https://gofrp.org/zh-cn/docs/"
	;;
esac
