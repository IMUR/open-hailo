#!/bin/bash
# Universal build dependency installer for HailoRT
# Safe to run multiple times (idempotent)

set -e

SCRIPT_NAME="Build Dependencies Installer"
REQUIRED_PACKAGES=(
    build-essential
    cmake
    git
    dkms
    libelf-dev
    python3-dev
    python3-venv
    python3-pip
    libgstreamer1.0-dev
    libgstreamer-plugins-base1.0-dev
    libgstreamer-plugins-bad1.0-dev
    libprotobuf-dev
    protobuf-compiler
    libzmq3-dev
    libgirepository1.0-dev
    python3-gi
    python3-gi-cairo
    pybind11-dev
    python3-pybind11
    ninja-build
    ccache
    pkg-config
    uv
)

# Optional but recommended packages
OPTIONAL_PACKAGES=(
    gcc-12
    g++-12
    python3.12
    python3.12-dev
    python3.12-venv
)

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  $SCRIPT_NAME                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Function to check if package is installed
is_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Function to get OS info
get_os_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "OS: $PRETTY_NAME"
        echo "Version: $VERSION_ID"
        echo "Codename: $VERSION_CODENAME"
    fi
}

echo "System Information:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
get_os_info
echo ""

# Check what's already installed
echo "Checking installed packages..."
MISSING_REQUIRED=()
MISSING_OPTIONAL=()

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if is_installed "$pkg"; then
        echo "  ✅ $pkg (installed)"
    else
        echo "  ❌ $pkg (missing)"
        MISSING_REQUIRED+=("$pkg")
    fi
done

echo ""
echo "Checking optional packages..."
for pkg in "${OPTIONAL_PACKAGES[@]}"; do
    if is_installed "$pkg"; then
        echo "  ✅ $pkg (installed)"
    else
        echo "  ⚠️  $pkg (optional, not installed)"
        MISSING_OPTIONAL+=("$pkg")
    fi
done

# Install missing required packages
if [ ${#MISSING_REQUIRED[@]} -gt 0 ]; then
    echo ""
    echo "Installing ${#MISSING_REQUIRED[@]} missing required packages..."
    echo "Packages: ${MISSING_REQUIRED[*]}"
    echo ""
    
    if [ "$EUID" -ne 0 ]; then
        echo "This script needs sudo privileges to install packages."
        echo "Running: sudo apt update && sudo apt install -y ${MISSING_REQUIRED[*]}"
        sudo apt update
        sudo apt install -y "${MISSING_REQUIRED[@]}"
    else
        apt update
        apt install -y "${MISSING_REQUIRED[@]}"
    fi
else
    echo ""
    echo "✅ All required packages are already installed!"
fi

# Ask about optional packages
if [ ${#MISSING_OPTIONAL[@]} -gt 0 ]; then
    echo ""
    echo "Optional packages for better compatibility:"
    echo "  ${MISSING_OPTIONAL[*]}"
    echo ""
    read -p "Install optional packages? (recommended for Trixie) [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ "$EUID" -ne 0 ]; then
            sudo apt install -y "${MISSING_OPTIONAL[@]}"
        else
            apt install -y "${MISSING_OPTIONAL[@]}"
        fi
    fi
fi

# Verify critical tools
echo ""
echo "Verifying critical tools:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
command -v cmake >/dev/null 2>&1 && echo "  ✅ CMake: $(cmake --version | head -1)" || echo "  ❌ CMake not found"
command -v ninja >/dev/null 2>&1 && echo "  ✅ Ninja: $(ninja --version)" || echo "  ❌ Ninja not found"
command -v python3 >/dev/null 2>&1 && echo "  ✅ Python: $(python3 --version)" || echo "  ❌ Python3 not found"
command -v gcc >/dev/null 2>&1 && echo "  ✅ GCC: $(gcc --version | head -1)" || echo "  ❌ GCC not found"
command -v gcc-12 >/dev/null 2>&1 && echo "  ✅ GCC-12: $(gcc-12 --version | head -1)" || echo "  ⚠️  GCC-12 not found (optional)"
command -v uv >/dev/null 2>&1 && echo "  ✅ UV: $(uv --version)" || echo "  ⚠️  UV not found (optional)"

echo ""
echo "✅ Build dependencies check complete!"
echo ""
echo "Next steps:"
echo "  1. Build HailoRT driver: ./scripts/setup/build_hailort_driver.sh"
echo "  2. Build HailoRT library: ./scripts/setup/build_hailort_library.sh"
