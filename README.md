# Hysteria 2 One-Key Installer

[English](README-en.md) | 中文

[![Release](https://img.shields.io/github/v/release/py473/hysteria2-onekey)](https://github.com/py473/hysteria2-onekey/releases)
[![License](https://img.shields.io/github/license/py473/hysteria2-onekey)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Unix-blue)](README.md)

这是一个面�?**Linux / Unix 服务器系�?* �?Hysteria 2 一键安装脚本，适用于常见的 `systemd` 服务器环境�?
**当前内置 Hysteria 2 版本：v2.9.2**（通过官方 `get.hy2.sh` 自动安装最新版�?
仓库地址�?https://github.com/py473/hysteria2-onekey>

## 目录

- [支持环境](#支持环境)
- [功能](#功能)
- [快速开始](#快速开�?
- [保姆级教程](#保姆级教�?
- [常用命令示例](#常用命令示例)
- [安装完成后](#安装完成�?
- [v2.9.2 新功能](#v292-新功�?
- [注意事项](#注意事项)
- [免责声明](#免责声明)
- [许可证](#许可�?

## 支持环境

- Debian 12 / Debian 11
- Ubuntu 22.04 / 24.04
- Rocky Linux
- CentOS Stream
- Fedora

## 功能

- 一键安�?/ 升级 Hysteria 2（v2.9.2�?- 交互式生成服务端配置
- 支持 ACME 自动证书
- 支持自有证书 + mTLS
- 支持自定义伪装地址
- 支持 **Salamander / Gecko 混淆**（v2.9.2 新增�?- 支持**协议嗅探 (Sniff)**
- 支持**拥塞控制算法选择**（BBR / Reno�?- 支持**服务端带宽限�?*
- 支持**内置测速服务器**
- 支持 **userpass 多用户认�?*
- 自动生成 v2rayN 可导入的 Hysteria2 节点信息
- 输出二维码，方便扫码导入
- 支持参数模式部署
- **Linux 性能自动优化**：系统缓冲区调优、进程实时优先级、QUIC 流控制窗�?
## 快速开�?
推荐直接使用下面这一条命令：

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

如果服务器没�?`wget`，也可以使用 `curl`�?
```bash
curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/install.sh -o /tmp/hysteria2-onekey-install.sh && bash /tmp/hysteria2-onekey-install.sh
```

安装器启动后，会显示菜单，请直接在菜单里输入数字选项�?
## 保姆级教�?
如果你是完全新手，或者需要从零开始的详细步骤，请阅读�?
📘 [**GUIDE.md �?Hysteria 2 一键部署保姆级教程**](GUIDE.md)

教程覆盖�?- VPS 准备�?SSH 连接
- 一键交互式部署（每一步截图式说明�?- 命令行模式部署（参数详解�?- v2rayN 客户端连接设�?- 日常管理命令
- 常见问题排错

## 常用命令示例

### 交互式部�?
```bash
# 下载主脚�?wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh
chmod +x /tmp/hy2-onekey.sh

# 运行交互式菜�?/tmp/hy2-onekey.sh
```

### 命令行一键部�?
```bash
# ACME 自动证书（推荐）
/tmp/hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --yes

# ACME + Gecko 混淆 + 嗅探 + 测�?/tmp/hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --obfs gecko --sniff --speed-test --yes

# 自有证书
/tmp/hy2-onekey.sh --deploy --tls cert --cert /path/to/fullchain.pem --key /path/to/privkey.pem --server your.domain.com --yes

# 多用�?+ 带宽限制
/tmp/hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --auth-type userpass --username user1 --password MyPass123 --bandwidth-up 100 mbps --bandwidth-down 100 mbps --yes
```

### 其他操作

```bash
# 查看帮助
/tmp/hy2-onekey.sh --help

# 重启服务
/tmp/hy2-onekey.sh --restart

# 卸载
/tmp/hy2-onekey.sh --remove
```

完整参数说明�?[GUIDE.md](GUIDE.md#第四章命令行模式部署更快)�?
## 安装完成�?
脚本执行完成后，服务器上会生成：

| 文件 | 说明 |
|------|------|
| `/etc/hysteria/config.yaml` | 服务端主配置（已自动性能优化�?|
| `/root/hy2-v2rayn.txt` | v2rayN 导入信息（复�?URI 即可�?|
| `/root/hy2-client.yaml` | 客户端配置示�?|
| `/etc/sysctl.d/99-hysteria.conf` | 系统缓冲区优化（持久化） |
| `/etc/systemd/system/hysteria-server.service.d/priority.conf` | 进程优先级优化（持久化） |

## v2.9.2 新功�?
此版本引入了多项重要功能和安全更新：

### 🔐 安全修复
- 修复 UDP 包绕�?ACL 的安全漏�?- 修复未完�?超大�?HTTP 请求可能导致 OOM 的漏�?- 修复域名尾随点绕�?ACL 的问�?
### 🆕 混淆 (Obfuscation)
- **Salamander**：将每个数据包打乱为看似随机的字�?- **Gecko（实验性）**：在 Salamander 基础上，�?QUIC 握手包分片为随机大小 + 随机填充的数据报
- 启用混淆后服务器将不再兼容标�?QUIC 连接

### 🔍 协议嗅探 (Sniff)
- 支持 HTTP、TLS (HTTPS)、QUIC (HTTP/3) 协议识别
- �?IP 请求自动转换为域名请求，配合 ACL 使用

### 🚦 拥塞控制 (Congestion)
- 支持 **BBR**（默认）�?**Reno** 两种算法
- BBR 支持三种配置文件：`standard`、`conservative`、`aggressive`

### 📊 带宽限制 (Bandwidth)
- 服务端可对每客户端设置上�?下行带宽速率限制
- 支持单位：bps, kbps, mbps, gbps, tbps

### �?测速服务器 (Speed Test)
- 开启后客户端可测试与服务器的传输速度

### 👥 多用户认�?- `password`：单密码认证（默认）
- `userpass`：用户名-密码对认�?
### 🔒 mTLS
- 通过 `clientCA` 配置项支持客户端证书验证

## 注意事项

- 本脚本仅面向 Linux / Unix 服务器，不支�?Windows�?- Hysteria 2 服务端通常需要放�?**UDP 443** 端口�?- 如果使用 ACME 证书，请确保域名已解析到 VPS�?- 伪装地址支持直接输入域名，脚本会自动补全 `https://`�?- 启用混淆后，服务器将不再兼容标准 QUIC/HTTP/3 连接�?- 如果你使�?UFW，请先安�?`ufw`，并放行 `443/udp` �?`443/tcp`�?
## 免责声明

请仅在你有权限管理的服务器上使用本脚本，并遵守当地法律法规及服务提供商政策�?
## 许可�?
本项目采�?MIT License，详�?[LICENSE](LICENSE)�?
