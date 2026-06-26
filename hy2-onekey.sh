#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="HY2 一键安装脚本（Linux 服务器）v2.1.0"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/hy2-onekey.sh"
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
    set +o pipefail
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20
    local _rc=$?
    set -o pipefail
    return $_rc
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
  --sub-urls                          显示订阅 HTTP URL
  --gen-subs                           从现有配置重新生成订阅文件（密码不变）
  --sub-port PORT                     订阅 HTTP 服务端口（默认 18989）
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
  nft delete table inet hysteria_ph 2>/dev/null || true
  fi
  if command -v iptables >/dev/null 2>&1; then
    iptables -t nat -F PREROUTING 2>/dev/null || true
    iptables -t nat -X PREROUTING 2>/dev/null || true
  fi
  # 清理订阅 HTTP 服务
  stop_subscription_service
  # 清理快捷命令
  rm -f /usr/local/bin/hy2 2>/dev/null || true
}

# ---- 快捷命令 ----
setup_symlink() {
  local script_path="$1"
  if [[ -f "${script_path}" ]]; then
    ln -sf "${script_path}" /usr/local/bin/hy2
    chmod +x /usr/local/bin/hy2
  fi
}

# ---- 订阅 HTTP 服务 ----
SUBS_SERVICE_NAME="hysteria-subscription.service"
SUBS_PORT="${HY2_SUBSCRIPTION_PORT:-18989}"
SUBS_DIR="/root"

setup_subscription_service() {
  local port="$1"
  local dir="$2"

  # 创建 systemd 服务文件
  cat >"/etc/systemd/system/${SUBS_SERVICE_NAME}" <<UNIT
[Unit]
Description=Hysteria 2 订阅 HTTP 服务 (hy2-onekey)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server ${port} --directory ${dir}
Restart=on-failure
RestartSec=5
User=root
Group=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
UNIT

  systemctl daemon-reload
  systemctl enable --now "${SUBS_SERVICE_NAME}" 2>/dev/null || {
    warn "订阅 HTTP 服务启动失败，请手动检查: journalctl -u ${SUBS_SERVICE_NAME}"
    return 1
  }

  if systemctl is-active --quiet "${SUBS_SERVICE_NAME}"; then
    success "订阅 HTTP 服务已启动 (端口 ${port})"
  fi
}

stop_subscription_service() {
  if systemctl is-enabled --quiet "${SUBS_SERVICE_NAME}" 2>/dev/null; then
    systemctl disable --now "${SUBS_SERVICE_NAME}" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SUBS_SERVICE_NAME}" 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null || true
    info "订阅 HTTP 服务已停止并移除。"
  fi
}

# ---- 多客户端订阅链接生成 ----
generate_subscriptions() {
  local server_addr="$1"
  local port="$2"
  local password="$3"
  local sni="$4"
  local insecure="$5"
  local obfs_type="${6:-}"
  local obfs_password="${7:-}"
  local auth_type="${8:-}"
  local port_hopping="${9:-}"

  local uri
  uri="$(generate_uri "${server_addr}" "${port}" "${password}" "${sni}" "${insecure}" "${obfs_type}" "${obfs_password}" "${port_hopping}")"

  # ph_uri 已弃用（v2rayN 不支持 URI 端口范围），不再生成端口跳跃 URI

  # ===== v2rayN / v2rayNG =====
  # 生成两个文件：
  #   hy2-v2rayn.txt              -> 纯 URI（供剪贴板/扫码直接导入）
  #   hy2-v2rayn-instructions.txt -> 含注释说明（端口跳跃配置指导）
  if [[ -n "${port_hopping}" ]]; then
    printf '%s\n' "${uri}" >"/root/hy2-v2rayn.txt"
    cat >"/root/hy2-v2rayn-instructions.txt" <<SUBEOF
# v2rayN / v2rayNG 端口跳跃配置指导
# ===== 步骤 =====
# 1. 复制下方 URI 到 v2rayN 导入（端口 ${port}）
# 2. 右键新节点 -> 编辑 -> 端口：将 ${port} 改为 ${port_hopping}
# 3. 在「自定义配置」中添加：
# {
#   "transport": {
#     "udp": {
#       "hopInterval": "30s"
#     }
#   }
# }
# =====
${uri}
SUBEOF
  else
    printf '%s\n' "${uri}" >"/root/hy2-v2rayn.txt"
    cat >"/root/hy2-v2rayn-instructions.txt" <<SUBEOF
# v2rayN / v2rayNG 订阅
# 使用方法：复制下方 URI 到 v2rayN -> 服务器 -> 从剪贴板导入（Ctrl+V）
${uri}
SUBEOF
  fi


  local obfs_yaml=""
  if [[ -n "${obfs_type}" && "${obfs_type}" != "off" ]]; then
    obfs_yaml=$'
    obfs: '"${obfs_type}"
    if [[ -n "${obfs_password}" ]]; then
      obfs_yaml+=$'
    obfs-password: '"${obfs_password}"
    fi
  fi

  local insecure_yaml=""
  if [[ "${insecure}" == "true" ]]; then
    insecure_yaml=$'
    skip-cert-verify: true'
  fi

  chmod 600 /root/hy2-v2rayn.txt 2>/dev/null || true
  : # chmod for subscription files (v2rayn/instructions handled above)

  # 保存订阅文件列表（供菜单使用）
  SUBS_FILES="/root/hy2-v2rayn.txt /root/hy2-v2rayn-instructions.txt"

  echo ""
  info "已生成订阅文件："
  echo "  v2rayN / v2rayNG:             /root/hy2-v2rayn.txt"
  echo "  v2rayN 配置指导:              /root/hy2-v2rayn-instructions.txt"
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
    BANDWIDTH_BLOCK="bandwidth:"
    if [[ -n "${up}" ]]; then
      BANDWIDTH_BLOCK+=$'
  up: '"${up}"
    fi
    if [[ -n "${down}" ]]; then
      BANDWIDTH_BLOCK+=$'
  down: '"${down}"
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
    info "使用 nftables 设置端口转发规则..."

    # 找出默认网卡
    local iface
    iface="$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}')"
    if [[ -z "${iface}" ]]; then
      iface="eth0"
    fi

    # 先清理旧规则（以 hysteria_ph_ 开头），避免每次部署重复添加
    # 清理旧规则
    nft delete table inet hysteria_ph 2>/dev/null || true

    # 从跳跃范围中提取基础端口（hysteria 实际监听的端口）
    local base_port
    base_port="${port_range%%-*}"
    base_port="${base_port%%,*}"
    base_port="${base_port:-${listen_port}}"

    # 新建 inet 表（同时处理 IPv4 + IPv6）
    nft add table inet hysteria_ph
    nft add chain inet hysteria_ph prerouting { type nat hook prerouting priority dstnat\; policy accept\; }

    # 规则1: 443 -> :base_port（供 sing-box / v2rayN 使用主端口）
    nft add rule inet hysteria_ph prerouting iifname "${iface}" udp dport 443 counter redirect to :"${base_port}" 2>/dev/null || true

    # 规则2: 端口跳跃范围 -> :base_port
    nft add rule inet hysteria_ph prerouting iifname "${iface}" udp dport "${port_range}" counter redirect to :"${base_port}" 2>/dev/null && {
      success "nftables 规则已更新: 443 + ${port_range} -> :${base_port}"
    } || {
      warn "nftables 规则添加失败，请手动设置："
      warn "nft add rule inet hysteria_ph prerouting iifname ${iface} udp dport ${port_range} counter redirect to :${base_port}"
    }
  elif command -v iptables >/dev/null 2>&1; then
    warn "未检测到 nftables，使用 iptables（性能不如 nftables）。"
    local iface
    iface="$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}')"
    if [[ -z "${iface}" ]]; then
      iface="eth0"
    fi
    # iptables 端口范围使用冒号分隔（如 20000:50000）
    local ipt_range="${port_range//-/:}"
    echo "${ipt_range}" | grep -q ':' || ipt_range="${port_range}"
    iptables -t nat -A PREROUTING -i "${iface}" -p udp --dport "${ipt_range}" -j REDIRECT --to-ports "${listen_port}" 2>/dev/null || warn "iptables 规则添加失败（可能已在规则中）。"
    if command -v ip6tables >/dev/null 2>&1; then
      ip6tables -t nat -A PREROUTING -i "${iface}" -p udp --dport "${ipt_range}" -j REDIRECT --to-ports "${listen_port}" 2>/dev/null || true
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

# ---- 性能优化：系统网络参数 (sysctl) ----
apply_sysctl_tuning() {
  local rmem=16777216
  local wmem=16777216
  local sysctl_conf="/etc/sysctl.d/99-hysteria-network.conf"

  # 动态设置缓冲区
  local current_rmem current_wmem
  current_rmem="$(sysctl -n net.core.rmem_max 2>/dev/null || echo "0")"
  current_wmem="$(sysctl -n net.core.wmem_max 2>/dev/null || echo "0")"
  if [[ "${current_rmem}" -lt "${rmem}" ]]; then
    sysctl -w net.core.rmem_max="${rmem}" >/dev/null 2>&1
  fi
  if [[ "${current_wmem}" -lt "${wmem}" ]]; then
    sysctl -w net.core.wmem_max="${wmem}" >/dev/null 2>&1
  fi

  # 加载 BBR 模块
  modprobe tcp_bbr 2>/dev/null || true
  echo "tcp_bbr" >/etc/modules-load.d/tcp_bbr.conf 2>/dev/null || true

  # 写入 sysctl 永久配置（覆盖旧文件）
  cat >"${sysctl_conf}" <<NETEOF
# Hysteria 2 全面网络性能优化
# QUIC/UDP 缓冲区上限
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
# BBR 拥塞控制（加速 VPS 回源 TCP，不影响 QUIC）
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
# TCP 快速打开（降低回源延迟）
net.ipv4.tcp_fastopen = 3
# TCP 缓冲区调大
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
# MTU 探测（减少 UDP 分片）
net.ipv4.tcp_mtu_probing = 1
NETEOF
  sysctl -p "${sysctl_conf}" >/dev/null 2>&1

  # 删除旧配置文件
  rm -f /etc/sysctl.d/99-hysteria.conf 2>/dev/null || true

  success "全网络优化已应用 (BBR + Buffer + FastOpen + MTU探测)"
}

# ---- 性能优化：进程优先级 (systemd drop-in) ----
apply_systemd_priority() {
  local dropin_dir="/etc/systemd/system/hysteria-server.service.d"
  mkdir -p "${dropin_dir}"

  # 优先级配置
  local priority_file="${dropin_dir}/priority.conf"
  if [[ ! -f "${priority_file}" ]]; then
    cat >"${priority_file}" <<EOF
[Service]
CPUSchedulingPolicy=rr
CPUSchedulingPriority=99
EOF
  fi

  # 并发连接数限制
  local limits_file="${dropin_dir}/limits.conf"
  if [[ ! -f "${limits_file}" ]]; then
    cat >"${limits_file}" <<EOF
[Service]
LimitNOFILE=1048576
LimitNPROC=1048576
EOF
  fi

  systemctl daemon-reload
  success "已设置 systemd 进程优先级 + 连接数上限 (1048576)"
}

# ---- 环境变量注入 ---- 
apply_env_settings() {
  local log_level="$1"
  local disable_update="$2"
  local dropin_dir="/etc/systemd/system/hysteria-server.service.d"
  local env_file="${dropin_dir}/environment.conf"

  if [[ -z "${log_level}" ]]; then
    log_level="warn"
  fi
  if [[ -z "${disable_update}" ]]; then
    :
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
    obfs_block=$'
'"obfs:"
    obfs_block+=$'
'"  type: ${obfs_type}"
    if [[ "${obfs_type}" == "salamander" ]]; then
      obfs_block+=$'
'"  salamander:"
      obfs_block+=$'
'"    password: ${obfs_password}"
    elif [[ "${obfs_type}" == "gecko" ]]; then
      obfs_block+=$'
'"  gecko:"
      obfs_block+=$'
'"    password: ${obfs_password}"
      obfs_block+=$'
'"    minPacketSize: 512"
      obfs_block+=$'
'"    maxPacketSize: 1200"
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
    transport_block=$'
'"transport:"
    transport_block+=$'
'"  udp:"
    transport_block+=$'
'"    hopInterval: 30s"
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

  # URI 始终使用主端口（443），端口跳跃由 nftables 服务端处理
  echo "hysteria2://${auth_encoded}@${host}:${port}/?${query}#HY2"
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

  # 复用现有密码（保持已有客户端不断连）
  if [[ -z "${auth_password}" && -f "${CONFIG_PATH}" ]]; then
    local existing_pw
    existing_pw="$(grep -A2 'auth:' "${CONFIG_PATH}" 2>/dev/null | grep 'password:' | head -1 | sed 's/.*password: *//;s/^ *//;s/ *$//;s/"//g' || true)"
    if [[ -n "${existing_pw}" ]]; then
      auth_password="${existing_pw}"
      info "已复用现有密码，已有客户端不受影响。"
    fi
  fi
  if [[ -z "${auth_password}" ]]; then
    auth_password="$(random_password)"
    success "已自动生成认证密码。"
  fi

  # 复用现有混淆密码
  if [[ -z "${OBFUSCATION_PASSWORD:-}" && -f "${CONFIG_PATH}" ]]; then
    local existing_opw
    existing_opw="$(grep -A1 'salamander:' "${CONFIG_PATH}" 2>/dev/null | grep 'password:' | head -1 | sed 's/.*password: *//;s/^ *//;s/ *$//;s/"//g' || true)"
    if [[ -n "${existing_opw}" ]]; then
      OBFUSCATION_PASSWORD="${existing_opw}"
    fi
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
    # TLS 方式选择
    echo
    echo "请选择 TLS 证书方式："
    echo "  1) ACME 自动证书（推荐，需域名）"
    echo "  2) 自有证书"
    local tls_choice_input
    read -r -p "请输入选项 [1-2，默认 1]: " tls_choice_input
    tls_choice_input="${tls_choice_input:-1}"
    if [[ "${tls_choice_input}" == "1" ]]; then
      tls_choice="1"
    else
      tls_choice="2"
    fi

    # 认证方式选择
    echo
    echo "请选择认证方式："
    echo "  1) 单密码认证（简单，推荐）"
    echo "  2) 用户名-密码认证（多用户）"
    local auth_choice
    read -r -p "请输入选项 [1-2，默认 1]: " auth_choice
    auth_choice="${auth_choice:-1}"
    if [[ "${auth_choice}" == "2" ]]; then
      auth_type="userpass"
      auth_username="$(prompt_required "请输入用户名")"
    fi

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

  # ---- 设置快捷命令 ----
  setup_symlink "${SCRIPT_PATH}"

  # ---- 生成多客户端订阅文件 ----
  generate_subscriptions     "${server_addr}"     "${listen_port}"     "${auth_password}"     "${sni}"     "${TLS_INSECURE}"     "${OBFUSCATION_TYPE}"     "${OBFUSCATION_PASSWORD}"     "${auth_type}"     "${port_hopping}"

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
  echo ""
  echo "--- 订阅文件 ---"
  echo "  v2rayN / v2rayNG:                 /root/hy2-v2rayn.txt"
  echo "  v2rayN 配置指导:              /root/hy2-v2rayn-instructions.txt"
  echo "  URI 直连:                         ${share_uri}"
  echo "--- 快捷命令 ---"
  echo "  hy2     （输入 hy2 即可调出菜单，需重新登录终端生效）"
  print_qr_code "${share_uri}"
  # ---- 启动订阅 HTTP 服务 ----
  setup_subscription_service "${SUBS_PORT}" "${SUBS_DIR}"

  # ---- 订阅 URL ----
  local server_ip
  server_ip="$(curl -s --max-time 3 ifconfig.me 2>/dev/null || curl -s --max-time 3 icanhazip.com 2>/dev/null || echo "${server_addr}")"
  local base_url="http://${server_ip}:${SUBS_PORT}"

  echo "--------------------------------------------------"
  echo "订阅服务："
  echo "  v2rayN / v2rayNG:             ${base_url}/hy2-v2rayn.txt"
  echo "--------------------------------------------------"
  echo "常用命令："
  echo "  hy2                 # 调出互动菜单（重新登录终端或运行 source /etc/profile）"
  echo "  hy2 --sub-urls       # 显示所有订阅 URL"
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
  echo "4) 显示订阅链接 / 快捷命令信息"
  echo "5) 重新生成订阅文件（基于当前配置）"
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
      --gen-subs)
        # 从现有配置提取参数，重新生成订阅文件（不更换密码）
        if [[ ! -f "${CONFIG_PATH}" ]]; then
          error "Hysteria 2 配置不存在，请先 --deploy。"
          exit 1
        fi
        echo "正在从现有配置重新生成订阅文件..."
        local _gsrv _gpw _gsni _gobfs_t _gobfs_pw _gport _gph
        _gsrv="${HY2_DOMAIN:-${HY2_SERVER:-}}"
        if [[ -z "${_gsrv}" ]]; then
          _gsrv="$(grep 'domains:' -A1 "${CONFIG_PATH}" 2>/dev/null | tail -1 | tr -d ' -')"
        fi
        if [[ -z "${_gsrv}" ]]; then
          _gsrv="$(curl -s --max-time 3 ifconfig.me 2>/dev/null || curl -s --max-time 3 icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")"
        fi
        _gpw="$(grep -A2 'auth:' "${CONFIG_PATH}" 2>/dev/null | grep 'password:' | head -1 | sed 's/.*password: *//;s/^ *//;s/ *$//;s/"//g')" || true
        _gsni="${HY2_SNI:-${_gsrv}}"
        _gobfs_t="$(grep -A2 'obfs:' "${CONFIG_PATH}" 2>/dev/null | grep 'type:' | head -1 | tr -d ' ' | cut -d: -f2)" || true
        _gph="$(grep -oP '[0-9]+-[0-9]+' "${CONFIG_PATH}" 2>/dev/null | head -1 || true)"
        _gobfs_pw="$(grep -A1 'salamander:' "${CONFIG_PATH}" 2>/dev/null | grep 'password:' | head -1 | sed 's/.*password: *//;s/^ *//;s/ *$//;s/"//g')" || true
        if [[ -n "${_gph}" ]]; then
          _gport="443"
        else
          _gport="$(sed -n 's/listen: :\([0-9]*\).*/\1/p' "${CONFIG_PATH}" 2>/dev/null)"
          _gport="${_gport:-443}"
        fi
        if [[ -z "${_gpw}" ]]; then
          error "无法从配置中提取密码。"
          exit 1
        fi
        generate_subscriptions "${_gsrv}" "${_gport}" "${_gpw}" "${_gsni}" "false" "${_gobfs_t}" "${_gobfs_pw}" "password" "${_gph}"
        echo ""
        success "订阅文件已重新生成（密码不变，客户端不受影响）。"
        systemctl restart "${SUBS_SERVICE_NAME}" 2>/dev/null || true
        exit 0
        ;;
      --sub-urls|--show-subs)
        echo "=================================================="
        echo "                订阅 URL"
        echo "=================================================="
        local server_ip
        server_ip="$(curl -s --max-time 3 ifconfig.me 2>/dev/null || curl -s --max-time 3 icanhazip.com 2>/dev/null || curl -s --max-time 3 http://checkip.amazonaws.com/ 2>/dev/null || echo "你的服务器IP")"
        local base_url="http://${server_ip}:${SUBS_PORT}"
        echo ""
      
        echo "  v2rayN / v2rayNG:         ${base_url}/hy2-v2rayn.txt"
        echo ""
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
  read -r -p "请选择操作 [0-4，默认 1]: " choice
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
    4)
      local _srv4
      _srv4="$(curl -s --max-time 3 ifconfig.me 2>/dev/null || curl -s --max-time 3 icanhazip.com 2>/dev/null || echo "获取IP失败")"
      local _base4="http://${_srv4}:${SUBS_PORT}"
      echo "=================================================="
      echo "                订阅链接 & 快捷命令"
      echo "=================================================="
      echo ""
      echo "--- HTTP 订阅 URL（导入客户端） ---"
      
      echo "  v2rayN / v2rayNG:         ${_base4}/hy2-v2rayn.txt"
    
      echo ""

      if [[ -f /root/hy2-v2rayn.txt ]]; then
        echo "--- v2rayN / v2rayNG (URI) ---"
        cat /root/hy2-v2rayn.txt
        echo ""
      fi
      if [[ -f /root/hy2-v2rayn-instructions.txt ]]; then
        echo "--- v2rayN 配置指导 ---"
        cat /root/hy2-v2rayn-instructions.txt
        echo ""
      fi

      echo "--- 快捷命令 ---"
      echo "  hy2                     # 调出菜单"
      echo "  hy2 --gen-subs          # 重新生成订阅文件（密码不变）"
      echo "  hy2 --sub-urls          # 显示 HTTP 订阅 URL"
      echo ""
      ;;
    5)
      if [[ ! -f "${CONFIG_PATH}" ]]; then
        error "Hysteria 2 配置不存在，请先部署。"
        break
      fi
      echo "=================================================="
      echo "          重新生成订阅文件"
      echo "=================================================="
      local _srv5="${HY2_DOMAIN:-${HY2_SERVER:-}}"
      if [[ -z "${_srv5}" ]]; then
        _srv5="$(grep 'domains:' -A1 "${CONFIG_PATH}" 2>/dev/null | tail -1 | tr -d ' -')"
      fi
      if [[ -z "${_srv5}" ]]; then
        _srv5="$(curl -s --max-time 3 ifconfig.me 2>/dev/null || curl -s --max-time 3 icanhazip.com 2>/dev/null || echo "YOUR_IP")"
      fi
      local _pw5 _sni5 _obfs_t5 _obfs_pw5 _port5 _ph5
      _pw5="$(grep -A2 'auth:' "${CONFIG_PATH}" 2>/dev/null | grep 'password:' | head -1 | sed 's/.*password: *//;s/^ *//;s/ *$//;s/"//g')" || true
      _sni5="${HY2_SNI:-${_srv5}}"
      _obfs_t5="$(grep -A2 'obfs:' "${CONFIG_PATH}" 2>/dev/null | grep 'type:' | head -1 | tr -d ' ' | cut -d: -f2)" || true
      _ph5="$(grep -oP '[0-9]+-[0-9]+' "${CONFIG_PATH}" 2>/dev/null | head -1 || true)"
      _obfs_pw5="$(grep -A1 'salamander:' "${CONFIG_PATH}" 2>/dev/null | grep 'password:' | head -1 | sed 's/.*password: *//;s/^ *//;s/ *$//;s/"//g')" || true
      if [[ -n "${_ph5}" ]]; then
        _port5="443"
      else
        _port5="$(sed -n 's/listen: :\([0-9]*\).*/\1/p' "${CONFIG_PATH}" 2>/dev/null)"
        _port5="${_port5:-443}"
      fi
      if [[ -z "${_pw5}" ]]; then
        error "无法从配置提取密码。"
        break
      fi
      generate_subscriptions "${_srv5}" "${_port5}" "${_pw5}" "${_sni5}" "false" "${_obfs_t5}" "${_obfs_pw5}" "password" "${_ph5}"
      echo ""
      success "订阅文件已重新生成（密码不变，客户端不受影响）。"
      systemctl restart "${SUBS_SERVICE_NAME}" 2>/dev/null || true
      ;;

    0)
      error "无效选项。"
      exit 1
      ;;
  esac
}

main "$@"
