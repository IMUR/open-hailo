#!/bin/bash
# Fix HailoRT version mismatch between host and device
# Specifically handles the 4.20.0 vs 4.23.0 issue

set -e

SCRIPT_NAME="HailoRT Version Mismatch Fixer"
PROJECT_ROOT="${PROJECT_ROOT:-/home/crtr/Projects/open-hailo}"
TARGET_VERSION="4.23.0"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  $SCRIPT_NAME                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect current situation
echo "Detecting version mismatch..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check host version
HOST_VERSION="unknown"
if command -v hailortcli >/dev/null 2>&1; then
    HOST_VERSION=$(hailortcli --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    echo "Host HailoRT version: $HOST_VERSION"
else
    echo -e "${RED}HailoRT not installed${NC}"
fi

# Check device version
DEVICE_VERSION="unknown"
if [ -e /dev/hailo0 ] && command -v hailortcli >/dev/null 2>&1; then
    DEVICE_VERSION=$(hailortcli fw-control identify 2>&1 | grep "Firmware Version" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    echo "Device firmware version: $DEVICE_VERSION"
fi

# Check for mismatch
if [ "$HOST_VERSION" = "$DEVICE_VERSION" ] && [ "$HOST_VERSION" = "$TARGET_VERSION" ]; then
    echo -e "${GREEN}✅ No version mismatch detected!${NC}"
    echo "Both host and device are at version $TARGET_VERSION"
    exit 0
fi

if [ "$HOST_VERSION" != "$DEVICE_VERSION" ]; then
    echo -e "${YELLOW}⚠️  Version mismatch detected!${NC}"
fi

echo ""
echo "Target version: $TARGET_VERSION"
echo "Action needed: Update host HailoRT to match device version"
echo ""

# Check for quick fixes first
echo "Checking for quick fixes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Check symlink issue
if [ -L /usr/local/lib/libhailort.so ]; then
    LINK_TARGET=$(readlink /usr/local/lib/libhailort.so)
    echo "libhailort.so points to: $LINK_TARGET"
    
    if [[ "$LINK_TARGET" == *"4.20.0"* ]]; then
        echo -e "${YELLOW}Found incorrect symlink to 4.20.0${NC}"
        
        # Check if 4.23.0 library exists
        if [ -f /usr/local/lib/libhailort.so.4.23.0 ]; then
            echo "Found libhailort.so.4.23.0 - fixing symlink..."
            
            if [ "$EUID" -ne 0 ]; then
                sudo rm /usr/local/lib/libhailort.so
                sudo ln -s /usr/local/lib/libhailort.so.4.23.0 /usr/local/lib/libhailort.so
                sudo ldconfig
            else
                rm /usr/local/lib/libhailort.so
                ln -s /usr/local/lib/libhailort.so.4.23.0 /usr/local/lib/libhailort.so
                ldconfig
            fi
            
            echo -e "${GREEN}✓ Symlink fixed${NC}"
        else
            echo "libhailort.so.4.23.0 not found - need to build from source"
        fi
    fi
fi

# 2. Check CMake config files
CMAKE_CONFIG="/usr/local/lib/cmake/HailoRT/HailoRTConfigVersion.cmake"
if [ -f "$CMAKE_CONFIG" ]; then
    if grep -q '"4\.20\.0"' "$CMAKE_CONFIG" 2>/dev/null; then
        echo -e "${YELLOW}Found outdated CMake config (4.20.0)${NC}"
        echo "Fixing CMake configuration files..."
        
        if [ "$EUID" -ne 0 ]; then
            sudo sed -i 's/"4\.20\.0"/"4.23.0"/g' /usr/local/lib/cmake/HailoRT/HailoRTConfigVersion.cmake
            sudo sed -i 's/4\.20\.0/4.23.0/g' /usr/local/lib/cmake/HailoRT/HailoRTTargets*.cmake
            sudo sed -i 's/MINOR_VERSION=20/MINOR_VERSION=23/g' /usr/local/lib/cmake/HailoRT/HailoRTTargets*.cmake
        else
            sed -i 's/"4\.20\.0"/"4.23.0"/g' /usr/local/lib/cmake/HailoRT/HailoRTConfigVersion.cmake
            sed -i 's/4\.20\.0/4.23.0/g' /usr/local/lib/cmake/HailoRT/HailoRTTargets*.cmake
            sed -i 's/MINOR_VERSION=20/MINOR_VERSION=23/g' /usr/local/lib/cmake/HailoRT/HailoRTTargets*.cmake
        fi
        
        echo -e "${GREEN}✓ CMake configs updated${NC}"
    fi
fi

echo ""

# Verify quick fixes worked
if command -v hailortcli >/dev/null 2>&1; then
    NEW_HOST_VERSION=$(hailortcli --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    
    if [ "$NEW_HOST_VERSION" = "$TARGET_VERSION" ]; then
        echo -e "${GREEN}✅ Quick fix successful!${NC}"
        echo "Host version now: $NEW_HOST_VERSION"
        
        # Test device communication
        if hailortcli fw-control identify >/dev/null 2>&1; then
            if ! hailortcli fw-control identify 2>&1 | grep -q "Unsupported firmware"; then
                echo -e "${GREEN}✅ Version mismatch resolved!${NC}"
                exit 0
            fi
        fi
    fi
fi

# If quick fixes didn't work, need to rebuild
echo ""
echo "Quick fixes insufficient - need to rebuild HailoRT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The following steps are needed to fully fix the version mismatch:"
echo ""
echo "1. Build HailoRT library from source:"
echo "   ./scripts/setup/build_hailort_library.sh"
echo ""
echo "2. Build Python bindings (if using Python):"
echo "   ./scripts/setup/build_python_bindings.sh"
echo ""
echo "3. Verify the fix:"
echo "   ./scripts/setup/verify_hailo_installation.sh"
echo ""

read -p "Run the full fix automatically? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Running full fix sequence..."
    echo ""
    
    # Run the build scripts
    "$PROJECT_ROOT/scripts/setup/build_hailort_library.sh" || {
        echo -e "${RED}Library build failed${NC}"
        exit 1
    }
    
    if [ -f "$PROJECT_ROOT/scripts/setup/build_python_bindings.sh" ]; then
        "$PROJECT_ROOT/scripts/setup/build_python_bindings.sh" || {
            echo -e "${YELLOW}Python bindings build failed (non-critical)${NC}"
        }
    fi
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "✅ Version mismatch fix complete!"
    echo ""
    echo "Running verification..."
    "$PROJECT_ROOT/scripts/setup/verify_hailo_installation.sh"
else
    echo "Manual fix required. Run the commands shown above."
fi
