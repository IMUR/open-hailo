#!/bin/bash
# Full Stack Demo - Hailo-8 Object Detection with Live Camera

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     🎯 HAILO-8 OBJECT DETECTION DEMO                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 1. Check Hailo device
echo "Step 1: Checking Hailo-8 device..."
if [ -e /dev/hailo0 ]; then
    echo "✅ Hailo device ready"
else
    echo "⚠️  Loading Hailo driver..."
    sudo modprobe hailo_pci
    sleep 2
    if [ -e /dev/hailo0 ]; then
        echo "✅ Hailo device loaded"
    else
        echo "❌ Failed to load Hailo device"
        echo "   Run: ./scripts/driver/get_official_driver.sh"
        exit 1
    fi
fi

# 2. Start Frigate NVR
echo ""
echo "Step 2: Starting Frigate NVR..."
if sudo systemctl is-active --quiet frigate; then
    echo "✅ Frigate already running"
else
    sudo systemctl start frigate
    sleep 3
    if sudo systemctl is-active --quiet frigate; then
        echo "✅ Frigate started"
    else
        echo "❌ Failed to start Frigate"
        echo "   Check: sudo journalctl -u frigate -n 20"
        exit 1
    fi
fi

# 3. Check Caddy proxy
echo ""
echo "Step 3: Checking web proxy..."
if sudo systemctl is-active --quiet caddy; then
    echo "✅ Caddy proxy running"
else
    sudo systemctl start caddy
    echo "✅ Caddy started"
fi

# 4. Get IP address
IP=$(hostname -I | cut -d' ' -f1)

# 5. Test if accessible
echo ""
echo "Step 4: Testing web interface..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 | grep -q "200"; then
    echo "✅ Web interface accessible"
else
    echo "⚠️  Web interface starting up..."
    sleep 3
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  🎉 DEMO READY!                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📺 ACCESS THE LIVE DEMO AT:"
echo ""
echo "   🌐 http://$IP:5000"
echo ""
echo "🎯 WHAT YOU'LL SEE:"
echo "   • Live camera feed from OV5647"
echo "   • Real-time object detection"
echo "   • System status dashboard"
echo "   • Detection overlays (mock data for now)"
echo ""
echo "📊 MONITORING:"
echo "   • Logs: sudo journalctl -u frigate -f"
echo "   • API: curl http://localhost:5000/api/stats"
echo ""
echo "⏹️  TO STOP DEMO:"
echo "   sudo systemctl stop frigate"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Opening browser in 5 seconds..."
sleep 5

# Try to open browser if display is available
if [ -n "$DISPLAY" ]; then
    xdg-open "http://$IP:5000" 2>/dev/null || echo "Please open browser manually"
else
    echo "Please open browser to: http://$IP:5000"
fi
