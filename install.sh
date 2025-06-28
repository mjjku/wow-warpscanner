#!/data/data/com.termux/files/usr/bin/bash
set -e

# 🎨 رنگ‌ها برای خروجی زیبا
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

clear

# 🎯 بنر خوش‌آمدگویی
banner() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}     ⚡️ Smart Termux WarpFusion Elite    ${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}🚀 هماهنگ‌سازی WarpScanner با Ubuntu${NC}"
}

# 📦 به‌روزرسانی Termux
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

# 📦 نصب پیش‌نیازها در Ubuntu
setup_ubuntu() {
    echo -e "${YELLOW}⏳ نصب پیش‌نیازها در Ubuntu...${NC}"
    proot-distro login ubuntu -- bash -c "
        apt update && apt upgrade -y
        apt install -y python3 python3-pip git curl wget
        pip3 install --break-system-packages requests cryptography icmplib psutil pyyaml rich alive_progress
    " || {
        echo -e "${RED}❌ خطا در نصب پیش‌نیازها${NC}"
        exit 1
    }
}

# 🔍 بررسی و دانلود WarpScanner.py
check_and_download_warp_scanner() {
    local file="WarpScanner.py"
    local url="https://raw.githubusercontent.com/mjjku/wow-warpscanner/main/WarpScanner.py"

    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ فایل WarpScanner.py در Termux موجود است.${NC}"
    else
        echo -e "${YELLOW}⬇️ دانلود آخرین نسخه WarpScanner.py...${NC}"
        curl -fsSL -o "$file" "$url" || {
            echo -e "${RED}❌ خطا در دانلود WarpScanner.py${NC}"
            exit 1
        }
        echo -e "${GREEN}✅ دانلود با موفقیت انجام شد.${NC}"
    fi
}

# 📂 انتقال فایل به Ubuntu
copy_to_ubuntu() {
    echo -e "${YELLOW}⏳ انتقال فایل WarpScanner.py به Ubuntu...${NC}"
    proot-distro login ubuntu -- bash -c "mkdir -p /root && cp /storage/emulated/0/Download/WarpScanner.py /root/WarpScanner.py" 2>/dev/null || {
        # اگر فایل در دایرکتوری فعلی Termux باشد
        cp WarpScanner.py ~/.termux-ubuntu-rootfs/root/ 2>/dev/null || {
            echo -e "${RED}❌ خطا در انتقال فایل به Ubuntu${NC}"
            exit 1
        }
    }
    echo -e "${GREEN}✅ فایل با موفقیت به Ubuntu منتقل شد.${NC}"
}

# 🚀 اجرای WarpScanner در Ubuntu
run_warp_scanner() {
    echo -e "${GREEN}🚀 اجرای WarpScanner در Ubuntu...${NC}"
    proot-distro login ubuntu -- bash -c "cd /root && python3 WarpScanner.py" || {
        echo -e "${RED}❌ خطا در اجرای WarpScanner${NC}"
        exit 1
    }
}

# 🧠 تابع اصلی
main() {
    banner
    update_termux
    install_ubuntu
    setup_ubuntu
    check_and_download_warp_scanner
    copy_to_ubuntu
    run_warp_scanner
    echo -e "${GREEN}[✓] همه مراحل با موفقیت انجام شد! 💥${NC}"
}

# اجرای اسکریپت
main
