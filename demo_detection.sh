#!/bin/bash
# Demo with real Hailo detection (accepting version warnings)

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     🎯 REAL HAILO DETECTION DEMO                           ║"
echo "║     Raspberry Pi OS Trixie (Debian 13)                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Stop Frigate to free camera
sudo systemctl stop frigate 2>/dev/null

echo "Testing Hailo device..."
if [ -e /dev/hailo0 ]; then
    echo "✅ Hailo device present"
else
    echo "⚠️  Loading driver..."
    sudo modprobe hailo_pci
fi

echo ""
echo "⚠️  IMPORTANT: Version mismatch warnings are expected!"
echo "    Detection may not work until driver/library versions match."
echo ""
echo "To fix permanently, run:"
echo "  ./scripts/diagnostics/check_version_compatibility.sh"
echo "  ./scripts/setup/fix_version_mismatch.sh"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Choose detection method:"
echo ""
echo "1. Python with OpenCV overlays (requires hailo_platform)"
echo "2. Python without OpenCV - PIL only (simulator mode)"
echo "3. Rebuild rpicam-apps with Hailo (45 min build)"
echo "4. Use Frigate web interface"
echo ""
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo "Checking dependencies..."
        
        # Check if venv exists
        if [ ! -d ".venv" ]; then
            echo "Creating virtual environment..."
            python3 -m venv .venv
        fi
        
        echo "Activating virtual environment..."
        source .venv/bin/activate
        
        # Install system dependencies
        echo "Installing system dependencies..."
        sudo apt install -y python3-picamera2 python3-numpy python3-opencv
        
        # Check for hailo_platform
        if ! python3 -c "import hailo_platform" 2>/dev/null; then
            echo ""
            echo "❌ ERROR: hailo_platform module not found!"
            echo ""
            echo "This requires HailoRT Python bindings to be installed."
            echo "Please ensure HailoRT is properly installed with Python support."
            echo ""
            echo "For now, try option 2 (simulator mode) instead."
            exit 1
        fi
        
        echo "Starting detection with overlays..."
        export HAILO_IGNORE_VERSION_MISMATCH=1
        python3 scripts/preview/hailo_live_overlay.py 2>&1 | grep -v "HAILO_DRIVER_INVALID_IOCTL"
        ;;
    2)
        echo "Installing dependencies..."
        sudo apt install -y python3-pil
        
        # Install picamera2 system-wide (has libcamera bindings)
        sudo apt install -y python3-picamera2 python3-numpy
        
        echo ""
        echo "⚠️  NOTE: This runs in SIMULATOR MODE"
        echo "    No actual Hailo inference - camera preview only"
        echo ""
        echo "Starting camera preview (saving snapshots)..."
        python3 scripts/preview/hailo_preview_no_cv.py 2>&1
        ;;
    3)
        echo "This will take 30-45 minutes..."
        read -p "Continue? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            ./scripts/build/build_hailo_preview_local.sh
        fi
        ;;
    4)
        sudo systemctl start frigate 2>/dev/null || echo "Frigate service not installed"
        echo "Frigate starting..."
        echo "Access at: http://$(hostname -I | cut -d' ' -f1):5000"
        echo ""
        echo "Note: Check Frigate config for camera and detector setup"
        ;;
    *)
        echo "Invalid choice"
        ;;
esac
