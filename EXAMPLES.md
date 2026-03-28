# Examples / 示例命令

## 中文

### 1. 在线安装

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

### 2. ACME 自动证书快速部署

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --yes
```

### 3. 自有证书快速部署

```bash
./hy2-onekey.sh --deploy --tls cert --cert /path/to/fullchain.pem --key /path/to/privkey.pem --server your.domain.com --sni your.domain.com --yes
```

### 4. 仅查看帮助

```bash
./hy2-onekey.sh --help
```

### 5. v2rayN 导入

安装完成后，查看：

```bash
cat /root/hy2-v2rayn.txt
```

### 6. 安装基础工具

#### Debian / Ubuntu

```bash
apt update
apt install -y curl wget ufw
```

#### Rocky Linux / CentOS Stream / Fedora

```bash
dnf install -y curl wget ufw
```

### 7. 检查监听与服务状态

```bash
ss -lunp | grep 443
systemctl status hysteria-server.service --no-pager
journalctl -u hysteria-server.service -e --no-pager
```

### 8. 使用 UFW 放行端口

```bash
ufw allow 443/udp
ufw allow 443/tcp
ufw status
```

### 9. 使用 iptables 放行端口

```bash
iptables -I INPUT -p udp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
```

## English

### 1. Online install

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

### 2. Quick deploy with ACME

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --yes
```

### 3. Quick deploy with custom certificate

```bash
./hy2-onekey.sh --deploy --tls cert --cert /path/to/fullchain.pem --key /path/to/privkey.pem --server your.domain.com --sni your.domain.com --yes
```

### 4. Show help

```bash
./hy2-onekey.sh --help
```

### 5. v2rayN import

After installation, check:

```bash
cat /root/hy2-v2rayn.txt
```

### 6. Install basic tools

#### Debian / Ubuntu

```bash
apt update
apt install -y curl wget ufw
```

#### Rocky Linux / CentOS Stream / Fedora

```bash
dnf install -y curl wget ufw
```

### 7. Check listening and service status

```bash
ss -lunp | grep 443
systemctl status hysteria-server.service --no-pager
journalctl -u hysteria-server.service -e --no-pager
```

### 8. Allow ports with UFW

```bash
ufw allow 443/udp
ufw allow 443/tcp
ufw status
```

### 9. Allow ports with iptables

```bash
iptables -I INPUT -p udp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
```