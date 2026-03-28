# Installation Guide / 安装说明

## 中文

### 1. 连接到你的 Linux 服务器

先通过 SSH 登录到你的 VPS。

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

- TLS 类型：ACME 或自有证书
- 域名：填写你的域名
- 邮箱：填写你的 ACME 邮箱
- 伪装地址：可以直接输入 `www.bing.com`

### 5. 安装完成后

安装完成后，重点查看：

- `/etc/hysteria/config.yaml`
- `/root/hy2-v2rayn.txt`

### 6. v2rayN 使用

把脚本输出的 Hysteria2 节点信息导入 v2rayN 即可。

如果连接失败，请先查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)。

## English

### 1. Connect to your Linux server

Log in to your VPS over SSH.

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

### 5. After installation

Check the following files:

- `/etc/hysteria/config.yaml`
- `/root/hy2-v2rayn.txt`

### 6. Use with v2rayN

Import the generated Hysteria2 node information into v2rayN.

If the connection fails, first check [TROUBLESHOOTING.md](TROUBLESHOOTING.md).