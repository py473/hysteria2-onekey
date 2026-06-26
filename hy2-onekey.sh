#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="HY2 一键安装脚本（Linux 服务器）v2.0.0"
CONFIG_PATH="/etc/hysteria/config.yaml"
CLIENT_EXAMPLE_PATH="/root/hy2-client.yaml"
SERVICE_NAME="hysteria-server.service"
INSTALL_CMD='bash <(curl -fsSL https://get.hy2.sh/)'
REMOVE_CMD='bash <(curl -fsSL https://get.hy2.sh/) --remove'

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERR]${NC} $*"; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    error "请使用 root 用户运行此脚本。"
    exit 1
  fi
}

require_linux() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    error "该脚本仅支持常见的 Linux/Unix 服务器环境。"
    exit 1
  fi
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    error "缺少依赖命令: $cmd"
    exit 1
  fi
}

random_password() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 24 | tr -d '=+/\n' | cut -c1-20
  else
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20
  fi
}

prompt_default() {
  local message="$1"
  local default_value="$2"
  local input
  read -r -p "$message [默认: ${default_value}]: " input
  if [[ -z "${input}" ]]; then
    echo "${default_value}"
  else
    echo "${input}"
  fi
}

prompt_required() {
  local message="$1"
  local input
  while true; do
    read -r -p "$message: " input
    if [[ -n "${input}" ]]; then
      echo "${input}"
      return
    fi
    warn "该项不能为空，请重新输入。"
  done
}

print_usage() {
  cat <<'EOF'
用法:
  hy2-onekey.sh                        # 交互式菜单
  hy2-onekey.sh --deploy [选项...]      # 直接部署
  hy2-onekey.sh --restart              # 重启服务
  hy2-onekey.sh --remove               # 卸载 Hysteria 2

适用环境:
  Ubuntu / Debian / Rocky Linux / CentOS Stream / Fedora 等常见 systemd 服务器系统

部署参数:
  --tls acme|cert                      TLS 方式，默认 acme
  --domain DOMAIN                      ACME 域名
  --email EMAIL                        ACME 邮箱
  --cert PATH                          证书文件路径
  --key PATH                           私钥文件路径
  --listen-port PORT                   监听端口，默认 443
  --password PASSWORD                  认证密码，留空自动生成
  --server HOST                        客户端连接地址（默认使用 domain）
  --sni HOST                           客户端 SNI，默认使用 server/domain
  --masquerade-url URL                 伪装地址 URL
  --no-masquerade                      关闭伪装
  --insecure                           客户端 TLS 忽略校验，适合自签名证书
  --yes                                直接执行，不再询问确认

高级参数 (v2.9.2+):
  --obfs salamander|gecko|off          混淆方式（默认 off）
  --obfs-password PASSWORD             混淆密码
  --sniff                             启用协议嗅探（默认开启）
  --no-sniff                           关闭协议嗅探
  --speed-test                         启用内置测速
  --auth-type password|userpass        认证类型（默认 password）
  --username USERNAME                  userpass 认证的用户名
  --bandwidth-up VALUE                 上行带宽限制（如 100 mbps）
  --bandwidth-down VALUE               下行带宽限制（如 100 mbps）
  --congestion bbr|reno                拥塞控制算法（默认 bbr）
  --bbr-profile standard|conservative|aggressive  BBR 配置文件（默认 standard）
  --client-ca PATH                     mTLS 客户端 CA 证书路径
  --sni-guard strict|disable|dns-san   SNI 验证模式（默认 dns-san）
EOF
}

print_qr_code() {
  local uri="$1"
  echo
  echo "二维码（v2rayN 可扫码/复制导入）："
  if command -v qrencode >/dev/null 2>&1; then
    qrencode -t ANSIUTF8 "${uri}"
  else
    warn "未安装 qrencode，已跳过终端二维码输出。"
    echo "可直接复制 URI：${uri}"
  fi
}

set_masquerade_block() {
  local url="$1"
  if [[ -n "${url}" ]]; then
    MASQUERADE_URL="${url}"
    MASQUERADE_BLOCK=$(cat <<EOF
masquerade:
  type: proxy
  proxy:
    url: ${MASQUERADE_URL}
    rewriteHost: true
EOF
)
  else
    MASQUERADE_URL=""
    MASQUERADE_BLOCK="# masquerade 已关闭"
  fi
}

normalize_masquerade_url() {
  local input="$1"
  input="${input#${input%%[![:space:]]*}}"
  input="${input%${input##*[![:space:]]}}"

  if [[ -z "${input}" ]]; then
    echo ""
    return
  fi

  case "${input}" in
    http://*|https://*)
      echo "${input}"
      ;;
    *)
      echo "https://${input}"
      ;;
  esac
}

install_or_upgrade_hy2() {
  info "开始执行 Hysteria 2 官方安装/升级脚本..."
  bash <(curl -fsSL https://get.hy2.sh/)
  success "Hysteria 2 安装/升级完成。"
}

remove_hy2() {
  warn "即将卸载 Hysteria 2，并移除服务。"
  read -r -p "确认卸载? 输入 YES 继续: " confirm
  if [[ "${confirm}" != "YES" ]]; then
    warn "已取消卸载。"
    return
  fi
  bash <(curl -fsSL https://get.hy2.sh/) --remove
  success "卸载完成。"
}

build_masquerade_config() {
  local choice
  echo
  echo "请选择是否开启伪装（Masquerade）："
  echo "  1) 开启（推荐，反代伪装地址）"
  echo "  2) 关闭（所有 HTTP 请求返回 404）"
  read -r -p "请输入选项 [1-2，默认 1]: " choice
  choice="${choice:-1}"

  if [[ "${choice}" == "1" ]]; then
    local masquerade_input
    masquerade_input="$(prompt_required "请输入你想伪装成的网站地址（直接输域名也可以，例如 www.bing.com）")"
    masquerade_input="$(normalize_masquerade_url "${masquerade_input}")"

    if [[ -z "${masquerade_input}" ]]; then
      error "你还没有输入伪装地址，请重新输入。"
      exit 1
    fi

    set_masquerade_block "${masquerade_input}"
  else
    set_masquerade_block ""
  fi
}

uri_encode() {
  local raw="$1"
  local encoded=""
  local pos char hex

  for ((pos = 0; pos < ${#raw}; pos++)); do
    char="${raw:pos:1}"
    case "${char}" in
      [a-zA-Z0-9.~_-])
        encoded+="${char}"
        ;;
      *)
        printf -v hex '%%%02X' "'${char}"
        encoded+="${hex}"
        ;;
    esac
  done

  printf '%s' "${encoded}"
}

uri_host() {
  local host="$1"
  if [[ "${host}" == *:* && "${host}" != \[*\] ]]; then
    printf '[%s]' "${host}"
  else
    printf '%s' "${host}"
  fi
}

prompt_tls_insecure() {
  local choice
  echo
  echo "证书校验方式："
  echo "  1) 正常校验（推荐，适用于 ACME 或受信任证书）"
  echo "  2) 忽略证书校验（适用于自签名证书，v2rayN 常用）"
  read -r -p "请输入选项 [1-2，默认 1]: " choice
  choice="${choice:-1}"

  if [[ "${choice}" == "2" ]]; then
    TLS_INSECURE="true"
  else
    TLS_INSECURE="false"
  fi
}

# ---- v2.9.2 新功能：混淆 (Obfuscation) ----
build_obfuscation_block() {
  local obfs_type="$1"
  local obfs_password="$2"

  if [[ -z "${obfs_type}" || "${obfs_type}" == "off" ]]; then
    OBFS_BLOCK="# obfuscation 未启用 (v2.9.2 可选)"
    return
  fi

  if [[ -z "${obfs_password}" ]]; then
    obfs_password="$(random_password)"
    success "已自动生成混淆密码。"
  fi

  case "${obfs_type}" in
    salamander)
      OBFS_BLOCK=$(cat <<EOF
obfs:
  type: salamander
  salamander:
    password: ${obfs_password}
EOF
)
      ;;
    gecko)
      OBFS_BLOCK=$(cat <<EOF
obfs:
  type: gecko
  gecko:
    password: ${obfs_password}
    minPacketSize: 512
    maxPacketSize: 1200
EOF
)
      ;;
    *)
      OBFS_BLOCK="# obfuscation 未启用"
      ;;
  esac
}

prompt_obfuscation() {
  local choice
  echo
  echo "请选择混淆方式 v2.9.2："
  echo "  Salamander: 将每个包伪造成随机字节（兼容 v2）"
  echo "  Gecko:      在 Salamander 基础上分片 QUIC 握手包（实验性）"
  echo "  0) 不启用混淆（保持标准 HTTP/3 外观）"
  echo "  1) Salamander"
  echo "  2) Gecko（实验性）"
  read -r -p "请输入选项 [0-2，默认 0]: " choice
  choice="${choice:-0}"

  case "${choice}" in
    1) OBFUSCATION_TYPE="salamander" ;;
    2) OBFUSCATION_TYPE="gecko" ;;
    *) OBFUSCATION_TYPE="off" ;;
  esac

  if [[ "${OBFUSCATION_TYPE}" != "off" ]]; then
    local pwd_input
    read -r -p "请输入混淆密码（留空自动生成）: " pwd_input
    OBFUSCATION_PASSWORD="${pwd_input}"
  fi
}

# ---- v2.9.2 新功能：协议嗅探 (Sniff) ----
build_sniff_block() {
  local enabled="$1"
  if [[ "${enabled}" == "true" ]]; then
    SNIFF_BLOCK=$(cat <<EOF
sniff:
  enable: true
  timeout: 2s
  rewriteDomain: false
  tcpPorts: 80,443,8000-9000
  udpPorts: all
EOF
)
  else
    SNIFF_BLOCK="# sniff 未启用"
  fi
}

# ---- v2.9.2 新功能：拥塞控制 (Congestion) ----
build_congestion_block() {
  local congestion_type="$1"
  local bbr_profile="$2"

  if [[ -z "${congestion_type}" ]]; then
    CONGESTION_BLOCK="# congestion 使用默认 BBR"
    return
  fi

  case "${congestion_type}" in
    bbr)
      CONGESTION_BLOCK=$(cat <<EOF
congestion:
  type: bbr
  bbrProfile: ${bbr_profile:-standard}
EOF
)
      ;;
    reno)
      CONGESTION_BLOCK=$(cat <<EOF
congestion:
  type: reno
EOF
)
      ;;
    *)
      CONGESTION_BLOCK="# congestion 使用默认 BBR"
      ;;
  esac
}

# ---- v2.9.2 新功能：带宽限制 (Bandwidth) ----
build_bandwidth_block() {
  local up="$1"
  local down="$2"
  if [[ -n "${up}" || -n "${down}" ]]; then
    BANDWIDTH_BLOCK=$(cat <<EOF
bandwidth:
EOF
)
    if [[ -n "${up}" ]]; then
      BANDWIDTH_BLOCK+=$(cat <<EOF
  up: ${up}
EOF
)
    fi
    if [[ -n "${down}" ]]; then
      BANDWIDTH_BLOCK+=$(cat <<EOF
  down: ${down}
EOF
)
    fi
  else
    BANDWIDTH_BLOCK="# bandwidth 未设置"
  fi
}

write_config_acme() {
  local domain="$1"
  local email="$2"
  local port="$3"
  local password="$4"
  local auth_type="${5:-password}"
  local username="${6:-}"

  cat >"${CONFIG_PATH}" <<EOF
listen: :${port}

acme:
  domains:
    - ${domain}
  email: ${email}

auth:
  type: ${auth_type}
EOF
  if [[ "${auth_type}" == "userpass" && -n "${username}" ]]; then
    cat >>"${CONFIG_PATH}" <<EOF
  userpass:
    ${username}: ${password}
EOF
  else
    cat >>"${CONFIG_PATH}" <<EOF
  password: ${password}
EOF
  fi

  cat >>"${CONFIG_PATH}" <<EOF

${BANDWIDTH_BLOCK}

${CONGESTION_BLOCK}

${OBFS_BLOCK}

${SNIFF_BLOCK}

${MASQUERADE_BLOCK}

# speedTest: false
EOF
}

write_config_cert() {
  local cert_path="$1"
  local key_path="$2"
  local port="$3"
  local password="$4"
  local auth_type="${5:-password}"
  local username="${6:-}"
  local client_ca="${7:-}"
  local sni_guard="${8:-dns-san}"

  cat >"${CONFIG_PATH}" <<EOF
listen: :${port}

tls:
  cert: ${cert_path}
  key: ${key_path}
EOF
  if [[ -n "${client_ca}" ]]; then
    cat >>"${CONFIG_PATH}" <<EOF
  clientCA: ${client_ca}
EOF
  fi
  if [[ -n "${sni_guard}" ]]; then
    cat >>"${CONFIG_PATH}" <<EOF
  sniGuard: ${sni_guard}
EOF
  fi

  cat >>"${CONFIG_PATH}" <<EOF

auth:
  type: ${auth_type}
EOF
  if [[ "${auth_type}" == "userpass" && -n "${username}" ]]; then
    cat >>"${CONFIG_PATH}" <<EOF
  userpass:
    ${username}: ${password}
EOF
  else
    cat >>"${CONFIG_PATH}" <<EOF
  password: ${password}
EOF
  fi

  cat >>"${CONFIG_PATH}" <<EOF

${BANDWIDTH_BLOCK}

${CONGESTION_BLOCK}

${OBFS_BLOCK}

${SNIFF_BLOCK}

${MASQUERADE_BLOCK}

# speedTest: false
EOF
}

write_client_example() {
  local server_addr="$1"
  local port="$2"
  local password="$3"
  local sni="$4"
  local insecure="$5"
  local obfs_type="${6:-}"
  local obfs_password="${7:-}"
  local auth_type="${8:-password}"

  local auth_block
  if [[ "${auth_type}" == "userpass" ]]; then
    auth_block="auth_str: ${password}"
  else
    auth_block="auth: ${password}"
  fi

  local obfs_block=""
  if [[ -n "${obfs_type}" && "${obfs_type}" != "off" ]]; then
    obfs_block=$(cat <<EOF

obfs:
  type: ${obfs_type}
EOF
)
    if [[ "${obfs_type}" == "salamander" ]]; then
      obfs_block+=$(cat <<EOF
  salamander:
    password: ${obfs_password}
EOF
)
    elif [[ "${obfs_type}" == "gecko" ]]; then
      obfs_block+=$(cat <<EOF
  gecko:
    password: ${obfs_password}
    minPacketSize: 512
    maxPacketSize: 1200
EOF
)
    fi
  fi

  cat >"${CLIENT_EXAMPLE_PATH}" <<EOF
server: "${server_addr}:${port}"
${auth_block}

tls:
  sni: ${sni}
  insecure: ${insecure}
${obfs_block}

socks5:
  listen: 127.0.0.1:1080

http:
  listen: 127.0.0.1:8080
EOF

  chmod 600 "${CLIENT_EXAMPLE_PATH}"
}

restart_service() {
  info "启动并设置开机自启: ${SERVICE_NAME}"
  systemctl enable --now "${SERVICE_NAME}"
  systemctl restart "${SERVICE_NAME}"

  if systemctl is-active --quiet "${SERVICE_NAME}"; then
    success "服务已启动。"
  else
    error "服务启动失败，请执行 journalctl --no-pager -e -u ${SERVICE_NAME} 查看日志。"
    exit 1
  fi
}

generate_uri() {
  local server_addr="$1"
  local port="$2"
  local password="$3"
  local sni="$4"
  local insecure="$5"
  local obfs_type="${6:-}"
  local obfs_password="${7:-}"
  local auth_encoded
  local sni_encoded
  local host
  local query

  auth_encoded="$(uri_encode "${password}")"
  sni_encoded="$(uri_encode "${sni}")"
  host="$(uri_host "${server_addr}")"
  query="sni=${sni_encoded}"
  if [[ "${insecure}" == "true" ]]; then
    query="${query}&insecure=1"
  fi
  if [[ -n "${obfs_type}" && "${obfs_type}" != "off" ]]; then
    query="${query}&obfs=${obfs_type}"
    if [[ -n "${obfs_password}" ]]; then
      local obfs_pwd_enc
      obfs_pwd_enc="$(uri_encode "${obfs_password}")"
      query="${query}&obfs-password=${obfs_pwd_enc}"
    fi
  fi

  echo "hysteria2://${auth_encoded}@${host}:${port}/?${query}#HY2"
}

deploy_with_config() {
  require_cmd curl
  require_cmd grep
  require_cmd sed
  require_cmd systemctl

  install_or_upgrade_hy2

  mkdir -p /etc/hysteria

  local server_addr
  local sni
  local TLS_INSECURE="false"
  local tls_choice="${HY2_TLS:-1}"
  local listen_port="${HY2_LISTEN_PORT:-443}"
  local auth_password="${HY2_PASSWORD:-}"
  local auth_type="${HY2_AUTH_TYPE:-password}"
  local auth_username="${HY2_USERNAME:-}"

  if [[ -z "${auth_password}" ]]; then
    auth_password="$(random_password)"
    success "已自动生成认证密码。"
  fi

  # ---- 处理 Obfuscation ----
  OBFUSCATION_TYPE="${HY2_OBFS:-off}"
  OBFUSCATION_PASSWORD="${HY2_OBFS_PASSWORD:-}"
  if [[ "${OBFUSCATION_TYPE}" != "off" && -z "${OBFUSCATION_PASSWORD}" ]]; then
    OBFUSCATION_PASSWORD="$(random_password)"
    success "已自动生成混淆密码。"
  fi
  build_obfuscation_block "${OBFUSCATION_TYPE}" "${OBFUSCATION_PASSWORD}"

  # ---- 处理 Sniff ----
  local sniff_enabled
  if [[ "${HY2_SNIFF:-true}" == "true" ]]; then
    sniff_enabled="true"
  else
    sniff_enabled="false"
  fi
  build_sniff_block "${sniff_enabled}"

  # ---- 处理 Speed Test ----
  local speed_test_enabled="${HY2_SPEED_TEST:-false}"

  # ---- 处理 BBR Profile ----
  local congestion_type="${HY2_CONGESTION:-bbr}"
  local bbr_profile="${HY2_BBR_PROFILE:-standard}"
  build_congestion_block "${congestion_type}" "${bbr_profile}"

  # ---- 处理 Bandwidth ----
  local bw_up="${HY2_BANDWIDTH_UP:-}"
  local bw_down="${HY2_BANDWIDTH_DOWN:-}"
  build_bandwidth_block "${bw_up}" "${bw_down}"

  # ---- 处理 Masquerade ----
  if [[ -n "${HY2_MASQUERADE_URL:-}" ]]; then
    set_masquerade_block "${HY2_MASQUERADE_URL}"
  elif [[ "${HY2_NO_MASQUERADE:-false}" == "true" || "${HY2_YES:-false}" == "true" ]]; then
    set_masquerade_block ""
  else
    build_masquerade_config
  fi

  if [[ "${HY2_INSECURE:-false}" == "true" ]]; then
    TLS_INSECURE="true"
  fi

  if [[ "${tls_choice}" == "1" ]]; then
    local domain="${HY2_DOMAIN:-}"
    local email="${HY2_EMAIL:-}"

    if [[ -z "${domain}" ]]; then
      if [[ "${HY2_YES:-false}" == "true" ]]; then
        error "--yes 模式下必须提供 --domain。"
        exit 1
      fi
      domain="$(prompt_required "请输入你的域名（需已解析到 VPS）")"
    fi
    if [[ -z "${email}" ]]; then
      if [[ "${HY2_YES:-false}" == "true" ]]; then
        error "--yes 模式下必须提供 --email。"
        exit 1
      fi
      email="$(prompt_required "请输入 ACME 邮箱")"
    fi

    # 交互式确认混淆和嗅探
    if [[ "${HY2_YES:-false}" != "true" ]]; then
      prompt_obfuscation
      build_obfuscation_block "${OBFUSCATION_TYPE}" "${OBFUSCATION_PASSWORD}"
    fi

    write_config_acme "${domain}" "${email}" "${listen_port}" "${auth_password}" "${auth_type}" "${auth_username}"

    server_addr="${domain}"
    sni="${domain}"
    TLS_INSECURE="false"
  else
    local cert_path="${HY2_CERT:-}"
    local key_path="${HY2_KEY:-}"
    local client_ca="${HY2_CLIENT_CA:-}"
    local sni_guard="${HY2_SNI_GUARD:-dns-san}"

    if [[ -z "${cert_path}" ]]; then
      if [[ "${HY2_YES:-false}" == "true" ]]; then
        error "--yes 模式下必须提供 --cert。"
        exit 1
      fi
      cert_path="$(prompt_required "请输入证书文件路径（cert）")"
    fi
    if [[ -z "${key_path}" ]]; then
      if [[ "${HY2_YES:-false}" == "true" ]]; then
        error "--yes 模式下必须提供 --key。"
        exit 1
      fi
      key_path="$(prompt_required "请输入私钥文件路径（key）")"
    fi

    if [[ ! -f "${cert_path}" || ! -f "${key_path}" ]]; then
      error "证书文件不存在，请检查路径后重试。"
      exit 1
    fi

    # 交互式确认混淆和嗅探
    if [[ "${HY2_YES:-false}" != "true" ]]; then
      prompt_obfuscation
      build_obfuscation_block "${OBFUSCATION_TYPE}" "${OBFUSCATION_PASSWORD}"
    fi

    write_config_cert "${cert_path}" "${key_path}" "${listen_port}" "${auth_password}" "${auth_type}" "${auth_username}" "${client_ca}" "${sni_guard}"

    server_addr="${HY2_SERVER:-}"
    if [[ -z "${server_addr}" ]]; then
      if [[ "${HY2_YES:-false}" == "true" ]]; then
        error "--yes 模式下必须提供 --server。"
        exit 1
      fi
      server_addr="$(prompt_required "请输入客户端连接地址（域名或 IP）")"
    fi
    sni="${HY2_SNI:-}"
    if [[ -z "${sni}" ]]; then
      if [[ "${HY2_YES:-false}" == "true" ]]; then
        sni="${server_addr}"
      else
        sni="$(prompt_default "请输入客户端 SNI" "${server_addr}")"
      fi
    fi
    if [[ "${HY2_INSECURE:-false}" == "true" ]]; then
      TLS_INSECURE="true"
    elif [[ "${HY2_YES:-false}" == "true" ]]; then
      TLS_INSECURE="false"
    else
      prompt_tls_insecure
    fi
  fi

  chmod 640 "${CONFIG_PATH}"
  chown hysteria:hysteria /etc/hysteria/config.yaml 2>/dev/null || true
  restart_service
  write_client_example "${server_addr}" "${listen_port}" "${auth_password}" "${sni}" "${TLS_INSECURE}" "${OBFUSCATION_TYPE}" "${OBFUSCATION_PASSWORD}" "${auth_type}"

  local share_uri
  share_uri="$(generate_uri "${server_addr}" "${listen_port}" "${auth_password}" "${sni}" "${TLS_INSECURE}" "${OBFUSCATION_TYPE}" "${OBFUSCATION_PASSWORD}")"

  cat >"/root/hy2-v2rayn.txt" <<EOF
v2rayN 导入信息
================
协议：Hysteria2
导入方式：直接粘贴下面的 URI 到 v2rayN

${share_uri}
EOF
  chmod 600 "/root/hy2-v2rayn.txt"

  echo
  success "部署完成。"
  echo "--------------------------------------------------"
  echo "服务配置文件: ${CONFIG_PATH}"
  echo "客户端示例文件: ${CLIENT_EXAMPLE_PATH}"
  echo "认证密码: ${auth_password}"
  echo "连接地址: ${server_addr}:${listen_port}"
  echo "SNI: ${sni}"
  echo "TLS 校验: ${TLS_INSECURE}"
  if [[ -n "${MASQUERADE_URL}" ]]; then
    echo "伪装地址: ${MASQUERADE_URL}"
  else
    echo "伪装地址: 已关闭"
  fi
  if [[ "${OBFUSCATION_TYPE}" != "off" ]]; then
    echo "混淆方式: ${OBFUSCATION_TYPE}"
    echo "混淆密码: ${OBFUSCATION_PASSWORD}"
  fi
  if [[ "${sniff_enabled}" == "true" ]]; then
    echo "协议嗅探: 已开启"
  fi
  if [[ "${speed_test_enabled}" == "true" ]]; then
    echo "测速功能: 已开启"
  fi
  echo "分享 URI: ${share_uri}"
  echo "v2rayN 导入文件: /root/hy2-v2rayn.txt"
  echo "v2rayN 使用方式：在 v2rayN 中新增 Hysteria2 节点，或直接粘贴上面的 URI。"
  print_qr_code "${share_uri}"
  echo "--------------------------------------------------"
  echo "常用命令："
  echo "  systemctl status ${SERVICE_NAME}"
  echo "  journalctl --no-pager -e -u ${SERVICE_NAME}"
  echo "  hysteria version"
}

show_menu() {
  echo "=================================================="
  echo "${SCRIPT_NAME}"
  echo "基于 Hysteria 2 v2.9.2 官方文档安装方式（get.hy2.sh）"
  echo "=================================================="
  echo "1) 一键安装/升级 + 交互式生成配置 + 启动服务"
  echo "2) 仅重启服务"
  echo "3) 卸载 Hysteria 2"
  echo "0) 退出"
  echo
}

main() {
  require_root
  require_linux

  if [[ $# -gt 0 ]]; then
    case "$1" in
      --help|-h)
        print_usage
        exit 0
        ;;
      --restart)
        restart_service
        exit 0
        ;;
      --remove)
        remove_hy2
        exit 0
        ;;
      --deploy)
        shift
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --tls)
              HY2_TLS="${2:-}"
              shift 2
              ;;
            --domain)
              HY2_DOMAIN="${2:-}"
              shift 2
              ;;
            --email)
              HY2_EMAIL="${2:-}"
              shift 2
              ;;
            --cert)
              HY2_CERT="${2:-}"
              shift 2
              ;;
            --key)
              HY2_KEY="${2:-}"
              shift 2
              ;;
            --listen-port)
              HY2_LISTEN_PORT="${2:-}"
              shift 2
              ;;
            --password)
              HY2_PASSWORD="${2:-}"
              shift 2
              ;;
            --server)
              HY2_SERVER="${2:-}"
              shift 2
              ;;
            --sni)
              HY2_SNI="${2:-}"
              shift 2
              ;;
            --masquerade-url)
              HY2_MASQUERADE_URL="${2:-}"
              shift 2
              ;;
            --no-masquerade)
              HY2_NO_MASQUERADE="true"
              shift 1
              ;;
            --insecure)
              HY2_INSECURE="true"
              shift 1
              ;;
            --yes)
              HY2_YES="true"
              shift 1
              ;;
            # ---- v2.9.2 新参数 ----
            --obfs)
              HY2_OBFS="${2:-off}"
              shift 2
              ;;
            --obfs-password)
              HY2_OBFS_PASSWORD="${2:-}"
              shift 2
              ;;
            --sniff)
              HY2_SNIFF="true"
              shift 1
              ;;
            --no-sniff)
              HY2_SNIFF="false"
              shift 1
              ;;
            --speed-test)
              HY2_SPEED_TEST="true"
              shift 1
              ;;
            --auth-type)
              HY2_AUTH_TYPE="${2:-password}"
              shift 2
              ;;
            --username)
              HY2_USERNAME="${2:-}"
              shift 2
              ;;
            --bandwidth-up)
              HY2_BANDWIDTH_UP="${2:-}"
              shift 2
              ;;
            --bandwidth-down)
              HY2_BANDWIDTH_DOWN="${2:-}"
              shift 2
              ;;
            --congestion)
              HY2_CONGESTION="${2:-bbr}"
              shift 2
              ;;
            --bbr-profile)
              HY2_BBR_PROFILE="${2:-standard}"
              shift 2
              ;;
            --client-ca)
              HY2_CLIENT_CA="${2:-}"
              shift 2
              ;;
            --sni-guard)
              HY2_SNI_GUARD="${2:-dns-san}"
              shift 2
              ;;
            *)
              error "未知参数: $1"
              print_usage
              exit 1
              ;;
          esac
        done
        if [[ -z "${HY2_TLS:-}" ]]; then
          if [[ -n "${HY2_CERT:-}" || -n "${HY2_KEY:-}" ]]; then
            HY2_TLS="2"
          else
            HY2_TLS="1"
          fi
        elif [[ "${HY2_TLS}" == "acme" ]]; then
          HY2_TLS="1"
        elif [[ "${HY2_TLS}" == "cert" ]]; then
          HY2_TLS="2"
        fi

        if [[ "${HY2_YES:-false}" == "true" ]]; then
          deploy_with_config
        else
          warn "即将开始部署，若有遗漏参数脚本仍会继续询问。"
          deploy_with_config
        fi
        exit 0
        ;;
    esac
  fi

  local choice
  show_menu
  read -r -p "请选择操作 [0-3，默认 1]: " choice
  choice="${choice:-1}"

  case "${choice}" in
    1)
      deploy_with_config
      ;;
    2)
      restart_service
      ;;
    3)
      remove_hy2
      ;;
    0)
      info "已退出。"
      ;;
    *)
      error "无效选项。"
      exit 1
      ;;
  esac
}

main "$@"
