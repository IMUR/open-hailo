#!/bin/bash
# Comprehensive Hailo installation verification script
# Can be run anytime to check system status

SCRIPT_NAME="Hailo Installation Verifier"
PROJECT_ROOT="${PROJECT_ROOT:-/home/crtr/Projects/open-hailo}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  $SCRIPT_NAME                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Score tracking
TOTAL_TESTS=0
PASSED_TESTS=0
WARNINGS=0
ERRORS=0

# Test result function
test_result() {
    local status=$1
    local message=$2
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    case $status in
        "pass")
            echo -e "${GREEN}✅ $message${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            ;;
        "warn")
            echo -e "${YELLOW}⚠️  $message${NC}"
            WARNINGS=$((WARNINGS + 1))
            PASSED_TESTS=$((PASSED_TESTS + 1))  # Warning counts as pass
            ;;
        "fail")
            echo -e "${RED}❌ $message${NC}"
            ERRORS=$((ERRORS + 1))
            ;;
    esac
}

# Section header
section() {
    echo ""
    echo -e "${BLUE}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# System Information
section "📊 System Information"
echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Python: $(python3 --version)"
echo "GCC: $(gcc --version | head -1)"
echo "Date: $(date)"

# 1. Driver Status
section "🔧 Test 1: PCIe Driver Status"

if lsmod | grep -q hailo_pci; then
    test_result "pass" "hailo_pci driver loaded"
    
    # Check driver version if possible
    if [ -f /sys/module/hailo_pci/version ]; then
        VERSION=$(cat /sys/module/hailo_pci/version)
        echo "   Driver version: $VERSION"
    fi
else
    test_result "fail" "hailo_pci driver not loaded"
    echo "   Fix: Run ./scripts/setup/build_hailort_driver.sh"
fi

# 2. Device Detection
section "🔧 Test 2: Device Detection"

if [ -e /dev/hailo0 ]; then
    test_result "pass" "Device /dev/hailo0 exists"
    
    # Check permissions
    PERMS=$(stat -c "%a" /dev/hailo0)
    if [ "$PERMS" = "666" ] || [ "$PERMS" = "660" ]; then
        test_result "pass" "Device permissions OK ($PERMS)"
    else
        test_result "warn" "Device permissions unusual ($PERMS)"
    fi
else
    test_result "fail" "Device /dev/hailo0 not found"
    echo "   Possible causes:"
    echo "   - Device not connected"
    echo "   - Driver not loaded"
    echo "   - Need to reboot"
fi

# Check PCIe detection
if lspci 2>/dev/null | grep -qi hailo; then
    test_result "pass" "Hailo device visible in PCIe"
    lspci | grep -i hailo | head -1 | sed 's/^/   /'
else
    test_result "warn" "Hailo device not visible in lspci"
fi

# 3. HailoRT Library
section "🔧 Test 3: HailoRT Library"

if command -v hailortcli >/dev/null 2>&1; then
    VERSION=$(hailortcli --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    test_result "pass" "HailoRT CLI installed (v$VERSION)"
    
    # Check for version mismatch
    if hailortcli fw-control identify 2>&1 | grep -q "Unsupported firmware"; then
        test_result "warn" "Version mismatch between host and device"
        echo "   Fix: Run ./scripts/setup/build_hailort_library.sh"
    else
        test_result "pass" "No version mismatch detected"
    fi
else
    test_result "fail" "HailoRT CLI not installed"
    echo "   Fix: Run ./scripts/setup/build_hailort_library.sh"
fi

# Check library file
if [ -f /usr/local/lib/libhailort.so ]; then
    test_result "pass" "libhailort.so found"
    
    # Check for missing dependencies
    if ldd /usr/local/lib/libhailort.so 2>&1 | grep -q "not found"; then
        test_result "fail" "Library has missing dependencies"
        echo "   Run: ldd /usr/local/lib/libhailort.so"
    else
        test_result "pass" "Library dependencies OK"
    fi
else
    test_result "fail" "libhailort.so not found"
fi

# 4. Device Communication
section "🔧 Test 4: Device Communication"

if command -v hailortcli >/dev/null 2>&1 && [ -e /dev/hailo0 ]; then
    if hailortcli fw-control identify >/dev/null 2>&1; then
        test_result "pass" "Device communication successful"
        
        # Get device info
        FW_VERSION=$(hailortcli fw-control identify 2>&1 | grep "Firmware Version" | cut -d: -f2 | xargs)
        BOARD_NAME=$(hailortcli fw-control identify 2>&1 | grep "Board Name" | cut -d: -f2 | xargs)
        
        if [ -n "$FW_VERSION" ]; then
            echo "   Firmware: $FW_VERSION"
        fi
        if [ -n "$BOARD_NAME" ]; then
            echo "   Board: $BOARD_NAME"
        fi
    else
        test_result "fail" "Device communication failed"
        echo "   Check: dmesg | grep hailo"
    fi
else
    test_result "warn" "Cannot test device communication"
fi

# 5. Python Bindings
section "🔧 Test 5: Python Bindings"

# Check if venv exists
if [ -d "$PROJECT_ROOT/venv" ]; then
    test_result "pass" "Virtual environment exists"
    
    # Test bindings
    source "$PROJECT_ROOT/venv/bin/activate" 2>/dev/null
    
    if python -c "from hailo_platform import HEF" 2>/dev/null; then
        test_result "pass" "Python bindings working"
        
        PYTHON_VERSION=$(python --version | cut -d' ' -f2)
        echo "   Python version in venv: $PYTHON_VERSION"
    else
        test_result "fail" "Python bindings not working"
        echo "   Fix: Run ./scripts/setup/build_python_bindings.sh"
    fi
    
    deactivate 2>/dev/null
else
    test_result "warn" "Virtual environment not found"
    echo "   Fix: Run ./scripts/setup/build_python_bindings.sh"
fi

# 6. Model Files
section "🔧 Test 6: Model Files"

MODEL_DIR="$PROJECT_ROOT/models"
if [ -d "$MODEL_DIR" ]; then
    MODEL_COUNT=$(ls -1 "$MODEL_DIR"/*.hef 2>/dev/null | wc -l)
    if [ $MODEL_COUNT -gt 0 ]; then
        test_result "pass" "$MODEL_COUNT model files found"
        ls -1 "$MODEL_DIR"/*.hef | head -3 | while read model; do
            echo "   - $(basename $model) ($(du -h "$model" | cut -f1))"
        done
    else
        test_result "warn" "No model files found"
        echo "   Fix: Run ./scripts/setup/download_yolov8_models.sh"
    fi
else
    test_result "fail" "Models directory not found"
fi

# 7. TAPPAS Installation
section "🔧 Test 7: TAPPAS Installation"

if pkg-config --exists hailo-tappas-core 2>/dev/null; then
    VERSION=$(pkg-config --modversion hailo-tappas-core)
    test_result "pass" "TAPPAS installed (v$VERSION)"
else
    test_result "warn" "TAPPAS not detected"
    echo "   This is optional but recommended for advanced features"
fi

# 8. rpicam-apps
section "🔧 Test 8: rpicam-apps with Hailo"

RPICAM_BIN="$HOME/local/bin/rpicam-hello"
if [ -f "$RPICAM_BIN" ]; then
    test_result "pass" "rpicam-apps found"
    
    # Check if built with Hailo support
    if ldd "$RPICAM_BIN" 2>&1 | grep -q libhailort; then
        test_result "pass" "Built with Hailo support"
    else
        test_result "warn" "No Hailo support detected"
        echo "   Fix: Rebuild after fixing HailoRT"
    fi
else
    test_result "warn" "rpicam-apps not built"
    echo "   Fix: Run ./scripts/build/build_hailo_preview_local.sh"
fi

# 9. Inference Test (if possible)
section "🔧 Test 9: Basic Inference Capability"

if [ -f "$PROJECT_ROOT/models/yolov8s.hef" ] && command -v hailortcli >/dev/null 2>&1; then
    echo "Running quick inference test..."
    
    # Try to run a basic test
    cd "$PROJECT_ROOT"
    if timeout 5 hailortcli run "$PROJECT_ROOT/models/yolov8s.hef" --measure-fps 2>&1 | grep -q "FPS"; then
        test_result "pass" "Basic inference working"
    else
        test_result "warn" "Inference test inconclusive"
    fi
else
    test_result "warn" "Cannot test inference (missing model or CLI)"
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "📋 VERIFICATION SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Calculate percentage
if [ $TOTAL_TESTS -gt 0 ]; then
    PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
else
    PERCENTAGE=0
fi

echo "Tests Run: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "Failed: ${RED}$ERRORS${NC}"
echo "Score: $PERCENTAGE%"
echo ""

# Overall status
if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✅ SYSTEM FULLY OPERATIONAL${NC}"
        echo ""
        echo "Ready to run:"
        echo "  source $PROJECT_ROOT/venv/bin/activate"
        echo "  export PATH=\"\$HOME/local/bin:\$PATH\""
        echo "  rpicam-hello -t 0 --post-process-file test/hailo_yolov8_custom.json"
    else
        echo -e "${YELLOW}⚠️  SYSTEM OPERATIONAL WITH WARNINGS${NC}"
        echo ""
        echo "The system should work but some optional features may be missing."
    fi
else
    echo -e "${RED}❌ SYSTEM NEEDS ATTENTION${NC}"
    echo ""
    echo "Fix the failed tests above to get the system fully operational."
    echo ""
    echo "Recommended fix order:"
    
    if ! lsmod | grep -q hailo_pci; then
        echo "  1. ./scripts/setup/build_hailort_driver.sh"
    fi
    
    if ! command -v hailortcli >/dev/null 2>&1; then
        echo "  2. ./scripts/setup/build_hailort_library.sh"
    fi
    
    if [ ! -d "$PROJECT_ROOT/venv" ]; then
        echo "  3. ./scripts/setup/build_python_bindings.sh"
    fi
fi

echo "═══════════════════════════════════════════════════════════"
