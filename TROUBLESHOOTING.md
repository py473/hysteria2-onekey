# Troubleshooting / 常见问题

## 中文

### 0. 安装基础工具

```bash
apt update
apt install -y curl wget ufw
```

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

如果你使用 UFW，可以执行：

```bash
ufw allow 443/udp
ufw allow 443/tcp
ufw status
```

如果你使用 iptables，可以执行：

```bash
iptables -I INPUT -p udp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
```

### 3. 迷惑问题（v2.9.2）

#### 3.1 启用混淆后连接失败

- 确认客户端也配置了相同的混淆方式和密码
- 确认 v2rayN 版本支持混淆参数
- 如果使用 Gecko，尝试切换为 Salamander 排查
- 建议手动检查 `/root/hy2-client.yaml` 中的混淆配置是否正确

#### 3.2 userpass 认证无法连接

- 确认客户端连接字符串中的密码格式正确
- userpass 模式下客户端应使用 `password` 字段，而不是传统的 `auth`

#### 3.3 启用嗅探后 ACL 异常

- 查看服务日志 `journalctl -u hysteria-server.service -e --no-pager`
- 确认是否匹配的 ACL 规则使用了域名而非 IP

### 4. 伪装地址报错

伪装地址可以直接输入域名，例如 `www.bing.com`。

脚本会自动补全成 `https://www.bing.com`。

如果仍然报错，检查地址是否能正常访问。

### 5. ACME 证书申请失败

- 确认域名已解析到 VPS
- 确认 443 端口可用
- 确认系统时间正确

### 6. 配置文件读权限错误（常见问题）

如果看到 `open /etc/hysteria/config.yaml: permission denied`，通常是因为配置文件被 root 创建后，hysteria 服务用户没有读取权限。可执行：

```bash
chown -R hysteria:hysteria /etc/hysteria
chmod 750 /etc/hysteria
chmod 640 /etc/hysteria/config.yaml
systemctl restart hysteria-server.service
```

> 本脚本 v2.0.0+ 版本已自动处理此问题，如果仍遇到请检查 SELinux 配置。


### 7. 检查 Hysteria 版本

```bash
hysteria version
```

如果上述步骤仍然无法解决问题，请在 GitHub 提交 Issue：

- <https://github.com/py473/hysteria2-onekey/issues>

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

### 3. Obfuscation issues (v2.9.2)

#### 3.1 Connection fails after enabling obfuscation

- Make sure the client is configured with the same obfuscation type and password
- Verify the v2rayN version supports obfuscation parameters
- If using Gecko, try switching to Salamander for debugging
- Manually check `/root/hy2-client.yaml` for correct obfuscation settings

#### 3.2 userpass authentication fails

- Verify the password format in the client connection string
- With userpass mode, the client should use the `password` field instead of the traditional `auth` field

#### 3.3 ACL issues after enabling sniffing

- Check the service log with `journalctl -u hysteria-server.service -e --no-pager`
- Confirm ACL rules use domain names rather than IPs

### 4. Masquerade URL error

You can enter a plain domain such as `www.bing.com`.

The script will automatically normalize it to `https://www.bing.com`.

If it still fails, make sure the URL is reachable.

### 5. ACME certificate issuance failed

- Make sure the domain resolves to your VPS
- Make sure port 443 is available
- Make sure the system time is correct

### 6. Config file permission error (common)

If you see `open /etc/hysteria/config.yaml: permission denied`, it's usually because the config file was created by root but the hysteria service user can't read it. Run:

```bash
chown -R hysteria:hysteria /etc/hysteria
chmod 750 /etc/hysteria
chmod 640 /etc/hysteria/config.yaml
systemctl restart hysteria-server.service
```
> Script v2.0.0+ handles this automatically. If still failing, check SELinux configuration.

### 7. Check Hysteria version

```bash
hysteria version
```

If the above steps do not solve your problem, please open a GitHub issue:

- <https://github.com/py473/hysteria2-onekey/issues>
