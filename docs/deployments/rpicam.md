# rpicam-apps Deployment Guide

**Recommended deployment for Raspberry Pi 5 + Hailo-8**

## Overview

rpicam-apps with Hailo integration provides the easiest and most reliable way to use Hailo-8 for AI object detection on Raspberry Pi.

### Why Choose This?

✅ **Works with any HEF models** - Automatically handles page size issues  
✅ **Official Raspberry Pi integration** - Native camera support  
✅ **Low latency** - Direct hardware pipeline  
✅ **Built-in overlays** - Detection boxes drawn automatically  
✅ **Simple to use** - One command to start  

### When NOT to Use This

- Need custom Python preprocessing
- Building a web API
- Want full programmatic control

→ See [python-direct.md](python-direct.md) instead

## Installation

```bash
./setup.sh
# Choose option 5: rpicam-apps

# Or directly:
./configs/rpicam/install.sh
```

## Configuration

The inference configuration is installed to:
```
/usr/share/pi-camera-assets/hailo_yolov8_inference.json
```

Source: `configs/rpicam/hailo_yolov8_inference.json`

### Adjust Detection Settings

Edit the JSON file to change:
- Model file path
- Detection threshold (0.3-0.7)
- Maximum detections per frame
- Temporal filtering settings

See: `../../configs/rpicam/README.md` for details

## Usage

### Live Preview

```bash
rpicam-hello --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json
```

### Record Video

```bash
rpicam-vid -t 30000 \
  --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json \
  -o detection.h264
```

### Take Photo

```bash
rpicam-still \
  --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json \
  -o detection.jpg
```

## Examples

See `configs/rpicam/examples/`:
- `preview_with_overlay.sh` - Live preview
- `record_with_detection.sh` - Recording script

## Performance

Expected FPS with YOLOv8s on Pi 5:
- 1080p: 15-20 FPS
- 720p: 25-30 FPS
- 480p: 30+ FPS

## Troubleshooting

See [../operations/troubleshooting.md](../operations/troubleshooting.md) for common issues.

## More Information

- Full config guide: `../../configs/rpicam/README.md`
- Model compatibility: [../getting-started/models.md](../getting-started/models.md)
- Hardware requirements: [../getting-started/hardware.md](../getting-started/hardware.md)

