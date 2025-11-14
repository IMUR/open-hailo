#!/bin/bash
# Quick diagnostic to check all Hailo component versions

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Hailo Component Version Check                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "1. HailoRT CLI Version:"
echo "━━━━━━━━━━━━━━━━━━━━━━"
if command -v hailortcli >/dev/null 2>&1; then
    VERSION=$(hailortcli --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    echo -e "   ${GREEN}✓${NC} hailortcli: v$VERSION"
    echo "   Location: $(which hailortcli)"
else
    echo -e "   ${RED}✗${NC} hailortcli not found"
fi
echo ""

echo "2. Library Versions:"
echo "━━━━━━━━━━━━━━━━━━━━━"
if [ -L /usr/local/lib/libhailort.so ]; then
    TARGET=$(readlink /usr/local/lib/libhailort.so)
    echo -e "   ${GREEN}✓${NC} libhailort.so -> $TARGET"
fi

for lib in /usr/local/lib/libhailort.so*; do
    if [ -f "$lib" ]; then
        echo "   • $(basename $lib) ($(du -h $lib | cut -f1))"
    fi
done
echo ""

echo "3. Device Firmware:"
echo "━━━━━━━━━━━━━━━━━━━━━"
if [ -e /dev/hailo0 ] && command -v hailortcli >/dev/null 2>&1; then
    FW_VERSION=$(hailortcli fw-control identify 2>&1 | grep "Firmware Version" | cut -d: -f2 | xargs | cut -d' ' -f1)
    if [ -n "$FW_VERSION" ]; then
        echo -e "   ${GREEN}✓${NC} Firmware: v$FW_VERSION"
    fi
else
    echo -e "   ${YELLOW}⚠${NC} Cannot check firmware version"
fi
echo ""

echo "4. Driver Version:"
echo "━━━━━━━━━━━━━━━━━━━━━"
if lsmod | grep -q hailo_pci; then
    if [ -f /sys/module/hailo_pci/version ]; then
        DRIVER_VERSION=$(cat /sys/module/hailo_pci/version)
        echo -e "   ${GREEN}✓${NC} Driver: v$DRIVER_VERSION"
    else
        echo -e "   ${YELLOW}⚠${NC} Driver loaded but version unknown"
    fi
else
    echo -e "   ${RED}✗${NC} Driver not loaded"
fi
echo ""

echo "5. Version Check:"
echo "━━━━━━━━━━━━━━━━━━━━━"
if hailortcli fw-control identify 2>&1 | grep -q "Unsupported firmware"; then
    echo -e "   ${RED}✗ VERSION MISMATCH DETECTED${NC}"
    hailortcli fw-control identify 2>&1 | grep "Unsupported" | sed 's/^/   /'
else
    echo -e "   ${GREEN}✓ No version mismatch${NC}"
fi
echo ""

echo "6. Python Bindings:"
echo "━━━━━━━━━━━━━━━━━━━━━"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [ -d "$PROJECT_ROOT/.venv" ]; then
    source "$PROJECT_ROOT/.venv/bin/activate" 2>/dev/null
    if python -c "from hailo_platform import HEF" 2>/dev/null; then
        echo -e "   ${GREEN}✓${NC} Python bindings working"
        PYTHON_VERSION=$(python --version | cut -d' ' -f2)
        echo "   Python: $PYTHON_VERSION"
    else
        echo -e "   ${RED}✗${NC} Python bindings not working"
    fi
    deactivate 2>/dev/null
else
    echo -e "   ${YELLOW}⚠${NC} Virtual environment not found"
fi
