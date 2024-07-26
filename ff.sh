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
check_url2="https://git.songwqs.top/"
version=${file_path}/version.txt
def_version="v0.52.0"
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
def_webServer.password=`fun_randstr 8`
def_dashboard_token=`fun_randstr 10`
touch ${file_path}/frps.toml	
cat <<EOF > ${file_path}/frps.toml
#完整的配置参数
bindPort = 7000
auth.token = "yqJ5zhUmkSXH"
kcpBindPort = 7000
##Web界面
##默认为 127.0.0.1 如果需要公网访问修改为 0.0.0.0
webServer.addr = "0.0.0.0"
webServer.port = 7500
webServer.user = "admin"
webServer.password = "admin"
##配置TLS 证书来启用HTTPS接口
# webServer.tls.certFile = "server.crt"
# webServer.tls.keyFile = "server.key"
# transport.tls.force 指定是否只接受 TLS 加密连接。默认情况下，该值为 false。
#tls.force = false
# transport.tls.certFile = "server.crt"
# transport.tls.keyFile = "server.key"
# transport.tls.trustedCaFile = "ca.crt"
# 仪表板资源目录（仅限调试模式）
# webServer.assetsDir = "./static"
##如果要支持虚拟主机，必须设置用于监听的 http 端口（可选）
##注意：http 端口和 https 端口可以与 bindPort 相同
vhostHTTPPort = 81
vhostHTTPSPort = 444
# 控制台或实际 logFile 路径，如 ./frps.log
log.to = "./frps.log"
# trace、debug、info、warn、error
log.level = "info"
log.maxDays = 3
# 当 log.to 为 console 时禁用日志颜色，默认值为 false
log.disablePrintColor = false
# 每个代理中保留的池计数不超过 maxPoolCount。
transport.maxPoolCount = 50
# 如果使用了 tcp 流复用，则默认值为 true
transport.tcpMux = true
# 指定 tcp mux 的保持活动间隔,仅当 tcpMux 为 true 时有效
transport.tcpMuxKeepaliveInterval = 60
#每个客户端可用的最大端口数，默认值为 0 表示无限制
##maxPortsPerClient = 0
##在仪表板监听器中启用 golang pprof 处理程序,必须首先设置仪表板端口
##webServer.pprofEnable = false
##enablePrometheus 将在 webServer 上的 /metrics API 导出 Prometheus 指标。
##enablePrometheus = true
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
ExecStart=${file_path}/frps -c ${file_path}/frps.toml
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
echo -e "用户名：admin  密码：${def_webServer.password}"
echo -e "默认 bindPort：7000"
echo -e "默认 token：${def_dashboard_token}"
echo ""
echo -e "默认 vhostHTTPPort：81"
echo -e "默认 vhostHTTPSPort：8443"
echo ""
echo -e "默认 kcpBindPort：7000"
echo -e "默认 allowPorts ：1-65535"
echo -e "----------------- 一键命令 ------------------------"
echo -e "一键修改token ：bash f.sh token"
echo -e "一键修改bindPort ：bash f.sh bindPort"
echo -e "一键修改vhostHTTPPort：bash f.sh vhostHTTPPort"
echo -e "一键修改vhostHTTPSPort：bash f.sh vhostHTTPSPort"
echo -e "一键修改webServer.port：bash f.sh webServer.port"
echo -e "一键修改webServer.user：bash f.sh webServer.user"
echo -e "一键修改webServer.password：bash f.sh webServer.password"
echo -e "一键修改kcpBindPort：bash f.sh kcpBindPort"
echo -e "一键修改subDomainHost(用于泛解析子域名)：bash f.sh subDomainHost"
echo -e "一键卸载frps：bash f.sh uninstall"
echo -e "一键更新frps：bash f.sh update"
echo -e "--------------------------------------------------"
echo -e "Linux 最新内核：${releases_url}"
echo -e "Windows 最新内核：${windows_url}"
echo -e "--------------------------------------------------"
}
# 各种设置项
# ====================================
set_bindPort(){
	get_value=""
	echo -e "你正在设置 bindPort "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_bindPort
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^bindPort/c\bindPort = '"${get_value}"'' ${file_path}/frps.toml
	systemctl restart frps
	echo -e "设置成功！"
}

set_kcpBindPort(){
	get_value=""
	echo -e "你正在设置 kcpBindPort "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_kcpBindPort
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^kcpBindPort/c\kcpBindPort = '"${get_value}"'' ${file_path}/frps.toml
	systemctl restart frps
	echo -e "设置成功！"
}
set_vhostHTTPPort(){
	get_value=""
	echo -e "你正在设置 vhostHTTPPort "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_vhostHTTPPort
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^vhostHTTPPort/c\vhostHTTPPort = '"${get_value}"'' ${file_path}/frps.toml
	systemctl restart frps
	echo -e "设置成功！"
}
set_vhostHTTPSPort(){
	get_value=""
	echo -e "你正在设置 vhostHTTPSPort "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_vhostHTTPSPort
	else
	echo -e "你设置的值为：${get_value}"
	fi
	sed -i '/^vhostHTTPSPort/c\vhostHTTPSPort = '"${get_value}"'' ${file_path}/frps.toml
	systemctl restart frps
	echo -e "设置成功！"
}
set_webServer.port(){
	get_value=""
	echo -e "你正在设置 webServer.port "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_webServer.port
	else
	echo -e "你设置的值为：${get_value}"
	fi
	sed -i '/^webServer.port/c\webServer.port = '"${get_value}"'' ${file_path}/frps.toml
	systemctl restart frps
	echo -e "设置成功！"
}
set_webServer.user(){
	get_value=""
	echo -e "你正在设置 webServer.user "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_webServer.user
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^webServer.user/c\webServer.user = '"${get_value}"'' ${file_path}/frps.toml
	systemctl restart frps
	echo -e "设置成功！"
}
set_webServer.password(){
	get_value=""
	echo -e "你正在设置 webServer.password "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_webServer.password
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^webServer.password/c\webServer.password = '"${get_value}"'' ${file_path}/frps.toml
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

	sed -i '/^auth.token/c\auth.token = '"${get_value}"'' ${file_path}/frps.toml
	systemctl restart frps
	echo -e "设置成功！"
}
set_subDomainHost(){
	get_value=""
	echo -e "你正在设置 subDomainHost "

	read -e -p "请输入：" get_value
	[[ -z ${get_value} ]] && get_value="none"
	if [ "${get_value}" = "none" ];then
	set_subDomainHost
	else
	echo -e "你设置的值为：${get_value}"
	fi

	sed -i '/^subDomainHost/c\subDomainHost = '"${get_value}"'' ${file_path}/frps.toml
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
	bindPort|bind_udp_port|kcpBindPort|vhostHTTPPort|vhostHTTPSPort|webServer.port|webServer.user|webServer.password|token|subDomainHost|install|uninstall|unapache2|update)
	set_$1
	;;
	*)
	echo -e "缺少参数,更多教程请访问：https://gofrp.org/zh-cn/docs/"
	;;
esac
