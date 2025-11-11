#!/bin/bash
# Open Hailo - Build Script for Debian 13
# This script automates the build process for Hailo AI HAT+ support

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$SCRIPT_DIR/build"
DRIVER_VERSION="hailo8"
HAILORT_VERSION="v4.20.0"

echo "Hailo AI HAT+ Open-Source Build Script"
echo "======================================"

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo "Warning: This script is designed for Raspberry Pi. Proceed anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for Hailo device
if ! lspci | grep -q "Hailo"; then
    echo "Warning: No Hailo device detected on PCIe. Continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 1: Install dependencies
echo "Step 1: Installing build dependencies..."
sudo apt update
sudo apt install -y build-essential linux-headers-$(uname -r) dkms pciutils pkg-config cmake git

# Step 2: Build kernel driver
echo "Step 2: Building Hailo kernel driver..."
cd "$SCRIPT_DIR/drivers"
if [ ! -d "hailort-drivers" ]; then
    git clone https://github.com/hailo-ai/hailort-drivers.git
fi
cd hailort-drivers
git checkout $DRIVER_VERSION

cd linux/pcie
make clean
make all
sudo make install

# Install udev rules
sudo cp 51-hailo-udev.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger

# Download firmware
cd ../..
if [ ! -f "hailo8_fw.*.bin" ]; then
    ./download_firmware.sh
fi
sudo mkdir -p /lib/firmware/hailo
sudo cp hailo8_fw.*.bin /lib/firmware/hailo/hailo8_fw.bin

# Load driver
sudo modprobe -r hailo_pci 2>/dev/null || true
sudo modprobe hailo_pci

# Step 3: Build HailoRT
echo "Step 3: Building HailoRT runtime..."
cd "$SCRIPT_DIR/runtime"
if [ ! -d "hailort" ]; then
    git clone https://github.com/hailo-ai/hailort.git
fi
cd hailort
git checkout $HAILORT_VERSION

mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
sudo make install
sudo ldconfig

# Step 4: Verify installation
echo "Step 4: Verifying installation..."
if [ -e "/dev/hailo0" ]; then
    echo "✓ Hailo device node created successfully"
else
    echo "✗ Hailo device node not found"
fi

if command -v hailortcli &> /dev/null; then
    echo "✓ HailoRT CLI installed successfully"
    echo "Device scan results:"
    hailortcli scan
else
    echo "✗ HailoRT CLI not found"
fi

echo ""
echo "Build complete! Next steps:"
echo "1. Run 'hailortcli fw-control identify' to check device"
echo "2. Build and run the test application in $SCRIPT_DIR/apps"
echo "3. Refer to docs/BUILD_GUIDE.md for troubleshooting"
