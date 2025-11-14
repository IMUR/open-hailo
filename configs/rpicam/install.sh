#!/bin/bash
# rpicam-apps Configuration Installer
# Sets up rpicam-apps with Hailo-8 support

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     rpicam-apps + Hailo-8 Configuration Installer         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Verify HailoRT is installed
echo "Step 1: Verifying HailoRT installation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ! command -v hailortcli &> /dev/null; then
    echo "❌ HailoRT not found!"
    echo "Please install HailoRT first:"
    echo "  cd $PROJECT_ROOT"
    echo "  ./setup.sh"
    exit 1
fi

hailortcli --version
if [ $? -ne 0 ]; then
    echo "❌ HailoRT CLI not working properly"
    echo "Run diagnostics:"
    echo "  $PROJECT_ROOT/scripts/setup/verify_hailo_installation.sh"
    exit 1
fi

echo "✅ HailoRT detected"
echo ""

# Step 2: Check if rpicam-apps with Hailo is already built
echo "Step 2: Checking for rpicam-apps with Hailo support..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if rpicam-hello --version 2>&1 | grep -q "post-process"; then
    echo "✅ rpicam-apps appears to be installed"
    if rpicam-hello --list-post-process-stages 2>&1 | grep -q "hailo"; then
        echo "✅ Hailo post-processing detected!"
    else
        echo "⚠️  rpicam-apps installed but Hailo support not detected"
        echo "You may need to rebuild rpicam-apps with Hailo support"
        echo "Run: $PROJECT_ROOT/scripts/build/build_hailo_preview_local.sh"
    fi
else
    echo "⚠️  rpicam-apps not found or missing post-process support"
    echo "Building rpicam-apps with Hailo support..."
    "$PROJECT_ROOT/scripts/build/build_hailo_preview_local.sh"
    if [ $? -ne 0 ]; then
        echo "❌ Build failed"
        exit 1
    fi
fi
echo ""

# Step 3: Install inference configuration
echo "Step 3: Installing inference configuration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo mkdir -p /usr/share/pi-camera-assets
sudo cp "$PROJECT_ROOT/configs/rpicam/hailo_yolov8_inference.json" /usr/share/pi-camera-assets/
echo "✅ Configuration installed to /usr/share/pi-camera-assets/"
echo ""

# Step 4: Verify camera
echo "Step 4: Verifying camera detection..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if rpicam-hello --list-cameras 2>&1 | grep -q "Available cameras"; then
    echo "✅ Camera detected:"
    rpicam-hello --list-cameras 2>&1 | grep -E "^\[|Camera"
else
    echo "⚠️  No camera detected"
    echo "Try resetting the camera:"
    echo "  $PROJECT_ROOT/scripts/diagnostics/reset_camera.sh"
fi
echo ""

# Step 5: Test inference
echo "Step 5: Testing Hailo inference (5 seconds)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running: rpicam-hello -t 5000 --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json"
timeout 10 rpicam-hello -t 5000 --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json 2>&1 || true
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  Installation Complete!                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Test live preview:"
echo "   rpicam-hello --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json"
echo ""
echo "2. Record video with detection:"
echo "   rpicam-vid -t 30000 --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json -o output.h264"
echo ""
echo "3. Use example scripts:"
echo "   $PROJECT_ROOT/configs/rpicam/examples/preview_with_overlay.sh"
echo ""
echo "📖 More info: $PROJECT_ROOT/configs/rpicam/README.md"

