#!/bin/bash
# Quick OpenCV installation test

echo "═══════════════════════════════════════════════════════════"
echo "     OpenCV Python Installation Test"
echo "═══════════════════════════════════════════════════════════"
echo

# Test import
echo "Testing Python OpenCV import..."
python3 -c "import cv2; print(f'✓ OpenCV {cv2.__version__} is installed!')" 2>/dev/null

if [ $? -eq 0 ]; then
    echo
    echo "✅ OpenCV Python bindings are working!"
    echo
    echo "You can now run the full preview with overlays:"
    echo "  python3 scripts/preview/simple_camera_test.py"
    echo "  python3 scripts/preview/hailo_live_preview.py"
else
    echo
    echo "❌ OpenCV Python bindings not found."
    echo
    echo "To install, run in a regular terminal:"
    echo "  sudo apt install python3-opencv"
    echo
    echo "Alternative (if you have pip access):"
    echo "  pip3 install opencv-python --break-system-packages"
fi

echo
echo "═══════════════════════════════════════════════════════════"
