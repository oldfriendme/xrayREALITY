echo -e "\e[32m欢迎使用REALITY一键脚本\e[0m"
echo .
echo "         _      _   __        _                   _ "
echo "   ___  | |  __| | / _| _ __ (_)  ___  _ __    __| |"
echo "  / _ \ | | / _I || |_ | __|| |  / _ \| |_ \  / _| |"
echo " | (_) || || (_| ||  _|| |   | ||  __/| | | || (_| |"
echo "  \___/ |_| \__,_||_|  |_|   |_| \___||_| |_| \__,_|"
echo "                                                    "
echo -e "\e[32m请输入监听IP,默认0.0.0.0\e[0m"
read ipaddr
echo -e "\e[32m请输入监听端口,默认443\e[0m"
read portx
echo -e "\e[32m请输入伪装的域名,默认www.apple.com\e[0m"
read domain_s
if [[ "$ipaddr" == "" ]]; then
ipaddr="0.0.0.0"
fi
if [[ "$portx" == "" ]]; then
portx="443"
fi
if [[ "$domain_s" == "" ]]; then
domain_s="www.apple.com"
fi
if ping -c 2 8.8.8.8 &> /dev/null
then
    echo "开始下载xray"
else
    echo -e "\033[31m没有网络连接\033[0m"
	exit
fi
if command -v wget > /dev/null 2>&1; then
    echo "Checking wget is installed."
else
    echo -e "\033[31mwget不存在,请apt install wget安装\033[0m"
	exit
fi
if command -v openssl > /dev/null 2>&1; then
    echo "Checking openssl is installed."
else
    echo -e "\033[31mopenssl不存在,请apt install openssl安装\033[0m"
	exit
fi
if command -v unzip > /dev/null 2>&1; then
    echo "Checking unzip is installed."
else
    echo -e "\033[31munzip不存在,请apt install unzip安装\033[0m"
	exit
fi
mkdir /usr/xray
architecture=$(uname -m)
if [[ "$architecture" == "x86_64" ]]; then
#系统是 64 位架构
wget -P /usr/xray https://github.com/XTLS/Xray-core/releases/download/v24.11.11/Xray-linux-64.zip
elif [[ "$architecture" == "i386" || "$architecture" == "i686" ]]; then
#系统是 32 位架构
wget -P /usr/xray https://github.com/XTLS/Xray-core/releases/download/v24.11.11/Xray-linux-32.zip
elif [[ "$architecture" == "aarch64" || "$architecture" == "aarch64" ]]; then
#系统是 ARM 架构
wget -P /usr/xray https://github.com/XTLS/Xray-core/releases/download/v24.11.11/Xray-linux-arm64-v8a.zip
else
echo -e "\033[31未知架构: $architecture,请手动安装\033[0m"
exit
fi
cd /usr/xray/
unzip *.zip
chmod 755 /usr/xray/xray
rm *.zip
id_s=`/usr/xray/xray uuid`
xray_x25519=`/usr/xray/xray x25519`
shortIds=`openssl rand -hex 8`
private_old=$(echo "$xray_x25519" | grep "Private key:" | cut -d ' ' -f 3-)
public_old=$(echo "$xray_x25519" | grep "Public key:" | cut -d ' ' -f 3-)
echo -n '{"log": {"loglevel": "warning"},"inbounds": [{"port": ' > /usr/xray/old_config.json
echo -n $portx >> /usr/xray/old_config.json
echo -n ',"listen": "'  >> /usr/xray/old_config.json
echo -n $ipaddr >> /usr/xray/old_config.json
echo -n '","protocol": "dokodemo-door","settings": {"address": "127.0.3.27","port": 20013,"network": "tcp"},"sniffing": {"enabled": true,"destOverride": ["tls"],"routeOnly": true}},{"listen": "127.0.3.27","port": 20013,"protocol": "vless","settings": {"clients": [{"id": "' >> /usr/xray/old_config.json
echo -n $id_s >> /usr/xray/old_config.json
echo -n '"}],"decryption": "none"},"streamSettings": {"network": "tcp","security": "reality","realitySettings": {"dest": "'  >> /usr/xray/old_config.json
echo -n $domain_s >> /usr/xray/old_config.json			
echo -n ':443","serverNames": ["' >> /usr/xray/old_config.json
echo -n $domain_s >> /usr/xray/old_config.json
echo -n '"],"privateKey": "' >> /usr/xray/old_config.json
echo -n $private_old >> /usr/xray/old_config.json
echo -n '","shortIds": ["' >> /usr/xray/old_config.json
echo -n $shortIds >> /usr/xray/old_config.json
echo -n '"]}},"sniffing": {"enabled": true,"destOverride": ["http","tls","quic"],"routeOnly": true}}],"outbounds": [{"protocol": "freedom","tag": "direct"},{"protocol": "blackhole","tag": "block"}],"routing": {"rules": [{"inboundTag": ["dokodemo-in"],"domain": ["' >> /usr/xray/old_config.json
echo -n $domain_s >> /usr/xray/old_config.json
echo -n '"],"outboundTag": "direct"},{"inboundTag": ["dokodemo-in"],"outboundTag": "block"}]}}' >> /usr/xray/old_config.json
useradd xrayuser
chown xrayuser /usr/xray/old_config.json
chmod 600 /usr/xray/old_config.json
setcap 'cap_net_bind_service=+ep' /usr/xray/xray
echo "[Unit]" > /etc/systemd/system/xray_service.service
echo "Description=xray Service" >> /etc/systemd/system/xray_service.service
echo "After=network.target" >> /etc/systemd/system/xray_service.service
echo "" >> /etc/systemd/system/xray_service.service
echo "[Service]" >> /etc/systemd/system/xray_service.service
echo "Type=simple" >> /etc/systemd/system/xray_service.service
echo "ExecStart=/usr/xray/xray -c /usr/xray/old_config.json" >> /etc/systemd/system/xray_service.service
echo "User=xrayuser" >> /etc/systemd/system/xray_service.service
echo "Restart=on-failure" >> /etc/systemd/system/xray_service.service
echo "" >> /etc/systemd/system/xray_service.service
echo "[Install]" >> /etc/systemd/system/xray_service.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/xray_service.service
echo -n $id_s > /usr/xray/oldf_uuid.json
oldip=$(wget -q -O - "https://oldfriend.me/cdn-cgi/trace")
realip=$(echo "$oldip" | grep "ip=" | cut -d '=' -f 2)
echo "#!/bin/bash" > /usr/xray/chaguuid
echo "newuuid=\`/usr/xray/xray uuid\`" >> /usr/xray/chaguuid
echo "olduuid=\`cat /usr/xray/oldf_uuid.json\`" >> /usr/xray/chaguuid
echo "sed -i \"s/\$olduuid/\$newuuid/g\" /usr/xray/old_config.json" >> /usr/xray/chaguuid
echo "sleep 2" >> /usr/xray/chaguuid
echo "echo -n \$newuuid > /usr/xray/oldf_uuid.json" >> /usr/xray/chaguuid
echo "systemctl restart xray_service" >> /usr/xray/chaguuid
echo "olddy=\"$realip:$portx?encryption=none&security=reality&sni=$domain_s&fp=chrome&pbk=$public_old&sid=$shortIds&type=tcp&headerType=none&host=$domain_s#xray_REALITY\"" >> /usr/xray/chaguuid
echo "echo uuid已更新,新uuid为: \$newuuid" >> /usr/xray/chaguuid
echo "echo 新订阅为: vless://\$newuuid@\$olddy" >> /usr/xray/chaguuid
echo "#!/bin/bash" > /usr/xray/delxray
echo "systemctl stop xray_service" >> /usr/xray/delxray
echo "systemctl disable xray_service" >> /usr/xray/delxray
echo "deluser xrayuser" >> /usr/xray/delxray
echo "rm /usr/bin/xray.*" >> /usr/xray/delxray
echo "rm /usr/xray/*" >> /usr/xray/delxray
echo "rmdir /usr/xray" >> /usr/xray/delxray
echo "echo -e \"\e[32m卸载完成,感谢使用\e[0m\"" >> /usr/xray/delxray
echo "#!/bin/bash" > /usr/xray/xraystop
echo "systemctl stop xray_service" >> /usr/xray/xraystop
echo "#!/bin/bash" > /usr/xray/xraystart
echo "systemctl start xray_service" >> /usr/xray/xraystart
echo "#!/bin/bash" > /usr/xray/xrayrestart
echo "systemctl restart xray_service" >> /usr/xray/xrayrestart
chmod 755 /usr/xray/delxray
chmod 755 /usr/xray/chaguuid
chmod 755 /usr/xray/xray*
ln -s /usr/xray/chaguuid /usr/bin/xray.chuuid
ln -s /usr/xray/delxray /usr/bin/xray.delxray
ln -s /usr/xray/xraystop /usr/bin/xray.stop
ln -s /usr/xray/xraystart /usr/bin/xray.start
ln -s /usr/xray/xrayrestart /usr/bin/xray.restart
systemctl enable xray_service
echo "done!"
echo -e "\e[32m安装完成\e[0m"
echo -e "\e[32m你的订阅为\e[0m"
echo
echo
echo -e "\e[32mvless://$id_s@$realip:$portx?encryption=none&security=reality&sni=$domain_s&fp=chrome&pbk=$public_old&sid=$shortIds&type=tcp&headerType=none&host=$domain_s#xray_REALITY\e[0m"
echo 
echo 
echo -e "\e[32mxray快捷命令\e[0m"
echo "修改订阅uuid-> xray.chuuid"
echo "删除xray及脚本->  xray.delxray"
echo "停止xray->  xray.stop"
echo "启动xray->  xray.start"
echo "重启xray->  xray.restart"
systemctl start xray_service