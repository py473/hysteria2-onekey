# Hysteria 2 One-Key Installer

这是一个面向 **Linux / Unix 服务器系统** 的 Hysteria 2 一键安装脚本，适用于常见的 `systemd` 服务器环境。

仓库地址：<https://github.com/py473/hysteria2-onekey>

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
wget -qO- https://github.com/py473/hysteria2-onekey/raw/main/install.sh | bash
```

如果服务器没有 `wget`，也可以使用 `curl`：

```bash
curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/install.sh | bash
```

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

## 文件说明

- `install.sh`：在线安装入口
- `hy2-onekey.sh`：主安装脚本
- `README.md`：项目说明

## 注意事项

- 本脚本仅面向 Linux / Unix 服务器，不支持 Windows。
- Hysteria 2 服务端通常需要放行 `UDP 443`。
- 如果使用 ACME 证书，请确保域名已解析到 VPS。
- 伪装地址支持直接输入域名，脚本会自动补全 `https://`。

## 免责声明

请仅在你有权限管理的服务器上使用本脚本，并遵守当地法律法规及服务提供商政策。

## 许可证

本项目采用 MIT License，详见 [LICENSE](LICENSE)。
