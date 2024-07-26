# frps 一键安装脚本  [源frp项目](https://github.com/fatedier/frp) 
## 支持系统 Centos 7+ Debian 8+
github：
```
wget -N --no-check-certificate https://raw.githubusercontent.com/songwqs/frpspro/master/ff.sh && chmod +x ff.sh && bash ff.sh install
```
gitee：
```
wget -N --no-check-certificate https://gitee.com/songwqs/frpspro/raw/master/ff.sh && chmod +x ff.sh && bash ff.sh install
```

## 一键修改 token
```
bash ff.sh token
```

# 【常用命令】

---

---

## 一键修改 bindPort
```
bash ff.sh bindPort
```

## 一键修改 vhostHTTPPort
```
bash ff.sh vhostHTTPPort
```

## 一键修改 vhostHTTPSPort
```
bash ff.sh vhostHTTPSPort
```


# 【备用命令】

---

---

## 一键修改 webServer.port
```
bash ff.sh webServer.port
```

## 一键修改 dashboard_user
```
bash ff.sh dashboard_user
```

## 一键修改 webServer.password
```
bash ff.sh webServer.password
```

## 一键修改 kcpBindPort
```
bash ff.sh kcpBindPort
```

## 一键修改 subDomainHost （用于泛解析子域名）
```
bash ff.sh subDomainHost
```

## 一键卸载 frps
```
bash ff.sh uninstall
```
## 一键更新 frps
```
bash ff.sh update
```
## 一键关闭 apache2、防火墙，释放 80 端口
```
bash ff.sh unapache2
```
# 【注意事项】

## 注意，除http(s)以外，客户端 frpc.ini 内任何端口修改时须在以下范围内：
```
开放端口： 1-65535
```

## 转发远程桌面时，需先在本机开启允许远程协助
```
我的电脑（此电脑）-右键属性-远程设置
```

## 需要注意 frpc 所在机器和 frps 所在机器的时间相差不能超过 15 分钟
