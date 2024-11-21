#!/bin/bash
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
echo -e "\e[32m请输入流控模式(0/1)['1'为使用xtls-rprx-vision流控,'0'为不开启(默认)]\e[0m"
read oflow
echo -e "\e[32m辅助开启bbr(y/n)?\e[0m"
read ebbr
echo -e "\e[32m是否开启sni-filter(y/n)?[测试功能(建议no)]\e[0m"
read osni
old_flow=""
sni_filter=0
shitswim=0
if [[ "$oflow" == "1" ]]; then
old_flow="xtls-rprx-vision"
fi
if [[ "$osni" == "y" ]]; then
sni_filter=1
fi
if [[ "$ipaddr" == "" ]]; then
ipaddr="0.0.0.0"
fi
if [[ "$portx" == "" ]]; then
portx="443"
fi
if [[ "$domain_s" == "" ]]; then
domain_s="www.apple.com"
fi
if [[ "$ebbr" == "y" ]]; then
current_cc=$(sysctl -n net.ipv4.tcp_congestion_control)
if [ "$current_cc" == "bbr" ]; then
echo "BBR 已开启,忽略"
else
sysctl -w net.ipv4.tcp_congestion_control=bbr
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
echo "BBR 开启中，拥塞算法$current_cc调整为bbr"
fi
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
wget -P /usr/xray https://github.com/XTLS/Xray-core/releases/download/v1.8.21/Xray-linux-64.zip
elif [[ "$architecture" == "i386" || "$architecture" == "i686" ]]; then
#系统是 32 位架构
wget -P /usr/xray https://github.com/XTLS/Xray-core/releases/download/v1.8.21/Xray-linux-32.zip
elif [[ "$architecture" == "aarch64" ]]; then
#系统是 ARM 架构
wget -P /usr/xray https://github.com/XTLS/Xray-core/releases/download/v1.8.21/Xray-linux-arm64-v8a.zip
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

cat << EOF > /usr/xray/old_config.json
{"log": {"loglevel": "warning"},"inbounds": [{
"port": $portx,
            "listen": "$ipaddr",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$id_s",
						"flow": "$old_flow"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "dest": "$domain_s:443",
                    "serverNames": [
                        "$domain_s"
                    ],
                    "privateKey": "$private_old",
                    "shortIds": [
                        "$shortIds"
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        }
    ]
}
EOF

if [ $sni_filter -eq 1 ]; then
cat << EOF > /usr/xray/sni_filter_config.json
{"log": {"loglevel": "warning"},"inbounds": [{
            "listen": "/run/old/xray.friend,0640",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$id_s",
						"flow": "$old_flow"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "dest": "$domain_s:443",
                    "serverNames": [
                        "$domain_s"
                    ],
                    "privateKey": "$private_old",
                    "shortIds": [
                        "$shortIds"
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        }
    ]
}
EOF
fi

useradd xrayuser
usermod -s /sbin/nologin xrayuser

chown :xrayuser /usr/xray/*.json
chown xrayuser /usr/xray/
if [ $sni_filter -eq 1 ]; then
	echo "#!/bin/bash" > /usr/xray/xrayinit
	chmod 755 /usr/xray/xrayinit
	wget -P /usr/xray https://github.com/oldfriendme/REALITY-sni-filter/releases/download/v0.1/autobuild.zip
	unzip autobuild.zip
	rm autobuild.zip
	setcap 'cap_net_bind_service=+ep' /usr/xray/sni-filter
else
    setcap 'cap_net_bind_service=+ep' /usr/xray/xray
fi

if [ $sni_filter -eq 1 ]; then
echo "[Unit]" > /etc/systemd/system/xray_service.service
echo "Description=xray Service" >> /etc/systemd/system/xray_service.service
echo "After=network.target" >> /etc/systemd/system/xray_service.service
echo "" >> /etc/systemd/system/xray_service.service
echo "[Service]" >> /etc/systemd/system/xray_service.service
echo "Type=simple" >> /etc/systemd/system/xray_service.service
echo "ExecStart=/usr/bin/sh /usr/xray/xrayinit" >> /etc/systemd/system/xray_service.service
echo "User=xrayuser" >> /etc/systemd/system/xray_service.service
echo "Restart=on-failure" >> /etc/systemd/system/xray_service.service
echo "" >> /etc/systemd/system/xray_service.service
echo "[Install]" >> /etc/systemd/system/xray_service.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/xray_service.service
echo "setsid /usr/xray/sni-filter -listen $ipaddr $portx -sni $domain_s &" >> /usr/xray/xrayinit
echo "setsid /usr/xray/xray -c /usr/xray/sni_filter_config.json &" >> /usr/xray/xrayinit
else
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
fi
if [[ "$shitswim" == "y" ]]; then
cp /sbin/sni* /usr/xray/snifilter
setcap 'cap_net_bind_service=+ep' /usr/xray/snifilter
fi

echo -n $id_s > /usr/xray/oldf_uuid.json
oldip=$(wget -q -O - "https://oldfriend.me/cdn-cgi/trace")
realip=$(echo "$oldip" | grep "ip=" | cut -d '=' -f 2)
if [ ${#realip} -gt 16 ]; then
	realip=[$realip]
fi
if [ $sni_filter -eq 1 ]; then
echo "#!/bin/bash" > /usr/xray/chaguuid
echo "newuuid=\`/usr/xray/xray uuid\`" >> /usr/xray/chaguuid
echo "olduuid=\`cat /usr/xray/oldf_uuid.json\`" >> /usr/xray/chaguuid
echo "sed -i \"s/\$olduuid/\$newuuid/g\" /usr/xray/sni_filter_config.json" >> /usr/xray/chaguuid
echo "sleep 1" >> /usr/xray/chaguuid
echo "killall xray > /dev/null 2>&1" >> /usr/xray/chaguuid
echo "killall sni-filter > /dev/null 2>&1" >> /usr/xray/chaguuid
echo "echo -n \$newuuid > /usr/xray/oldf_uuid.json" >> /usr/xray/chaguuid
echo "systemctl restart xray_service" >> /usr/xray/chaguuid
echo "olddy=\"$realip:$portx?encryption=none&security=reality&sni=$domain_s&fp=chrome&pbk=$public_old&sid=$shortIds&type=tcp&headerType=none&host=$domain_s&flow=$old_flow#xray_REALITY\"" >> /usr/xray/chaguuid
echo "echo uuid已更新,新uuid为: \$newuuid" >> /usr/xray/chaguuid
echo "echo 新订阅为: vless://\$newuuid@\$olddy" >> /usr/xray/chaguuid
echo "#!/bin/bash" > /usr/xray/closedsni
echo "setcap 'cap_net_bind_service=+ep' /usr/xray/xray" >> /usr/xray/closedsni
echo "echo \"#!/bin/bash\" > /usr/xray/xrayinit" >> /usr/xray/closedsni
echo "echo \"setsid /usr/xray/xray -c /usr/xray/old_config.json &\" >> /usr/xray/xrayinit" >> /usr/xray/closedsni
echo "killall xray > /dev/null 2>&1" >> /usr/xray/closedsni
echo "killall sni-filter > /dev/null 2>&1" >> /usr/xray/closedsni
echo "sleep 1" >> /usr/xray/closedsni
echo "echo 已关闭,正在重启xray" >> /usr/xray/closedsni
echo "systemctl restart xray_service" >> /usr/xray/closedsni
echo "#!/bin/bash" > /usr/xray/opensni
echo "echo \"#!/bin/bash\" > /usr/xray/xrayinit" >> /usr/xray/opensni
echo "echo \"setsid /usr/xray/sni-filter -listen $ipaddr $portx -sni $domain_s &\" >> /usr/xray/xrayinit" >> /usr/xray/opensni
echo "echo \"setsid /usr/xray/xray -c /usr/xray/sni_filter_config.json &\" >> /usr/xray/xrayinit" >> /usr/xray/opensni
echo "killall xray > /dev/null 2>&1" >> /usr/xray/opensni
echo "sleep 1" >> /usr/xray/opensni
echo "echo 已打开,正在重启xray" >> /usr/xray/opensni
echo "systemctl restart xray_service" >> /usr/xray/opensni
mkdir /run/old
chown xrayuser /run/old
chmod 655 /usr/xray/sni*
else
echo "#!/bin/bash" > /usr/xray/chaguuid
echo "newuuid=\`/usr/xray/xray uuid\`" >> /usr/xray/chaguuid
echo "olduuid=\`cat /usr/xray/oldf_uuid.json\`" >> /usr/xray/chaguuid
echo "sed -i \"s/\$olduuid/\$newuuid/g\" /usr/xray/old_config.json" >> /usr/xray/chaguuid
echo "sleep 2" >> /usr/xray/chaguuid
echo "echo -n \$newuuid > /usr/xray/oldf_uuid.json" >> /usr/xray/chaguuid
echo "systemctl restart xray_service" >> /usr/xray/chaguuid
echo "olddy=\"$realip:$portx?encryption=none&security=reality&sni=$domain_s&fp=chrome&pbk=$public_old&sid=$shortIds&type=tcp&headerType=none&host=$domain_s&flow=$old_flow#xray_REALITY\"" >> /usr/xray/chaguuid
echo "echo uuid已更新,新uuid为: \$newuuid" >> /usr/xray/chaguuid
echo "echo 新订阅为: vless://\$newuuid@\$olddy" >> /usr/xray/chaguuid
echo "#!/bin/bash" > /usr/xray/opensni
echo "echo -e \"\033[31msni-filter未安装\033[0m\"" >> /usr/xray/opensni
cp /usr/xray/opensni /usr/xray/closedsni
fi


echo "#!/bin/bash" > /usr/xray/delxray
echo "systemctl stop xray_service" >> /usr/xray/delxray
echo "systemctl disable xray_service" >> /usr/xray/delxray
if [ $sni_filter -eq 1 ]; then
echo "killall xray > /dev/null 2>&1" >> /usr/xray/delxray
fi
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
cat << EOF > /usr/xray/xrayhelp
echo -e "\e[32mxray快捷命令\e[0m"
echo "修改订阅uuid->          xray.chuuid"
echo "删除xray及脚本->        xray.delxray"
echo "停止xray->              xray.stop"
echo "启动xray->              xray.start"
echo "重启xray->              xray.restart"
echo "关闭sni-filter模式->    xray.csni"
echo "打开sni-filter模式->    xray.osni"
echo "帮助->                  xray.help"
EOF
chmod 655 /usr/xray/*sni
chmod 640 /usr/xray/*.json
chmod 755 /usr/xray/delxray
chmod 755 /usr/xray/chaguuid
chmod 755 /usr/xray/xray*
ln -s /usr/xray/chaguuid /usr/bin/xray.chuuid
ln -s /usr/xray/delxray /usr/bin/xray.delxray
ln -s /usr/xray/xraystop /usr/bin/xray.stop
ln -s /usr/xray/xraystart /usr/bin/xray.start
ln -s /usr/xray/xrayrestart /usr/bin/xray.restart
ln -s /usr/xray/closedsni /usr/bin/xray.csni
ln -s /usr/xray/opensni /usr/bin/xray.osni
ln -s /usr/xray/xrayhelp /usr/bin/xray.help
systemctl enable xray_service
echo "done!"
echo -e "\e[32m安装完成\e[0m"
echo -e "\e[32m你的订阅为\e[0m"
echo
echo
echo -e "\e[32mvless://$id_s@$realip:$portx?encryption=none&security=reality&sni=$domain_s&fp=chrome&pbk=$public_old&sid=$shortIds&type=tcp&headerType=none&host=$domain_s&flow=$old_flow#xray_REALITY\e[0m"
echo 
echo 
/usr/xray/xrayhelp
systemctl start xray_service