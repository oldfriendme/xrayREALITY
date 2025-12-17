# xrayREALITY.sh

xray REALITY install script

xray REALITY协议一键安装脚本（2025-12-17）。

## 特点

* 开源安全可审查。
* 一键安装REALITY协议。
* 支持一键卸载。
* 支持一键更换uuid【如果旧的uuid泄露了】。
* 支持一键重启xray。
* 支持xray降级运行【降级为普通用户运行xray-core】。
* 买一赠一 【赠送Hysteria2协议（可选）】。
* 脚本简单易理解。
* 脚本仅从官方下载xray,不依赖任何第三方,安全可靠。
* 最新without being stolen（2024-11-9）科技。
* 单用户运行。
* 支持x86_64位,x86_32位,arm64架构

## 功能介绍

- [x] 集成快捷指令Command【xray.start, xray.stop, xray.restart, xray.chuuid, xray.delxray】
- [x] 单用户使用
- [x] 支持sni-filter模式，阻止指向cdn后被偷跑流量。
- [ ] 其他协议支持。

## 软件安装
#### 2025-12-17更新：
- 1.sni-filter模式已成熟，默认启用。
- 2.xray 更新到 v25.10.15
- 3.脚本默认运行在非root用户，如果root用户执行，会自动降权到非root。【注意：如果非root启动，添加systemd启动会失败，请手动启动，也不能绑定<1024端口】

<br>

### 一键安装

```
wget -N https://raw.githubusercontents.com/oldfriendme/xrayREALITY/main/xrayREALITY.sh && bash xrayREALITY.sh
```

<details>
<summary>旧版本</summary>
  
如果系统差异导致新脚本用不了sni-filter模式,可以尝试最旧的脚本
  
```
wget -N https://raw.githubusercontents.com/oldfriendme/xrayREALITY/main/xrayREALITY-11-17.sh && bash xrayREALITY.sh
```

</details>

## 快捷指令操作

在安装完后,可使用下列指令快速操作
```
xray.start     #启动xray
xray.stop      #停止xray
xray.restart   #重启xray
xray.chuuid    #重新生成uuid
xray.delxray   #彻底删除xray内核及脚本
xray.help      #帮助
```

</br>

## 注意事项
> [!IMPORTANT]
> 如果你的机器是双栈IP或者其他多IP，IP地址应该替换为实际入口IP
> 
> 如IPv6为`2001:4860:1234::8888`，生成的订阅为：
> 
> `vless://uuid@[2001:4860::8888]:443?encryption=none&security=reality&sni=...`
> 
> 但是入口为IPv4:`1.1.8.8`
> 
> 应该改为
> 
> `vless://uuid@1.1.8.8:443?encryption=none&security=reality&sni=...`

</br></br>

## 常见问题
### 默认内核Xray-core v25.10.15如何更换
搜索脚本”v25.10.15“关键字，修改

### 没有相应架构怎么办
脚本第87行接着加

</br>

### 脚本使用技术与模板

2024-11-17脚本使用了最新(2024-11-9)的REALITY模板进行编写
* [不会被偷跑流量的 REALITY](https://github.com/XTLS/Xray-examples/tree/main/VLESS-TCP-REALITY%20(without%20being%20stolen)) （Xray 本身就支持这种操作，这也是这个模板的原理）

* [REALITY-sni-filter模式](https://github.com/oldfriendme/REALITY-sni-filter)

* [2024-11-17默认版本Xray-core v24.11.11](https://github.com/XTLS/Xray-core/releases/tag/v24.11.11)

* [2024-11-21默认版本Xray-core v1.8.21](https://github.com/XTLS/Xray-core/releases/tag/v1.8.21)

* [2025-12-17默认版本Xray-core v25.10.15](https://github.com/XTLS/Xray-core/releases/tag/v25.10.15)
