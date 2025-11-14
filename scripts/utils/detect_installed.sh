#!/bin/bash
# Detect what's actually installed on the system and update state

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/state_manager.sh"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Detecting Installed Components                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Initialize state
init_state
update_system_info

# Detect HailoRT
echo "Checking HailoRT..."
if command -v hailortcli &> /dev/null; then
    HAILORT_VER=$(hailortcli --version 2>&1 | grep -oP 'HailoRT-CLI version \K[0-9.]+' || echo "unknown")
    HAILORT_LOC=$(which hailortcli)
    mark_installed "hailort" "$HAILORT_VER" "$HAILORT_LOC"

    # Check driver
    if lsmod | grep -q hailo_pci; then
        set_component "hailo_driver" "installed" "true"
        set_component "hailo_driver" "loaded" "true"
        set_component "hailo_driver" "version" "$HAILORT_VER"
    fi
else
    echo "  ❌ HailoRT not found"
fi

# Detect TAPPAS
echo "Checking TAPPAS..."
if pkg-config --exists hailo-tappas-core 2>/dev/null; then
    TAPPAS_VER=$(pkg-config --modversion hailo-tappas-core)
    TAPPAS_LOC="$HOME/tappas"
    mark_installed "tappas" "$TAPPAS_VER" "$TAPPAS_LOC"
else
    echo "  ❌ TAPPAS not found"
fi

# Detect rpicam-apps
echo "Checking rpicam-apps..."
if command -v rpicam-hello &> /dev/null; then
    RPICAM_VER=$(rpicam-hello --version 2>&1 | grep -oP 'rpicam-apps \K[0-9.]+' || echo "unknown")
    RPICAM_LOC=$(which rpicam-hello | xargs dirname)

    # Check for Hailo support
    HAILO_SUPPORT=false
    if ls "$RPICAM_LOC"/../lib/*/rpicam-apps-postproc/hailo-postproc.so 2>/dev/null; then
        HAILO_SUPPORT=true
    fi

    mark_installed "rpicam-apps" "$RPICAM_VER" "$RPICAM_LOC"
    set_component "rpicam-apps" "hailo_support" "$HAILO_SUPPORT"
else
    echo "  ❌ rpicam-apps not found"
fi

# Detect dependencies
echo "Checking dependencies..."

# OpenCV
if pkg-config --exists opencv4 2>/dev/null; then
    OPENCV_VER=$(pkg-config --modversion opencv4)
    set_component "dependencies.opencv" "installed" "true"
    set_component "dependencies.opencv" "version" "$OPENCV_VER"
fi

# GStreamer
if pkg-config --exists gstreamer-1.0 2>/dev/null; then
    GST_VER=$(pkg-config --modversion gstreamer-1.0)
    set_component "dependencies.gstreamer" "installed" "true"
    set_component "dependencies.gstreamer" "version" "$GST_VER"
fi

# Boost
if pkg-config --exists boost 2>/dev/null; then
    BOOST_VER=$(pkg-config --modversion boost)
    set_component "dependencies.boost" "installed" "true"
    set_component "dependencies.boost" "version" "$BOOST_VER"
fi

# uv
if command -v uv &> /dev/null; then
    UV_VER=$(uv --version | awk '{print $2}')
    set_component "dependencies.uv" "installed" "true"
    set_component "dependencies.uv" "version" "$UV_VER"
fi

# Update capabilities
echo "Updating capabilities..."
update_capabilities

echo ""
echo "✅ Detection complete!"
echo ""
echo "Run './scripts/utils/state_manager.sh show' to see results"
