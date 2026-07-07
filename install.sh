#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/py473/hysteria2-onekey"
REPO_RAW_URL="${REPO_URL}/raw/main/hy2-onekey.sh"
TMP_SCRIPT="/tmp/hy2-onekey.sh"
PROJECT_NAME="Hysteria 2 One-Key Installer"
PROJECT_VERSION="2.1.1"

cleanup() {
  rm -f "${TMP_SCRIPT}"
}

require_linux() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "此安装脚本仅支持 Linux / Unix 服务器系统，不支持 Windows。" >&2
    exit 1
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    case "${cmd}" in
      curl)
        echo "缺少 curl。请安装: apt install -y curl  (Debian/Ubuntu) 或 yum install -y curl (CentOS/Rocky)" >&2
        ;;
      wget)
        echo "缺少 wget。请安装: apt install -y wget  (Debian/Ubuntu) 或 yum install -y wget (CentOS/Rocky)" >&2
        ;;
      *)
        echo "缺少依赖命令: ${cmd}" >&2
        ;;
    esac
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
    require_cmd curl
  fi
}

main() {
  trap cleanup EXIT
  require_linux
  # 主脚本依赖 curl，提前检查以便给出友好提示
  require_cmd curl
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
