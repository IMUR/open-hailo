#!/bin/bash
# OpenCV Python Installation Script
# Run this in a regular terminal with: bash install_opencv_python.sh

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Installing OpenCV Python Bindings                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

# Check if running with sudo capability
if ! sudo -n true 2>/dev/null; then 
    echo "This script requires sudo access."
    echo "Please run in a regular terminal, not the AI interface."
    echo
    echo "Command to run:"
    echo "  bash $0"
    exit 1
fi

echo "📦 Installing python3-opencv..."
sudo apt update
sudo apt install -y python3-opencv

echo
echo "✅ Installation complete!"
echo

# Test the installation
echo "Testing OpenCV Python..."
python3 -c "import cv2; print(f'✓ OpenCV {cv2.__version__} installed successfully!')"

if [ $? -eq 0 ]; then
    echo
    echo "🎉 SUCCESS! You can now run:"
    echo
    echo "1. Simple camera test with overlays:"
    echo "   cd /home/crtr/Projects/open-hailo"
    echo "   python3 scripts/preview/simple_camera_test.py"
    echo
    echo "2. Full Hailo YOLOv8 preview:"
    echo "   python3 scripts/preview/hailo_live_preview.py --model models/yolov8s.hef"
    echo
else
    echo
    echo "⚠️ Installation succeeded but import test failed."
    echo "This might be a PATH issue. Try:"
    echo "  export PYTHONPATH=/usr/lib/python3/dist-packages:\$PYTHONPATH"
fi

echo "════════════════════════════════════════════════════════════"
