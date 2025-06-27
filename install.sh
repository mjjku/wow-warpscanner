#!/data/data/com.termux/files/usr/bin/bash
# -*- coding: utf-8 -*-
#
# Smart Termux WarpFusion Ultimate Launcher
# Version: 2.0.0
# Description: The most advanced, automated, and professional Bash script to set up
# and run WarpFusion Ultimate Pro in Termux or a proot-distro Ubuntu environment.
# Handles dependencies, downloads, Ubuntu setup, and execution with comprehensive
# error handling and user-friendly output.
#

set -e

# 🎨 Colors for Terminal Output
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# 📌 Global Variables
VERSION="2.0.0"
SCRIPT_NAME="WarpScanner.py"
REPO_URL="https://raw.githubusercontent.com/mjjku/wow-warpscanner/main/WarpScanner.py"
CONFIG_DIR="$HOME/warpfusion"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/warpfusion_launcher.log"
PYTHON_MODULES=("rich" "icmplib" "cryptography" "psutil" "requests")
APT_PACKAGES=("python" "git" "curl" "wget" "clang" "openssl" "libffi" "rust" "pkg-config")
TERMUX_STORAGE_DIR="/sdcard/warpfusion"
UBUNTU_DISTRO="ubuntu"
UBUNTU_ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/$UBUNTU_DISTRO"

# 🖥️ Clear Screen
clear

# 🎯 Display Banner
banner() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}     ⚡️ Smart Termux WarpFusion Ultimate Pro Launcher    ${NC}"
    echo -e "${CYAN}                Version: $VERSION                   ${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
}

# 📝 Setup Logging
setup_logging() {
    mkdir -p "$LOG_DIR"
    exec 1> >(tee -a "$LOG_FILE")
    exec 2>&1
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] Starting WarpFusion Launcher v$VERSION${NC}"
}

# 🔍 Check Termux Environment
check_termux_environment() {
    echo -e "${YELLOW}⏳ Checking Termux environment...${NC}"
    
    # Check storage permissions
    if ! termux-setup-storage >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ Requesting storage permissions...${NC}"
        termux-setup-storage
        sleep 2
    fi
    
    # Create storage directory
    mkdir -p "$TERMUX_STORAGE_DIR"
    
    # Check Termux version
    if ! pkg_install_quiet termux-tools; then
        echo -e "${RED}❌ Failed to install termux-tools. Please update Termux.${NC}"
        log_error "Failed to install termux-tools"
        exit 1
    fi
}

# 📦 Install System Packages in Termux
pkg_install() {
    local pkg="$1"
    echo -e "${BLUE}📦 Installing $pkg in Termux...${NC}"
    pkg_install_quiet "$pkg" || {
        echo -e "${RED}❌ Failed to install $pkg. Check your package manager.${NC}"
        log_error "Failed to install package: $pkg"
        exit 1
    }
}

pkg_install_quiet() {
    pkg install -y "$1" >/dev/null 2>&1
}

# 📦 Install Core Dependencies in Termux
install_termux_dependencies() {
    echo -e "${YELLOW}⏳ Installing Termux dependencies...${NC}"
    pkg_install_quiet pkg-config || pkg_install pkg-config
    for pkg in "${APT_PACKAGES[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1 && [[ "$pkg" != "pkg-config" ]]; then
            pkg_install "$pkg"
        elif [[ "$pkg" == "pkg-config" ]] && ! command -v pkg-config >/dev/null 2>&1; then
            pkg_install "$pkg"
        fi
    done

    # Ensure pip is installed
    if ! command -v pip >/dev/null 2>&1; then
        echo -e "${BLUE}📦 Installing pip in Termux...${NC}"
        pkg_install_quiet python-pip || {
            echo -e "${RED}❌ Failed to install pip.${NC}"
            log_error "Failed to install pip"
            exit 1
        }
    fi
    echo -e "${GREEN}✅ Termux dependencies installed.${NC}"
}

# 🧰 Install Python Modules
install_python_modules() {
    local python_cmd="$1"
    echo -e "${YELLOW}⏳ Checking and installing Python modules...${NC}"
    for module in "${PYTHON_MODULES[@]}"; do
        if ! $python_cmd -c "import $module" 2>/dev/null; then
            echo -e "${BLUE}📦 Installing Python module: $module...${NC}"
            if [[ "$module" == "cryptography" ]]; then
                echo -e "${YELLOW}⚙️ Building cryptography with optimizations...${NC}"
                export CFLAGS="-O2 -fPIC"
                export LDFLAGS="-lm"
                export RUST_BACKTRACE=1
                $python_cmd -m pip install --no-cache-dir --break-system-packages cryptography >/dev/null 2>&1 || {
                    echo -e "${RED}❌ Failed to install cryptography. Ensure rust and clang are installed.${NC}"
                    log_error "Failed to install cryptography module"
                    exit 1
                }
            else
                $python_cmd -m pip install --break-system-packages "$module" >/dev/null 2>&1 || {
                    echo -e "${RED}❌ Failed to install $module.${NC}"
                    log_error "Failed to install Python module: $module"
                    exit 1
                }
            fi
        else
            echo -e "${GREEN}✅ Python module $module is already installed.${NC}"
        fi
    done
}

# 🐧 Setup Ubuntu Environment with proot-distro
setup_ubuntu() {
    echo -e "${YELLOW}⏳ Setting up Ubuntu environment with proot-distro...${NC}"
    
    # Update Termux packages
    echo -e "${BLUE}📦 Updating Termux package manager...${NC}"
    pkg update -y && pkg upgrade -y >/dev/null 2>&1 || {
        echo -e "${RED}❌ Failed to update Termux packages.${NC}"
        log_error "Failed to update Termux packages"
        exit 1
    }

    # Install proot-distro
    if ! command -v proot-distro >/dev/null 2>&1; then
        echo -e "${BLUE}📦 Installing proot-distro...${NC}"
        pkg_install proot-distro
    fi

    # Install Ubuntu if not already installed
    if [ ! -d "$UBUNTU_ROOTFS" ]; then
        echo -e "${BLUE}📦 Installing Ubuntu distro...${NC}"
        proot-distro install "$UBUNTU_DISTRO" || {
            echo -e "${RED}❌ Failed to install Ubuntu distro.${NC}"
            log_error "Failed to install Ubuntu distro"
            exit 1
        }
    fi
    echo -e "${GREEN}✅ Ubuntu environment ready.${NC}"

    # Update Ubuntu packages and install dependencies
    echo -e "${YELLOW}⏳ Updating Ubuntu packages and installing dependencies...${NC}"
    proot-distro login "$UBUNTU_DISTRO" -- bash -c "
        apt update -y && apt upgrade -y >/dev/null 2>&1 || exit 1
        apt install -y python3 python3-pip git curl wget clang libssl-dev libffi-dev pkg-config >/dev/null 2>&1 || exit 1
    " || {
        echo -e "${RED}❌ Failed to update or install Ubuntu dependencies.${NC}"
        log_error "Failed to update or install Ubuntu dependencies"
        exit 1
    }
    echo -e "${GREEN}✅ Ubuntu dependencies installed.${NC}"
}

# 📥 Download WarpFusion Script
check_and_download_warpfusion() {
    echo -e "${YELLOW}⬇️ Checking for WarpFusion Ultimate Pro script...${NC}"
    local target_path="$CONFIG_DIR/$SCRIPT_NAME"
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    if [ -f "$target_path" ]; then
        # Validate script
        if ! grep -q "WarpFusion Ultimate Pro" "$target_path"; then
            echo -e "${YELLOW}🔁 Removing outdated or invalid script...${NC}"
            rm -f "$target_path"
        else
            echo -e "${GREEN}✅ Valid WarpFusion script found.${NC}"
            return
        fi
    fi

    echo -e "${BLUE}⬇️ Downloading WarpFusion Ultimate Pro...${NC}"
    curl -fsSL -o "$target_path" "$REPO_URL" || {
        echo -e "${RED}❌ Failed to download WarpFusion script from $REPO_URL${NC}"
        log_error "Failed to download WarpFusion script from $REPO_URL"
        exit 1
    }
    chmod +x "$target_path"
    echo -e "${GREEN}✅ WarpFusion script downloaded successfully.${NC}"
}

# 🔍 Check Network Connectivity
check_network() {
    echo -e "${YELLOW}⏳ Checking network connectivity...${NC}"
    if ! ping -c 1 1.1.1.1 >/dev/null 2>&1; then
        echo -e "${RED}❌ No internet connection detected. Please check your network.${NC}"
        log_error "No internet connection detected"
        exit 1
    fi
    echo -e "${GREEN}✅ Network connection verified.${NC}"
}

# ⚙️ Patch Imports (if needed)
patch_imports() {
    local target_path="$CONFIG_DIR/$SCRIPT_NAME"
    if ! grep -q "X25519PrivateKey" "$target_path"; then
        echo -e "${YELLOW}⚙️ Adding missing imports to WarpFusion script...${NC}"
        sed -i '1i from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey' "$target_path"
        sed -i '2i from cryptography.hazmat.primitives import serialization' "$target_path"
    fi
}

# 🚀 Run WarpFusion Script
run_warpfusion() {
    local env="$1"
    local target_path="$CONFIG_DIR/$SCRIPT_NAME"
    if [ ! -f "$target_path" ]; then
        echo -e "${RED}❌ WarpFusion script not found at $target_path${NC}"
        log_error "WarpFusion script not found at $target_path"
        exit 1
    fi

    echo -e "${GREEN}🚀 Launching WarpFusion Ultimate Pro in $env environment...${NC}"
    if [[ "$env" == "ubuntu" ]]; then
        proot-distro login "$UBUNTU_DISTRO" -- bash -c "
            cd $CONFIG_DIR
            python3 $SCRIPT_NAME
        " || {
            echo -e "${RED}❌ Failed to execute WarpFusion in Ubuntu. Check logs at $LOG_FILE${NC}"
            log_error "Failed to execute WarpFusion in Ubuntu"
            exit 1
        }
    else
        python3 "$target_path" || {
            echo -e "${RED}❌ Failed to execute WarpFusion in Termux. Check logs at $LOG_FILE${NC}"
            log_error "Failed to execute WarpFusion in Termux"
            exit 1
        }
    fi
}

# 📜 Log Error Helper
log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >> "$LOG_FILE"
}

# 🧠 Main Orchestration
main() {
    banner
    setup_logging
    check_termux_environment
    check_network
    
    # Update Termux and install dependencies
    install_termux_dependencies
    install_python_modules python3

    # Setup Ubuntu environment
    setup_ubuntu
    proot-distro login "$UBUNTU_DISTRO" -- bash -c "
        python3 -m pip install --break-system-packages ${PYTHON_MODULES[*]} >/dev/null 2>&1 || exit 1
    " || {
        echo -e "${RED}❌ Failed to install Python modules in Ubuntu.${NC}"
        log_error "Failed to install Python modules in Ubuntu"
        exit 1
    }

    check_and_download_warpfusion
    patch_imports

    # Try running in Ubuntu first, fallback to Termux if it fails
    if run_warpfusion ubuntu; then
        echo -e "${GREEN}✅ WarpFusion executed successfully in Ubuntu environment.${NC}"
    else
        echo -e "${YELLOW}⚠️ Ubuntu execution failed, falling back to Termux...${NC}"
        run_warpfusion termux
    fi

    echo -e "${GREEN}[✓] WarpFusion Ultimate Pro setup and execution completed successfully! 💥${NC}"
    echo -e "${CYAN}📜 Logs saved to: $LOG_FILE${NC}"
    echo -e "${CYAN}📁 Configs saved to: $CONFIG_DIR/warp_profiles${NC}"
    echo -e "${CYAN}📂 Results also available in: $TERMUX_STORAGE_DIR${NC}"
}

# 🛡️ Error Handling
trap 'echo -e "${RED}✖️ Operation interrupted by user${NC}"; log_error "Script interrupted by user"; exit 1' INT
main
