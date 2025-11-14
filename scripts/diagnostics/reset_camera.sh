#!/bin/bash
# Reset camera subsystem when it's locked

echo "🔄 Resetting camera subsystem..."

# Stop any camera processes
sudo pkill -f rpicam 2>/dev/null
sudo pkill -f libcamera 2>/dev/null
sudo pkill -f picamera 2>/dev/null

# Stop Docker containers that might use camera
docker stop frigate mediamtx 2>/dev/null

# Wait a moment
sleep 2

# Check if camera module is loaded
if lsmod | grep -q ov5647; then
    echo "Camera module detected: OV5647"
fi

# Test camera
echo ""
echo "Testing camera..."
v4l2-ctl --list-devices 2>/dev/null | head -10

echo ""
echo "✅ Camera reset complete"
echo ""
echo "Now try:"
echo "  ~/local/bin/rpicam-hello -t 5000"
