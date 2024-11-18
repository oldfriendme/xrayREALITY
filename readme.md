# xrayREALITY.sh

xray REALITY install script

xray REALITY协议一键安装脚本（2024-11-17）。

## 特点

* 开源安全可审查。
* 一键安装REALITY协议。
* 支持一键卸载。
* 支持一键更换uuid【如果旧的uuid泄露了】。
* 支持一键重启xray。
* 支持xray降级运行【降级为普通用户运行xray-core】。
* 脚本加上注释只有100行左右,简单高效。
* 脚本仅从官方下载xray,不依赖任何第三方,安全可靠。
* 最新without being stolen（2024-11-9）科技。
* 单用户运行。
* 支持x86_64位,x86_32位,arm64架构

## 功能介绍

- [x] 集成快捷指令Command【xray.start, xray.stop, xray.restart, xray.chuuid, xray.delxray】
- [x] 单用户使用
- [ ] 其他协议支持

## 软件安装
注意，脚本构造简单。只支持REALITY协议，不支持其他协议


### 一键安装

```
wget -N https://raw.githubusercontents.com/oldfriendme/xrayREALITY/main/xrayREALITY.sh && bash xrayREALITY.sh
```

## 快捷指令操作

在安装完后,可使用下列指令快速操作
```
xray.start #启动xray
xray.stop  #停止xray
xray.restart #重启xray
xray.chuuid #重新生成uuid
xray.delxray #彻底删除xray内核及脚本
```

</br>

## 注意事项
> [!IMPORTANT]
> 脚本自动生成的订阅对纯IPv6的格式处理有问题,请手动添加`[]`
> 
> 如IPv6为`2001:4860:1234::8888`，生成的订阅为：
> 
> `vless://uuid@2001:4860:1234::8888:443?encryption=none&security=reality&sni=...`
> 
> IPv6 `2001:4860:1234::8888`的前后
> 
> 应该添加`[]`
> 
> `vless://uuid@[2001:4860::8888]:443?encryption=none&security=reality&sni=...`

其他注意事项：如果你的机器是双栈IP或者其他多IP，IP地址应该替换为实际入口IP

</br></br>

## 常见问题
### 默认内核Xray-core v24.11.11如何更换
脚本第54行修改

### 没有相应架构怎么办
脚本第61行接着加

</br>

### 脚本使用技术与模板

脚本使用了最新(2024-11-9)的REALITY模板进行编写
* [不会被偷跑流量的 REALITY](https://github.com/XTLS/Xray-examples/tree/main/VLESS-TCP-REALITY%20(without%20being%20stolen)) （Xray 本身就支持这种操作，这也是这个模板的原理）

* [默认版本Xray-core v24.11.11](https://github.com/XTLS/Xray-core/releases/tag/v24.11.11)
