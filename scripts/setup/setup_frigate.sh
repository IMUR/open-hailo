#!/bin/bash
# Frigate NVR Setup Script for Raspberry Pi 5 with Hailo-8

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Frigate NVR Setup for Hailo-8 + Raspberry Pi 5        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first:"
    echo "   curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "   sudo sh get-docker.sh"
    exit 1
fi

# Create Frigate directory structure
FRIGATE_DIR="$HOME/frigate"
echo "Creating Frigate directory at $FRIGATE_DIR..."
mkdir -p "$FRIGATE_DIR"/{storage,config,media}
cd "$FRIGATE_DIR"

# Create Frigate configuration for Hailo
cat > "$FRIGATE_DIR/config/config.yml" << 'EOF'
# Frigate Configuration for Raspberry Pi 5 + Hailo-8

# MQTT Configuration (optional, for Home Assistant)
mqtt:
  enabled: false  # Set to true if using Home Assistant
  host: 192.168.1.100  # Your MQTT broker IP
  user: mqtt_user
  password: mqtt_password

# Hailo-8 Detector Configuration
detectors:
  hailo:
    type: hailo
    device: PCIe  # Hailo-8 on M.2 HAT
    model:
      path: /models/yolov8s_hailo.hef  # Will download models

# Camera Configuration
cameras:
  rpi_camera:
    enabled: true
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/stream  # We'll set up RTSP stream
          roles:
            - detect
            - record
    
    # Detection settings
    detect:
      enabled: true
      width: 640
      height: 640
      fps: 10
    
    # Recording settings  
    record:
      enabled: true
      retain:
        days: 7
        mode: motion
      events:
        retain:
          default: 14
          mode: active_objects
    
    # Motion detection
    motion:
      mask:
        - 0,0,0,0  # Adjust based on your camera view
    
    # Object tracking
    objects:
      track:
        - person
        - car
        - cat
        - dog
      filters:
        person:
          min_score: 0.5
          threshold: 0.7

# Optional: Birdseye view (multi-camera overview)
birdseye:
  enabled: true
  width: 1280
  height: 720
  quality: 8
  mode: continuous

# Web UI settings
ui:
  live_mode: mse  # or webrtc for lower latency
  timezone: America/New_York  # Set your timezone

# Performance settings for RPi 5
ffmpeg:
  hwaccel_args: preset-rpi-64-h264  # Hardware acceleration for Pi
  input_args: preset-rtsp-generic
  output_args:
    record: preset-record-generic-audio-copy
EOF

# Create docker-compose.yml
cat > "$FRIGATE_DIR/docker-compose.yml" << 'EOF'
version: "3.9"

services:
  frigate:
    container_name: frigate
    image: ghcr.io/blakeblackshear/frigate:stable-hailo
    restart: unless-stopped
    privileged: true
    shm_size: "256mb"
    devices:
      - /dev/hailo0:/dev/hailo0  # Hailo-8 device
      - /dev/video0:/dev/video0  # Camera device (adjust if needed)
      - /dev/dri:/dev/dri  # For hardware acceleration
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./config:/config
      - ./storage:/media/frigate
      - type: tmpfs
        target: /tmp/cache
        tmpfs:
          size: 1000000000
    environment:
      - FRIGATE_RTSP_PASSWORD=password
    ports:
      - "5000:5000"  # Web UI
      - "8554:8554"  # RTSP restream
      - "8555:8555/tcp"  # WebRTC
      - "8555:8555/udp"  # WebRTC
    
  # Optional: RTSP server for Pi Camera
  mediamtx:
    container_name: mediamtx
    image: bluenviron/mediamtx:latest
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./mediamtx.yml:/mediamtx.yml
    devices:
      - /dev/video0:/dev/video0
EOF

# Create MediaMTX config for camera streaming
cat > "$FRIGATE_DIR/mediamtx.yml" << 'EOF'
paths:
  stream:
    source: rpiCamera
    rpiCameraWidth: 1920
    rpiCameraHeight: 1080
    rpiCameraFPS: 30
EOF

# Create start script
cat > "$FRIGATE_DIR/start_frigate.sh" << 'EOF'
#!/bin/bash
echo "Starting Frigate NVR with Hailo-8..."

# Check Hailo device
if [ ! -e /dev/hailo0 ]; then
    echo "❌ Hailo device not found at /dev/hailo0"
    exit 1
fi

# Start services
docker compose up -d

echo "✅ Frigate started!"
echo "   Web UI: http://$(hostname -I | cut -d' ' -f1):5000"
echo "   RTSP Stream: rtsp://$(hostname -I | cut -d' ' -f1):8554/stream"
EOF

chmod +x "$FRIGATE_DIR/start_frigate.sh"

echo
echo "═══════════════════════════════════════════════════════════"
echo "✅ Frigate setup complete!"
echo
echo "📁 Configuration created at: $FRIGATE_DIR"
echo
echo "🚀 To start Frigate:"
echo "   cd $FRIGATE_DIR"
echo "   ./start_frigate.sh"
echo
echo "📺 Then access the Web UI at:"
echo "   http://$(hostname -I | cut -d' ' -f1):5000"
echo
echo "⚙️  Edit config at: $FRIGATE_DIR/config/config.yml"
echo
echo "📚 Documentation: https://docs.frigate.video"
echo "═══════════════════════════════════════════════════════════"
