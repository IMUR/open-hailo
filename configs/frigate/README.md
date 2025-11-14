# Frigate NVR Configuration

Network Video Recorder with AI object detection using Hailo-8.

## Overview

Frigate is an open-source NVR (Network Video Recorder) designed for real-time AI object detection. This configuration integrates Frigate with Hailo-8 for accelerated detection on Raspberry Pi 5.

## Deployment Options

### Docker (Recommended)
- ✅ Easier updates
- ✅ Isolated environment
- ✅ Official support
- ❌ Additional overhead

### Native (Advanced)
- ✅ Better performance
- ✅ Direct hardware access
- ❌ Manual dependency management
- ❌ Trixie compatibility challenges

## Docker Installation

```bash
cd open-hailo/configs/frigate/docker
docker compose up -d
```

Access web UI: http://localhost:5000

## Native Installation

```bash
cd open-hailo/configs/frigate/native
./install_frigate_native.sh
```

## Configuration

Edit `config.yml` to configure cameras and detection:

```yaml
cameras:
  front_door:
    ffmpeg:
      inputs:
        - path: /dev/video0
          roles:
            - detect
    detect:
      enabled: true
      width: 640
      height: 480
      fps: 10

detectors:
  hailo:
    type: hailo
    device: /dev/hailo0
```

## More Information

- Frigate docs: https://docs.frigate.video
- Hailo integration: See `native/` scripts

