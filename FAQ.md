# FAQ / 常见问答

## 中文

### 1. 这个脚本支持哪些系统？

支持常见的 Linux / Unix 服务器系统，例如 Debian、Ubuntu、Rocky Linux、CentOS Stream 和 Fedora。

### 2. 如何一键安装？

推荐使用：

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

### 3. 为什么 v2rayN 连不上？

通常是以下原因之一：

- 服务器没有监听 UDP 443
- 云厂商安全组没有放行 UDP 443
- 证书或 SNI 配置不一致

请先查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)。

### 4. 伪装地址要怎么填？

可以直接输入域名，例如 `www.bing.com`。

脚本会自动补全 `https://`。

## English

### 1. Which systems are supported?

Common Linux / Unix server systems are supported, including Debian, Ubuntu, Rocky Linux, CentOS Stream, and Fedora.

### 2. How do I install it in one line?

Recommended command:

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

### 3. Why does v2rayN fail to connect?

Common reasons include:

- The server is not listening on UDP 443
- The cloud firewall does not allow UDP 443
- Certificate or SNI mismatch

Please check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) first.

### 4. How should I enter the masquerade URL?

You can enter a plain domain such as `www.bing.com`.

The script will automatically prepend `https://`.