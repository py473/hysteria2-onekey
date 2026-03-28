# Hysteria 2 One-Key Installer v1.0.0

## What's New

- Added one-click installation entry for Linux / Unix servers
- Added interactive Hysteria 2 server deployment flow
- Added ACME and custom certificate support
- Added customizable masquerade URL
- Added v2rayN-compatible node output
- Added QR code output for easy import
- Added online install entry via `install.sh`
- Added project documentation and MIT License

## Installation

```bash
wget -O /tmp/hysteria2-onekey-install.sh https://github.com/py473/hysteria2-onekey/raw/main/install.sh && bash /tmp/hysteria2-onekey-install.sh
```

## Notes

- This project is for Linux / Unix server systems only.
- Hysteria 2 server traffic usually requires UDP 443 to be open.
- If you use ACME certificates, make sure the domain resolves to your VPS.

## Repository

<https://github.com/py473/hysteria2-onekey>