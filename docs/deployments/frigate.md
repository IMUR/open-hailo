# Frigate NVR Deployment Guide

Network Video Recorder with AI object detection using Hailo-8.

## Overview

Frigate is an open-source NVR designed for real-time AI object detection, perfect for home surveillance and monitoring.

## Deployment Options

### Docker (Recommended)

✅ Easier updates  
✅ Isolated environment  
✅ Official support  

```bash
cd configs/frigate/docker
docker compose up -d
```

Access: http://localhost:5000

### Native (Advanced)

✅ Better performance  
✅ Direct hardware access  

```bash
./configs/frigate/native/install_frigate_native.sh
```

## Configuration

Edit `configs/frigate/docker/config.yml` or `configs/frigate/native/config.yml`:

```yaml
detectors:
  hailo:
    type: hailo
    device: /dev/hailo0

cameras:
  camera1:
    ffmpeg:
      inputs:
        - path: /dev/video0
          input_args: -f v4l2 -input_format yuyv422
          roles:
            - detect
    detect:
      enabled: true
      width: 640
      height: 480
```

## Features

- 24/7 recording
- Motion detection
- Object tracking
- Web UI for review
- Mobile app support
- Notifications

## Requirements

- Same as Python Direct (needs 4KB page size models)
- Adequate storage (SSD recommended for 24/7)

## More Information

- Frigate docs: https://docs.frigate.video
- Config guide: `../../configs/frigate/README.md`
- Troubleshooting: [../operations/troubleshooting.md](../operations/troubleshooting.md)

