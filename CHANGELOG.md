# Changelog

## v2.0.0

- 升级 Hysteria 2 至 v2.9.2 版本
- 新增 **Gecko 混淆** (实验性)：对 QUIC 握手包进行分片和随机填充，增强流量特征伪装
- 新增 **Salamander 混淆**：将每个数据包打乱为随机字节
- 新增 **协议嗅探 (Sniff)**：支持 HTTP/TLS/QUIC 协议源IP请求转换为域名请求
- 新增 **拥塞控制算法选择**：支持 BBR / Reno，BBR 支持 standard / conservative / aggressive 三种配置文件
- 新增 **带宽限制配置**：支持服务端上行/下行带宽速率限制
- 新增 **内置测速功能** `speedTest` 配置项
- 新增 **多认证模式**：支持 password 和 userpass 两种认证方式
- 新增 **mTLS 客户端证书验证** `clientCA` 配置项
- 新增 **SNI 验证模式** `sniGuard`：支持 strict / disable / dns-san
- 更新 `install.sh` 版本号至 v2.0.0
- 更新客户端示例配置文件，支持混淆配置输出
- 更新 URI 分享链接，支持混淆参数
- 更新交互式菜单，增加混淆方式选择步骤
- 更新文档，覆盖所有 v2.9.2 新增功能说明
- 安全性：修复 UDP 包绕过 ACL 的安全漏洞
- 安全性：修复未完成/超大的 HTTP 请求可能导致 OOM 的漏洞
- 安全性：修复域名尾随点（如 `example.com.`）绕过 ACL 的问题

## v1.0.0

- Initial release of the Hysteria 2 one-key installer
- Added Linux / Unix server support
- Added interactive Hysteria 2 deployment flow
- Added ACME and custom certificate support
- Added customizable masquerade URL support
- Added v2rayN-compatible node output
- Added QR code output for easy import
- Added online installer entry
- Added bilingual documentation and MIT License
