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

### 4. ACME + Gecko 混淆 + 嗅探 (v2.9.2)

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --obfs gecko --sniff --yes
```

### 5. 自有证书 + Salamander 混淆 + 带宽限制 (v2.9.2)

```bash
./hy2-onekey.sh --deploy --tls cert --cert /path/to/fullchain.pem --key /path/to/privkey.pem --server your.domain.com --sni your.domain.com --obfs salamander --obfs-password myObfsPwd --bandwidth-up 500 mbps --bandwidth-down 500 mbps --yes
```

### 6. 多用户认证 (v2.9.2)

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --auth-type userpass --username myuser --password mypass --yes
```

### 7. 拥塞控制 Reno + 关闭嗅探 (v2.9.2)

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --congestion reno --no-sniff --yes
```

### 8. 仅查看帮助

```bash
./hy2-onekey.sh --help
```

### 9. v2rayN 导入

安装完成后，查看：

```bash
cat /root/hy2-v2rayn.txt
```

支持的客户端和官方下载地址请看 [CLIENTS.md](CLIENTS.md)。

### 10. 安装基础工具

#### Debian / Ubuntu

```bash
apt update
apt install -y curl wget ufw
```

#### Rocky Linux / CentOS Stream / Fedora

```bash
dnf install -y curl wget ufw
```

### 11. 检查监听与服务状态

```bash
ss -lunp | grep 443
systemctl status hysteria-server.service --no-pager
journalctl -u hysteria-server.service -e --no-pager
```

### 12. 使用 UFW 放行端口

```bash
ufw allow 443/udp
ufw allow 443/tcp
ufw status
```

### 13. 使用 iptables 放行端口

```bash
iptables -I INPUT -p udp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
```

### 14. 检查 Hysteria 版本

```bash
hysteria version
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

### 4. ACME + Gecko obfuscation + sniffing (v2.9.2)

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --obfs gecko --sniff --yes
```

### 5. Custom cert + Salamander + bandwidth limiting (v2.9.2)

```bash
./hy2-onekey.sh --deploy --tls cert --cert /path/to/fullchain.pem --key /path/to/privkey.pem --server your.domain.com --sni your.domain.com --obfs salamander --obfs-password myObfsPwd --bandwidth-up 500 mbps --bandwidth-down 500 mbps --yes
```

### 6. Multi-user authentication (v2.9.2)

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --auth-type userpass --username myuser --password mypass --yes
```

### 7. Reno congestion + disable sniffing (v2.9.2)

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --congestion reno --no-sniff --yes
```

### 8. Show help

```bash
./hy2-onekey.sh --help
```

### 9. v2rayN import

After installation, check:

```bash
cat /root/hy2-v2rayn.txt
```

For supported clients and official download links, see [CLIENTS.md](CLIENTS.md).

### 10. Install basic tools

#### Debian / Ubuntu

```bash
apt update
apt install -y curl wget ufw
```

#### Rocky Linux / CentOS Stream / Fedora

```bash
dnf install -y curl wget ufw
```

### 11. Check listening and service status

```bash
ss -lunp | grep 443
systemctl status hysteria-server.service --no-pager
journalctl -u hysteria-server.service -e --no-pager
```

### 12. Allow ports with UFW

```bash
ufw allow 443/udp
ufw allow 443/tcp
ufw status
```

### 13. Allow ports with iptables

```bash
iptables -I INPUT -p udp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
```

### 14. Check Hysteria version

```bash
hysteria version
```
