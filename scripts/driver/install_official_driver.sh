#!/bin/bash
# Install the built official driver permanently

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Installing Official Hailo Driver Permanently           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

DRIVER_PATH="/home/crtr/Projects/open-hailo/hailort-drivers-official/linux/pcie/hailo_pci.ko"
KERNEL_VER=$(uname -r)

if [ ! -f "$DRIVER_PATH" ]; then
    echo "❌ Driver not found at: $DRIVER_PATH"
    echo "   Please run ./get_official_driver.sh first"
    exit 1
fi

echo "Installing driver to system..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Unload existing drivers
sudo modprobe -r hailo_pci 2>/dev/null || true
sudo modprobe -r hailo1x_pci 2>/dev/null || true

# Compress and install to system
echo "Compressing driver..."
xz -c "$DRIVER_PATH" > /tmp/hailo_pci.ko.xz

echo "Installing to kernel modules..."
sudo cp /tmp/hailo_pci.ko.xz /lib/modules/$KERNEL_VER/kernel/drivers/media/pci/hailo/hailo_pci.ko.xz

# Also install to misc location
sudo mkdir -p /lib/modules/$KERNEL_VER/kernel/drivers/misc/
sudo cp /tmp/hailo_pci.ko.xz /lib/modules/$KERNEL_VER/kernel/drivers/misc/

# Update module database
echo "Updating module dependencies..."
sudo depmod -a

# Load the driver
echo "Loading driver..."
sudo modprobe hailo_pci

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
    modinfo hailo_pci | grep version: | head -1
else
    echo "❌ Device not created"
    echo "Check dmesg for errors: dmesg | tail -20"
fi

echo ""
echo "To make persistent across reboots:"
echo "  echo 'hailo_pci' | sudo tee /etc/modules-load.d/hailo.conf"
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Installation Complete!                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
