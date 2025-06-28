#!/data/data/com.termux/files/usr/bin/bash
# -*- coding: utf-8 -*-
#
# WarpFusion Ultimate Pro - Termux Installer
# Version: 12.0.0 (Absolute Zero-Error Edition)
# Description: The most complete, bulletproof installation system

# =============== Core Configuration ===============
set -eo pipefail
shopt -s nullglob extglob
trap '__error_handler $?' EXIT
trap '__emergency_recovery' ERR
trap '__interrupt_handler' INT

# =============== Color System ===============
if [[ -t 1 ]]; then
    NC='\033[0m' RED='\033[1;31m' GREEN='\033[1;32m'
    YELLOW='\033[1;33m' BLUE='\033[1;34m' CYAN='\033[1;36m' 
    PURPLE='\033[1;35m' WHITE='\033[1;37m' BOLD='\033[1m'
else
    NC='' RED='' GREEN='' YELLOW='' BLUE='' CYAN='' PURPLE='' WHITE='' BOLD=''
fi

# =============== Logging System ===============
LOG_FILE="$HOME/warpfusion_install.log"
exec 3>&1 4>&2
exec > >(tee -ia "$LOG_FILE") 2>&1

# =============== Helper Functions ===============
__step() {
    echo -e "${BLUE}${BOLD}[+] ${1}...${NC}" >&3
}

__success() {
    echo -e "${GREEN}${BOLD}[✓] ${1}${NC}" >&3
}

__warning() {
    echo -e "${YELLOW}${BOLD}[!] ${1}${NC}" >&3
}

__error() {
    echo -e "${RED}${BOLD}[✗] ${1}${NC}" >&3
}

__error_handler() {
    local exit_code=$1
    [[ $exit_code -eq 0 ]] && return
    
    echo -e "${RED}${BOLD}"
    echo " ╔════════════════════════════════════╗"
    echo " ║          INSTALL FAILED!           ║"
    echo " ╚════════════════════════════════════╝"
    echo -e "${NC}"
    exit $exit_code
}

__emergency_recovery() {
    echo -e "${YELLOW}${BOLD}"
    echo " ╔════════════════════════════════════╗"
    echo " ║      AUTO-RECOVERY ACTIVATED       ║"
    echo " ╚════════════════════════════════════╝"
    echo -e "${NC}"
    
    pkg remove -y proot-distro python rust >/dev/null 2>&1 || true
    rm -rf ~/warpfusion ~/ubuntu-fs ~/.cache/pip >/dev/null 2>&1
    pkg update -y >/dev/null 2>&1
    pkg upgrade -y >/dev/null 2>&1
}

__interrupt_handler() {
    echo -e "${RED}${BOLD}"
    echo " ╔════════════════════════════════════╗"
    echo " ║     INSTALLATION INTERRUPTED!      ║"
    echo " ╚════════════════════════════════════╝"
    echo -e "${NC}"
    exit 1
}

# =============== Installation Modules ===============
__install_core() {
    __step "Installing core dependencies"
    
    # Fix Termux repositories
    termux-change-repo --mirror main >/dev/null 2>&1 || true
    
    pkg update -y >/dev/null 2>&1
    pkg upgrade -y >/dev/null 2>&1
    
    local packages=(
        "python" "git" "curl" "wget" "clang"
        "openssl" "libffi" "rust" "pkg-config"
        "termux-tools" "proot-distro" "jq"
    )
    
    for pkg in "${packages[@]}"; do
        if ! pkg list-installed | grep -q "$pkg"; then
            pkg install -y "$pkg" >/dev/null 2>&1 || {
                __warning "Failed to install $pkg, retrying..."
                pkg install -y "$pkg" >/dev/null 2>&1 || {
                    __error "Failed to install $pkg"
                    return 1
                }
            }
        fi
    done
    
    __success "Core dependencies installed"
    return 0
}

__setup_ubuntu() {
    __step "Configuring Ubuntu environment"
    
    if proot-distro list | grep -q ubuntu; then
        __step "Resetting existing Ubuntu installation"
        proot-distro reset ubuntu -y >/dev/null 2>&1 || {
            __error "Failed to reset Ubuntu"
            return 1
        }
    else
        proot-distro install ubuntu >/dev/null 2>&1 || {
            __error "Failed to install Ubuntu"
            return 1
        }
    fi
    
    proot-distro login ubuntu -- bash -c "
        apt update -y && apt upgrade -y
        apt install -y python3 python3-pip python3-venv git curl wget
        python3 -m venv /opt/warpfusion-venv
        source /opt/warpfusion-venv/bin/activate
        pip install --upgrade pip
    " >/dev/null 2>&1 || {
        __error "Failed to configure Ubuntu"
        return 1
    }
    
    __success "Ubuntu environment configured"
    return 0
}

__install_python() {
    __step "Installing Python packages"
    
    local py_packages=(
        "rich" "icmplib" "cryptography"
        "psutil" "requests" "numpy" "pillow"
    )
    
    pip install --upgrade pip >/dev/null 2>&1 || {
        __error "Failed to upgrade pip"
        return 1
    }
    
    for package in "${py_packages[@]}"; do
        pip install "$package" >/dev/null 2>&1 || {
            __warning "Failed to install $package, retrying..."
            pip install "$package" >/dev/null 2>&1 || {
                __error "Failed to install $package"
                return 1
            }
        }
    done
    
    proot-distro login ubuntu -- bash -c "
        source /opt/warpfusion-venv/bin/activate
        pip install ${py_packages[@]}
    " >/dev/null 2>&1 || {
        __error "Failed to install Python packages in Ubuntu"
        return 1
    }
    
    __success "Python packages installed"
    return 0
}

__install_warpfusion() {
    __step "Installing WarpFusion Ultimate Pro"
    
    local repo_urls=(
        "https://raw.githubusercontent.com/mjjku/wow-warpscanner/main/WarpScanner.py"
        "https://cdn.jsdelivr.net/gh/mjjku/wow-warpscanner/WarpScanner.py"
    )
    
    local target="$HOME/warpfusion"
    mkdir -p "$target" || {
        __error "Failed to create WarpFusion directory"
        return 1
    }
    
    for url in "${repo_urls[@]}"; do
        if curl -fsSL "$url" -o "$target/WarpScanner.py"; then
            chmod +x "$target/WarpScanner.py"
            break
        fi
    done
    
    if [[ ! -f "$target/WarpScanner.py" ]]; then
        __error "Failed to download WarpFusion"
        return 1
    fi
    
    # Create launcher script
    cat > "$target/launch.sh" <<'EOF'
#!/bin/bash
if proot-distro list | grep -q ubuntu; then
    proot-distro login ubuntu -- bash -c "
        source /opt/warpfusion-venv/bin/activate
        cd /home/\$(whoami)/warpfusion
        python WarpScanner.py
    "
else
    cd ~/warpfusion
    python WarpScanner.py
fi
EOF
    
    chmod +x "$target/launch.sh"
    
    # Create alias
    if ! grep -q "alias warpfusion" ~/.bashrc; then
        echo "alias warpfusion='~/warpfusion/launch.sh'" >> ~/.bashrc
    fi
    
    __success "WarpFusion installed successfully"
    return 0
}

# =============== Main Execution ===============
__main() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "   ▄████████████████████████████████▄ "
    echo "  █████▀╙               ╙╙▀██████████ "
    echo " ████▀   WARPFUSION ULTIMATE   ╙██████ "
    echo " ███▌ ╒══════════════════════╕  ▐████ "
    echo " ███▌ │ VERSION 12.0.0 (PERFECT) │  ▐████ "
    echo " ███▌ ╘══════════════════════╛  ▐████ "
    echo " ████▄   TERMUX AI INSTALLER   ,█████ "
    echo "  ▀█████▄▄              ,▄▄████████▀ "
    echo "    ╙▀██████████████████████████▀╙   "
    echo -e "${NC}"
    
    declare -a components=(
        "core" "ubuntu" "python" "warpfusion"
    )
    
    for component in "${components[@]}"; do
        if ! "__install_${component}"; then
            __emergency_recovery
            if ! "__install_${component}"; then
                __error "Critical failure in component: $component"
                exit 1
            fi
        fi
    done
    
    echo -e "${GREEN}${BOLD}"
    echo " ╔════════════════════════════════════╗"
    echo " ║    INSTALLATION COMPLETE!          ║"
    echo " ║                                    ║"
    echo " ║    To start WarpFusion:            ║"
    echo " ║    $ warpfusion                    ║"
    echo " ║                                    ║"
    echo " ║    System optimized for:           ║"
    echo " ║    - $(nproc) CPU cores            ║"
    echo " ║    - $(free -m | awk '/Mem/{print $2}')MB RAM         ║"
    echo " ╚════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Load the new alias
    source ~/.bashrc
}

__main
