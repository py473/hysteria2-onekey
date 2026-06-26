# Hysteria 2 One-Key Installer

[English](README-en.md) | 中文

[![Release](https://img.shields.io/github/v/release/py473/hysteria2-onekey)](https://github.com/py473/hysteria2-onekey/releases)
[![License](https://img.shields.io/github/license/py473/hysteria2-onekey)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Unix-blue)](README.md)

这是一个面向 **Linux / Unix 服务器系统** 的 Hysteria 2 一键安装脚本，适用于常见的 `systemd` 服务器环境。

**当前内置 Hysteria 2 版本：v2.9.2**（通过官方 `get.hy2.sh` 自动安装最新版）

仓库地址：<https://github.com/py473/hysteria2-onekey>

## 目录

- [支持环境](#支持环境)
- [功能](#功能)
- [在线安装](#在线安装)
- [安装说明](#安装说明)
- [示例命令](#示例命令)
- [本地运行](#本地运行)
- [安装完成后](#安装完成后)
- [v2.9.2 新功能](#v292-新功能)
- [文件说明](#文件说明)
- [更新日志](#更新日志)
- [常见问题](#常见问题)
- [FAQ](#faq)
- [支持](#支持)
- [客户端](#客户端)
- [安全](#安全)
- [行为准则](#行为准则)
- [常用命令](#常用命令)
- [注意事项](#注意事项)
- [免责声明](#免责声明)
- [许可证](#许可证)

## 支持环境

- Debian 12 / Debian 11
- Ubuntu 22.00 / 24.04
- Rocky Linux
- CentOS Stream
- Fedora

## 功能

- 一键安装 / 升级 Hysteria 2（v2.9.2）
- 交互式生成服务端配置
- 支持 ACME 自动证书
- 支持自有证书 + mTLS
- 支持自定义伪装地址
- 支持 **Salamander / Gecko 混淆**（v2.9.2 新增）
- 支持**协议嗅探 (Sniff)**
- 支持**拥塞控制算法选择**（BBR / Reno）
- 支持**服务端带宽限制**
- 支持**内置测速服务器**
- 支持 **userpass 多用户认证**
- 自动生成 v2rayN 可导入的 Hysteria2 节点信息
- 输出二维码，方便扫码导入
- 支持参数模式部署

## 在线安装

推荐直接使用下面这一条：

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

如果服务器没有 `wget`，也可以使用 `curl`：

```bash
curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/install.sh -o /tmp/hysteria2-onekey-install.sh && bash /tmp/hysteria2-onekey-install.sh
```

安装器启动后，会显示菜单，请直接在菜单里输入数字选项，不要回到 shell 提示符后再输入。

## 安装说明

- [INSTALLATION.md](INSTALLATION.md)

## 示例命令

- [EXAMPLES.md](EXAMPLES.md)

## 本地运行

```bash
cd /root/hysteria
chmod +x hy2-onekey.sh
./hy2-onekey.sh
```

查看帮助：

```bash
./hy2-onekey.sh --help
```

## 安装完成后

脚本执行完成后，通常会在服务器上生成：

- `/etc/hysteria/config.yaml`：服务端配置
- `/root/hy2-v2rayn.txt`：v2rayN 导入信息
- `/root/hy2-client.yaml`：客户端示例配置

## v2.9.2 新功能

此版本引入了多项重要功能和安全更新：

### 🔐 安全修复
- 修复 UDP 包绕过 ACL 的安全漏洞
- 修复未完成/超大的 HTTP 请求可能导致 OOM 的漏洞
- 修复域名尾随点（如 `example.com.`）绕过 ACL 的问题

### 🆕 混淆 (Obfuscation)
- **Salamander**：将每个数据包打乱为看似随机的字节
- **Gecko（实验性）**：在 Salamander 基础上，将 QUIC 握手包分片为随机大小 + 随机填充的数据报
- 启用混淆后服务器将不再兼容标准 QUIC 连接

### 🔍 协议嗅探 (Sniff)
- 支持 HTTP、TLS (HTTPS)、QUIC (HTTP/3) 协议识别
- 将 IP 请求自动转换为域名请求，配合 ACL 使用
- 可通过 `--no-sniff` 关闭

### 🚦 拥塞控制 (Congestion)
- 支持 **BBR**（默认）和 **Reno** 两种算法
- BBR 支持三种配置文件：`standard`、`conservative`、`aggressive`

### 📊 带宽限制 (Bandwidth)
- 服务端可对每客户端设置上行/下行带宽速率限制
- 支持单位：bps, kbps, mbps, gbps, tbps

### ⚡ 测速服务器 (Speed Test)
- 开启后客户端可测试与服务器的传输速度

### 👥 多用户认证
- `password`：单密码认证（默认）
- `userpass`：用户名-密码对认证

### 🔒 mTLS
- 通过 `clientCA` 配置项支持客户端证书验证

## 快速部署示例

### ACME 自动证书

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --yes
```

### ACME + Gecko 混淆

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --obfs gecko --yes
```

### 自有证书 + Salamander 混淆 + 开启嗅探

```bash
./hy2-onekey.sh --deploy --tls cert --cert /path/to/fullchain.pem --key /path/to/privkey.pem --server your.domain.com --sni your.domain.com --obfs salamander --sniff --yes
```

### 多用户认证 + 带宽限制

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --auth-type userpass --username user1 --password MyPass123 --bandwidth-up 100 mbps --bandwidth-down 100 mbps --yes
```

## 文件说明

- `install.sh`：在线安装入口
- `hy2-onekey.sh`：主安装脚本（v2.0.0）
- `README.md`：项目说明
- `README-en.md`：英文说明
- `INSTALLATION.md`：新手安装说明
- `EXAMPLES.md`：示例命令
- `RELEASE.md`：发布说明
- `DOCS.md`：文档总览
- `CHANGELOG.md`：更新日志

## 更新日志

- [CHANGELOG.md](CHANGELOG.md)

## 常见问题

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## FAQ

- [FAQ.md](FAQ.md)

## 支持

- 查看最新版本：<https://github.com/py473/hysteria2-onekey/releases>
- 排查常见问题：[TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 查看 FAQ：[FAQ.md](FAQ.md)
- 提交新问题：<https://github.com/py473/hysteria2-onekey/issues>
- 参与贡献：[CONTRIBUTING.md](CONTRIBUTING.md)

## 客户端

以下客户端可用于导入或使用 Hysteria 2 配置。下载地址请以各项目官方页面为准：

- v2rayN：<https://github.com/2dust/v2rayN>
- Clash.Meta：<https://github.com/MetaCubeX/Clash.Meta>
- sing-box：<https://github.com/SagerNet/sing-box>
- Hiddify Next：<https://github.com/hiddify/hiddify-next>
- NekoBox for Android：<https://github.com/MatsuriDayo/NekoBoxForAndroid>
- V2Box：<https://apps.apple.com/app/v2box-v2ray-client/id6446814690>

更多支持 Hysteria 2 的第三方应用，请参考官方列表：

- <https://v2.hysteria.network/zh/docs/getting-started/3rd-party-apps/>

## 安全

如果你发现与本项目相关的安全问题，请优先通过 GitHub Security Advisories 或私下联系维护者，不要直接公开敏感细节。

- 安全说明：[SECURITY.md](SECURITY.md)

## 行为准则

- 社区行为准则：[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## 常用命令

- 新手安装说明：[INSTALLATION.md](INSTALLATION.md)
- 示例命令：[EXAMPLES.md](EXAMPLES.md)

## 注意事项

- 本脚本仅面向 Linux / Unix 服务器，不支持 Windows。
- Hysteria 2 服务端通常需要放行 `UDP 443`。
- 如果使用 ACME 证书，请确保域名已解析到 VPS。
- 伪装地址支持直接输入域名，脚本会自动补全 `https://`。
- 启用混淆后，服务器将不再兼容标准 QUIC/HTTP/3 连接。
- 如果你使用 UFW，请先安装 `ufw`，并放行 `443/udp` 与 `443/tcp`。

## 免责声明

请仅在你有权限管理的服务器上使用本脚本，并遵守当地法律法规及服务提供商政策。

## 许可证

本项目采用 MIT License，详见 [LICENSE](LICENSE)。
