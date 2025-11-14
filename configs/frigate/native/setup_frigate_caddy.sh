#!/bin/bash
# Setup Caddy for Frigate instead of Nginx

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Setting up Caddy for Frigate (Better than Nginx!)      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Step 1: Installing Caddy (if needed)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! command -v caddy &> /dev/null; then
    echo "Installing Caddy..."
    sudo apt update
    sudo apt install -y caddy
else
    echo "✅ Caddy already installed"
fi

echo ""
echo "Step 2: Disabling Nginx (if running)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo systemctl stop nginx 2>/dev/null || true
sudo systemctl disable nginx 2>/dev/null || true
echo "✅ Nginx disabled"

echo ""
echo "Step 3: Creating Caddyfile for Frigate..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create Caddyfile for Frigate
sudo tee /etc/caddy/Caddyfile.d/frigate.conf > /dev/null << 'EOF'
# Frigate NVR reverse proxy
:5000 {
    # Main reverse proxy to Frigate
    reverse_proxy localhost:5001 {
        # WebSocket support
        header_up Upgrade {http.request.header.Upgrade}
        header_up Connection {http.request.header.Connection}
        
        # Timeouts for streaming
        transport http {
            read_timeout 60s
            write_timeout 60s
            dial_timeout 10s
        }
    }
    
    # API endpoints
    handle /api/* {
        reverse_proxy localhost:5001
    }
    
    # Live stream
    handle /live/* {
        reverse_proxy localhost:5001 {
            flush_interval -1
        }
    }
    
    # Video feed
    handle /video_feed {
        reverse_proxy localhost:5001 {
            flush_interval -1
            buffer_responses off
        }
    }
    
    # Enable compression
    encode gzip
    
    # Security headers
    header {
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
    }
    
    # Logging
    log {
        output file /var/log/caddy/frigate.log
        level INFO
    }
}

# Optional: HTTPS with automatic certificate (if you have a domain)
# frigate.yourdomain.com {
#     reverse_proxy localhost:5001
#     tls your-email@example.com
# }
EOF

# Create directory for additional configs if not exists
sudo mkdir -p /etc/caddy/Caddyfile.d/

# Update main Caddyfile to include our config
if ! grep -q "import /etc/caddy/Caddyfile.d/\*" /etc/caddy/Caddyfile 2>/dev/null; then
    echo "" | sudo tee -a /etc/caddy/Caddyfile > /dev/null
    echo "import /etc/caddy/Caddyfile.d/*" | sudo tee -a /etc/caddy/Caddyfile > /dev/null
fi

echo "✅ Caddyfile configured"

echo ""
echo "Step 4: Reloading Caddy..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test config
sudo caddy validate --config /etc/caddy/Caddyfile 2>/dev/null && echo "✅ Config valid" || {
    echo "⚠️  Config validation failed, using simplified config..."
    # Simplified config
    sudo tee /etc/caddy/Caddyfile > /dev/null << 'EOF'
:5000 {
    reverse_proxy localhost:5001
}
EOF
}

# Restart Caddy
sudo systemctl enable caddy
sudo systemctl restart caddy

sleep 2

if sudo systemctl is-active --quiet caddy; then
    echo "✅ Caddy is running!"
else
    echo "⚠️  Caddy failed to start, checking status..."
    sudo systemctl status caddy --no-pager | head -20
fi

echo ""
echo "Step 5: Starting Frigate service..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Make sure Frigate service is running
sudo systemctl restart frigate

sleep 5

if sudo systemctl is-active --quiet frigate; then
    echo "✅ Frigate is running!"
else
    echo "⚠️  Frigate not running, starting it manually..."
    # Try to start manually
    sudo -u frigate /opt/frigate/venv/bin/python /opt/frigate/run_frigate.py > /var/log/frigate.log 2>&1 &
    sleep 3
    if pgrep -f "run_frigate.py" > /dev/null; then
        echo "✅ Frigate started manually"
    else
        echo "❌ Failed to start Frigate"
    fi
fi

echo ""
echo "Step 6: Testing the setup..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test if Frigate API is accessible
if curl -s http://localhost:5001/api/config > /dev/null 2>&1; then
    echo "✅ Frigate API responding on port 5001"
else
    echo "⚠️  Frigate API not responding"
fi

# Test if Caddy proxy is working
if curl -s http://localhost:5000 > /dev/null 2>&1; then
    echo "✅ Caddy proxy working on port 5000"
else
    echo "⚠️  Caddy proxy not working"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║            Caddy + Frigate Setup Complete!                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📺 Access Frigate at: http://$(hostname -I | cut -d' ' -f1):5000"
echo ""
echo "🔧 Caddy advantages over Nginx:"
echo "   • Simpler configuration"
echo "   • Automatic HTTPS (if you add a domain)"
echo "   • Better WebSocket handling"
echo "   • Built-in compression"
echo ""
echo "📊 Check logs:"
echo "   • Frigate: sudo journalctl -u frigate -f"
echo "   • Caddy: sudo journalctl -u caddy -f"
echo ""
echo "🔄 Restart services:"
echo "   • sudo systemctl restart frigate"
echo "   • sudo systemctl restart caddy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
