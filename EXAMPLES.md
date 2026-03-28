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