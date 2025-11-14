#!/bin/bash
# Check and explain Hailo version compatibility

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Hailo Version Compatibility Check                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Current System Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check CLI version
echo -n "HailoRT CLI Version: "
hailortcli --version 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" || echo "Not installed"

# Check library version
echo -n "HailoRT Library: "
ldconfig -p | grep libhailort | head -1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" || echo "Not found"

# Check driver version
echo -n "Driver Version: "
if lsmod | grep -q hailo; then
    modinfo $(lsmod | grep hailo | awk '{print $1}' | head -1) 2>/dev/null | grep "^version:" | awk '{print $2}'
else
    echo "No driver loaded"
fi

# Check firmware version
echo -n "Device Firmware: "
if [ -e /dev/hailo0 ]; then
    # Try to get firmware version from device
    sudo hailortcli fw-control identify 2>&1 | grep -oE "Firmware [0-9]+\.[0-9]+\.[0-9]+" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" || echo "Cannot read"
else
    echo "Device not available"
fi

echo ""
echo "Compatibility Matrix:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Known Compatible Combinations:"
echo ""
echo "┌──────────────┬──────────┬──────────────┬──────────────┐"
echo "│ HailoRT Ver  │ Driver   │ Firmware     │ Status       │"
echo "├──────────────┼──────────┼──────────────┼──────────────┤"
echo "│ 4.20.0       │ 4.20.0   │ 4.20.x-4.23.x│ ✅ Works     │"
echo "│ 4.23.0       │ 4.23.0   │ 4.23.0       │ ✅ Works     │"
echo "│ 5.0.0        │ 5.0.0    │ 5.0.0        │ ✅ Works     │"
echo "│ 5.1.1        │ 5.1.1    │ 5.1.x        │ ✅ Works     │"
echo "│ Mixed        │ Various  │ Various      │ ⚠️  Warnings │"
echo "└──────────────┴──────────┴──────────────┴──────────────┘"
echo ""
echo "Version Mismatch Symptoms:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. HAILO_DRIVER_INVALID_IOCTL(86)"
echo "   → Driver and library versions don't match"
echo "   → Solution: Match driver to library version"
echo ""
echo "2. 'Unsupported firmware operation'"
echo "   → CLI/library version doesn't match firmware"
echo "   → Solution: Update firmware or downgrade library"
echo ""
echo "3. '/dev/hailo0' not created"
echo "   → Driver didn't load properly"
echo "   → Solution: Check dmesg, rebuild driver"
echo ""
echo "4. 'Device communication failed'"
echo "   → Multiple possible causes"
echo "   → Check all version matches"
echo ""

echo "Checking your specific issue..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect specific issues
if ! [ -e /dev/hailo0 ]; then
    echo "❌ Issue: No device file"
    echo "   Recommendation: Rebuild driver from official repo"
    echo "   Run: ./get_official_driver.sh"
elif hailortcli fw-control identify 2>&1 | grep -q "HAILO_DRIVER_INVALID_IOCTL"; then
    echo "⚠️  Issue: Driver/Library version mismatch"
    echo "   Recommendation: Use matching versions"
    echo "   Option 1: Downgrade library to match driver"
    echo "   Option 2: Build driver from official repo"
elif hailortcli fw-control identify 2>&1 | grep -q "Unsupported firmware"; then
    echo "⚠️  Issue: Firmware/Library version mismatch"
    echo "   Your device firmware may be newer/older than library"
    echo "   Recommendation: Check Hailo support for firmware update"
else
    echo "✅ Communication appears to be working!"
fi

echo ""
echo "Quick Fixes:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Get official driver:  ./get_official_driver.sh"
echo "2. Test with warnings:   Accept version warnings, inference still works"
echo "3. Use Docker Frigate:   Containerized environment handles versions"
echo "4. Contact Hailo:        support@hailo.ai for firmware updates"
echo ""
