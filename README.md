# Hysteria 2 一键安装脚本

这是一个面向 **Linux / Unix 服务器系统** 的 Hysteria 2 一键部署脚本，适用于常见的 `systemd` 服务器环境，例如：

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

## 使用方式

```bash
cd /root/hysteria
chmod +x hy2-onekey.sh
./hy2-onekey.sh
```

如果想直接参数部署，可以先查看帮助：

```bash
./hy2-onekey.sh --help
```

## 说明

- 本脚本仅面向 Linux / Unix 服务器，不支持 Windows。
- Hysteria 2 服务端通常需要放行 `UDP 443`。
- 如果使用 ACME 证书，请确保域名已解析到 VPS。

## 文件说明

- `hy2-onekey.sh`：主安装脚本
- `README.md`：项目说明

## 免责声明

请仅在你有权限管理的服务器上使用本脚本，并遵守当地法律法规及服务提供商政策。
