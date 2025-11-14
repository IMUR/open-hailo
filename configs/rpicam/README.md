# rpicam-apps Configuration

**Recommended deployment method for Raspberry Pi 5 + Hailo-8**

## Why Choose rpicam-apps?

rpicam-apps is the **easiest and most reliable** way to use Hailo-8 on Raspberry Pi because:

✅ **Works with any HEF models** - Automatically handles page size issues  
✅ **Official Raspberry Pi integration** - Native camera support  
✅ **Low latency** - Direct hardware pipeline  
✅ **Built-in overlays** - Detection boxes drawn automatically  
✅ **Simple to use** - One command to start detection  

## Prerequisites

- Raspberry Pi 5
- Hailo-8 PCIe module installed
- Pi Camera (OV5647, IMX219, IMX477, etc.)
- HailoRT 4.23.0 installed (driver + library)

## Installation

```bash
cd open-hailo
./configs/rpicam/install.sh
```

This script will:
1. Verify HailoRT is installed
2. Build rpicam-apps with Hailo support
3. Install inference configuration
4. Verify camera is detected

## Quick Start

### Live Preview with Detection

```bash
rpicam-hello --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json
```

Press `Ctrl+C` to stop.

### Record Video with Detection

```bash
rpicam-vid -t 30000 \
  --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json \
  -o detection_output.h264
```

Records 30 seconds with detection overlays burned into the video.

### Take Photo with Detection

```bash
rpicam-still \
  --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json \
  -o detection.jpg
```

## Configuration

The inference configuration is in `hailo_yolov8_inference.json` and gets installed to:
```
/usr/share/pi-camera-assets/hailo_yolov8_inference.json
```

### Change Detection Model

Edit the config to use different YOLOv8 models:

```json
{
  "hailo_yolo_inference": {
    "hef_file": "../../models/x86-models/yolov8s.hef",
    "max_detections": 20,
    "threshold": 0.5
  }
}
```

Available models:
- `yolov8n.hef` - Fastest (8MB)
- `yolov8s.hef` - Balanced (19MB) - Default
- `yolov8m.hef` - Most accurate (30MB)

### Adjust Detection Sensitivity

Lower threshold = more detections (but more false positives):
```json
"threshold": 0.3
```

Higher threshold = fewer detections (more confident):
```json
"threshold": 0.7
```

### Temporal Filtering

Smooth out detections over time:
```json
"temporal_filter": {
  "tolerance": 0.1,
  "factor": 0.75,
  "visible_frames": 6,
  "hidden_frames": 3
}
```

## Examples

See `examples/` directory for:
- `preview_with_overlay.sh` - Live preview script
- `record_with_detection.sh` - Recording script with options

## Troubleshooting

### Camera Not Detected

```bash
rpicam-hello --list-cameras
```

If no cameras:
```bash
../../scripts/diagnostics/reset_camera.sh
```

### HailoRT Not Installed

```bash
../../scripts/setup/verify_hailo_installation.sh
```

If driver/library missing:
```bash
cd open-hailo
./setup.sh
```

### rpicam-apps Not Built with Hailo

Rebuild from source:
```bash
../../scripts/build/build_hailo_preview_local.sh
```

### Poor Detection Performance

1. **Try different models**:
   - YOLOv8n: Fast but less accurate
   - YOLOv8s: Balanced (recommended)
   - YOLOv8m: Slower but more accurate

2. **Adjust lighting**: Better lighting = better detection

3. **Lower threshold**: See more detections (may include false positives)

## Advanced Usage

### Custom Resolution

```bash
rpicam-hello \
  --width 1920 --height 1080 \
  --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json
```

### Disable Preview (Headless)

```bash
rpicam-hello -n \
  --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json
```

### Network Streaming

```bash
rpicam-vid -t 0 --inline \
  --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json \
  -o - | cvlc stream:///dev/stdin --sout '#rtp{sdp=rtsp://:8554/stream}' :demux=h264
```

## Performance

Expected FPS with YOLOv8s on Pi 5:
- 1080p: 15-20 FPS
- 720p: 25-30 FPS
- 480p: 30+ FPS

## More Information

- Official rpicam docs: https://www.raspberrypi.com/documentation/computers/camera_software.html
- Hailo integration: https://github.com/hailo-ai/hailo-rpi5-examples
- Troubleshooting: `../../docs/TROUBLESHOOTING.md`

