# Hysteria 2 One-Key Installer

[中文](README.md) | English

[![Release](https://img.shields.io/github/v/release/py473/hysteria2-onekey)](https://github.com/py473/hysteria2-onekey/releases)
[![License](https://img.shields.io/github/license/py473/hysteria2-onekey)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Blue)](README-en.md)

This is a Hysteria 2 one-key installer for **Linux / Unix server systems**, designed for common `systemd` server environments.

**Built-in Hysteria 2 version: v2.9.2** (auto-installs latest via official `get.hy2.sh`)

Repository: <https://github.com/py473/hysteria2-onekey>

## Table of Contents

- [Supported Systems](#supported-systems)
- [Features](#features)
- [Online Install](#online-install)
- [Installation Guide](#installation-guide)
- [Examples](#examples)
- [Local Run](#local-run)
- [After Installation](#after-installation)
- [v2.9.2 New Features](#v292-new-features)
- [Files](#files)
- [Changelog](#changelog)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Support](#support)
- [Clients](#clients)
- [Security](#security)
- [Code of Conduct](#code-of-conduct)
- [Common Commands](#common-commands)
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
- Online one-line installer

## Online Install

Recommended command:

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

If `wget` is not available on the server, use `curl`:

```bash
curl -fsSL https://github.com/py473/hysteria2-onekey/raw/main/install.sh -o /tmp/hysteria2-onekey-install.sh && bash /tmp/hysteria2-onekey-install.sh
```

After the installer starts, it will show a menu. Please enter the menu number directly in the menu, not at the shell prompt.

## Installation Guide

- [INSTALLATION.md](INSTALLATION.md)

## Examples

- [EXAMPLES.md](EXAMPLES.md)

## Local Run

```bash
cd /root/hysteria
chmod +x hy2-onekey.sh
./hy2-onekey.sh
```

View help:

```bash
./hy2-onekey.sh --help
```

## After Installation

The script usually generates the following files on the server:

- `/etc/hysteria/config.yaml`: server configuration
- `/root/hy2-v2rayn.txt`: v2rayN import information
- `/root/hy2-client.yaml`: client example configuration

## v2.9.2 New Features

### 🔐 Security Fixes
- Fixed UDP packet bypass of ACL
- Fixed potential OOM from incomplete/oversized HTTP requests
- Fixed ACL bypass via trailing dots in domain names (e.g., `example.com.`)

### 🆕 Obfuscation
- **Salamander**: scrambles every packet into seemingly random bytes
- **Gecko (experimental)**: fragments QUIC handshake packets into randomly-sized, randomly-padded datagrams
- Enabling obfuscation makes the server incompatible with standard QUIC/HTTP/3

### 🔍 Protocol Sniffing
- Supports HTTP, TLS (HTTPS), and QUIC (HTTP/3) protocol detection
- Converts IP requests to domain requests for ACL compatibility
- Can be disabled with `--no-sniff`

### 🚦 Congestion Control
- Supports **BBR** (default) and **Reno** algorithms
- BBR profiles: `standard`, `conservative`, `aggressive`

### 📊 Bandwidth Limiting
- Per-client upload/download bandwidth rate limiting on the server side
- Supported units: bps, kbps, mbps, gbps, tbps

### ⚡ Speed Test
- Built-in speed test server for client download/upload testing

### 👥 Multi-User Authentication
- `password`: single password (default)
- `userpass`: username-password pair authentication

### 🔒 mTLS
- Client certificate verification via `clientCA` configuration option

## Quick Deploy Examples

### ACME Automatic Certificate

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --yes
```

### ACME + Gecko Obfuscation

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --obfs gecko --yes
```

### Custom Certificate + Salamander Obfuscation + Sniffing

```bash
./hy2-onekey.sh --deploy --tls cert --cert /path/to/fullchain.pem --key /path/to/privkey.pem --server your.domain.com --sni your.domain.com --obfs salamander --sniff --yes
```

### Multi-User + Bandwidth Limiting

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --auth-type userpass --username user1 --password MyPass123 --bandwidth-up 100 mbps --bandwidth-down 100 mbps --yes
```

## Files

- `install.sh`: online installer entry
- `hy2-onekey.sh`: main installer script (v2.0.0)
- `README.md`: Chinese project overview
- `README-en.md`: English project overview
- `INSTALLATION.md`: beginner installation guide
- `EXAMPLES.md`: example commands
- `RELEASE.md`: release notes
- `DOCS.md`: documentation overview
- `CHANGELOG.md`: changelog

## Changelog

- [CHANGELOG.md](CHANGELOG.md)

## Troubleshooting

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## FAQ

- [FAQ.md](FAQ.md)

## Support

- Latest releases: <https://github.com/py473/hysteria2-onekey/releases>
- Troubleshooting guide: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- FAQ: [FAQ.md](FAQ.md)
- Open a new issue: <https://github.com/py473/hysteria2-onekey/issues>
- Contribute: [CONTRIBUTING.md](CONTRIBUTING.md)

## Clients

The following clients can be used to import or use Hysteria 2 configurations. Please refer to each project's official page for downloads:

- v2rayN: <https://github.com/2dust/v2rayN>
- Clash.Meta: <https://github.com/MetaCubeX/Clash.Meta>
- sing-box: <https://github.com/SagerNet/sing-box>
- Hiddify Next: <https://github.com/hiddify/hiddify-next>
- NekoBox for Android: <https://github.com/MatsuriDayo/NekoBoxForAndroid>
- V2Box: <https://apps.apple.com/app/v2box-v2ray-client/id6446814690>

For more Hysteria 2-compatible third-party apps, see the official list:

- <https://v2.hysteria.network/docs/getting-started/3rd-party-apps/>

## Security

If you discover a security issue related to this project, please report it via GitHub Security Advisories or contact the maintainer privately. Please do not publish sensitive details publicly.

- Security policy: [SECURITY.md](SECURITY.md)

## Code of Conduct

- Community guidelines: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## Common Commands

- Installation guide: [INSTALLATION.md](INSTALLATION.md)
- Example commands: [EXAMPLES.md](EXAMPLES.md)

## Notes

- This project is for Linux / Unix server systems only. It does not support Windows.
- Hysteria 2 servers usually require UDP 443 to be open.
- If you use ACME certificates, make sure your domain resolves to the VPS.
- Masquerade URLs can be entered as plain domains; the script will automatically prepend `https://`.
- Enabling obfuscation makes the server incompatible with standard QUIC/HTTP/3 connections.
- If you use UFW, install `ufw` first and allow both `443/udp` and `443/tcp`.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
