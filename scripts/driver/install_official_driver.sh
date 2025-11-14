#!/bin/bash
# Install the built official driver permanently
# Note: This script expects the driver to be already built

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Installing Official Hailo Driver Permanently           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_ROOT="/home/crtr/Projects/open-hailo"
DRIVER_DIR="$PROJECT_ROOT/hailort-drivers-official/linux/pcie"
KERNEL_VER=$(uname -r)

# v5.1.1+ uses hailo1x_pci.ko, older versions use hailo_pci.ko
if [ -f "$DRIVER_DIR/hailo1x_pci.ko" ]; then
    DRIVER_PATH="$DRIVER_DIR/hailo1x_pci.ko"
    DRIVER_NAME="hailo1x_pci"
elif [ -f "$DRIVER_DIR/hailo_pci.ko" ]; then
    DRIVER_PATH="$DRIVER_DIR/hailo_pci.ko"
    DRIVER_NAME="hailo_pci"
else
    DRIVER_PATH="$DRIVER_DIR/hailo_pci.ko"
    DRIVER_NAME="hailo_pci"
fi

# Check if driver directory exists
if [ ! -d "$DRIVER_DIR" ]; then
    echo "❌ Driver directory not found: $DRIVER_DIR"
    echo "   Please run ./scripts/driver/get_official_driver.sh first"
    exit 1
fi

# Check if driver is built, if not - build it
if [ ! -f "$DRIVER_PATH" ]; then
    echo "⚠️  Driver not built yet. Building now..."
    echo ""
    cd "$DRIVER_DIR"
    
    # Build the driver - use 'make all' to actually build
    # (Plain 'make' just shows help in this driver's Makefile)
    make clean 2>/dev/null || true
    make all
    
    # Check both possible locations
    if [ -f "hailo_pci.ko" ]; then
        echo "✅ Driver built successfully (current dir)!"
    elif [ -f "build/release/aarch64/hailo_pci.ko" ]; then
        echo "✅ Driver built successfully (build dir)!"
        cp build/release/aarch64/hailo_pci.ko .
    else
        echo "❌ Driver build failed!"
        echo "Checked locations:"
        echo "  - $DRIVER_DIR/hailo_pci.ko"
        echo "  - $DRIVER_DIR/build/release/aarch64/hailo_pci.ko"
        exit 1
    fi
    echo ""
fi

echo "Installing driver to system..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Unload existing drivers
sudo modprobe -r hailo_pci 2>/dev/null || true
sudo modprobe -r hailo1x_pci 2>/dev/null || true

# Compress and install to system
echo "Compressing driver ($DRIVER_NAME)..."
xz -c "$DRIVER_PATH" > /tmp/${DRIVER_NAME}.ko.xz

echo "Installing to kernel modules..."
# Install with the actual driver name
sudo mkdir -p /lib/modules/$KERNEL_VER/kernel/drivers/misc/
sudo cp /tmp/${DRIVER_NAME}.ko.xz /lib/modules/$KERNEL_VER/kernel/drivers/misc/

# Also create hailo_pci symlink for compatibility
if [ "$DRIVER_NAME" = "hailo1x_pci" ]; then
    sudo mkdir -p /lib/modules/$KERNEL_VER/kernel/drivers/media/pci/hailo/
    sudo ln -sf /lib/modules/$KERNEL_VER/kernel/drivers/misc/hailo1x_pci.ko.xz \
                /lib/modules/$KERNEL_VER/kernel/drivers/media/pci/hailo/hailo_pci.ko.xz 2>/dev/null || true
fi

# Update module database
echo "Updating module dependencies..."
sudo depmod -a

# Load the driver
echo "Loading driver ($DRIVER_NAME)..."
sudo modprobe $DRIVER_NAME

# Wait for device
sleep 2

# Check results
echo ""
echo "Installation Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -e /dev/hailo0 ]; then
    echo "✅ Device created successfully!"
    ls -la /dev/hailo0
    echo ""
    echo "Driver version:"
    modinfo $DRIVER_NAME | grep version: | head -1
else
    echo "❌ Device not created"
    echo "Check dmesg for errors: dmesg | tail -20"
fi

echo ""
echo "To make persistent across reboots:"
echo "  echo '$DRIVER_NAME' | sudo tee /etc/modules-load.d/hailo.conf"
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Installation Complete!                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
