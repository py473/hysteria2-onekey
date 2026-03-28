# Hysteria 2 One-Key Installer

[English](README-en.md) | 中文

[![Release](https://img.shields.io/github/v/release/py473/hysteria2-onekey)](https://github.com/py473/hysteria2-onekey/releases)
[![License](https://img.shields.io/github/license/py473/hysteria2-onekey)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Unix-blue)](README.md)

这是一个面向 **Linux / Unix 服务器系统** 的 Hysteria 2 一键安装脚本，适用于常见的 `systemd` 服务器环境。

仓库地址：<https://github.com/py473/hysteria2-onekey>

## 目录

- [支持环境](#支持环境)
- [功能](#功能)
- [在线安装](#在线安装)
- [安装说明](#安装说明)
- [示例命令](#示例命令)
- [本地运行](#本地运行)
- [安装完成后](#安装完成后)
- [文件说明](#文件说明)
- [更新日志](#更新日志)
- [常见问题](#常见问题)
- [FAQ](#faq)
- [支持](#支持)
- [安全](#安全)
- [行为准则](#行为准则)
- [常用命令](#常用命令)
- [注意事项](#注意事项)
- [免责声明](#免责声明)
- [许可证](#许可证)

## 支持环境

- Debian 12 / Debian 11
- Ubuntu 22.04 / 24.04
- Rocky Linux
- CentOS Stream
- Fedora

## 功能

- 一键安装 / 升级 Hysteria 2
- 交互式生成服务端配置
- 支持 ACME 自动证书
- 支持自有证书
- 支持自定义伪装地址
- 自动生成 v2rayN 可导入的 Hysteria2 节点信息
- 输出二维码，方便扫码导入
- 支持参数模式部署
- 提供在线一键安装入口

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

## 快速部署示例

### ACME 自动证书

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --yes
```

### 自有证书

```bash
./hy2-onekey.sh --deploy --tls cert --cert /path/to/fullchain.pem --key /path/to/privkey.pem --server your.domain.com --sni your.domain.com --yes
```

## 文件说明

- `install.sh`：在线安装入口
- `hy2-onekey.sh`：主安装脚本
- `README.md`：项目说明
- `README-en.md`：英文说明
- `INSTALLATION.md`：新手安装说明
- `EXAMPLES.md`：示例命令
- `DOCS.md`：文档总览

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
- 如果你使用 UFW，请先安装 `ufw`，并放行 `443/udp` 与 `443/tcp`。

## 免责声明

请仅在你有权限管理的服务器上使用本脚本，并遵守当地法律法规及服务提供商政策。

## 许可证

本项目采用 MIT License，详见 [LICENSE](LICENSE)。
