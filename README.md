# Hysteria 2 One-Key Installer

[English](README-en.md) | 中文

[![Release](https://img.shields.io/github/v/release/py473/hysteria2-onekey)](https://github.com/py473/hysteria2-onekey/releases)
[![License](https://img.shields.io/github/license/py473/hysteria2-onekey)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Unix-blue)](README.md)

一个面向 **Linux / Unix 服务器系统** 的 Hysteria 2 一键安装管理脚本，适用于常见的 `systemd` 服务器环境。

**通过官方 `get.hy2.sh` 自动安装最新版 Hysteria 2**

仓库地址：<https://github.com/py473/hysteria2-onekey>

---

## 为什么选择这个脚本？

本脚本经历了 **27 项以上深度 Bug 修复与安全审计**，与市面上其他一键脚本相比，拥有以下独特优势：

| 特性 | 本脚本 |
|------|--------|
| **nftables/iptables 自适应** | 先测试 nftables 可用性，失败自动降级 iptables，容器/老旧系统均不崩溃 |
| **订阅文件安全** | 生成 `sub_{UUID}.txt` 随机文件名，彻底杜绝公网爆破风险 |
| **userpass 全面支持** | URI / 客户端配置 / 订阅文件全部正确生成 userpass 格式 |
| **系统性能优化** | 自动调优系统缓冲区、BBR 拥塞控制、进程优先级、连接数上限 |
| **端口跳跃** | 支持 nftables 多端口组合 + iptables 回退，真正的可用端口跳跃 |
| **YAML 注入防护** | 所有用户输入写入配置文件时均经过双引号包裹 + 特殊字符清理 |
| **离线部署友好** | 依赖缺失时给出精准的系统对应安装命令（apt / yum） |
| **ACME + 自签名双模式** | 域名用户自动获取 Let's Encrypt 证书；无域名用户支持自签名 + insecure |

---

## 支持环境

- Debian 11 / Debian 12
- Ubuntu 20.04 / 22.04 / 24.04
- Rocky Linux 8+
- CentOS Stream 8+
- Fedora 37+

---

## 功能

- 一键安装 / 升级 Hysteria 2（通过官方 `get.hy2.sh` 自动获取最新版）
- 交互式生成服务端配置（完整提示所有高级功能）
- 支持 ACME 自动证书（域名部署）
- 支持自签名证书 + mTLS（IP 部署）
- 支持自定义伪装地址
- 支持 **Salamander / Gecko 混淆**
- 支持 **协议嗅探 (Sniff)**
- 支持 **拥塞控制算法选择**（BBR / Reno）
- 支持 **服务端带宽限制**
- 支持 **内置测速服务器**
- 支持 **端口跳跃 (Port Hopping)** — 自动 nftables/iptables 规则
- 支持 **环境变量配置**（日志级别、禁用更新检查）
- 支持 **userpass 多用户认证**
- 自动生成 v2rayN 可导入的 Hysteria2 节点信息（UUID 随机文件名，防爆破）
- 输出二维码，方便扫码导入
- 支持参数模式部署（`--deploy`）
- **Linux 性能自动优化**：系统缓冲区调优、BBR 拥塞控制、QUIC 流控制窗口

---

## 快速开始

### 方式一：通过 install.sh 引导安装（推荐）

```bash
bash <(curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/install.sh)
```

### 方式二：直接运行主脚本

```bash
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh && bash /tmp/hy2-onekey.sh
```

脚本启动后会显示菜单，输入数字选项操作。

---

## 命令行一键部署

### 域名部署（推荐，自动 HTTPS 证书）

```bash
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh
chmod +x /tmp/hy2-onekey.sh

/tmp/hy2-onekey.sh --deploy \
  --tls acme \
  --domain hy2.yourdomain.com \
  --email admin@yourdomain.com \
  --yes
```

### IP 部署（无域名，自签名证书）

```bash
/tmp/hy2-onekey.sh --deploy \
  --tls cert \
  --cert /etc/hysteria/server.crt \
  --key /etc/hysteria/server.key \
  --server 你的VPS_IP \
  --insecure \
  --yes
```

> ⚠️ IP 部署完成后，在客户端必须开启「跳过证书验证（Allow Insecure）」。

### 其他参数组合

```bash
# 带 Gecko 混淆 + 嗅探 + 测速
/tmp/hy2-onekey.sh --deploy --tls acme --domain hy2.yourdomain.com --email admin@yourdomain.com --obfs gecko --sniff --speed-test --yes

# 多用户 + 带宽限制
/tmp/hy2-onekey.sh --deploy --tls acme --domain hy2.yourdomain.com --email admin@yourdomain.com --auth-type userpass --username user1 --password MyPass123 --bandwidth-up 100 mbps --bandwidth-down 100 mbps --yes

# 开启端口跳跃
/tmp/hy2-onekey.sh --deploy --tls acme --domain hy2.yourdomain.com --email admin@yourdomain.com --port-hopping 20000-50000 --yes
```

---

## 菜单功能说明

| 编号 | 功能 | 说明 |
|------|------|------|
| 1 | 一键安装/升级 + 交互式生成配置 + 启动服务 | 完整的交互式部署流程 |
| 2 | 仅重启服务 | 重启 hysteria-server 服务 |
| 3 | 卸载 Hysteria 2 | 完全卸载（含订阅服务、nftables 规则清理） |
| 4 | 显示订阅链接 / 快捷命令信息 | 显示 HTTP 订阅 URL 和常用命令 |
| 5 | 重新生成订阅文件 | 基于当前服务端配置重新生成（密码不变） |
| 0 | 退出 | 退出脚本 |

---

## 安装完成后

脚本执行完成后，服务器上会生成：

| 文件 | 说明 |
|------|------|
| `/etc/hysteria/config.yaml` | 服务端主配置（已自动性能优化） |
| `/root/sub_xxxx-xxxx-xxxx.txt` | v2rayN 导入信息（UUID 随机文件名） |
| `/root/hy2-client.yaml` | 客户端配置示例 |
| `/etc/sysctl.d/99-hysteria-network.conf` | 系统缓冲区优化（持久化） |
| `/etc/systemd/system/hysteria-server.service.d/priority.conf` | 进程优先级优化 |

---

## 订阅服务安全说明

本脚本的 HTTP 订阅服务使用 **UUID 随机文件名**（`sub_{UUID}.txt`），而不是固定的文件名。这意味着：

- ✅ 即使别人知道你的服务器 IP 和端口，也无法猜测订阅文件 URL
- ✅ 每次部署生成的 UUID 不同，历史文件自动失效
- ✅ 订阅服务仅暴露 `/etc/hysteria/subs/` 目录下的文件，不暴露 `/root/` 等其他目录

---

## 注意事项

- 本脚本仅面向 Linux / Unix 服务器，不支持 Windows
- Hysteria 2 服务端通常需要放行 **UDP 443** 端口
- 如果使用 ACME 证书，请确保域名已解析到 VPS（Cloudflare 必须关闭代理）
- IP 部署用户必须在客户端开启 **跳过证书验证（Allow Insecure）**
- 伪装地址支持直接输入域名，脚本会自动补全 `https://`
- 启用混淆后，服务器将不再兼容标准 QUIC/HTTP/3 连接
- 如果你使用 UFW，请先安装 `ufw`，并放行 `443/udp`

---

## 免责声明

请仅在你有权限管理的服务器上使用本脚本，并遵守当地法律法规及服务提供商政策。

## 许可证

本项目采用 MIT License，详见 [LICENSE](LICENSE)。
