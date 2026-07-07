# Hysteria 2 一键部署保姆级教程

> 对应脚本版本：hy2-onekey.sh v2.1.1（1871 行终极稳定版）
> 本文档面向**完全新手**，只要跟着每一步操作就能部署成功。

---

## 📖 目录

- [第一章：准备工作](#第一章准备工作)
- [第二章：连接 VPS](#第二章连接-vps)
- [第三章：核心分流 — IP 部署 vs 域名部署](#第三章核心分流--ip-部署-vs-域名部署)
- [第四章：一键安装部署（逐屏教学）](#第四章一键安装部署逐屏教学)
- [第五章：命令行模式部署（快速）](#第五章命令行模式部署快速)
- [第六章：客户端连接（v2rayN）](#第六章客户端连接v2rayn)
- [第七章：日常管理](#第七章日常管理)
- [第八章：常见问题](#第八章常见问题)

---

## 第一章：准备工作

### 1.1 你需要准备的东西

| 项目 | 说明 | 备注 |
|------|------|------|
| **一台 VPS** | Linux 系统（推荐 Debian 11+ / Ubuntu 20.04+） | 任意云服务商 |
| **一个域名（可选）** | 用于自动申请 HTTPS 证书 | **没有域名也能部署！** 见第三章 |
| **SSH 客户端** | 用来连接 VPS | Windows 用 Terminal / Xshell / PuTTY |

### 1.2 SSH 连接 VPS

**Windows 11 / 10 自带方式（推荐）：**

按 `Win + R` → 输入 `powershell` 回车 → 执行：
```powershell
ssh root@你的VPS_IP
```

**用 PuTTY：**
1. Host Name 填：`root@你的VPS_IP`
2. Port: `22`
3. 点 Open → 提示点「接受」→ 输入密码

> ✅ 连接成功后你会看到 `root@your-vps:~#` 的提示符。

### 1.3 更新系统

```bash
# Debian / Ubuntu
apt update && apt upgrade -y

# CentOS / Rocky Linux
yum update -y
```

### 1.4 安装必要工具

```bash
# Debian / Ubuntu
apt install -y curl wget

# CentOS / Rocky
yum install -y curl wget
```

### 1.5 放行防火墙（非常重要）

**VPS 内部防火墙：**
```bash
ufw allow 443/udp
ufw allow 18989/tcp
ufw reload
```

**云服务商安全组：** 登录你的云控制台（阿里云/腾讯云/搬瓦工等），在「安全组 / 防火墙」中添加：
- 入站规则：**UDP 443**（来源：`0.0.0.0/0`）
- 入站规则：**TCP 18989**（订阅 HTTP 服务，可选）

---

## 第二章：连接 VPS

### 2.1 获取 VPS 信息

在你的云服务商控制台找到：
- **公网 IP**（如 `203.0.113.1`）
- **用户名**（通常是 `root`）
- **密码** 或 **SSH 密钥**

### 2.2 验证连接

```bash
ssh root@你的VPS_IP
```

输入密码（输入时不会显示，这是正常的）后回车。看到 `root@your-vps:~#` 就成功了。

---

## 第三章：核心分流 — IP 部署 vs 域名部署

> ⚠️ **在运行脚本之前，请先确定你属于哪种情况。** 两种方式脚本都支持，但后续操作有区别。

---

### 路径 A：纯 VPS IP 部署（适合无域名用户）

#### 适用场景

- 你没有域名，或不想买域名
- 想快速部署先用上

#### 原理说明

IP 部署模式下，脚本会使用**自签名证书**。自签名证书不是由受信任的证书机构颁发的，所以客户端连接时必须**手动跳过证书验证**，否则节点完全无法联网。

#### ⚠️ 客户端必须设置

部署完成后，在 v2rayN / Clash 中导入节点后，**必须开启「跳过证书验证（Allow Insecure / skip-cert-verify: true）」**。

> 🔴 **不开启此选项 = 节点不通！**

#### 防火墙要求

确保 VPS 厂商控制台的安全组已放行：
- **UDP 443**

#### IP 部署推荐一键命令

```bash
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh
chmod +x /tmp/hy2-onekey.sh
/tmp/hy2-onekey.sh --deploy \
  --tls cert \
  --cert /etc/hysteria/server.crt \
  --key /etc/hysteria/server.key \
  --server 你的VPS_IP \
  --insecure \
  --yes
```

---

### 路径 B：域名部署（适合有域名、追求高安全性用户）

#### 适用场景

- 你有一个域名（如 `yourdomain.com`）
- 你想要正规的 HTTPS 证书，更安全

#### 步骤 1：域名解析

登录你的域名管理后台（Cloudflare / 阿里云 / Namecheap 等），添加一条 **A 记录**：

```
记录类型：A
主机记录：hy2（或你想要的子域名，如 vpn、proxy）
记录值：你的 VPS 公网 IP
TTL：自动或 600
```

> ⚠️ **Cloudflare 用户特别注意！** 必须关闭代理（小云朵），保持「仅限 DNS（DNS Only）」—— 图标应为灰色。Hysteria 2 基于 UDP，CDN 代理会导致连接失败！

#### 步骤 2：验证解析

```bash
ping hy2.yourdomain.com
```
返回的 IP 是你 VPS 的 IP 即为成功（需等待几分钟）。

#### 步骤 3：准备邮箱

脚本在申请 Let's Encrypt 免费证书时需要用到邮箱。准备一个常用邮箱（如 `admin@yourdomain.com`）。

---

## 第四章：一键安装部署（逐屏教学）

### 4.1 下载并运行脚本

```bash
# 方式一（推荐）：
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh && bash /tmp/hy2-onekey.sh

# 方式二（curl）：
curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh -o /tmp/hy2-onekey.sh && bash /tmp/hy2-onekey.sh
```

### 4.2 主菜单

```
==================================================
HY2 一键安装脚本（Linux 服务器）v2.1.1
基于 Hysteria 2 官方文档安装方式（get.hy2.sh）
==================================================
1) 一键安装/升级 + 交互式生成配置 + 启动服务
2) 仅重启服务
3) 卸载 Hysteria 2
4) 显示订阅链接 / 快捷命令信息
5) 重新生成订阅文件（基于当前配置）
0) 退出
```

输入 **`1`** 回车。

### 4.3 选择 TLS 证书方式

```
请选择 TLS 证书方式：
  1) ACME 自动证书（推荐，需域名）
  2) 自有证书
请输入选项 [1-2，默认 1]:
```

- **有域名（路径 B）：** 输入 `1` 回车 ✅
- **IP 部署（路径 A）：** 输入 `2` 回车 ✅

### 4.4 选择认证方式

```
请选择认证方式：
  1) 单密码认证（简单，推荐）
  2) 用户名-密码认证（多用户）
请输入选项 [1-2，默认 1]:
```

直接回车（选 1）。

### 4.5 混淆方式

```
请选择混淆方式 v2.9.3：
  0) 不启用混淆（保持标准 HTTP/3 外观）
  1) Salamander
  2) Gecko（实验性）
请输入选项 [0-2，默认 0]:
```

直接回车（不启用）。

### 4.6 协议嗅探 / 测速 / 拥塞控制

依次出现以下提示，全部直接回车（使用默认值）：

```
是否启用协议嗅探 (Sniff)？[默认 1]
是否启用内置测速服务器？[默认 0]
请选择拥塞控制算法：[默认 1]
是否要设置服务端带宽限制？[默认 0]
是否启用端口跳跃？[默认 0]
```

### 4.7 ⚠️ 关键分歧点：域名 vs IP

#### 如果你有域名（路径 B）

```
请输入你的域名（需已解析到 VPS）:
```
输入 `hy2.yourdomain.com` 回车。

```
请输入 ACME 邮箱:
```
输入 `admin@yourdomain.com` 回车。

#### 如果你用 IP 部署（路径 A）

脚本会提示输入证书路径。推荐直接用 **第四章的命令行模式**（`--deploy` 带 `--insecure` 参数），这样可以跳过证书相关的交互问题。

### 4.8 监听端口

```
请输入监听端口 [默认: 443]:
```
直接回车（推荐 443）。

### 4.9 伪装地址

```
请选择是否开启伪装（Masquerade）：
  1) 开启（推荐）
  2) 关闭
请输入选项 [1-2，默认 1]:
```
直接回车。然后输入伪装地址：
```
请输入你想伪装成的网站地址（例如 www.bing.com）:
```
输入 `www.bing.com` 回车。

### 4.10 证书校验方式

```
证书校验方式：
  1) 正常校验（推荐，适用于 ACME 或受信任证书）
  2) 忽略证书校验（适用于自签名证书，v2rayN 常用）
请输入选项 [1-2，默认 1]:
```

- **域名部署：** 直接回车 ✅
- **IP 部署：** 输入 `2` 回车 ✅（忽略校验）

### 4.11 安装成功输出示例

```
[OK] 部署完成。
--------------------------------------------------
服务配置文件: /etc/hysteria/config.yaml
客户端示例文件: /root/hy2-client.yaml
认证密码: xxxxxx
连接地址: hy2.yourdomain.com:443
SNI: hy2.yourdomain.com
TLS 校验: false
伪装地址: https://www.bing.com
分享 URI: hysteria2://xxxxxx@hy2.yourdomain.com:443/?sni=xxx#HY2
--------------------------------------------------
订阅服务：
  v2rayN / v2rayNG:  http://你的IP:18989/sub_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.txt
--------------------------------------------------
```

> 🔒 **注意：** 订阅文件名为 **随机 UUID 格式**（`sub_xxxx-xxxx-xxxx.txt`），防止公网随意下载你的配置。

---

## 第五章：命令行模式部署（快速）

### 5.1 域名部署一键命令

```bash
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh
chmod +x /tmp/hy2-onekey.sh

/tmp/hy2-onekey.sh --deploy \
  --tls acme \
  --domain hy2.yourdomain.com \
  --email admin@yourdomain.com \
  --yes
```

### 5.2 IP 部署一键命令

```bash
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh
chmod +x /tmp/hy2-onekey.sh

/tmp/hy2-onekey.sh --deploy \
  --tls cert \
  --cert /etc/hysteria/server.crt \
  --key /etc/hysteria/server.key \
  --server 你的VPS_IP \
  --insecure \
  --yes
```

### 5.3 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| `--deploy` | 直接部署模式 | 必须 |
| `--tls acme` | ACME 自动证书 | `acme` / `cert` |
| `--domain` | 域名 | `hy2.yourdomain.com` |
| `--email` | ACME 邮箱 | `admin@yourdomain.com` |
| `--password` | 指定密码（留空自动生成） | `MyPass123` |
| `--listen-port` | 监听端口 | `443` |
| `--server` | 客户端连接地址（IP 部署必填） | `你的VPS_IP` |
| `--insecure` | 跳过证书校验（IP 部署用） | 无参数值 |
| `--yes` | 跳过确认直接执行 | 无参数值 |
| `--obfs gecko` | 启用混淆 | `salamander`/`gecko`/`off` |
| `--sniff` | 启用嗅探 | 无参数值 |
| `--port-hopping` | 端口跳跃范围 | `20000-50000` |
| `--auth-type userpass` | 多用户认证 | `password`/`userpass` |
| `--username` | 用户名（配合 userpass） | `user1` |
| `--bandwidth-up` | 上行带宽限制 | `100 mbps` |
| `--bandwidth-down` | 下行带宽限制 | `100 mbps` |
| `--congestion bbr` | 拥塞控制 | `bbr`/`reno` |
| `--log-level` | 日志级别 | `debug`/`info`/`warn`/`error` |

---

## 第六章：客户端连接（v2rayN）

### 6.1 获取订阅链接

在 VPS 上执行：
```bash
hy2 --sub-urls
```

输出示例：
```
  v2rayN / v2rayNG:  http://你的VPS_IP:18989/sub_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.txt
```

> 🔒 **安全说明：** 订阅文件名为随机 UUID 格式，无法被暴力破解。这是最新版本的安全增强设计。

### 6.2 下载 v2rayN

1. 去 https://github.com/2dust/v2rayN/releases 下载最新版
2. 下载 `v2rayN-With-Core.zip`
3. 解压到 `D:\v2rayN`

### 6.3 添加节点

**方法一：通过订阅链接（推荐）**

1. v2rayN → 服务器 → 订阅设置 → 添加
2. 粘贴上面的订阅 URL → 备注填 `HY2`
3. 右键托盘图标 → 更新订阅（不通过代理）

**方法二：通过 URI**

1. 在 VPS 上执行：
   ```bash
   cat /root/sub_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.txt
   ```
2. 复制 `hysteria2://...` 开头的整行
3. v2rayN → 服务器 → 从剪贴板导入

### 6.4 ⚠️ IP 部署用户必须做

添加节点后：
1. 右键节点 → 编辑
2. **勾选「允许不安全的连接（Allow Insecure）」** 🔴
3. 确认核心类型为 **sing-box**
4. 点确定

> **不勾选此选项，节点完全无法上网！**

### 6.5 设置核心类型

1. 右键节点 → 核心类型 → **sing-box**
2. 右键节点 → 设为活动服务器
3. 右下角图标 → 系统代理 → 开启

### 6.6 测试

打开浏览器访问 https://www.google.com，能打开就成功了！

---

## 第七章：日常管理

### 查看服务状态
```bash
systemctl status hysteria-server.service
```

### 查看实时日志
```bash
journalctl --no-pager -e -u hysteria-server.service -f
```

### 重启服务
```bash
systemctl restart hysteria-server.service
```

### 使用快捷命令
```bash
hy2
```
输入 `hy2` 调出管理菜单。

### 重新生成订阅文件
```bash
hy2 --gen-subs
```

### 查看订阅 URL
```bash
hy2 --sub-urls
```

### 查看客户端示例配置
```bash
cat /root/hy2-client.yaml
```

### 更新 Hysteria 2
```bash
bash <(curl -fsSL https://get.hy2.sh/)
```

### 完全卸载
```bash
hy2 --remove
```

---

## 第八章：常见问题

### Q1：部署后服务启动失败

```bash
journalctl --no-pager -e -u hysteria-server.service
```

**常见原因：**
- 端口被占用：`ss -tulpn | grep 443`
- 防火墙未放行：`ufw status` 确认 UDP 443 已放行
- ACME 证书失败：检查域名是否正确解析到 VPS

### Q2：域名部署 ACME 证书申请失败

**检查项：**
1. **DNS 解析是否生效：** `ping hy2.yourdomain.com`
2. **80 端口是否被占用：** `ss -tulpn | grep :80`
3. **Cloudflare CDN 是否关闭：** 必须为灰色「仅限 DNS」

### Q3：客户端连接不上

按顺序排查：
1. 服务在运行吗？`systemctl status hysteria-server.service`
2. 防火墙放行了吗？检查 VPS 和云服务商安全组
3. **IP 部署忘记跳过证书验证？** 在客户端勾选「允许不安全的连接」
4. 端口对不对？客户端和服务器端口要一致

### Q4：忘记密码了

```bash
cat /etc/hysteria/config.yaml | grep -i password
```

### Q5：v2rayN 报端口绑定失败

**解决：** v2rayN → 设置 → 参数设置 → 本地监听端口 → 改为 **18888**

```powershell
# 查看被排除的端口范围
netsh interface ipv4 show excludedportrange protocol=tcp
```

### Q6：订阅链接返回 404

检查：
1. 订阅服务是否运行：`systemctl status hysteria-subscription.service`
2. 防火墙是否放行 18989 端口（TCP）
3. 用 `hy2 --sub-urls` 获取准确的 URL

### Q7：想用手机连接

- **iOS：** 使用 **Sing-box** 或 **Stash**
- **Android：** 使用 **v2rayNG** 或 **Sing-box**

---

## 附录：VPS 生成的文件清单

| 文件路径 | 说明 |
|---------|------|
| `/etc/hysteria/config.yaml` | 服务端主配置文件 |
| `/root/sub_xxxx-xxxx-xxxx.txt` | v2rayN 订阅（UUID 随机名） |
| `/root/sub_xxxx-xxxx-xxxx-instructions.txt` | 配置指导 |
| `/root/hy2-client.yaml` | 客户端配置示例 |
| `/etc/sysctl.d/99-hysteria-network.conf` | 系统网络优化（持久化） |
| `/etc/systemd/system/hysteria-server.service.d/priority.conf` | 进程优先级优化 |
| `/etc/systemd/system/hysteria-server.service.d/limits.conf` | 连接数上限优化 |
| `/etc/systemd/system/hysteria-subscription.service` | 订阅 HTTP 服务 |
| `/etc/hysteria/subs/` | 订阅 HTTP 服务目录 |
| `/usr/local/bin/hy2` | 快捷命令 |

---

*本教程对应脚本版本：v2.1.1 | 更新日期：2026-07*
