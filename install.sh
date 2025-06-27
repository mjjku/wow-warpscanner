#!/data/data/com.termux/files/usr/bin/bash
set -e

# 🎨 Colors
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

clear

# 🎯 Banner
banner() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}     ⚡️ Smart Termux WarpScanner          ${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
}

# 📦 Install Core Dependencies Without apt Warnings
install_dependencies() {
    echo -e "${YELLOW}⏳ Installing required packages silently...${NC}"
    packages=("python" "git" "curl" "wget" "clang" "openssl" "libffi" "rust")

    for apt  in "${packages[@]}"; do
        if ! command -v "$apt " >/dev/null 2>&1; then
            echo -e "${BLUE}📦 Installing $apt  ...${NC}"
            yes | apt  install "$apt " >/dev/null 2>&1 || {
                echo -e "${RED}❌ Failed to install $apt .${NC}"
                exit 1
            }
        fi
    done

    if ! command -v pip >/dev/null 2>&1; then
        echo -e "${BLUE}📦 Installing pip...${NC}"
        yes | apt  install python-pip >/dev/null 2>&1 || {
            echo -e "${RED}❌ Failed to install pip.${NC}"
            exit 1
        }
    fi
}

# 🧰 Install Python Modules - Fully Auto
install_python_modules() {
    echo -e "${YELLOW}⏳ Checking required Python modules...${NC}"
    modules=("rich" "requests" "cryptography")

    for module in "${modules[@]}"; do
        if ! python -c "import $module" 2>/dev/null; then
            echo -e "${BLUE}📦 Installing Python module: $module...${NC}"

            if [[ "$module" == "cryptography" ]]; then
                echo -e "${YELLOW}⚙️ Building cryptography from source...${NC}"
                export CFLAGS="-O2 -fPIC"
                export LDFLAGS="-lm"
                export RUST_BACKTRACE=1
                pip install --no-cache-dir --no-binary :all: --break-system-packages cryptography >/dev/null 2>&1 || {
                    echo -e "${RED}❌ Failed to compile cryptography.${NC}"
                    exit 1
                }
            else
                pip install --break-system-packages "$module" >/dev/null 2>&1 || {
                    echo -e "${RED}❌ Failed to install $module.${NC}"
                    exit 1
                }
            fi
        else
            echo -e "${GREEN}✅ Python module $module is already installed.${NC}"
        fi
    done
}

# 🔍 Get or Update WarpScanner.py
check_and_download_warp_scanner() {
    local file="WarpScanner.py"
    local url="https://raw.githubusercontent.com/mjjku/wow-warpscanner/main/WarpScanner.py"

    if [ -f "$file" ]; then
        local first_line
        first_line=$(head -n 1 "$file")
        if [[ "$first_line" != "V=76" && "$first_line" != "import urllib.request" ]]; then
            echo -e "${YELLOW}🔁 Removing outdated version...${NC}"
            rm -f "$file"
        elif [[ "$first_line" == "import urllib.request" ]]; then
            echo -e "${YELLOW}⚠️ Legacy version removed...${NC}"
            rm -f "$file"
        else
            echo -e "${GREEN}✅ WarpScanner.py is valid.${NC}"
        fi
    fi

    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}⬇️ Downloading latest WarpScanner.py...${NC}"
        curl -fsSL -o "$file" "$url" || {
            echo -e "${RED}❌ Failed to download WarpScanner.py.${NC}"
            exit 1
        }
        echo -e "${GREEN}✅ Downloaded successfully.${NC}"
    fi
}

# ⚙️ Fix missing imports if needed
patch_imports() {
    if ! grep -q "X25519PrivateKey" WarpScanner.py; then
        echo -e "${YELLOW}⚙️ Injecting missing imports...${NC}"
        sed -i '1i from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey' WarpScanner.py
        sed -i '2i from cryptography.hazmat.primitives import serialization' WarpScanner.py
    fi
}

# 🚀 Run Scanner
run_warp_scanner() {
    echo -e "${GREEN}🚀 Running WarpScanner...${NC}"
    python WarpScanner.py || {
        echo -e "${RED}❌ WarpScanner failed to execute.${NC}"
        exit 1
    }
}

# 🧠 Main Orchestration
main() {
    banner
    install_dependencies
    install_python_modules
    check_and_download_warp_scanner
    patch_imports
    run_warp_scanner
    echo -e "${GREEN}[✓] All tasks completed. Ready to go! 💥${NC}"
}

main
