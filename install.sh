#!/data/data/com.termux/files/usr/bin/bash
# WarpFusion Ultimate Pro - Auto Installer
# Version: 15.1.0 Supreme Final Persian Edition

set -eo pipefail
shopt -s nullglob extglob
trap '__error_handler $?' EXIT
trap '__emergency_recovery' ERR
trap '__interrupt_handler' INT

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# ========== رنگ‌ها ==========
if [[ -t 1 ]]; then
  NC='\033[0m' RED='\033[1;31m' GREEN='\033[1;32m'
  YELLOW='\033[1;33m' BLUE='\033[1;34m' CYAN='\033[1;36m'
  BOLD='\033[1m'
else
  NC='' RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD=''
fi

# ========== سیستم لاگ ==========
LOG_FILE="$HOME/warpfusion_install.log"
exec 3>&1 4>&2
exec > >(tee -ia "$LOG_FILE") 2>&1

# ========== توابع پیام ==========
log_step() { echo -e "${BLUE}${BOLD}[+] $1...${NC}" >&3; }
log_success() { echo -e "${GREEN}${BOLD}[✓] $1${NC}" >&3; }
log_warn() { echo -e "${YELLOW}${BOLD}[!] $1${NC}" >&3; }
log_error() { echo -e "${RED}${BOLD}[✗] $1${NC}" >&3; }

__error_handler() {
  local exit_code=$1
  [[ $exit_code -eq 0 ]] && return
  log_error "خطا در نصب، کد خروج: $exit_code"
  exit $exit_code
}

__interrupt_handler() {
  echo -e "${RED}${BOLD}نصب قطع شد توسط کاربر!${NC}"
  exit 1
}

__emergency_recovery() {
  log_warn "بازیابی خودکار فعال شد..."
  pkg remove -y proot-distro python rust >/dev/null 2>&1 || true
  rm -rf ~/warpfusion ~/ubuntu-fs ~/.cache/pip >/dev/null 2>&1
  pkg update -y >/dev/null 2>&1 || true
  pkg upgrade -y >/dev/null 2>&1 || true
}

# ========== مراحل نصب ==========

__install_dependencies() {
  log_step "نصب پیش‌نیازهای اصلی"
  local packages=(python git curl wget clang openssl libffi rust pkg-config termux-tools proot-distro jq)

  pkg update -y -o Acquire::ForceIPv4=true >/dev/null 2>&1 || true
  pkg upgrade -y >/dev/null 2>&1 || true

  for pkg in "${packages[@]}"; do
    pkg install -y "$pkg" >/dev/null 2>&1 || { log_warn "تلاش مجدد نصب $pkg"; pkg install -y "$pkg"; }
  done

  [[ -x "$(command -v proot-distro)" ]] || { log_error "proot-distro نصب نشد."; return 1; }

  log_success "پیش‌نیازها نصب شدند."
}

__setup_ubuntu() {
  log_step "راه‌اندازی محیط اوبونتو"
  if proot-distro list | grep -q ubuntu; then
    proot-distro reset ubuntu -y >/dev/null 2>&1 || return 1
  else
    proot-distro install ubuntu >/dev/null 2>&1 || return 1
  fi

  proot-distro login ubuntu -- bash -c "
    apt update -y && apt upgrade -y
    apt install -y python3 python3-pip python3-venv git curl wget
    python3 -m venv /opt/warpfusion-venv
    source /opt/warpfusion-venv/bin/activate
    pip install --upgrade pip
  " >/dev/null 2>&1 || return 1

  log_success "محیط اوبونتو آماده شد."
}

__install_python_packages() {
  log_step "نصب پکیج‌های پایتون"
  local py_pkgs=(rich icmplib cryptography psutil requests numpy pillow)

  pip install --upgrade pip >/dev/null 2>&1 || return 1
  pip install "${py_pkgs[@]}" >/dev/null 2>&1 || return 1

  proot-distro login ubuntu -- bash -c "
    source /opt/warpfusion-venv/bin/activate
    pip install ${py_pkgs[*]}
  " >/dev/null 2>&1 || return 1

  log_success "پکیج‌های پایتون نصب شدند."
}

__install_warpfusion() {
  log_step "دریافت WarpFusion"

  local repo_url="https://cdn.jsdelivr.net/gh/mjjku/wow-warpscanner/WarpScanner.py"
  local target="$HOME/warpfusion"
  mkdir -p "$target"

  curl -fsSL "$repo_url" -o "$target/WarpScanner.py" || return 1
  chmod +x "$target/WarpScanner.py"

  cat > "$target/launch.sh" <<'EOF'
#!/bin/bash
if proot-distro list | grep -q ubuntu; then
  proot-distro login ubuntu -- bash -c "
    source /opt/warpfusion-venv/bin/activate
    cd /home/$(whoami)/warpfusion
    python WarpScanner.py
  "
else
  cd ~/warpfusion
  python WarpScanner.py
fi
EOF

  chmod +x "$target/launch.sh"
  grep -q "alias warpfusion" ~/.bashrc || echo "alias warpfusion='~/warpfusion/launch.sh'" >> ~/.bashrc

  log_success "WarpFusion نصب شد و آماده اجراست."
}

__main() {
  clear
  echo -e "${PURPLE}${BOLD}"
  echo "██████╗ ██╗    ██╗███████╗███████╗███████╗██╗   ██╗"
  echo "██╔══██╗██║    ██║██╔════╝██╔════╝██╔════╝╚██╗ ██╔╝"
  echo "██████╔╝██║ █╗ ██║█████╗  █████╗  █████╗   ╚████╔╝ "
  echo "██╔═══╝ ██║███╗██║██╔══╝  ██╔══╝  ██╔══╝    ╚██╔╝  "
  echo "██║     ╚███╔███╔╝███████╗██║     ███████╗   ██║   "
  echo "╚═╝      ╚══╝╚══╝ ╚══════╝╚═╝     ╚══════╝   ╚═╝   "
  echo -e "${CYAN}     WarpFusion Ultimate Pro - نصب نهایی موفق!${NC}"

  __install_dependencies || __emergency_recovery
  __setup_ubuntu || __emergency_recovery
  __install_python_packages || __emergency_recovery
  __install_warpfusion || __emergency_recovery

  source ~/.bashrc
  echo -e "${GREEN}${BOLD}نصب کامل شد. اجرای برنامه با دستور: warpfusion${NC}"
}

__main
