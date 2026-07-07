# Hysteria 2 One-Key Installer

English | [中文](README.md)

[![Release](https://img.shields.io/github/v/release/py473/hysteria2-onekey)](https://github.com/py473/hysteria2-onekey/releases)
[![License](https://img.shields.io/github/license/py473/hysteria2-onekey)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Unix-blue)](README.md)

A one-click Hysteria 2 installation and management script for **Linux / Unix server systems** with `systemd`.

**Automatically installs the latest Hysteria 2 via official `get.hy2.sh`**

Repository: <https://github.com/py473/hysteria2-onekey>

---

## Why This Script?

This script has undergone **27+ deep Bug fixes and security audits**. Compared to other one-click scripts, it offers:

| Feature | This Script |
|---------|-------------|
| **nftables/iptables Adaptive** | Tests nftables first, gracefully falls back to iptables — works in containers and legacy systems |
| **Subscription File Security** | Generates `sub_{UUID}.txt` random filenames — no more brute-forceable public URLs |
| **Full userpass Support** | URI, client config, and subscription files all correctly handle userpass auth |
| **System Performance Tuning** | Auto-tunes kernel buffers, BBR congestion control, process priority, connection limits |
| **Port Hopping** | Multi-port nftables + iptables fallback — truly usable port hopping |
| **YAML Injection Protection** | All user input is double-quoted and sanitized before writing to config files |
| **Offline-Friendly** | Gives precise install commands (`apt`/`yum`) when dependencies are missing |
| **ACME + Self-Signed Dual Mode** | Automatic Let's Encrypt for domain users; self-signed certs + insecure for IP-only users |

---

## Supported Environments

- Debian 11 / Debian 12
- Ubuntu 20.04 / 22.04 / 24.04
- Rocky Linux 8+
- CentOS Stream 8+
- Fedora 37+

---

## Features

- One-click install / upgrade Hysteria 2 (via official `get.hy2.sh`)
- Interactive server config generation (full advanced options)
- ACME auto certificate (domain deployment)
- Self-signed certificate + mTLS (IP deployment)
- Custom masquerade URL
- **Salamander / Gecko obfuscation**
- **Protocol sniffing**
- **Congestion control selection** (BBR / Reno)
- **Server-side bandwidth limiting**
- **Built-in speed test server**
- **Port Hopping** — automatic nftables/iptables rules
- **Environment variable configuration** (log level, update check)
- **userpass multi-user authentication**
- Auto-generates v2rayN-compatible subscription files (UUID random filenames)
- QR code output for easy import
- CLI parameter deployment (`--deploy`)
- **Linux performance auto-tuning**: kernel buffers, BBR, QUIC flow control windows

---

## Quick Start

### Via install.sh (recommended)

```bash
bash <(curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/install.sh)
```

### Directly run the main script

```bash
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh && bash /tmp/hy2-onekey.sh
```

---

## CLI Deployment

### Domain deployment (recommended, auto HTTPS)

```bash
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh
chmod +x /tmp/hy2-onekey.sh

/tmp/hy2-onekey.sh --deploy \
  --tls acme \
  --domain hy2.yourdomain.com \
  --email admin@yourdomain.com \
  --yes
```

### IP deployment (no domain, self-signed cert)

```bash
/tmp/hy2-onekey.sh --deploy \
  --tls cert \
  --cert /etc/hysteria/server.crt \
  --key /etc/hysteria/server.key \
  --server YOUR_SERVER_IP \
  --insecure \
  --yes
```

> ⚠️ For IP deployment, you **must enable** "Allow Insecure / Skip Certificate Verification" in your client.

### Other parameter combinations

```bash
# With Gecko obfuscation + sniffing + speed test
/tmp/hy2-onekey.sh --deploy --tls acme --domain hy2.yourdomain.com --email admin@yourdomain.com --obfs gecko --sniff --speed-test --yes

# Multi-user + bandwidth limit
/tmp/hy2-onekey.sh --deploy --tls acme --domain hy2.yourdomain.com --email admin@yourdomain.com --auth-type userpass --username user1 --password MyPass123 --bandwidth-up 100 mbps --bandwidth-down 100 mbps --yes

# With port hopping
/tmp/hy2-onekey.sh --deploy --tls acme --domain hy2.yourdomain.com --email admin@yourdomain.com --port-hopping 20000-50000 --yes
```

---

## Menu Options

| # | Function | Description |
|---|----------|-------------|
| 1 | Install/Upgrade + Interactive Config + Start | Full interactive deployment |
| 2 | Restart Service | Restart hysteria-server |
| 3 | Uninstall Hysteria 2 | Complete removal (service, nftables, subscription) |
| 4 | Show Subscription Links / Commands | Display HTTP subscription URL and common commands |
| 5 | Regenerate Subscription Files | Regenerate based on current server config (password unchanged) |
| 0 | Exit | Exit the script |

---

## Post-Installation Files

| File | Description |
|------|-------------|
| `/etc/hysteria/config.yaml` | Server config (performance-optimized) |
| `/root/sub_xxxx-xxxx-xxxx.txt` | v2rayN import info (UUID random filename) |
| `/root/hy2-client.yaml` | Client config example |
| `/etc/sysctl.d/99-hysteria-network.conf` | System buffer optimization (persistent) |
| `/etc/systemd/system/hysteria-server.service.d/priority.conf` | Process priority optimization |

---

## Subscription Service Security

The HTTP subscription service uses **UUID random filenames** (`sub_{UUID}.txt`) instead of fixed filenames:

- ✅ Even if someone knows your server IP and port, they cannot guess the subscription URL
- ✅ Each deployment generates a different UUID; old files become invalid automatically
- ✅ The service only exposes files under `/etc/hysteria/subs/`, not `/root/` or other directories

---

## Notes

- This script is for Linux / Unix servers only, not Windows
- Hysteria 2 requires **UDP 443** to be open
- For ACME certificates, ensure your domain resolves to the VPS (Cloudflare must be DNS-only)
- IP deployment users **must enable** "Allow Insecure / Skip Certificate Verification" in the client
- Enabling obfuscation breaks standard QUIC/HTTP/3 compatibility

---

## Disclaimer

Use this script only on servers you own or have permission to manage. Comply with all applicable laws and service provider policies.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
