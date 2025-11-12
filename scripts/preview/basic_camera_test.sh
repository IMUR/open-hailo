#!/bin/bash
# Basic Camera Test using rpicam-hello

echo "═══════════════════════════════════════════════════════════"
echo "     Basic Camera Test (using rpicam-hello)"
echo "═══════════════════════════════════════════════════════════"

# Test with our locally built rpicam-hello
RPICAM_HELLO="$HOME/local/bin/rpicam-hello"

if [ ! -f "$RPICAM_HELLO" ]; then
    echo "Error: rpicam-hello not found at $RPICAM_HELLO"
    echo "Trying system rpicam-hello..."
    RPICAM_HELLO="rpicam-hello"
fi

echo ""
echo "Testing camera for 5 seconds..."
echo "If you see a preview window, the camera is working!"
echo ""

# Run camera preview for 5 seconds
$RPICAM_HELLO -t 5000

echo ""
echo "Camera test complete!"
echo ""
echo "Now capturing a test image..."
$HOME/local/bin/rpicam-still -o test_image.jpg --width 1920 --height 1080 -t 100

if [ -f test_image.jpg ]; then
    echo "✓ Image captured successfully: test_image.jpg"
    ls -lh test_image.jpg
else
    echo "✗ Image capture failed"
fi
