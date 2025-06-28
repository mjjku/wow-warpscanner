#!/data/data/com.termux/files/usr/bin/bash
# WarpFusion نصب هوشمند Supreme Final - بدون خطا

set -eo pipefail
trap '__error_handler $?' EXIT
trap '__interrupt_handler' INT
trap '__emergency_recovery' ERR

RED='\033[1;31m' GREEN='\033[1;32m' YELLOW='\033[1;33m' BLUE='\033[1;34m' NC='\033[0m' BOLD='\033[1m'
log() { echo -e "${BLUE}${BOLD}[⚙️]${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}[✅]${NC} $1"; }
warn() { echo -e "${YELLOW}${BOLD}[!]${NC} $1"; }
error() { echo -e "${RED}${BOLD}[✘]${NC} $1"; }

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
  warn "🛠 بازیابی اضطراری فعال شد..."
  rm -rf ~/.termux/apt ~/.cache ~/warpfusion >/dev/null 2>&1 || true
  pkg clean
  pkg update -y
  pkg upgrade -y
}

__check_internet() {
  log "بررسی اتصال اینترنت..."
  if ! ping -c1 -w2 1.1.1.1 >/dev/null 2>&1; then
    error "⛔ اتصال اینترنت برقرار نیست!"
    exit 1
  fi
  success "اتصال اینترنت برقرار است."
}

__prepare_env() {
  log "بروزرسانی کامل سیستم و نصب پیش‌نیازها..."
  pkg update -y >/dev/null
  pkg upgrade -y >/dev/null

  # لیست بسته‌های ضروری
  packages=(python git curl wget clang openssl libffi rust cargo proot-distro termux-tools)

  for pkg in "${packages[@]}"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
      log "در حال نصب ${pkg}..."
      pkg install -y "$pkg" >/dev/null 2>&1 || {
        warn "🔁 تلاش مجدد برای نصب $pkg"
        pkg install -y "$pkg" >/dev/null 2>&1
      }
    else
      log "$pkg قبلاً نصب شده است."
    fi
  done

  # اطمینان از وجود python با لینک از python3
  [[ -f /data/data/com.termux/files/usr/bin/python ]] || ln -sf "$(command -v python3)" /data/data/com.termux/files/usr/bin/python
  success "پیش‌نیازها با موفقیت نصب شدند."
}

__install_warpfusion() {
  log "📥 دریافت و نصب WarpFusion..."
  curl -fsSL https://raw.githubusercontent.com/warpfusionproject/install/main/warpfusion.sh | bash || {
    error "نصب warp-fusion ناموفق بود!"
    exit 1
  }

  if command -v warpfusion >/dev/null 2>&1; then
    success "✅ WarpFusion با موفقیت نصب شد."
  else
    error "warpfusion نصب نشد!"
    exit 1
  fi
}

__main() {
  clear
  echo -e "${YELLOW}${BOLD}🔥 نصب هوشمند WarpFusion Supreme Final در حال اجراست...${NC}"
  __check_internet
  __prepare_env
  __install_warpfusion
  echo -e "\n${GREEN}${BOLD}🎉 نصب کامل شد! برای اجرا بنویس:\n👉 warpfusion${NC}"
}

__main
