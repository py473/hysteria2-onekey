#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/py473/hysteria2-onekey"
REPO_RAW_URL="${REPO_URL}/raw/main/hy2-onekey.sh"
TMP_SCRIPT="/tmp/hy2-onekey.sh"
PROJECT_NAME="Hysteria 2 One-Key Installer"
PROJECT_VERSION="2.0.0"

cleanup() {
  rm -f "${TMP_SCRIPT}"
}

require_linux() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "此安装脚本仅支持 Linux / Unix 服务器系统，不支�?Windows�? >&2
    exit 1
  fi
}

print_banner() {
  echo "========================================"
  echo "${PROJECT_NAME}"
  echo "Version: ${PROJECT_VERSION}"
  echo "Repo: ${REPO_URL}"
  echo "========================================"
}

download_script() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${REPO_RAW_URL}" -o "${TMP_SCRIPT}"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "${TMP_SCRIPT}" "${REPO_RAW_URL}"
  else
    echo "未找�?curl �?wget，请先安装其中一个再重试�? >&2
    exit 1
  fi
}

main() {
  trap cleanup EXIT
  require_linux
  print_banner
  download_script
  chmod +x "${TMP_SCRIPT}"
  echo "正在下载并启动主脚本..."
  if [[ -r /dev/tty ]]; then
    bash "${TMP_SCRIPT}" "$@" </dev/tty
  else
    bash "${TMP_SCRIPT}" "$@"
  fi
}

main "$@"
