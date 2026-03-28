#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_URL="https://raw.githubusercontent.com/py473/hysteria2-onekey/main/hy2-onekey.sh"
TMP_SCRIPT="/tmp/hy2-onekey.sh"

download_script() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${REPO_RAW_URL}" -o "${TMP_SCRIPT}"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "${TMP_SCRIPT}" "${REPO_RAW_URL}"
  else
    echo "未找到 curl 或 wget，请先安装其中一个再重试。" >&2
    exit 1
  fi
}

main() {
  download_script
  chmod +x "${TMP_SCRIPT}"
  bash "${TMP_SCRIPT}" "$@"
}

main "$@"