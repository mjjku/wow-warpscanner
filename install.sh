#!/data/data/com.termux/files/usr/bin/bash
# -*- coding: utf-8 -*-

# Smart Termux WarpFusion Ultimate Launcher - Optimized Version
# Version: 2.3.0 (Ultra Fast & Error-Free)

set -e

# 🎨 Terminal Colors
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# 📌 Global Variables
VERSION="2.3.0"
SCRIPT_NAME="WarpScanner.py"
REPO_URL="https://raw.githubusercontent.com/mjjku/wow-warpscanner/main/WarpScanner.py"
CONFIG_DIR="$HOME/warpfusion"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/warpfusion_launcher.log"
PYTHON_MODULES=("rich" "icmplib" "cryptography" "psutil" "requests")
APT_PACKAGES=("python" "python-pip" "git" "curl" "wget" "clang" "openssl" "libffi" "rust" "pkg-config" "termux-tools")
TERMUX_STORAGE_DIR="/sdcard/warpfusion"
UBUNTU_DISTRO="ubuntu"
UBUNTU_ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/$UBUNTU_DISTRO"
MAX_RETRIES=3
RETRY_DELAY=3

# 🖥️ Clear Screen and Display Banner
clear
banner() {
  echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN} ⚡ WarpFusion Ultimate Pro Launcher v$VERSION ⚡ ${NC}"
  echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
}

setup_logging() {
  mkdir -p "$LOG_DIR"
  exec 1> >(tee -a "$LOG_FILE")
  exec 2>&1
  echo -e "${YELLOW}[\$(date '+%Y-%m-%d %H:%M:%S')] Starting Launcher${NC}"
}

check_network() {
  echo -e "${YELLOW}⏳ Checking internet...${NC}"
  for i in $(seq 1 $MAX_RETRIES); do
    ping -c1 1.1.1.1 >/dev/null 2>&1 && return
    sleep $RETRY_DELAY
  done
  echo -e "${RED}❌ No internet detected!${NC}"
  exit 1
}

check_termux_environment() {
  echo -e "${YELLOW}⏳ Checking Termux environment...${NC}"
  if ! command -v termux-setup-storage >/dev/null 2>&1; then pkg install termux-api -y; fi
  termux-setup-storage || true
  mkdir -p "$TERMUX_STORAGE_DIR"
  echo -e "${GREEN}✅ Termux environment ready.${NC}"
}

pkg_install_all() {
  echo -e "${YELLOW}⏳ Installing all Termux dependencies...${NC}"
  pkg update -y && pkg upgrade -y
  pkg install -y "${APT_PACKAGES[@]}"
  echo -e "${GREEN}✅ All Termux packages installed.${NC}"
}

install_python_modules() {
  echo -e "${YELLOW}⏳ Installing Python modules...${NC}"
  pip install --upgrade pip >/dev/null 2>&1
  for module in "${PYTHON_MODULES[@]}"; do
    python -c "import $module" 2>/dev/null || pip install --break-system-packages "$module"
  done
  echo -e "${GREEN}✅ Python modules installed.${NC}"
}

setup_ubuntu() {
  echo -e "${YELLOW}⏳ Setting up Ubuntu...${NC}"
  if ! command -v proot-distro >/dev/null 2>&1; then pkg install proot-distro -y; fi
  [ -d "$UBUNTU_ROOTFS" ] || proot-distro install "$UBUNTU_DISTRO"
  proot-distro login "$UBUNTU_DISTRO" -- bash -c "apt update -y && apt upgrade -y && \
    apt install -y python3 python3-pip git curl wget clang libssl-dev libffi-dev pkg-config"
  proot-distro login "$UBUNTU_DISTRO" -- bash -c "pip3 install ${PYTHON_MODULES[*]}"
  echo -e "${GREEN}✅ Ubuntu setup complete.${NC}"
}

check_and_download_script() {
  echo -e "${YELLOW}⬇️ Downloading WarpFusion script...${NC}"
  mkdir -p "$CONFIG_DIR"
  curl -fsSL -o "$CONFIG_DIR/$SCRIPT_NAME" "$REPO_URL"
  chmod +x "$CONFIG_DIR/$SCRIPT_NAME"
  echo -e "${GREEN}✅ Script downloaded.${NC}"
}

run_warpfusion() {
  echo -e "${CYAN}🚀 Launching WarpFusion Ultimate Pro...${NC}"
  proot-distro login "$UBUNTU_DISTRO" -- bash -c "cd $CONFIG_DIR && python3 $SCRIPT_NAME" || {
    echo -e "${YELLOW}⚠️ Ubuntu failed. Trying in Termux...${NC}"
    python "$CONFIG_DIR/$SCRIPT_NAME" || {
      echo -e "${RED}❌ WarpFusion failed in both environments.${NC}"
      exit 1
    }
  }
  echo -e "${GREEN}✅ WarpFusion launched successfully.${NC}"
}

log_error() {
  echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >> "$LOG_FILE"
}

# 🔧 Main
main() {
  banner
  setup_logging
  check_network
  check_termux_environment
  pkg_install_all
  install_python_modules
  setup_ubuntu
  check_and_download_script
  run_warpfusion
  echo -e "${CYAN}📁 Configs: $CONFIG_DIR/warp_profiles"
  echo -e "${CYAN}📂 Logs: $LOG_FILE"
}

trap 'echo -e "${RED}✖️ Interrupted by user${NC}"; log_error "Script interrupted"; exit 1' INT
main
