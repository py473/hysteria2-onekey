# Troubleshooting / 常见问题

## 中文

### 1. 服务启动失败

先检查服务状态和日志：

```bash
systemctl status hysteria-server.service --no-pager
journalctl -u hysteria-server.service -e --no-pager
```

如果日志里出现 `permission denied`，请检查 `/etc/hysteria/config.yaml` 的权限与所属用户。

### 2. v2rayN 测试连接失败

先确认服务器已经监听 UDP 443：

```bash
ss -lunp | grep 443
```

如果没有输出，说明服务没有真正监听成功，优先看服务日志。

如果已经监听，再检查云厂商安全组和本机防火墙是否放行 UDP 443。

### 3. 伪装地址报错

伪装地址可以直接输入域名，例如 `www.bing.com`。

脚本会自动补全成 `https://www.bing.com`。

如果仍然报错，检查地址是否能正常访问。

### 4. ACME 证书申请失败

- 确认域名已解析到 VPS
- 确认 443 端口可用
- 确认系统时间正确

### 5. 配置文件读权限错误

如果看到 `open /etc/hysteria/config.yaml: permission denied`，可执行：

```bash
chown -R hysteria:hysteria /etc/hysteria
chmod 750 /etc/hysteria
chmod 640 /etc/hysteria/config.yaml
systemctl restart hysteria-server.service
```

## English

### 1. Service failed to start

Check the service status and logs:

```bash
systemctl status hysteria-server.service --no-pager
journalctl -u hysteria-server.service -e --no-pager
```

If the log shows `permission denied`, verify the ownership and permissions of `/etc/hysteria/config.yaml`.

### 2. v2rayN connection test failed

Make sure the server is actually listening on UDP 443:

```bash
ss -lunp | grep 443
```

If there is no output, the service is not listening properly. Check the service logs first.

If it is listening, verify that your cloud firewall and local firewall allow UDP 443.

### 3. Masquerade URL error

You can enter a plain domain such as `www.bing.com`.

The script will automatically normalize it to `https://www.bing.com`.

If it still fails, make sure the URL is reachable.

### 4. ACME certificate issuance failed

- Make sure the domain resolves to your VPS
- Make sure port 443 is available
- Make sure the system time is correct

### 5. Config file permission error

If you see `open /etc/hysteria/config.yaml: permission denied`, run:

```bash
chown -R hysteria:hysteria /etc/hysteria
chmod 750 /etc/hysteria
chmod 640 /etc/hysteria/config.yaml
systemctl restart hysteria-server.service
```

If the above steps do not solve your problem, please open a GitHub issue:

- <https://github.com/py473/hysteria2-onekey/issues>

If the above steps do not solve your problem, please open a GitHub issue:

- <https://github.com/py473/hysteria2-onekey/issues>