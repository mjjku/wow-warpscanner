#!/data/data/com.termux/files/usr/bin/bash
# -*- coding: utf-8 -*-
#
# WarpFusion Ultimate Pro - Termux Installer
# Version: 15.1.0 (Fixed Persian Edition)
# Description: نصب کامل خودکار بدون خطا با قابلیت بازیابی پیشرفته

# =============== تنظیمات اصلی ===============
set -eo pipefail
shopt -s nullglob extglob
trap '__error_handler $?' EXIT
trap '__emergency_recovery' ERR
trap '__interrupt_handler' INT

# =============== سیستم رنگ ===============
if [[ -t 1 ]]; then
    NC='\033[0m' RED='\033[1;31m' GREEN='\033[1;32m'
    YELLOW='\033[1;33m' BLUE='\033[1;34m' CYAN='\033[1;36m' 
    PURPLE='\033[1;35m' WHITE='\033[1;37m' BOLD='\033[1m'
else
    NC='' RED='' GREEN='' YELLOW='' BLUE='' CYAN='' PURPLE='' WHITE='' BOLD=''
fi

# =============== سیستم لاگینگ ===============
LOG_FILE="$HOME/warpfusion_install.log"
exec 3>&1 4>&2
exec > >(tee -ia "$LOG_FILE") 2>&1

# =============== توابع کمکی ===============
__show_step() {
    echo -e "${BLUE}${BOLD}[+] ${1}...${NC}" >&3
}

__show_success() {
    echo -e "${GREEN}${BOLD}[✓] ${1}${NC}" >&3
}

__show_warning() {
    echo -e "${YELLOW}${BOLD}[!] ${1}${NC}" >&3
}

__show_error() {
    echo -e "${RED}${BOLD}[✗] ${1}${NC}" >&3
}

__error_handler() {
    local exit_code=$1
    [[ $exit_code -eq 0 ]] && return
    
    echo -e "${RED}${BOLD}"
    echo " ╔════════════════════════════════════╗"
    echo " ║          خطا در نصب!           ║"
    echo " ╚════════════════════════════════════╝"
    echo -e "${NC}"
    exit $exit_code
}

__emergency_recovery() {
    echo -e "${YELLOW}${BOLD}"
    echo " ╔════════════════════════════════════╗"
    echo " ║      بازیابی خودکار فعال شد       ║"
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
    echo " ║     نصب متوقف شد!      ║"
    echo " ╚════════════════════════════════════╝"
    echo -e "${NC}"
    exit 1
}

# =============== توابع نصب ===============
__install_core_dependencies() {
    __show_step "نصب پیش‌نیازهای اصلی"
    
    # غیرفعال کردن هشدارهای apt
    export DEBIAN_FRONTEND=noninteractive
    export APT_LISTCHANGES_FRONTEND=none
    
    if ! pkg update -y >/dev/null 2>&1; then
        __show_warning "خطا در بروزرسانی، استفاده از روش جایگزین..."
        pkg update -y -o Acquire::ForceIPv4=true >/dev/null 2>&1 || {
            __show_error "خطا در بروزرسانی پکیج‌ها"
            return 1
        }
    fi
    
    pkg upgrade -y >/dev/null 2>&1
    
    local packages=(
        "python" "git" "curl" "wget" "clang"
        "openssl" "libffi" "rust" "pkg-config"
        "termux-tools" "proot-distro" "jq"
    )
    
    for pkg in "${packages[@]}"; do
        if ! pkg list-installed | grep -q "$pkg"; then
            if ! pkg install -y "$pkg" >/dev/null 2>&1; then
                __show_warning "خطا در نصب $pkg، تلاش مجدد..."
                pkg install -y "$pkg" >/dev/null 2>&1 || {
                    __show_error "خطا در نصب $pkg پس از تلاش مجدد"
                    return 1
                }
            fi
        fi
    done
    
    # بررسی نصب صحیح proot-distro
    if [ ! -f "/data/data/com.termux/files/usr/bin/proot-distro" ]; then
        __show_error "proot-distro به درستی نصب نشده است"
        return 1
    fi
    
    __show_success "پیش‌نیازهای اصلی با موفقیت نصب شدند"
    return 0
}

__setup_ubuntu_environment() {
    __show_step "تنظیم محیط اوبونتو"
    
    # بررسی وجود proot-distro
    if [ ! -f "/data/data/com.termux/files/usr/bin/proot-distro" ]; then
        __show_error "proot-distro یافت نشد!"
        return 1
    fi
    
    if proot-distro list | grep -q ubuntu; then
        __show_step "بازنشانی نصب قبلی اوبونتو"
        if ! proot-distro reset ubuntu -y >/dev/null 2>&1; then
            __show_error "خطا در بازنشانی اوبونتو"
            return 1
        fi
    else
        if ! proot-distro install ubuntu >/dev/null 2>&1; then
            __show_error "خطا در نصب اوبونتو"
            return 1
        fi
    fi
    
    if ! proot-distro login ubuntu -- bash -c "
        apt update -y && apt upgrade -y
        apt install -y python3 python3-pip python3-venv git curl wget
        python3 -m venv /opt/warpfusion-venv
        source /opt/warpfusion-venv/bin/activate
        pip install --upgrade pip
    " >/dev/null 2>&1; then
        __show_error "خطا در پیکربندی اوبونتو"
        return 1
    fi
    
    __show_success "محیط اوبونتو با موفقیت تنظیم شد"
    return 0
}

__install_python_dependencies() {
    __show_step "نصب پکیج‌های پایتون"
    
    local py_packages=(
        "rich" "icmplib" "cryptography"
        "psutil" "requests" "numpy" "pillow"
    )
    
    if ! pip install --upgrade pip >/dev/null 2>&1; then
        __show_error "خطا در بروزرسانی pip"
        return 1
    fi
    
    for package in "${py_packages[@]}"; do
        if ! pip install "$package" >/dev/null 2>&1; then
            __show_warning "خطا در نصب $package، تلاش مجدد..."
            pip install "$package" >/dev/null 2>&1 || {
                __show_error "خطا در نصب $package پس از تلاش مجدد"
                return 1
            }
        fi
    done
    
    if ! proot-distro login ubuntu -- bash -c "
        source /opt/warpfusion-venv/bin/activate
        pip install ${py_packages[@]}
    " >/dev/null 2>&1; then
        __show_error "خطا در نصب پکیج‌های پایتون در اوبونتو"
        return 1
    fi
    
    __show_success "پکیج‌های پایتون با موفقیت نصب شدند"
    return 0
}

__install_warpfusion_core() {
    __show_step "نصب WarpFusion Ultimate Pro"
    
    local repo_urls=(
        "https://raw.githubusercontent.com/mjjku/wow-warpscanner/main/WarpScanner.py"
        "https://cdn.jsdelivr.net/gh/mjjku/wow-warpscanner/WarpScanner.py"
    )
    
    local target_dir="$HOME/warpfusion"
    if ! mkdir -p "$target_dir"; then
        __show_error "خطا در ایجاد پوشه WarpFusion"
        return 1
    fi
    
    for url in "${repo_urls[@]}"; do
        if curl -fsSL "$url" -o "$target_dir/WarpScanner.py"; then
            if ! chmod +x "$target_dir/WarpScanner.py"; then
                __show_error "خطا در اجرایی کردن WarpScanner"
                return 1
            fi
            break
        fi
    done
    
    if [[ ! -f "$target_dir/WarpScanner.py" ]]; then
        __show_error "خطا در دانلود WarpFusion از تمامی میزبان‌ها"
        return 1
    fi
    
    cat > "$target_dir/launch.sh" <<'EOF'
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
    
    if ! chmod +x "$target_dir/launch.sh"; then
        __show_error "خطا در اجرایی کردن لانچر"
        return 1
    fi
    
    if ! grep -q "alias warpfusion" ~/.bashrc; then
        echo "alias warpfusion='~/warpfusion/launch.sh'" >> ~/.bashrc
    fi
    
    __show_success "WarpFusion با موفقیت نصب شد"
    return 0
}

# =============== اجرای اصلی ===============
__main() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "   ▄████████████████████████████████▄ "
    echo "  █████▀╙               ╙╙▀██████████ "
    echo " ████▀   WARPFUSION ULTIMATE   ╙██████ "
    echo " ███▌ ╒══════════════════════╕  ▐████ "
    echo " ███▌ │ نسخه ۱۵.۱.۰ (رفع خطاها) │  ▐████ "
    echo " ███▌ ╘══════════════════════╛  ▐████ "
    echo " ████▄   نصب کننده هوشمند ترمکس   ,█████ "
    echo "  ▀█████▄▄              ,▄▄████████▀ "
    echo "    ╙▀██████████████████████████▀╙   "
    echo -e "${NC}"
    
    declare -a installation_steps=(
        "__install_core_dependencies"
        "__setup_ubuntu_environment"
        "__install_python_dependencies"
        "__install_warpfusion_core"
    )
    
    for step in "${installation_steps[@]}"; do
        if ! $step; then
            __emergency_recovery
            if ! $step; then
                __show_error "خطای بحرانی در حین نصب"
                exit 1
            fi
        fi
    done
    
    echo -e "${GREEN}${BOLD}"
    echo " ╔════════════════════════════════════╗"
    echo " ║    نصب با موفقیت کامل شد!          ║"
    echo " ║                                    ║"
    echo " ║    برای اجرای WarpFusion:         ║"
    echo " ║    $ warpfusion                    ║"
    echo " ║                                    ║"
    echo " ║    سیستم بهینه شده برای:           ║"
    echo " ║    - $(nproc) هسته پردازنده       ║"
    echo " ║    - $(free -m | awk '/Mem/{print $2}')MB رم         ║"
    echo " ╚════════════════════════════════════╝"
    echo -e "${NC}"
    
    # بارگذاری alias جدید
    source ~/.bashrc
}

__main
