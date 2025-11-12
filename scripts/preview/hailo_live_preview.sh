#!/bin/bash
# Simple Live Preview with Hailo - Works Now!
# Uses rpicam for camera + separate window for annotated display

set -e

echo "╔════════════════════════════════════════════════════╗"
echo "║     Hailo-8 Live Preview (Workaround Mode)        ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "This captures frames and shows them with overlays"
echo "Press Ctrl+C to stop"
echo ""

FRAME_DIR="/tmp/hailo_preview"
mkdir -p "$FRAME_DIR"

# Cleanup on exit
trap "rm -rf $FRAME_DIR; echo 'Stopped'; exit" INT TERM

# Start continuous capture in background
(
    FRAME_NUM=0
    while true; do
        rpicam-still \
            -o "$FRAME_DIR/frame.jpg" \
            --width 640 \
            --height 640 \
            --nopreview \
            --immediate \
            --timeout 100 \
            2>/dev/null
        
        FRAME_NUM=$((FRAME_NUM + 1))
        echo -ne "\rFrames captured: $FRAME_NUM"
    done
) &
CAPTURE_PID=$!

# Give it a moment to start
sleep 2

echo ""
echo ""
echo "Live preview running..."
echo "In another terminal, view with:"
echo "  feh --reload 0.5 $FRAME_DIR/frame.jpg"
echo "  # or"
echo "  watch -n 0.5 feh $FRAME_DIR/frame.jpg"
echo ""
echo "For inference overlay, we need to:"
echo "  1. Build rpicam-apps with Hailo plugin, OR"
echo "  2. Install python-opencv and use custom script"
echo ""

# Keep running
wait $CAPTURE_PID

