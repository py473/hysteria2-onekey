# Hysteria 2 一键部署保姆级教程

## 写在前面

本文档面向**完全新手**，只要你有一台 VPS 和一个域名，跟着每一步操作就能部署成功。

**项目地址：** https://github.com/py473/hysteria2-onekey

---

## 目录

- [第一章：准备工作](#第一章准备工作)
- [第二章：连接 VPS](#第二章连接-vps)
- [第三章：一键安装部署](#第三章一键安装部署)
- [第四章：命令行模式部署（更快）](#第四章命令行模式部署更快)
- [第五章：客户端连接（v2rayN）](#第五章客户端连接v2rayn)
- [第六章：日常管理](#第六章日常管理)
- [第七章：常见问题](#第七章常见问题)

---

## 第一章：准备工作

### 1.1 你需要准备的东西

| 项目 | 说明 | 示例 |
|------|------|------|
| **一台 VPS** | Linux 系统（推荐 Ubuntu 22.04 / Debian 12） | 任意云服务商买的服务器 |
| **一个域名** | 用来申请 HTTPS 证书 | `your.domain.com` |
| **SSH 客户端** | 用来连接 VPS | Windows 用 PuTTY 或 Terminal |

### 1.2 域名解析

购买域名后，去你的域名管理后台（如阿里云、Cloudflare、Namecheap 等），添加一条 **A 记录**：

```
记录类型: A
主机记录: @ （或用你想要的子域名，比如 vpn）
记录值:   <你的 VPS 公网 IP>
TTL:     建议 600 或自动
```

> ⏳ 解析生效需要几分钟到半小时不等。可以用 `ping your.domain.com` 检查是否解析到了你的 VPS IP。

### 1.3 放行防火墙

你的 VPS 需要放行 **UDP 443 端口**（Hysteria 2 默认端口）。

**Ubuntu / Debian 系统（UFW）：**
```bash
ufw allow 443/udp
ufw reload
```

**如果云服务商还有安全组/防火墙**（如腾讯云、阿里云、AWS），记得也在网页控制台里放行 **UDP 443** 入站。

---

## 第二章：连接 VPS

### 2.1 获取 VPS 信息

在你的云服务商控制台找到：

- **公网 IP**（比如：`203.0.113.1`）
- **用户名**（通常是 `root`）
- **密码** 或 **SSH 密钥**

### 2.2 用 SSH 连接

**Windows 新式方法（PowerShell / Terminal）：**
```powershell
ssh root@你的VPS_IP
# 输入密码（输入时不会显示，正常现象）
```

**Windows 旧式方法（PuTTY）：**
1. 打开 PuTTY
2. Host Name 填：`root@你的VPS_IP`
3. Port: `22`
4. 点 Open
5. 弹出提示点「接受」
6. 输入密码

> ✅ 连接成功后你会看到类似 `root@your-vps:~#` 的提示符。

---

## 第三章：一键安装部署

### 3.1 运行安装命令

在 VPS 的 SSH 窗口中，复制下面**任意一条**命令回车执行（推荐第一条）：

```bash
# 推荐（wget 方式）：
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

```bash
# 备用（curl 方式）：
curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/install.sh -o /tmp/hysteria2-onekey-install.sh && bash /tmp/hysteria2-onekey-install.sh
```

你会看到类似这样的输出：

```
========================================
Hysteria 2 One-Key Installer
Version: 2.0.0
Repo: https://github.com/py473/hysteria2-onekey
========================================
正在下载并启动主脚本...
```

### 3.2 交互式安装步骤

下载完自动进入主菜单：

```
==================================================
HY2 一键安装脚本（Linux 服务器）v2.0.0
基于 Hysteria 2 v2.9.2 官方文档安装方式
==================================================
1) 一键安装/升级 + 交互式生成配置 + 启动服务
2) 仅重启服务
3) 卸载 Hysteria 2
0) 退出
```

输入 **`1`** 回车。

### 3.3 填写配置信息

接下来脚本会一步步问你，这里以 ACME 证书（自动 HTTPS）为例：

#### 步骤①：选择 TLS 方式

```
请选择 TLS 证书方式：
  1) ACME 自动证书（推荐，需域名）
  2) 自有证书
请输入选项 [1-2，默认 1]:
```

✅ **输入 1 回车**（推荐用 ACME 自动证书）

#### 步骤②：输入域名

```
请输入你的域名（需已解析到 VPS）:
```

输入你的域名，比如 `vpn.yourdomain.com`，回车。

#### 步骤③：输入邮箱

```
请输入 ACME 邮箱:
```

输入你的邮箱，比如 `admin@yourdomain.com`，回车。

#### 步骤④：选择混淆方式（可选）

```
请选择混淆方式 v2.9.2：
  Salamander: 将每个包伪造成随机字节（兼容 v2）
  Gecko:      在 Salamander 基础上分片 QUIC 握手包（实验性）
  0) 不启用混淆（保持标准 HTTP/3 外观）
  1) Salamander
  2) Gecko（实验性）
  请输入选项 [0-2，默认 0]:
```

✅ **直接回车**（选默认 0，不启用混淆，最简单）
如果你想更隐蔽就选 1 或 2。

#### 步骤⑤：选择监听端口

```
请输入监听端口 [默认: 443]:
```

✅ **直接回车**（默认 443）

#### 步骤⑥：选择伪装地址

```
请选择是否开启伪装（Masquerade）：
  1) 开启（推荐，反代伪装地址）
  2) 关闭（所有 HTTP 请求返回 404）
请输入选项 [1-2，默认 1]:
```

✅ **直接回车**（选默认 1 开启）

然后输入伪装网站地址，比如：
```
请输入你想伪装成的网站地址（直接输域名也可以，例如 www.bing.com）
: 
```
输入 `www.bing.com` 回车。

#### 步骤⑦：选择证书校验

```
证书校验方式：
  1) 正常校验（推荐，适用于 ACME 或受信任证书）
  2) 忽略证书校验（适用于自签名证书，v2rayN 常用）
请输入选项 [1-2，默认 1]:
```

✅ **直接回车**（选默认 1，正常校验）

#### 步骤⑧：确认部署

脚本最后会显示总结信息，问你是否确认。输入 `YES`。

### 3.4 安装完成

整个流程结束后，你会看到类似这样的输出：

```
[OK] 部署完成。
--------------------------------------------------
服务配置文件: /etc/hysteria/config.yaml
客户端示例文件: /root/hy2-client.yaml
认证密码: xxxxxx
连接地址: vpn.yourdomain.com:443
SNI: vpn.yourdomain.com
TLS 校验: false
伪装地址: https://www.bing.com
分享 URI: hysteria2://xxxxxx@vpn.yourdomain.com:443/?sni=xxx#HY2
v2rayN 导入文件: /root/hy2-v2rayn.txt
```

**🎉 部署成功！** 服务器端搞定了。

---

## 第四章：命令行模式部署（更快）

如果你不想一步步交互问答，可以用 `--deploy` 参数一次性搞定：

```bash
# 先下载脚本
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh
chmod +x /tmp/hy2-onekey.sh

# ACME 自动证书 + 开启伪装 + 自动完成
/tmp/hy2-onekey.sh --deploy \
  --tls acme \
  --domain your.domain.com \
  --email your@email.com \
  --yes
```

各参数说明：

| 参数 | 说明 | 示例 |
|------|------|------|
| `--deploy` | 直接部署模式 | 必须 |
| `--tls acme` | ACME 自动证书 | `acme` 或 `cert` |
| `--domain` | 你的域名 | `vpn.yourdomain.com` |
| `--email` | ACME 邮箱 | `admin@yourdomain.com` |
| `--password` | 指定密码（不指定则自动生成） | `MyPass123` |
| `--listen-port` | 监听端口 | `443` |
| `--yes` | 跳过确认，直接执行 | 无参数值 |
| `--no-masquerade` | 关闭伪装 | 无参数值 |
| `--obfs gecko` | 启用 Gecko 混淆 | `salamander` / `gecko` / `off` |
| `--sniff` | 启用协议嗅探 | 无参数值 |
| `--speed-test` | 启用内置测速 | 无参数值 |
| `--auth-type userpass` | 多用户认证 | `password` / `userpass` |
| `--username` | 用户名（配合 userpass） | `user1` |
| `--bandwidth-up 100 mbps` | 上行带宽限制 | `100 mbps` |
| `--bandwidth-down 100 mbps` | 下行带宽限制 | `100 mbps` |
| `--congestion bbr` | 拥塞控制算法 | `bbr` / `reno` |
| `--insecure` | 忽略证书校验 | 无参数值 |

**常用组合示例：**

```bash
# 最简部署（ACME + 自动密码 + 伪装）
/tmp/hy2-onekey.sh --deploy --tls acme --domain vpn.yourdomain.com --email admin@yourdomain.com --yes

# 带 Gecko 混淆 + 开启嗅探 + 开启测速
/tmp/hy2-onekey.sh --deploy --tls acme --domain vpn.yourdomain.com --email admin@yourdomain.com --obfs gecko --sniff --speed-test --yes

# 自有证书 + 无伪装 + 忽略证书校验
/tmp/hy2-onekey.sh --deploy --tls cert --cert /path/to/cert.pem --key /path/to/key.pem --server your.domain.com --insecure --no-masquerade --yes
```

---

## 第五章：客户端连接（v2rayN）

### 5.1 下载 v2rayN

1. 去 https://github.com/2dust/v2rayN/releases 下载最新版
2. 找到 `v2rayN-With-Core.zip` 或 `v2rayN.zip`（带核心版更方便）
3. 解压到一个文件夹（如 `D:\v2rayN`）

### 5.2 确认核心文件

v2rayN V7.22.7+ 自带 `sing-box` 核心，可以直接用它来跑 Hysteria2。

检查 `bin\sing_box\` 目录下是否有 `sing-box.exe`，有就行。

### 5.3 添加 Hysteria2 节点

**方法一：粘贴 URI（最简单）**

拷贝 VPS 上生成的分享 URI：
```
hysteria2://xxxxxxxx@vpn.yourdomain.com:443/?sni=vpn.yourdomain.com#HY2
```

然后在 v2rayN 中：
1. 点顶部的「服务器」→「从剪贴板导入」
2. 回车

**方法二：手动添加**

在 v2rayN 中按 `Ctrl+N` 或点右下角「+」号：
1. 服务器类型选择：**Hysteria2**
2. 别名：`HY2`
3. 地址：`vpn.yourdomain.com`
4. 端口：`443`
5. 密码：粘贴 VPS 脚本输出的密码
6. SNI：`vpn.yourdomain.com`
7. 传输安全：`tls`
8. 点「确认」

### 5.4 设置核心类型

**重要步骤！** 添加完节点后：

1. 右键刚添加的 Hysteria2 节点
2. 选择「设为活动服务器」
3. 如果延迟显示 `-1`，在节点的「核心类型」中确认设置为 **sing-box**

> ⚠️ **核心类型必须是 sing-box（而不是 hysteria2 独立核心）**，因为 v2rayN 对 hysteria2 独立核心的配置生成有兼容性问题。

### 5.5 设置系统代理

1. 右键右下角 v2rayN 图标
2. 选择「系统代理」→「开启」
3. 默认会走 SOCKS5 代理 `127.0.0.1:10808`

### 5.6 测试

打开浏览器访问 https://www.google.com，能打开就成功了！

如果延迟显示 `-1`，断开重连试试，或者检查 `设置→参数设置→本地监听端口` 是否被 Windows 预留（参考 7.2 节）。

---

## 第六章：日常管理

### 查看服务状态
```bash
systemctl status hysteria-server.service
```

### 查看实时日志
```bash
journalctl --no-pager -e -u hysteria-server.service -f
```

### 查看最近 50 行错误日志
```bash
journalctl --no-pager -u hysteria-server.service -n 50 --no-hostname
```

### 重启服务
```bash
systemctl restart hysteria-server.service
```

### 查看服务端配置
```bash
cat /etc/hysteria/config.yaml
```

### 查看 v2rayN 导入信息
```bash
cat /root/hy2-v2rayn.txt
```

### 查看客户端示例配置
```bash
cat /root/hy2-client.yaml
```

### 更新 Hysteria 2 到最新版
```bash
# 重新运行官方安装脚本（不会删除已有配置）
bash <(curl -fsSL https://get.hy2.sh/)
```

### 完全卸载
```bash
# 方法一：用脚本卸载
bash <(curl -fsSL https://get.hy2.sh/) --remove

# 方法二：手动删除
systemctl stop hysteria-server.service
systemctl disable hysteria-server.service
rm -rf /etc/hysteria
rm -f /etc/systemd/system/hysteria-server.service
rm -rf /etc/systemd/system/hysteria-server.service.d
rm -f /etc/sysctl.d/99-hysteria.conf
systemctl daemon-reload
```

---

## 第七章：常见问题

### 7.1 部署后服务启动失败

```bash
# 查日志
journalctl --no-pager -e -u hysteria-server.service
```

**常见原因：**
- 端口被占用：`ss -tulpn | grep 443`
- 防火墙未放行：`ufw status` 确认 UDP 443 已放行
- 配置文件权限：`ls -la /etc/hysteria/config.yaml` 确认属主是 `hysteria:hysteria`
- ACME 证书失败：检查域名是否正确解析到 VPS

### 7.2 v2rayN 报端口绑定失败

错误信息：
```
listen tcp 127.0.0.1:10808: bind: An attempt was made to access a socket in a way forbidden by its access permissions.
```

**原因：** Windows 的 Hyper-V / WSL 占用了 `10808` 端口。
**解决：** v2rayN → 设置 → 参数设置 → 本地监听端口 → 改为 **18888** 或其他不在排除范围内的端口。

查看排除端口范围：
```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

### 7.3 v2rayN 找不到核心文件

**解决：** 确认下载了 v2rayN-With-Core 版本，或手动下载核心：
- 去 https://github.com/apernet/hysteria/releases 下载 `hysteria-windows-amd64.exe` 
- 放到 `bin\hysteria2\` 目录并重命名为 `hysteria.exe`

或者直接用自带的 sing-box 核心（推荐）。

### 7.4 想用手机连接

- **iOS：** 使用 **Sing-box** 或 **Stash** App
- **Android：** 使用 **v2rayNG** 或 **Sing-box**
- **配置信息：** 用 VPS 上 `/root/hy2-client.yaml` 的内容导入

### 7.5 忘记密码了

查看 VPS 上的配置文件：
```bash
cat /etc/hysteria/config.yaml | grep -i password
```

或者根目录的导入文件：
```bash
cat /root/hy2-v2rayn.txt
```

### 7.6 证书过期了

如果启用了 ACME 自动证书，Hysteria 2 会自动续期，无需手动操作。

如果使用了自有证书，在到期前替换证书文件：
```bash
# 替换证书文件后重启
systemctl restart hysteria-server.service
```

---

## 附录：VPS 上生成的清单

部署完成后，你的 VPS 上会生成以下文件：

| 文件路径 | 说明 |
|---------|------|
| `/etc/hysteria/config.yaml` | **服务端主配置文件**（已自动优化性能） |
| `/root/hy2-v2rayn.txt` | v2rayN 导入信息（复制其中的 URI） |
| `/root/hy2-client.yaml` | 客户端配置示例 |
| `/etc/sysctl.d/99-hysteria.conf` | 系统缓冲区优化（持久化） |
| `/etc/systemd/system/hysteria-server.service.d/priority.conf` | 进程优先级优化（持久化） |

---

*本教程对应项目版本：v2.0.0 | 更新日期：2026-06-26*
