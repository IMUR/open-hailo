#!/bin/bash
# Native Frigate installation for Raspberry Pi 5 with Hailo-8

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Native Frigate Installation for Pi 5 + Hailo-8         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Stop Docker version if running
echo "Step 1: Stopping Docker Frigate (if running)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd ~/frigate 2>/dev/null && docker compose down 2>/dev/null || true
echo "✅ Docker Frigate stopped"

echo ""
echo "Step 2: Installing system dependencies..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo apt update
sudo apt install -y \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-opencv \
    python3-numpy \
    python3-picamera2 \
    ffmpeg \
    nginx \
    redis-server \
    mosquitto \
    mosquitto-clients \
    libcamera-dev \
    libcamera-apps \
    v4l-utils \
    git \
    build-essential \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libjpeg-dev

echo "✅ Dependencies installed"

echo ""
echo "Step 3: Creating Frigate directory and user..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
FRIGATE_DIR="/opt/frigate"
sudo mkdir -p $FRIGATE_DIR/{config,storage,recordings,clips,models}

# Create frigate user if not exists
if ! id -u frigate &>/dev/null; then
    sudo useradd -r -s /bin/false frigate
    sudo usermod -aG video frigate  # For camera access
    echo "✅ Frigate user created"
else
    echo "✅ Frigate user exists"
fi

# Set permissions
sudo chown -R frigate:frigate $FRIGATE_DIR
echo "✅ Directory structure created"

echo ""
echo "Step 4: Creating Python virtual environment..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd $FRIGATE_DIR
sudo -u frigate python3 -m venv venv
echo "✅ Virtual environment created"

echo ""
echo "Step 5: Installing Frigate from source..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Clone Frigate repository
if [ ! -d "$FRIGATE_DIR/frigate-source" ]; then
    sudo -u frigate git clone https://github.com/blakeblackshear/frigate.git frigate-source
    cd frigate-source
    sudo -u frigate git checkout stable  # Use stable branch
else
    cd frigate-source
    sudo -u frigate git pull
fi

# Install Python dependencies
sudo -u frigate $FRIGATE_DIR/venv/bin/pip install --upgrade pip wheel setuptools
sudo -u frigate $FRIGATE_DIR/venv/bin/pip install \
    flask \
    flask-cors \
    peewee \
    peewee-migrate \
    paho-mqtt \
    pyyaml \
    numpy \
    opencv-python-headless \
    tensorflow-lite \
    picamera2 \
    ws4py \
    requests \
    psutil \
    imutils

echo "✅ Frigate core installed"

echo ""
echo "Step 6: Creating configuration for OV5647 camera..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > $FRIGATE_DIR/config/config.yml << 'EOF'
# Native Frigate Configuration for Raspberry Pi 5 + Hailo-8

# MQTT Configuration
mqtt:
  enabled: true
  host: 127.0.0.1
  port: 1883
  topic_prefix: frigate
  client_id: frigate
  stats_interval: 60

# Detector Configuration
detectors:
  cpu1:
    type: cpu
    num_threads: 4
# Note: Add Hailo detector when available
#  hailo:
#    type: hailo
#    device: /dev/hailo0

# Camera Configuration for OV5647
cameras:
  rpi_camera:
    enabled: true
    ffmpeg:
      inputs:
        # Use libcamera-vid for OV5647 camera
        - path: "exec:/usr/bin/libcamera-vid --inline --nopreview --codec mjpeg --width 1280 --height 720 --framerate 15 --timeout 0 --output -"
          input_args: -f mjpeg
          roles:
            - detect
            - record
    
    # Detection settings
    detect:
      enabled: true
      width: 640
      height: 480
      fps: 10
      stationary:
        interval: 50
        threshold: 50
    
    # Recording settings
    record:
      enabled: true
      retain:
        days: 3
        mode: motion
      events:
        retain:
          default: 10
          mode: active_objects
    
    # Snapshots with overlays
    snapshots:
      enabled: true
      bounding_box: true
      retain:
        default: 10
    
    # Motion detection
    motion:
      mask:
        - 0,0,0,0
      threshold: 30
      contour_area: 100
    
    # Objects to detect
    objects:
      track:
        - person
        - car
        - bicycle
        - cat
        - dog
      filters:
        person:
          min_score: 0.5
          threshold: 0.6

# Recordings directory
record:
  enabled: true
  retain:
    days: 3
    mode: all
  events:
    retain:
      default: 10
      mode: motion

# Snapshots directory  
snapshots:
  enabled: true
  bounding_box: true
  retain:
    default: 10
    clean_copy: true

# Birdseye view
birdseye:
  enabled: true
  width: 1280
  height: 720
  quality: 8
  mode: continuous

# Web UI
ui:
  live_mode: mse
  timezone: America/Los_Angeles
  use_experimental: false
  time_format: 24hour
  date_style: short
  time_style: medium
  strftime_fmt: "%m/%d %H:%M"

# Logging
logger:
  default: info
  logs:
    frigate.detectors.hailo: debug
    frigate.capture: debug

# Performance optimization for Pi 5
ffmpeg:
  hwaccel_args: []
  input_args: preset-rtsp-generic
  output_args:
    record: preset-record-generic-audio-copy

# Database
database:
  path: /opt/frigate/storage/frigate.db

# Temporary files
tmp_dir: /tmp/cache
EOF

echo "✅ Configuration created"

echo ""
echo "Step 7: Creating systemd service..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sudo tee /etc/systemd/system/frigate.service > /dev/null << 'EOF'
[Unit]
Description=Frigate NVR
After=network.target redis.service mosquitto.service
Wants=redis.service mosquitto.service

[Service]
Type=simple
User=frigate
Group=frigate
Environment="PATH=/opt/frigate/venv/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONPATH=/opt/frigate/frigate-source"
WorkingDirectory=/opt/frigate
ExecStart=/opt/frigate/venv/bin/python /opt/frigate/frigate-source/frigate/__main__.py
Restart=on-failure
RestartSec=5

# Device access
DeviceAllow=/dev/hailo0 rwm
DeviceAllow=/dev/video0 rwm
DeviceAllow=/dev/dri rwm
SupplementaryGroups=video

# Security
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/frigate

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Systemd service created"

echo ""
echo "Step 8: Setting up Nginx reverse proxy..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sudo tee /etc/nginx/sites-available/frigate > /dev/null << 'EOF'
server {
    listen 5000;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # API endpoints
    location /api {
        proxy_pass http://127.0.0.1:5001/api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # Live stream
    location /live {
        proxy_pass http://127.0.0.1:5001/live;
        proxy_buffering off;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/frigate /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
echo "✅ Nginx configured"

echo ""
echo "Step 9: Starting services..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Start Redis and Mosquitto
sudo systemctl enable --now redis-server
sudo systemctl enable --now mosquitto

# Reload systemd and start Frigate
sudo systemctl daemon-reload
sudo systemctl enable frigate
sudo systemctl start frigate

echo "✅ Services started"

echo ""
echo "Step 10: Checking status..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sleep 5
if sudo systemctl is-active --quiet frigate; then
    echo "✅ Frigate is running!"
else
    echo "⚠️  Frigate failed to start. Check logs:"
    echo "   sudo journalctl -u frigate -n 50"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║            Native Frigate Installation Complete!           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📺 Access Frigate at: http://$(hostname -I | cut -d' ' -f1):5000"
echo ""
echo "📁 Configuration: /opt/frigate/config/config.yml"
echo "📊 Logs: sudo journalctl -u frigate -f"
echo "🔄 Restart: sudo systemctl restart frigate"
echo "⏹️  Stop: sudo systemctl stop frigate"
echo ""
echo "📝 Note: The Hailo-8 detector will be available once"
echo "   the Python bindings are properly configured."
echo ""
echo "🎯 Your OV5647 camera should work natively now!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
