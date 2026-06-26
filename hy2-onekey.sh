#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="HY2 一键安装脚本（Linux 服务器）v2.1.0"
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

# ---- 通用：验证端口范围格式 ----
validate_port_range() {
  local input="$1"
  # 支持格式：80,443,20000-50000
  if [[ -z "${input}" ]]; then
    return 1
  fi
  while IFS=',' read -ra parts; do
    for part in "${parts[@]}"; do
      part="${part// /}"
      if [[ "${part}" =~ ^([0-9]+)-([0-9]+)$ ]]; then
        if [[ "${BASH_REMATCH[1]}" -lt 1 || "${BASH_REMATCH[1]}" -gt 65535 || \
              "${BASH_REMATCH[2]}" -lt 1 || "${BASH_REMATCH[2]}" -gt 65535 ]]; then
          return 1
        fi
      elif [[ "${part}" =~ ^[0-9]+$ ]]; then
        if [[ "${part}" -lt 1 || "${part}" -gt 65535 ]]; then
          return 1
        fi
      else
        return 1
      fi
    done
  done <<< "${input}"
  return 0
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

基础部署参数:
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

高级功能参数:
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
  --port-hopping RANGE                 端口跳跃范围（如 20000-50000）
  --log-level debug|info|warn|error    日志级别（默认 info）
  --disable-update-check               关闭启动时的版本更新检查
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
  # 清理端口跳跃残留
  if command -v nft >/dev/null 2>&1; then
    nft delete table inet hysteria_porthopping 2>/dev/null || true
  fi
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

# =========================================================
# 配置块构建函数
# =========================================================

# ---- 混淆 (Obfuscation) ----
build_obfuscation_block() {
  local obfs_type="$1"
  local obfs_password="$2"

  if [[ -z "${obfs_type}" || "${obfs_type}" == "off" ]]; then
    OBFS_BLOCK="# obfuscation 未启用"
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

# ---- 协议嗅探 (Sniff) ----
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

prompt_sniff() {
  local choice
  echo
  echo "是否启用协议嗅探 (Sniff)？"
  echo "  Sniff 可将 IP 请求自动转为域名请求，配合 ACL 使用"
  echo "  1) 启用（推荐）"
  echo "  2) 关闭"
  read -r -p "请输入选项 [1-2，默认 1]: " choice
  choice="${choice:-1}"
  if [[ "${choice}" == "1" ]]; then
    prompt_sniff_result="true"
  else
    prompt_sniff_result="false"
  fi
}

# ---- 拥塞控制 (Congestion) ----
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

prompt_congestion() {
  local choice
  echo
  echo "请选择拥塞控制算法："
  echo "  1) BBR（默认，高性能）"
  echo "  2) Reno（传统算法，兼容性更好）"
  echo "  0) 使用 Hysteria 2 默认值"
  read -r -p "请输入选项 [0-2，默认 1]: " choice
  choice="${choice:-1}"

  case "${choice}" in
    2)
      prompt_congestion_result="reno"
      prompt_bbr_profile_result=""
      ;;
    0)
      prompt_congestion_result=""
      prompt_bbr_profile_result=""
      ;;
    *)
      prompt_congestion_result="bbr"
      local bbr_choice
      echo "  BBR 配置文件："
      echo "    1) standard（标准）"
      echo "    2) conservative（保守）"
      echo "    3) aggressive（激进）"
      read -r -p "  请输入选项 [1-3，默认 1]: " bbr_choice
      bbr_choice="${bbr_choice:-1}"
      case "${bbr_choice}" in
        2) prompt_bbr_profile_result="conservative" ;;
        3) prompt_bbr_profile_result="aggressive" ;;
        *) prompt_bbr_profile_result="standard" ;;
      esac
      ;;
  esac
}

# ---- 带宽限制 (Bandwidth) ----
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

prompt_bandwidth() {
  local choice
  echo
  echo "是否要设置服务端带宽限制？"
  echo "  1) 是（设置每客户端的上下行速率上限）"
  echo "  0) 否（不限速）"
  read -r -p "请输入选项 [0-1，默认 0]: " choice
  choice="${choice:-0}"

  if [[ "${choice}" == "1" ]]; then
    bw_up=$(prompt_default "上行带宽限制（如 100 mbps，留空不限制）" "")
    bw_down=$(prompt_default "下行带宽限制（如 100 mbps，留空不限制）" "")
    prompt_bandwidth_up_result="${bw_up}"
    prompt_bandwidth_down_result="${bw_down}"
  else
    prompt_bandwidth_up_result=""
    prompt_bandwidth_down_result=""
  fi
}

# ---- 测速服务器 (Speed Test) ----
prompt_speed_test() {
  local choice
  echo
  echo "是否启用内置测速服务器 (Speed Test)？"
  echo "  开启后客户端可用 hysteria speedtest 测试速度"
  echo "  1) 启用"
  echo "  0) 关闭（默认）"
  read -r -p "请输入选项 [0-1，默认 0]: " choice
  choice="${choice:-0}"
  if [[ "${choice}" == "1" ]]; then
    prompt_speed_test_result="true"
  else
    prompt_speed_test_result="false"
  fi
}

# ---- 端口跳跃 (Port Hopping) ----
prompt_port_hopping() {
  local choice
  echo
  echo "是否启用端口跳跃 (Port Hopping)？"
  echo "  端口跳跃可绕过运营商对单个 UDP 端口的限速/封锁"
  echo "  1) 启用（输入范围，如 20000-50000）"
  echo "  0) 关闭（默认）"
  read -r -p "请输入选项 [0-1，默认 0]: " choice
  choice="${choice:-0}"

  if [[ "${choice}" == "1" ]]; then
    while true; do
      read -r -p "请输入端口跳跃范围（如 20000-50000，支持逗号组合如 10000,20000-50000,60000）: " range
      if validate_port_range "${range}"; then
        prompt_port_hopping_result="${range}"
        break
      else
        warn "端口范围格式不正确，请重新输入（1-65535）。"
      fi
    done
  else
    prompt_port_hopping_result=""
  fi
}

# ---- 端口跳跃：写入 nftables 规则 ---- 
apply_port_hopping() {
  local port_range="$1"
  local listen_port="$2"
  if [[ -z "${port_range}" ]]; then
    return
  fi

  # 自动检测 Firewall 后端
  if command -v nft >/dev/null 2>&1; then
    info "使用 nftables 设置端口跳跃规则..."
    nft add table inet hysteria_porthopping 2>/dev/null || true
    nft add chain inet hysteria_porthopping prerouting { type nat hook prerouting priority dstnat\; policy accept\; } 2>/dev/null || true

    # 找出默认网卡
    local iface
    iface="$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}')"
    if [[ -z "${iface}" ]]; then
      iface="eth0"
    fi

    nft add rule inet hysteria_porthopping prerouting iifname "${iface}" udp dport "${port_range}" counter redirect to :"${listen_port}" 2>/dev/null || {
      warn "nftables 规则添加失败，请手动设置端口跳跃："
      warn "nft add rule inet hysteria_porthopping prerouting iifname ${iface} udp dport ${port_range} counter redirect to :${listen_port}"
    }
    success "已添加 nftables 端口跳跃规则: ${port_range} -> :${listen_port}"
  elif command -v iptables >/dev/null 2>&1; then
    warn "未检测到 nftables，使用 iptables（性能不如 nftables）。"
    local iface
    iface="$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}')"
    if [[ -z "${iface}" ]]; then
      iface="eth0"
    fi
    iptables -t nat -A PREROUTING -i "${iface}" -p udp --dport "${port_range}" -j REDIRECT --to-ports "${listen_port}" 2>/dev/null || warn "iptables 规则添加失败（可能已在规则中）。"
    if command -v ip6tables >/dev/null 2>&1; then
      ip6tables -t nat -A PREROUTING -i "${iface}" -p udp --dport "${port_range}" -j REDIRECT --to-ports "${listen_port}" 2>/dev/null || true
    fi
    success "已添加 iptables 端口跳跃规则: ${port_range} -> :${listen_port}"
  else
    warn "未检测到 nftables 或 iptables，端口跳跃规则无法自动设置。"
    warn "请手动执行以下命令（替换 eth0 为你的网卡名）："
    warn "  iptables -t nat -A PREROUTING -i eth0 -p udp --dport ${port_range} -j REDIRECT --to-ports ${listen_port}"
  fi
}

# ---- 性能优化：QUIC 流控制接收窗口 ----
build_quic_block() {
  QUIC_BLOCK=$(cat <<EOF
quic:
  initStreamReceiveWindow: 26843545
  maxStreamReceiveWindow: 26843545
  initConnReceiveWindow: 67108864
  maxConnReceiveWindow: 67108864
EOF
)
}

# ---- 性能优化：系统缓冲区大小 (Linux sysctl) ----
apply_sysctl_tuning() {
  local rmem=16777216
  local wmem=16777216

  local current_rmem
  local current_wmem
  current_rmem="$(sysctl -n net.core.rmem_max 2>/dev/null || echo "0")"
  current_wmem="$(sysctl -n net.core.wmem_max 2>/dev/null || echo "0")"

  if [[ "${current_rmem}" -lt "${rmem}" ]]; then
    sysctl -w net.core.rmem_max="${rmem}" >/dev/null 2>&1
    success "已设置系统接收缓冲区: ${rmem}"
  fi
  if [[ "${current_wmem}" -lt "${wmem}" ]]; then
    sysctl -w net.core.wmem_max="${wmem}" >/dev/null 2>&1
    success "已设置系统发送缓冲区: ${wmem}"
  fi

  local sysctl_conf="/etc/sysctl.d/99-hysteria.conf"
  if [[ ! -f "${sysctl_conf}" ]]; then
    cat >"${sysctl_conf}" <<EOF
# Hysteria 2 性能优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
EOF
    success "已持久化 sysctl 设置: ${sysctl_conf}"
  fi
}

# ---- 性能优化：进程优先级 (systemd drop-in) ----
apply_systemd_priority() {
  local dropin_dir="/etc/systemd/system/hysteria-server.service.d"
  local dropin_file="${dropin_dir}/priority.conf"

  if [[ ! -f "${dropin_file}" ]]; then
    mkdir -p "${dropin_dir}"
    cat >"${dropin_file}" <<EOF
[Service]
CPUSchedulingPolicy=rr
CPUSchedulingPriority=99
EOF
    success "已设置 systemd 实时优先级"
    systemctl daemon-reload
  fi
}

# ---- 环境变量注入 ---- 
apply_env_settings() {
  local log_level="$1"
  local disable_update="$2"
  local dropin_dir="/etc/systemd/system/hysteria-server.service.d"
  local env_file="${dropin_dir}/environment.conf"

  if [[ -z "${log_level}" && -z "${disable_update}" ]]; then
    return
  fi

  mkdir -p "${dropin_dir}"
  local env_line="Environment="
  local has_content=false

  if [[ -n "${log_level}" ]]; then
    env_line+="HYSTERIA_LOG_LEVEL=${log_level}"
    has_content=true
  fi
  if [[ -n "${disable_update}" ]]; then
    if [[ "${has_content}" == "true" ]]; then
      env_line+=" "
    fi
    env_line+="HYSTERIA_DISABLE_UPDATE_CHECK=1"
    has_content=true
  fi

  if [[ "${has_content}" == "true" ]]; then
    local existing
    if [[ -f "${env_file}" ]]; then
      existing="$(cat "${env_file}")"
    else
      existing=""
    fi

    if [[ "${existing}" != *"${env_line}"* ]]; then
      # 追加到现有或新建
      if [[ -n "${existing}" ]]; then
        # 如果已存在 [Service]，在其后添加
        echo "${env_line}" >>"${env_file}"
      else
        cat >"${env_file}" <<EOF
[Service]
${env_line}
EOF
      fi
      success "已设置环境变量: ${env_line}"
      systemctl daemon-reload
    fi
  fi
}

# =========================================================
# 配置写入函数
# =========================================================

write_config_acme() {
  local domain="$1"
  local email="$2"
  local port="$3"
  local password="$4"
  local auth_type="${5:-password}"
  local username="${6:-}"
  local speed_test="${7:-false}"
  local port_hopping="${8:-}"

  local speed_test_block
  if [[ "${speed_test}" == "true" ]]; then
    speed_test_block="speedTest: true"
  else
    speed_test_block="# speedTest: false"
  fi

  local listen_value
  if [[ -n "${port_hopping}" ]]; then
    listen_value=":${port_hopping}"
    info "端口跳跃已启用，监听端口范围: ${port_hopping}"
  else
    listen_value=":${port}"
  fi

  cat >"${CONFIG_PATH}" <<EOF
listen: ${listen_value}

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

${QUIC_BLOCK}

${speed_test_block}
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
  local speed_test="${9:-false}"
  local port_hopping="${10:-}"

  local speed_test_block
  if [[ "${speed_test}" == "true" ]]; then
    speed_test_block="speedTest: true"
  else
    speed_test_block="# speedTest: false"
  fi

  local listen_value
  if [[ -n "${port_hopping}" ]]; then
    listen_value=":${port_hopping}"
    info "端口跳跃已启用，监听端口范围: ${port_hopping}"
  else
    listen_value=":${port}"
  fi

  cat >"${CONFIG_PATH}" <<EOF
listen: ${listen_value}

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

${QUIC_BLOCK}

${speed_test_block}
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
  local port_hopping="${9:-}"

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

  # 客户端连接地址：如果启用了端口跳跃，使用端口范围
  local server_addr_line
  if [[ -n "${port_hopping}" ]]; then
    server_addr_line="\"${server_addr}:${port_hopping}\""
  else
    server_addr_line="\"${server_addr}:${port}\""
  fi

  # 客户端传输配置：端口跳跃需添加 transport.udp.hopInterval
  local transport_block=""
  if [[ -n "${port_hopping}" ]]; then
    transport_block=$(cat <<EOF

transport:
  udp:
    hopInterval: 30s
EOF
)
  fi

  cat >"${CLIENT_EXAMPLE_PATH}" <<EOF
server: ${server_addr_line}
${auth_block}

tls:
  sni: ${sni}
  insecure: ${insecure}
${obfs_block}
${transport_block}
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
  local port_hopping="${8:-}"

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

  # URI 中的端口：如果启用了端口跳跃，写入跳跃范围（v2rayN 可能不支持，仅记录文档）
  local uri_port="${port}"
  if [[ -n "${port_hopping}" ]]; then
    # v2rayN URI 不支持端口跳跃范围，但我们在备注里说明
    uri_port="${port}"
  fi

  echo "hysteria2://${auth_encoded}@${host}:${uri_port}/?${query}#HY2"
}

# =========================================================
# 主部署逻辑
# =========================================================

deploy_with_config() {
  require_cmd curl
  require_cmd grep
  require_cmd sed
  require_cmd systemctl

  install_or_upgrade_hy2

  mkdir -p /etc/hysteria

  # ---- 性能优化 ----
  apply_sysctl_tuning
  apply_systemd_priority
  build_quic_block

  # ---- 环境变量设置 ----
  apply_env_settings "${HY2_LOG_LEVEL:-}" "${HY2_DISABLE_UPDATE_CHECK:-}"

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

  # ---- 初始化全局变量 ----
  OBFUSCATION_TYPE="${HY2_OBFS:-off}"
  OBFUSCATION_PASSWORD="${HY2_OBFS_PASSWORD:-}"
  prompt_sniff_result="${HY2_SNIFF:-true}"
  prompt_speed_test_result="${HY2_SPEED_TEST:-false}"
  prompt_congestion_result="${HY2_CONGESTION:-bbr}"
  prompt_bbr_profile_result="${HY2_BBR_PROFILE:-standard}"
  prompt_bandwidth_up_result="${HY2_BANDWIDTH_UP:-}"
  prompt_bandwidth_down_result="${HY2_BANDWIDTH_DOWN:-}"
  prompt_port_hopping_result="${HY2_PORT_HOPPING:-}"

  # ---- 交互式配置（非 --yes 模式） ----
  if [[ "${HY2_YES:-false}" != "true" ]]; then
    prompt_obfuscation
    prompt_sniff
    prompt_speed_test
    prompt_congestion
    prompt_bandwidth
    prompt_port_hopping
  fi

  # ---- 构建所有配置块 ----
  if [[ "${OBFUSCATION_TYPE}" != "off" && -z "${OBFUSCATION_PASSWORD}" ]]; then
    OBFUSCATION_PASSWORD="$(random_password)"
    success "已自动生成混淆密码。"
  fi
  build_obfuscation_block "${OBFUSCATION_TYPE}" "${OBFUSCATION_PASSWORD}"

  build_sniff_block "${prompt_sniff_result}"
  build_congestion_block "${prompt_congestion_result}" "${prompt_bbr_profile_result}"
  build_bandwidth_block "${prompt_bandwidth_up_result}" "${prompt_bandwidth_down_result}"

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

  # ---- 端口跳跃 ----
  local port_hopping="${prompt_port_hopping_result}"
  if [[ -n "${port_hopping}" ]]; then
    apply_port_hopping "${port_hopping}" "${listen_port}"
  fi

  # ---- TLS 选择 ----
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

    write_config_acme "${domain}" "${email}" "${listen_port}" "${auth_password}" "${auth_type}" "${auth_username}" "${prompt_speed_test_result}" "${port_hopping}"

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

    write_config_cert "${cert_path}" "${key_path}" "${listen_port}" "${auth_password}" "${auth_type}" "${auth_username}" "${client_ca}" "${sni_guard}" "${prompt_speed_test_result}" "${port_hopping}"

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

  # ---- 权限修复 ----
  chmod 640 "${CONFIG_PATH}"
  chown hysteria:hysteria /etc/hysteria/config.yaml 2>/dev/null || true

  # ---- 服务启动 ----
  restart_service

  # ---- 客户端示例 ----
  write_client_example "${server_addr}" "${listen_port}" "${auth_password}" "${sni}" "${TLS_INSECURE}" "${OBFUSCATION_TYPE}" "${OBFUSCATION_PASSWORD}" "${auth_type}" "${port_hopping}"

  # ---- 分享 URI ----
  local share_uri
  share_uri="$(generate_uri "${server_addr}" "${listen_port}" "${auth_password}" "${sni}" "${TLS_INSECURE}" "${OBFUSCATION_TYPE}" "${OBFUSCATION_PASSWORD}" "${port_hopping}")"

  cat >"/root/hy2-v2rayn.txt" <<EOF
v2rayN 导入信息
================
协议：Hysteria2
导入方式：直接粘贴下面的 URI 到 v2rayN

${share_uri}
EOF
  chmod 600 "/root/hy2-v2rayn.txt"

  # ---- 输出总结 ----
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
  if [[ "${prompt_sniff_result}" == "true" ]]; then
    echo "协议嗅探: 已开启"
  fi
  if [[ "${prompt_speed_test_result}" == "true" ]]; then
    echo "测速功能: 已开启"
  fi
  if [[ -n "${prompt_congestion_result}" ]]; then
    echo "拥塞控制: ${prompt_congestion_result}"
    if [[ -n "${prompt_bbr_profile_result}" ]]; then
      echo "BBR 配置: ${prompt_bbr_profile_result}"
    fi
  fi
  if [[ -n "${prompt_bandwidth_up_result}" ]]; then
    echo "上行带宽: ${prompt_bandwidth_up_result}"
  fi
  if [[ -n "${prompt_bandwidth_down_result}" ]]; then
    echo "下行带宽: ${prompt_bandwidth_down_result}"
  fi
  if [[ -n "${port_hopping}" ]]; then
    echo "端口跳跃: ${port_hopping}"
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
  echo "  hysteria speedtest -c ${CLIENT_EXAMPLE_PATH}  # 测速"
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
            # v2.9.2+ 参数
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
            # v2.1.0 新增参数
            --port-hopping)
              HY2_PORT_HOPPING="${2:-}"
              shift 2
              ;;
            --log-level)
              HY2_LOG_LEVEL="${2:-}"
              shift 2
              ;;
            --disable-update-check)
              HY2_DISABLE_UPDATE_CHECK="1"
              shift 1
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
