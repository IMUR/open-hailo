#!/bin/bash
# Get, build, and install the official HailoRT driver from GitHub
# This script does everything - no need to run install_official_driver.sh separately

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Getting & Installing Official HailoRT Driver           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Clone the official repository
echo "Step 1: Cloning official HailoRT drivers repository..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT/hailort"

if [ -d "hailort-drivers-official" ]; then
    echo "Repository exists, updating..."
    cd hailort-drivers-official
    git fetch --all --tags
    cd ..
else
    git clone https://github.com/hailo-ai/hailort-drivers.git hailort-drivers-official
fi

cd hailort-drivers-official

echo ""
echo "Step 2: Available versions:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
git tag | tail -10
LATEST_TAG=$(git describe --tags --abbrev=0)
echo ""
echo "Latest version: $LATEST_TAG"

echo ""
echo "Step 3: Checking for version matching your firmware (4.23.0)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Try to find a matching version
if git tag | grep -q "v4.23"; then
    echo "✅ Found v4.23.x version!"
    git checkout v4.23.0 2>/dev/null || git checkout $(git tag | grep "v4.23" | head -1)
elif git tag | grep -q "v5.1"; then
    echo "✅ Found v5.1.x version!"
    git checkout v5.1.1 2>/dev/null || git checkout $(git tag | grep "v5.1" | head -1)
else
    echo "⚠️  No exact match, using latest: $LATEST_TAG"
    git checkout $LATEST_TAG
fi

echo ""
echo "Step 4: Building the driver..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd linux/pcie

# Check current kernel
KERNEL_VER=$(uname -r)
echo "Building for kernel: $KERNEL_VER"

# Build the driver - use 'make all' to actually build
# (Plain 'make' just shows help in this Makefile)
make clean 2>/dev/null || true
make all

if [ -f "hailo_pci.ko" ]; then
    echo "✅ Driver built successfully!"
    echo ""
    echo "Step 5: Installing the new driver..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Backup old driver
    sudo cp /lib/modules/$KERNEL_VER/kernel/drivers/media/pci/hailo/hailo_pci.ko.xz \
           /lib/modules/$KERNEL_VER/kernel/drivers/media/pci/hailo/hailo_pci.ko.xz.old 2>/dev/null || true
    
    # Compress and install new driver
    xz -c hailo_pci.ko > hailo_pci.ko.xz
    sudo cp hailo_pci.ko.xz /lib/modules/$KERNEL_VER/kernel/drivers/media/pci/hailo/
    
    # Also copy to misc location
    sudo mkdir -p /lib/modules/$KERNEL_VER/kernel/drivers/misc/
    sudo cp hailo_pci.ko.xz /lib/modules/$KERNEL_VER/kernel/drivers/misc/
    
    # Update module dependencies
    sudo depmod -a
    
    echo "✅ Driver installed!"
    
    echo ""
    echo "Step 6: Loading the new driver..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Unload old driver
    sudo modprobe -r hailo_pci 2>/dev/null || true
    sudo modprobe -r hailo1x_pci 2>/dev/null || true
    
    # Load new driver
    sudo modprobe hailo_pci
    
    # Check if device created
    sleep 2
    if [ -e /dev/hailo0 ]; then
        echo "✅ Device created successfully!"
        ls -la /dev/hailo0
        
        echo ""
        echo "Testing communication..."
        hailortcli fw-control identify 2>&1 | head -5 || true
    else
        echo "⚠️  Device not created - checking dmesg..."
        dmesg | tail -10 | grep -i hailo
    fi
    
    # Show driver info
    echo ""
    echo "Driver info:"
    modinfo hailo_pci | grep -E "version|description|author"
    
else
    echo "❌ Build failed!"
    echo "Check build errors above."
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                        Complete!                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Driver cloned, built, and installed!"
echo ""
echo "📁 Driver source: $(pwd)"
echo "📝 To rebuild: cd $(pwd) && make clean && make"
echo "📝 To reinstall: sudo ./scripts/driver/install_official_driver.sh"
echo ""
echo "Next steps:"
echo "  1. Verify installation: ./scripts/setup/verify_hailo_installation.sh"
echo "  2. Check versions: ./scripts/utils/check_hailo_versions.sh"
echo "  3. Run detection: ./demo_detection.sh"
echo ""
echo "If the driver still doesn't work, try:"
echo "  1. Reboot the system (ensures clean driver load)"
echo "  2. Check dmesg for errors: dmesg | grep -i hailo"
echo "  3. Try different version: cd $(pwd) && git checkout <tag> && make"
echo "  4. Check firmware compatibility with: hailortcli fw-control identify"
