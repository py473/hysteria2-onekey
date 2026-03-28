# Installation Guide / 安装说明

## 中文

### 1. 连接到你的 Linux 服务器

先通过 SSH 登录到你的 VPS。

### 1.1 安装基础工具

#### Debian / Ubuntu

```bash
apt update
apt install -y curl wget ufw
```

#### Rocky Linux / CentOS Stream / Fedora

```bash
dnf install -y curl wget ufw
```

如果你的系统没有 `dnf`，可以尝试：

```bash
yum install -y curl wget ufw
```

### 2. 使用一键在线安装

推荐命令：

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

如果服务器没有 `wget`，也可以使用：

```bash
curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/install.sh -o /tmp/hysteria2-onekey-install.sh && bash /tmp/hysteria2-onekey-install.sh
```

### 3. 按菜单选择

脚本启动后，会出现菜单。

- 输入 `1`：一键安装 / 升级并生成配置
- 输入 `2`：仅重启服务
- 输入 `3`：卸载
- 输入 `0`：退出

### 4. 配置服务端

脚本会继续询问：

- TLS 类型：ACME、自有证书或无域名 / IP 模式
- 域名：填写你的域名
- 邮箱：填写你的 ACME 邮箱
- 伪装地址：可以直接输入 `www.bing.com`

如果你没有域名，脚本会自动改用 VPS IP 和自签名证书，也可以手动在部署参数里使用 `--tls ip`。

### 5. 安装完成后

安装完成后，重点查看：

- `/etc/hysteria/config.yaml`
- `/root/hy2-v2rayn.txt`

### 6. v2rayN 使用

把脚本输出的 Hysteria2 节点信息导入 v2rayN 即可。

如果连接失败，请先查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)。

如果你还想查看支持哪些客户端和官方下载地址，请看 [CLIENTS.md](CLIENTS.md)。

### 7. 开放端口与检查命令

#### UFW

```bash
ufw allow 443/udp
ufw allow 443/tcp
ufw status
```

#### iptables

```bash
iptables -I INPUT -p udp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
```

#### 检查监听与服务状态

```bash
ss -lunp | grep 443
systemctl status hysteria-server.service --no-pager
journalctl -u hysteria-server.service -e --no-pager
```

## English

### 1. Connect to your Linux server

Log in to your VPS over SSH.

### 1.1 Install basic tools

#### Debian / Ubuntu

```bash
apt update
apt install -y curl wget ufw
```

#### Rocky Linux / CentOS Stream / Fedora

```bash
dnf install -y curl wget ufw
```

If your system does not use `dnf`, try:

```bash
yum install -y curl wget ufw
```

### 2. Use the one-line installer

Recommended command:

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

If `wget` is not available, use:

```bash
curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/install.sh -o /tmp/hysteria2-onekey-install.sh && bash /tmp/hysteria2-onekey-install.sh
```

### 3. Follow the menu

When the script starts, a menu will appear.

- Enter `1`: install / upgrade and generate configuration
- Enter `2`: restart service only
- Enter `3`: uninstall
- Enter `0`: exit

### 4. Configure the server

The script will then ask for:

- TLS type: ACME or custom certificate
- Domain: your server domain
- Email: your ACME email
- Masquerade URL: you can enter `www.bing.com`

If you do not have a domain, the script will automatically use your VPS IP and a self-signed certificate. You can also set `--tls ip` manually.

### 5. After installation

Check the following files:

- `/etc/hysteria/config.yaml`
- `/root/hy2-v2rayn.txt`

### 6. Use with v2rayN

Import the generated Hysteria2 node information into v2rayN.

If the connection fails, first check [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

If you want to see which clients are supported and where to download them, check [CLIENTS.md](CLIENTS.md).

### 7. Open ports and check commands

#### UFW

```bash
ufw allow 443/udp
ufw allow 443/tcp
ufw status
```

#### iptables

```bash
iptables -I INPUT -p udp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
```

#### Check listening and service status

```bash
ss -lunp | grep 443
systemctl status hysteria-server.service --no-pager
journalctl -u hysteria-server.service -e --no-pager
```