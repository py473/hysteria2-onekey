# Hysteria 2 One-Key Installer v2.0.0

## What's New

- 升级 Hysteria 2 至 v2.9.2（重要安全修复 + 新功能）
- 新增 **Gecko 混淆**：QUIC 握手包分片和随机填充（实验性）
- 新增 **Salamander 混淆**：数据包随机字节伪装
- 新增 **协议嗅探 (Sniff)**：支持 HTTP/TLS/QUIC 协议识别
- 新增 **拥塞控制算法**：BBR / Reno，BBR 支持三种配置文件
- 新增 **带宽限制**：服务器端每客户端上下行速率限制
- 新增 **内置测速** `speedTest` 配置
- 新增 **多用户认证** `userpass` 认证类型
- 新增 **mTLS** 通过 `clientCA` 配置项
- 新增 **SNI 验证模式** `sniGuard`
- `install.sh` 升级至 v2.0.0
- 交互式菜单新增混淆方式选择步骤
- 文档全面更新覆盖所有 v2.9.2 新功能

## Installation

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

## Notes

- This project is for Linux / Unix server systems only.
- Hysteria 2 server traffic usually requires UDP 443 to be open.
- If you use ACME certificates, make sure the domain resolves to your VPS.
- Enabling obfuscation makes the server incompatible with standard QUIC/HTTP/3 connections.

## Repository

<https://github.com/py473/hysteria2-onekey>
