#!/data/data/com.termux/files/usr/bin/bash
# WarpFusion Ultimate Pro - نصب نهایی خودکار
# نسخه: 15.1.0 Supreme Final Persian Edition

set -eo pipefail
shopt -s nullglob extglob

trap '__error_handler $?' EXIT
trap '__interrupt_handler' INT
trap '__emergency_recovery' ERR

export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# رنگ‌ها
RED='\033[1;31m' GREEN='\033[1;32m' YELLOW='\033[1;33m' BLUE='\033[1;34m'
CYAN='\033[1;36m' NC='\033[0m' BOLD='\033[1m'

log()     { echo -e "${BLUE}${BOLD}[⚙️]${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}[✅]${NC} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}[!]${NC} $1"; }
error()   { echo -e "${RED}${BOLD}[✘]${NC} $1"; }

__error_handler() {
  local code=$1
  [[ $code -eq 0 ]] && return
  error "خطای غیرمنتظره با کد خروج $code رخ داد!"
  exit $code
}

__interrupt_handler() {
  echo -e "${RED}${BOLD}⛔ نصب توسط کاربر قطع شد.${NC}"
  exit 1
}

__emergency_recovery() {
  warn "🛠 فعال‌سازی بازیابی اضطراری..."
  pkg uninstall -y proot-distro python rust cargo >/dev/null 2>&1 || true
  rm -rf ~/warpfusion ~/.cache ~/.termux/apt >/dev/null 2>&1
  pkg update -y >/dev/null 2>&1 || true
  pkg upgrade -y >/dev/null 2>&1 || true
}

__check_internet() {
  log "بررسی اتصال اینترنت..."
  ping -c 1 8.8.8.8 >/dev/null 2>&1 || {
    error "اتصال اینترنت برقرار نیست!"
    exit 1
  }
  success "اتصال اینترنت برقرار است."
}

__prepare_env() {
  log "بروزرسانی کامل سیستم و نصب پیش‌نیازها..."
  pkg update -y >/dev/null 2>&1
  pkg upgrade -y >/dev/null 2>&1

  local pkgs=(python python3 git curl wget clang openssl libffi rust rustc cargo pkg-config proot-distro termux-tools)
  for pkg in "${pkgs[@]}"; do
    pkg install -y "$pkg" >/dev/null 2>&1 || {
      warn "تلاش مجدد برای نصب ${pkg}"
      pkg install -y "$pkg"
    }
  done

  ln -sf "$(command -v python3)" /data/data/com.termux/files/usr/bin/python || true
  touch ~/.bashrc
  success "محیط ترموکس آماده است."
}

__install_warpfusion() {
  log "دریافت و نصب WarpFusion Ultimate Pro..."

  curl -fsSL https://raw.githubusercontent.com/warpfusionproject/install/main/warpfusion.sh | bash || {
    error "نصب warp-fusion با مشکل مواجه شد."
    exit 1
  }

  command -v warpfusion >/dev/null 2>&1 && success "WarpFusion با موفقیت نصب شد." || {
    error "اجرای warpfusion یافت نشد."
    exit 1
  }
}

__main() {
  clear
  echo -e "${CYAN}${BOLD}🔥 نصب هوشمند WarpFusion Supreme Final در حال اجراست...${NC}"
  __check_internet
  __prepare_env
  __install_warpfusion
  echo -e "${GREEN}${BOLD}✅ نصب کامل شد! برای اجرا دستور زیر را وارد کنید:\n👉 warpfusion${NC}"
}

__main
