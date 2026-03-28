# Hysteria 2 One-Key Installer

[中文](README.md) | English

[![Release](https://img.shields.io/github/v/release/py473/hysteria2-onekey)](https://github.com/py473/hysteria2-onekey/releases)
[![License](https://img.shields.io/github/license/py473/hysteria2-onekey)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Unix-blue)](README-en.md)

This is a Hysteria 2 one-key installer for **Linux / Unix server systems**, designed for common `systemd` server environments.

Repository: <https://github.com/py473/hysteria2-onekey>

## Table of Contents

- [Supported Systems](#supported-systems)
- [Features](#features)
- [Online Install](#online-install)
- [Local Run](#local-run)
- [After Installation](#after-installation)
- [Files](#files)
- [Changelog](#changelog)
- [Troubleshooting](#troubleshooting)
- [Support](#support)
- [Security](#security)
- [Code of Conduct](#code-of-conduct)
- [Notes](#notes)
- [License](#license)

## Supported Systems

- Debian 12 / Debian 11
- Ubuntu 22.04 / 24.04
- Rocky Linux
- CentOS Stream
- Fedora

## Features

- One-click install / upgrade for Hysteria 2
- Interactive server configuration generation
- ACME automatic certificate support
- Custom certificate support
- Custom masquerade URL support
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

## Quick Deploy Examples

### ACME Automatic Certificate

```bash
./hy2-onekey.sh --deploy --tls acme --domain your.domain.com --email your@email.com --yes
```

### Custom Certificate

```bash
./hy2-onekey.sh --deploy --tls cert --cert /path/to/fullchain.pem --key /path/to/privkey.pem --server your.domain.com --sni your.domain.com --yes
```

## Files

- `install.sh`: online installer entry
- `hy2-onekey.sh`: main installer script
- `README.md`: Chinese project overview
- `README-en.md`: English project overview

## Changelog

- [CHANGELOG.md](CHANGELOG.md)

## Troubleshooting

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Support

- Latest releases: <https://github.com/py473/hysteria2-onekey/releases>
- Troubleshooting guide: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Open a new issue: <https://github.com/py473/hysteria2-onekey/issues>
- Contribute: [CONTRIBUTING.md](CONTRIBUTING.md)

## Security

If you discover a security issue related to this project, please report it via GitHub Security Advisories or contact the maintainer privately. Please do not publish sensitive details publicly.

- Security policy: [SECURITY.md](SECURITY.md)

## Code of Conduct

- Community guidelines: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## Notes

- This project is for Linux / Unix server systems only. It does not support Windows.
- Hysteria 2 servers usually require UDP 443 to be open.
- If you use ACME certificates, make sure your domain resolves to the VPS.
- Masquerade URLs can be entered as plain domains; the script will automatically prepend `https://`.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).