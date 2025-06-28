#!/data/data/com.termux/files/usr/bin/bash
set -e

# 🎨 رنگ‌ها
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

clear

# 🎯 بنر
banner() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}     ⚡️ Smart Termux WarpFusion Elite    ${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}🚀 هماهنگ‌سازی WarpScanner و WarpFusion با Ubuntu${NC}"
}

# 📦 به‌روزرسانی و ارتقاء پکیج‌های Termux
update_termux() {
    echo -e "${YELLOW}⏳ به‌روزرسانی و ارتقاء پکیج‌های Termux...${NC}"
    yes | pkg update && yes | pkg upgrade -y || {
        echo -e "${RED}❌ خطا در به‌روزرسانی Termux${NC}"
        exit 1
    }
}

# 📦 نصب proot-distro و Ubuntu
install_ubuntu() {
    if ! command -v proot-distro >/dev/null 2>&1; then
        echo -e "${BLUE}📦 نصب proot-distro...${NC}"
        yes | pkg install proot-distro -y || {
            echo -e "${RED}❌ خطا در نصب proot-distro${NC}"
            exit 1
        }
    fi

    if ! proot-distro list | grep -q "ubuntu"; then
        echo -e "${BLUE}📦 نصب Ubuntu...${NC}"
        proot-distro install ubuntu || {
            echo -e "${RED}❌ خطا در نصب Ubuntu${NC}"
            exit 1
        }
    fi
}

# 📦 ورود به Ubuntu و نصب پیش‌نیازها
setup_ubuntu() {
    echo -e "${YELLOW}⏳ ورود به Ubuntu و نصب پیش‌نیازها...${NC}"
    proot-distro login ubuntu -- bash -c "
        apt update && apt upgrade -y
        apt install -y python3 python3-pip git curl wget clang libssl-dev libffi-dev rustc wireguard-tools
        pip3 install --break-system-packages rich requests cryptography icmplib psutil pyyaml alive_progress
    " || {
        echo -e "${RED}❌ خطا در نصب پیش‌نیازها در Ubuntu${NC}"
        exit 1
    }
}

# 🔍 بررسی و دانلود WarpScanner.py
check_and_download_warp_scanner() {
    local file="WarpScanner.py"
    local url="https://raw.githubusercontent.com/mjjku/wow-warpscanner/main/WarpScanner.py"

    if [ -f "$file" ]; then
        local first_line
        first_line=$(head -n 1 "$file")
        if [[ "$first_line" != "V=76" && "$first_line" != "import urllib.request" ]]; then
            echo -e "${YELLOW}🔁 حذف نسخه قدیمی...${NC}"
            rm -f "$file"
        elif [[ "$first_line" == "import urllib.request" ]]; then
            echo -e "${YELLOW}⚠️ حذف نسخه قدیمی‌تر...${NC}"
            rm -f "$file"
        else
            echo -e "${GREEN}✅ فایل WarpScanner.py معتبر است.${NC}"
        fi
    fi

    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}⬇️ دانلود آخرین نسخه WarpScanner.py...${NC}"
        curl -fsSL -o "$file" "$url" || {
            echo -e "${RED}❌ خطا در دانلود WarpScanner.py${NC}"
            exit 1
        }
        echo -e "${GREEN}✅ دانلود با موفقیت انجام شد.${NC}"
    fi
}

# ⚙️ رفع مشکل ایمپورت‌ها
patch_imports() {
    if [ -f "WarpScanner.py" ] && ! grep -q "X25519PrivateKey" WarpScanner.py; then
        echo -e "${YELLOW}⚙️ تزریق ایمپورت‌های لازم...${NC}"
        sed -i '1i from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey' WarpScanner.py
        sed -i '2i from cryptography.hazmat.primitives import serialization' WarpScanner.py
    fi
}

# 🚀 اجرای WarpScanner در Ubuntu
run_warp_scanner() {
    echo -e "${GREEN}🚀 اجرای WarpScanner در Ubuntu...${NC}"
    proot-distro login ubuntu -- python3 WarpScanner.py || {
        echo -e "${RED}❌ خطا در اجرای WarpScanner${NC}"
        exit 1
    }
}

# 🚀 اجرای WarpFusion Elite Pro در Ubuntu
run_warpfusion() {
    if [ -f "warpfusion_elite_pro.py" ]; then
        echo -e "${GREEN}🚀 اجرای WarpFusion Elite Pro در Ubuntu...${NC}"
        proot-distro login ubuntu -- python3 warpfusion_elite_pro.py || {
            echo -e "${RED}❌ خطا در اجرای WarpFusion${NC}"
            exit 1
        }
    else
        echo -e "${YELLOW}⚠️ فایل warpfusion_elite_pro.py یافت نشد. فقط WarpScanner اجرا می‌شود.${NC}"
    fi
}

# 🧠 مدیریت اصلی
main() {
    banner
    update_termux
    install_ubuntu
    setup_ubuntu
    check_and_download_warp_scanner
    patch_imports
    run_warp_scanner
    run_warpfusion
    echo -e "${GREEN}[✓] همه وظایف با موفقیت انجام شد. آماده استفاده! 💥${NC}"
}

main
