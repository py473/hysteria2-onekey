# Hysteria 2 一键脚本 — 终极保姆级部署教程

> 适用脚本版本：hy2-onekey.sh v2.1.1+  
> 本教程面向零基础用户，**跟着每一步操作就能部署成功**。

---

## 📖 目录

- [一、部署前置准备](#一部署前置准备)
- [二、核心分流：IP 部署 vs 域名部署](#二核心分流ip-部署-vs-域名部署)
  - [路径 A：纯 VPS IP 部署（无域名用户）](#路径-a纯-vps-ip-部署适合无域名用户)
  - [路径 B：域名部署（有域名用户）](#路径-b域名部署适合有域名追求高安全性用户)
- [三、脚本安装与配置交互全记录](#三脚本安装与配置交互全记录)
- [四、客户端配置与订阅提取](#四客户端配置与订阅提取)
- [五、日常管理与维护](#五日常管理与维护)
- [六、常见排错与 FAQ](#六常见排错与-faq)

---

## 一、部署前置准备

### 1.1 你需要准备的东西

| 项目 | 说明 | 备注 |
|------|------|------|
| **一台 VPS** | 任意云服务商的 Linux 服务器 | 推荐 Debian 11+/Ubuntu 20.04+ |
| **SSH 工具** | 用来连接 VPS 的软件 | Windows 用 Termius / Xshell / PowerShell |
| **一个域名（可选）** | 用于自动申请 HTTPS 证书 | 没有域名也可以部署，见下文 |

### 1.2 连接 VPS（SSH）

打开你的 SSH 工具：

```
主机/地址：你的VPS公网IP（如 203.0.113.1）
端口：22
用户名：root
密码：你的VPS密码（输入时不会显示，正常现象）
```

> **Windows 自带方式（推荐）：** 按下 `Win + R`，输入 `powershell` 回车，然后输入：
> ```powershell
> ssh root@你的VPS_IP
> ```
> 首次连接会提示是否信任，输入 `yes` 回车。然后输入密码（不显示是正常的）回车。

**连接成功后**，你会看到类似这样的提示符：
```
root@your-vps:~#
```

### 1.3 更新系统

连接成功后，先更新系统包（Debian/Ubuntu）：

```bash
apt update && apt upgrade -y
```

> 如果是 CentOS/Rocky Linux，用这个命令：
> ```bash
> yum update -y
> ```

### 1.4 安装必要工具

```bash
# Debian/Ubuntu
apt install -y curl wget

# CentOS/Rocky
yum install -y curl wget
```

---

## 二、核心分流：IP 部署 vs 域名部署

> ⚠️ **重要决策点：** 在运行脚本之前，请先确定你属于下面哪一种情况。两种方式脚本都支持，但后续操作有区别。

---

### 路径 A：纯 VPS IP 部署（适合无域名用户）

#### 适用场景

- 你没有域名
- 你不想买域名
- 你想快速部署先用上

#### 原理说明

IP 部署模式下，脚本会使用**自签名证书**。自签名证书不是由受信任的证书机构颁发的，所以客户端连接时需要**手动跳过证书验证**，否则无法连接。

#### 需要做的事情

1. **放行防火墙**（非常重要！）

   在 VPS 上执行：
   ```bash
   # 查看防火墙状态
   ufw status
   
   # 放行 Hysteria 2 默认端口（UDP 443）
   ufw allow 443/udp
   
   # 如果启用了 HTTP 订阅服务（默认端口 18989），也放行
   ufw allow 18989/tcp
   ```

   另外，**务必登录你的云服务商控制台**（阿里云、腾讯云、搬瓦工等），在「安全组 / 防火墙」中添加入站规则：
   - 协议：UDP
   - 端口：443
   - 来源：0.0.0.0/0（允许所有来源）

2. **客户端注意事项**

   部署完成后，在 v2rayN / Clash 中导入节点时，**必须开启「跳过证书验证（Allow Insecure）」**，否则节点无法联网。

---

### 路径 B：域名部署（适合有域名、追求高安全性用户）

#### 适用场景

- 你有一个域名（比如 `yourdomain.com`）
- 你想要正规的 HTTPS 证书，更安全、更隐蔽
- 你的运营商不封锁 UDP 443 端口

#### 步骤 1：域名解析

登录你的域名管理后台（Cloudflare、阿里云、Namecheap 等），添加一条 **A 记录**：

```
记录类型：A
主机记录：hy2（或者任何你想要的子域名，如 vpn、proxy 等）
记录值：你的 VPS 公网 IP
TTL：自动或 600
```

> ⚠️ **Cloudflare 用户注意！** 必须关闭「代理状态（Proxy Status）」——确保图标是**灰色**的「仅限 DNS」（DNS Only），不要让它变成黄色的云朵。Hysteria 2 基于 UDP，CDN 代理会导致连接失败！

#### 步骤 2：等待解析生效

解析可能需要几分钟到半小时。检查是否生效：

```bash
ping hy2.yourdomain.com
```

如果返回的 IP 是你 VPS 的 IP，就说明解析成功了。

#### 步骤 3：准备邮箱

脚本在申请 Let's Encrypt 免费证书时需要用到邮箱。准备一个你常用的邮箱即可（如 `admin@yourdomain.com`）。

---

## 三、脚本安装与配置交互全记录

### 3.1 下载并运行脚本

在 VPS 上执行以下**任意一条**命令：

```bash
# 推荐方式（wget）
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh && bash /tmp/hy2-onekey.sh
```

```bash
# 备用方式（curl）
curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh -o /tmp/hy2-onekey.sh && bash /tmp/hy2-onekey.sh
```

### 3.2 主菜单

运行成功后，你会看到：

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

输入 **`1`** 然后回车，开始安装。

### 3.3 选择 TLS 证书方式

```
请选择 TLS 证书方式：
  1) ACME 自动证书（推荐，需域名）
  2) 自有证书
请输入选项 [1-2，默认 1]:
```

- **如果你有域名（路径 B）：** 输入 `1` 回车（选择 ACME 自动证书）
- **如果你用 IP 部署（路径 A）：** 输入 `2` 回车（选择自有证书，脚本会自动处理自签名）

### 3.4 选择认证方式

```
请选择认证方式：
  1) 单密码认证（简单，推荐）
  2) 用户名-密码认证（多用户）
请输入选项 [1-2，默认 1]:
```

直接回车（选默认的 1）即可。如果你想设置多个用户，可以选 2。

### 3.5 选择混淆方式（可选）

```
请选择混淆方式 v2.9.3：
  Salamander: 将每个包伪造成随机字节（兼容 v2）
  Gecko:      在 Salamander 基础上分片 QUIC 握手包（实验性）
  0) 不启用混淆（保持标准 HTTP/3 外观）
  1) Salamander
  2) Gecko（实验性）
请输入选项 [0-2，默认 0]:
```

- **直接回车**（默认不启用）—— 最简单，兼容性最好
- 如果你希望流量更隐蔽，选 `1`（Salamander）或 `2`（Gecko）

### 3.6 协议嗅探

```
是否启用协议嗅探 (Sniff)？
  Sniff 可将 IP 请求自动转为域名请求，配合 ACL 使用
  1) 启用（推荐）
  2) 关闭
请输入选项 [1-2，默认 1]:
```

直接回车（启用）。

### 3.7 测速服务器

```
是否启用内置测速服务器 (Speed Test)？
  开启后客户端可用 hysteria speedtest 测试速度
  1) 启用
  0) 关闭（默认）
请输入选项 [0-1，默认 0]:
```

直接回车（不启用）。

### 3.8 拥塞控制

```
请选择拥塞控制算法：
  1) BBR（默认，高性能）
  2) Reno（传统算法，兼容性更好）
  0) 使用 Hysteria 2 默认值
请输入选项 [0-2，默认 1]:
```

直接回车（选 BBR）。

### 3.9 带宽限制

```
是否要设置服务端带宽限制？
  1) 是（设置每客户端的上下行速率上限）
  0) 否（不限速）
请输入选项 [0-1，默认 0]:
```

直接回车（不限速）。

### 3.10 端口跳跃

```
是否启用端口跳跃 (Port Hopping)？
  端口跳跃可绕过运营商对单个 UDP 端口的限速/封锁
  1) 启用（输入范围，如 20000-50000）
  0) 关闭（默认）
请输入选项 [0-1，默认 0]:
```

- **直接回车**（不启用）—— 如果你不确定运营商是否限速，先不启用
- 选 `1` 可以输入范围如 `20000-50000`（脚本会自动配置 nftables DNAT 规则）

### 3.11 ⚠️ 关键分歧点：域名 vs IP

#### 如果你有域名（路径 B）—— 出现以下提示

```
请输入你的域名（需已解析到 VPS）:
```

输入你的域名，如 `hy2.yourdomain.com`，回车。

```
请输入 ACME 邮箱:
```

输入你的邮箱，如 `admin@yourdomain.com`，回车。

#### 如果你用 IP 部署（路径 A）—— 出现以下提示

```
请输入证书文件路径（cert）:
```

> 直接回车**无效**，这里需要输入路径。但不用担心——脚本实际上**不需要你事先准备证书文件**。这里的交互流程是让你输入任意占位路径，脚本后续会自动生成自签名证书。

不过在当前脚本版本中（v2.1.1），对于选择自有证书 + 无 `--yes` 模式的情况，你需要输入证书路径后，脚本会检查文件是否存在并退出。

> **建议：** IP 部署用户推荐使用 `--deploy` 命令行模式 + `--insecure` 参数来跳过证书交互。具体见下方。

#### IP 部署推荐的一键命令

```bash
# 下载脚本
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh
chmod +x /tmp/hy2-onekey.sh

# 直接用命令行部署（IP 模式 + 自签名 + 跳过证书校验）
/tmp/hy2-onekey.sh --deploy \
  --tls cert \
  --cert /etc/hysteria/server.crt \
  --key /etc/hysteria/server.key \
  --server 你的VPS_IP \
  --insecure \
  --yes
```

> 这个命令会：使用自签名证书，连接地址用你的 VPS IP，客户端跳过证书校验，全程不询问直接执行。

### 3.12 监听端口

```
请输入监听端口 [默认: 443]:
```

直接回车（默认 443）。如果 443 被占用，可以改成其他端口如 `8443`。

### 3.13 伪装地址

```
请选择是否开启伪装（Masquerade）：
  1) 开启（推荐，反代伪装地址）
  2) 关闭（所有 HTTP 请求返回 404）
请输入选项 [1-2，默认 1]:
```

直接回车。然后输入伪装地址（如 `www.bing.com`）：

```
请输入你想伪装成的网站地址（直接输域名也可以，例如 www.bing.com）:
```

输入 `www.bing.com` 回车。

### 3.14 证书校验方式

```
证书校验方式：
  1) 正常校验（推荐，适用于 ACME 或受信任证书）
  2) 忽略证书校验（适用于自签名证书，v2rayN 常用）
请输入选项 [1-2，默认 1]:
```

- **域名部署（路径 B）：** 直接回车（选 1，正常校验）
- **IP 部署（路径 A）：** 输入 `2` 回车（选 2，忽略校验）

### 3.15 安装成功

脚本会开始下载安装 Hysteria 2，然后生成配置文件，启动服务。安装成功后的输出示例：

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
分享 URI: hysteria2://xxxxxx@hy2.yourdomain.com:443/?sni=hy2.yourdomain.com#HY2
--------------------------------------------------
订阅服务：
  v2rayN / v2rayNG:             http://你的VPS_IP:18989/sub_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.txt
--------------------------------------------------
```

> **保存好以上信息！** 特别是「认证密码」和「订阅 URL」，后面客户端配置要用。

---

## 四、客户端配置与订阅提取

### 4.1 获取订阅链接

部署完成后，脚本会启动一个 HTTP 订阅服务（端口 18989）。你也可以随时用以下命令查看：

```bash
# 在 VPS 上运行
hy2 --sub-urls
```

你会看到类似这样的输出：
```
  v2rayN / v2rayNG:         http://你的VPS_IP:18989/sub_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.txt
```

> 🔒 **安全说明：** 订阅文件名是随机 UUID 格式（如 `sub_a1b2c3d4-....txt`），**文件名不可猜测**，防止公网上的陌生人随意下载你的配置。即使别人知道你的服务器 IP 和端口 18989，也无法破解文件名。

### 4.2 使用 v2rayN 客户端

#### 下载 v2rayN

1. 访问 https://github.com/2dust/v2rayN/releases
2. 下载 `v2rayN-With-Core.zip`（带核心版）
3. 解压到任意文件夹

#### 添加订阅

**方法一：复制订阅 URL**

1. 在 VPS 上执行 `hy2 --sub-urls`，复制显示的完整 URL
2. 在 v2rayN 中：点击顶部菜单「服务器」→「订阅设置」→「添加」
3. 粘贴 URL，备注填 `HY2`，点确定
4. 右键托盘图标 →「更新订阅（不通过代理）」

**方法二：手动导入 URI**

1. 在 VPS 上执行：
   ```bash
   cat /root/sub_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.txt
   ```
   复制输出的 URI（以 `hysteria2://` 开头的那一行）
2. 在 v2rayN 中：点击「服务器」→「从剪贴板导入」
3. 按 `Ctrl+V` 回车

#### ⚠️ IP 部署用户必看

如果选择的是 IP 部署（自签名证书），添加节点后：

1. 右键节点 → 编辑
2. 找到「TLS」设置
3. **勾选「允许不安全的连接（Allow Insecure）」**
4. 点确定

**不勾选这个选项，节点将无法上网！**

#### 设置核心类型

1. 右键 Hysteria2 节点 → 核心类型 → 选择 **sing-box**
2. 设为活动服务器
3. 右下角图标右键 → 系统代理 → 开启

### 4.3 使用 Clash Meta (Mihomo)

如果你使用 Clash Meta：

1. 获取订阅 URL（同上）
2. 在 Clash 面板中添加订阅
3. 或者手动将 URI 转为 Clash 配置格式：

```yaml
proxies:
  - name: "HY2"
    type: hysteria2
    server: 你的域名或IP
    port: 443
    password: "你的密码"
    sni: 你的域名或IP
    skip-cert-verify: true  # IP 部署必须 true，域名部署可 false
    udp: true
```

---

## 五、日常管理与维护

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

部署完成后，输入 `hy2` 即可调出管理菜单：

```bash
hy2
```

### 重新生成订阅文件

```bash
hy2 --gen-subs
```

### 查看订阅 URL

```bash
hy2 --sub-urls
```

### 更新 Hysteria 2 到最新版

重新运行脚本，选菜单 1 即可（不会删除已有配置）。

### 完全卸载

```bash
hy2 --remove
```

---

## 六、常见排错与 FAQ

### Q1：部署后服务启动失败

```bash
# 先查日志
journalctl --no-pager -e -u hysteria-server.service
```

**常见原因：**
- **端口被占用：** `ss -tulpn | grep 443` 查看 443 端口是否被其他程序占用
- **防火墙未放行：** `ufw status` 确认 UDP 443 已放行
- **配置文件权限：** `ls -la /etc/hysteria/config.yaml` 确认属主是 `hysteria:hysteria`
- **ACME 证书失败：** 检查域名是否正确解析到了 VPS

### Q2：域名部署提示 ACME 证书申请失败

**原因和解决方案：**

1. **DNS 解析未生效：** 用 `ping your.domain.com` 检查是否解析到了你的 VPS IP
2. **80 端口被占用：** ACME 证书申请需要在 80 端口进行验证
   ```bash
   # 检查 80 端口占用
   ss -tulpn | grep :80
   ```
   如果有其他网站占用了 80 端口，先暂停那个服务，等证书申请成功后再重启
3. **Cloudflare CDN 未关闭：** 去 Cloudflare 控制台，确保代理状态是灰色的「仅限 DNS」

### Q3：客户端连接不上

**按顺序排查：**

1. **服务在运行吗？** `systemctl status hysteria-server.service`
2. **防火墙放行了吗？** 检查 VPS 防火墙和云服务商安全组
3. **IP 部署忘记跳过证书验证：** 在客户端勾选「允许不安全的连接」
4. **端口不对：** 如果你改过默认端口，客户端也要用同样的端口
5. **订阅文件是不是最新的：** 在 VPS 上执行 `hy2 --gen-subs` 重新生成

### Q4：如何查看密码

如果在部署时忘了保存密码，在 VPS 上运行：

```bash
# 从配置文件中查找
cat /etc/hysteria/config.yaml | grep -i password

# 或者从订阅文件中查看（密码在 URI 中）
cat /root/sub_*.txt
```

### Q5：v2rayN 报"端口绑定失败"

错误信息：
```
listen tcp 127.0.0.1:10808: bind: An attempt was made to access a socket...
```

**原因：** Windows 的 Hyper-V / WSL 占用了 10808 端口。

**解决：** v2rayN → 设置 → 参数设置 → 本地监听端口 → 改为 **18888**（或任意不在排除范围内的端口）

查看被排除的端口范围：
```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

### Q6：想用手机连接

- **iOS：** 使用 **Sing-box** 或 **Stash** App
- **Android：** 使用 **v2rayNG** 或 **Sing-box**
- **配置信息：** 用 VPS 上生成的订阅文件导入（方法同上）

### Q7：订阅链接在浏览器中打开是 404

如果你的服务器 IP 和端口都是对的，但访问订阅链接返回 404：

1. **确认订阅服务在运行：**
   ```bash
   systemctl status hysteria-subscription.service
   ```
2. **确认防火墙放行了 18989 端口（TCP）**
3. **确认文件名正确：** 用 `hy2 --sub-urls` 获取准确的 URL
4. **如果是重装后订阅文件没同步：** 执行 `hy2 --gen-subs`

---

## 附录：VPS 上生成的文件清单

| 文件路径 | 说明 |
|---------|------|
| `/etc/hysteria/config.yaml` | 服务端主配置文件 |
| `/root/sub_xxxx-xxxx-xxxx.txt` | v2rayN 订阅文件（UUID 随机名） |
| `/root/sub_xxxx-xxxx-xxxx-instructions.txt` | v2rayN 配置指导 |
| `/root/hy2-client.yaml` | 客户端配置示例 |
| `/etc/sysctl.d/99-hysteria-network.conf` | 系统网络优化（持久化） |
| `/etc/systemd/system/hysteria-server.service.d/priority.conf` | 进程优先级优化 |
| `/etc/systemd/system/hysteria-server.service.d/limits.conf` | 连接数上限优化 |
| `/etc/hysteria/subs/` | 订阅 HTTP 服务目录 |
| `/usr/local/bin/hy2` | 快捷命令（输入 hy2 调出菜单） |

---

*本教程对应脚本版本：v2.1.1 | 更新日期：2026-07*
