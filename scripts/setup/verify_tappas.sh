#!/bin/bash
# Verify and fix TAPPAS installation

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          TAPPAS Verification & Fix                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

TAPPAS_DIR="$HOME/tappas"

if [ ! -d "$TAPPAS_DIR" ]; then
    echo "❌ TAPPAS directory not found at $TAPPAS_DIR"
    echo "Run: ./scripts/setup/install_tappas.sh"
    exit 1
fi

echo "Checking TAPPAS installation..."
echo ""

# Check for pkg-config file
if pkg-config --exists hailo-tappas-core 2>/dev/null; then
    echo "✅ TAPPAS pkg-config found"
    echo "   Version: $(pkg-config --modversion hailo-tappas-core)"
    echo "   Lib dir: $(pkg-config --variable=libdir hailo-tappas-core)"
else
    echo "❌ TAPPAS pkg-config not found"
    echo ""
    echo "Searching for TAPPAS libraries..."

    # Find where TAPPAS might have installed
    TAPPAS_LIB_LOCATIONS=(
        "$TAPPAS_DIR/build/x86_64/core/hailo"
        "$TAPPAS_DIR/build/aarch64/core/hailo"
        "/usr/local/lib/hailo/tappas"
        "/usr/lib/hailo/tappas"
    )

    FOUND_LIB=""
    for loc in "${TAPPAS_LIB_LOCATIONS[@]}"; do
        if [ -d "$loc" ]; then
            echo "  Found: $loc"
            FOUND_LIB="$loc"
            break
        fi
    done

    if [ -z "$FOUND_LIB" ]; then
        echo ""
        echo "⚠️  TAPPAS libraries not found in expected locations"
        echo "   This usually means TAPPAS didn't build correctly"
        echo ""
        echo "Trying to rebuild TAPPAS..."
        cd "$TAPPAS_DIR"

        # Re-run install with verbose output
        ./install.sh --target-platform rpi5 --skip-hailort --core-only 2>&1 | tee tappas_rebuild.log

        if pkg-config --exists hailo-tappas-core 2>/dev/null; then
            echo "✅ TAPPAS rebuild successful!"
        else
            echo "❌ TAPPAS rebuild failed"
            echo "   Check log: $TAPPAS_DIR/tappas_rebuild.log"
            exit 1
        fi
    fi
fi

echo ""
echo "Checking post-processing libraries..."

# Find TAPPAS lib directory
if pkg-config --exists hailo-tappas-core 2>/dev/null; then
    TAPPAS_LIBDIR=$(pkg-config --variable=libdir hailo-tappas-core 2>/dev/null || echo "")

    if [ -n "$TAPPAS_LIBDIR" ]; then
        # Check for post-processing libraries
        PP_DIRS=("post-process" "post_processes")
        PP_DIR_FOUND=""

        for dir in "${PP_DIRS[@]}"; do
            if [ -d "$TAPPAS_LIBDIR/$dir" ]; then
                PP_DIR_FOUND="$TAPPAS_LIBDIR/$dir"
                break
            fi
        done

        if [ -n "$PP_DIR_FOUND" ]; then
            echo "✅ Post-processing dir: $PP_DIR_FOUND"
            echo ""
            echo "Available post-processing libraries:"
            ls -1 "$PP_DIR_FOUND"/*.so 2>/dev/null | while read lib; do
                echo "  - $(basename $lib)"
            done
        else
            echo "⚠️  Post-processing libraries not found"
        fi
    fi
fi

echo ""
echo "Checking HailoRT library location..."

# HailoRT should be in /usr/local/lib
if [ -f "/usr/local/lib/libhailort.so" ]; then
    echo "✅ HailoRT found at /usr/local/lib/libhailort.so"
elif [ -f "/usr/lib/libhailort.so" ]; then
    echo "✅ HailoRT found at /usr/lib/libhailort.so"
else
    echo "❌ HailoRT library not found in standard locations"
    echo "   Searching..."
    find /usr -name "libhailort.so*" 2>/dev/null || echo "   Not found"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                Verification Complete                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if pkg-config --exists hailo-tappas-core 2>/dev/null; then
    echo "✅ TAPPAS is properly installed"
    echo ""
    echo "Next step: Build rpicam-apps with Hailo support"
    echo "  ./configs/rpicam/install.sh"
else
    echo "❌ TAPPAS installation incomplete"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check TAPPAS install log: $TAPPAS_DIR/install.log"
    echo "  2. Try manual rebuild: cd $TAPPAS_DIR && ./install.sh --target-platform rpi5 --skip-hailort --core-only"
    echo "  3. Check for Python/uv issues"
fi
