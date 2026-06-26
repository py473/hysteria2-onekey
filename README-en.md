# Hysteria 2 One-Key Installer

[中文](README.md) | English

[![Release](https://img.shields.io/github/v/release/py473/hysteria2-onekey)](https://github.com/py473/hysteria2-onekey/releases)
[![License](https://img.shields.io/github/license/py473/hysteria2-onekey)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Unix-blue)](README-en.md)

This is a Hysteria 2 one-key installer for **Linux / Unix server systems**, designed for common `systemd` server environments.

**Built-in Hysteria 2 version: v2.9.2** (auto-installs latest via official `get.hy2.sh`)

Repository: <https://github.com/py473/hysteria2-onekey>

## Table of Contents

- [Supported Systems](#supported-systems)
- [Features](#features)
- [Quick Start](#quick-start)
- [Step-by-Step Guide](#step-by-step-guide)
- [CLI Examples](#cli-examples)
- [After Installation](#after-installation)
- [v2.9.2 New Features](#v292-new-features)
- [Notes](#notes)
- [License](#license)

## Supported Systems

- Debian 12 / Debian 11
- Ubuntu 22.04 / 24.04
- Rocky Linux
- CentOS Stream
- Fedora

## Features

- One-click install / upgrade for Hysteria 2 (v2.9.2)
- Interactive server configuration generation
- ACME automatic certificate support
- Custom certificate + mTLS support
- Custom masquerade URL support
- **Salamander / Gecko obfuscation** (new in v2.9.2)
- **Protocol sniffing** (HTTP/TLS/QUIC)
- **Congestion control** (BBR / Reno)
- **Server bandwidth limiting**
- **Built-in speed test server**
- **userpass multi-user authentication**
- v2rayN-compatible node output
- QR code output for easy import
- Parameter-based deployment support
- **Linux performance auto-tuning**: sysctl buffer tuning, process real-time priority, QUIC flow control windows

## Quick Start

Recommended command:

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

If `wget` is not available:

```bash
curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/install.sh -o /tmp/hysteria2-onekey-install.sh && bash /tmp/hysteria2-onekey-install.sh
```

## Step-by-Step Guide

New to this? Check out the detailed tutorial:

📘 [**GUIDE.md — Hysteria 2 Deployment Guide (Chinese)**](GUIDE.md)

Covers: VPS preparation, SSH connection, interactive deployment walkthrough, CLI mode, v2rayN setup, daily management, troubleshooting.

## CLI Examples

### Interactive Mode

```bash
wget -O /tmp/hy2-onekey.sh https://github.com/py473/hysteria2-onekey/raw/main/hy2-onekey.sh
chmod +x /tmp/hy2-onekey.sh
/tmp/hy2-onekey.sh
```

### One-Command Deploy

```bash
# ACME auto certificate (recommended)
/tmp/hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --yes

# ACME + Gecko obfuscation + sniff + speed test
/tmp/hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --obfs gecko --sniff --speed-test --yes

# Custom certificate
/tmp/hy2-onekey.sh --deploy --tls cert --cert /path/to/fullchain.pem --key /path/to/privkey.pem --server your.domain.com --yes

# Multi-user + bandwidth limit
/tmp/hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --auth-type userpass --username user1 --password MyPass123 --bandwidth-up 100 mbps --bandwidth-down 100 mbps --yes
```

### Other Commands

```bash
# View help
/tmp/hy2-onekey.sh --help

# Restart service
/tmp/hy2-onekey.sh --restart

# Uninstall
/tmp/hy2-onekey.sh --remove
```

## After Installation

Files generated on the server:

| File | Description |
|------|-------------|
| `/etc/hysteria/config.yaml` | Server config (auto-optimized) |
| `/root/hy2-v2rayn.txt` | v2rayN import data (copy the URI) |
| `/root/hy2-client.yaml` | Client example config |
| `/etc/sysctl.d/99-hysteria.conf` | sysctl buffer tuning (persistent) |
| `/etc/systemd/system/hysteria-server.service.d/priority.conf` | Process priority tuning (persistent) |

## v2.9.2 New Features

### 🔐 Security Fixes
- Fixed UDP packet bypass of ACL
- Fixed potential OOM from incomplete/oversized HTTP requests
- Fixed ACL bypass via trailing dots in domain names

### 🆕 Obfuscation
- **Salamander**: scrambles every packet into seemingly random bytes
- **Gecko (experimental)**: fragments QUIC handshake packets into randomly-sized datagrams
- Enabling obfuscation makes the server incompatible with standard QUIC/HTTP/3

### 🔍 Protocol Sniffing
- Supports HTTP, TLS (HTTPS), and QUIC (HTTP/3) protocol detection

### 🚦 Congestion Control
- Supports **BBR** (default) and **Reno** algorithms
- BBR profiles: `standard`, `conservative`, `aggressive`

### 📊 Bandwidth Limiting
- Per-client upload/download bandwidth rate limiting

### ⚡ Speed Test
- Built-in speed test server for client download/upload testing

### 👥 Multi-User Authentication
- `password`: single password (default)
- `userpass`: username-password pair authentication

### 🔒 mTLS
- Client certificate verification via `clientCA` configuration option

## Notes

- This project is for Linux / Unix server systems only.
- Hysteria 2 servers usually require **UDP 443** to be open.
- For ACME certificates, make sure your domain resolves to the VPS.
- Enabling obfuscation makes the server incompatible with standard QUIC/HTTP/3 connections.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
