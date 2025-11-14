# Quick Start Guide

Get Hailo-8 working on your Raspberry Pi 5 in minutes.

## Prerequisites

- Raspberry Pi 5 (4GB or 8GB)
- Hailo-8 PCIe module installed
- Pi Camera (OV5647, IMX219, or similar)
- Raspberry Pi OS Trixie (Debian 13)
- Internet connection

## Installation Steps

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd open-hailo
```

### 2. Run Setup

```bash
./setup.sh
```

The setup menu will guide you through:

**Core Setup (required):**
1. Install build dependencies
2. Setup HailoRT driver + library
3. Verify installation

**Choose Your Deployment:**
- Option 5: **rpicam-apps** ⭐ Recommended - works with any models
- Option 6: **Python Direct** - custom API access
- Option 7: **Frigate NVR** - video surveillance
- Option 8: **TAPPAS** - GStreamer pipelines
- Option 9: **OpenCV Custom** - advanced pipelines

### 3. Recommended Path (rpicam-apps)

```bash
./setup.sh
# Choose: 5 (rpicam-apps)
```

This will:
- ✅ Verify HailoRT is installed
- ✅ Build rpicam-apps with Hailo support
- ✅ Configure detection settings
- ✅ Test camera

### 4. Test Detection

```bash
rpicam-hello --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json
```

You should see live camera preview with object detection overlays!

## Need Help?

- **Detailed setup:** [setup-details.md](setup-details.md)
- **Hardware questions:** [hardware.md](hardware.md)
- **Model issues:** [models.md](models.md)
- **Troubleshooting:** [../operations/troubleshooting.md](../operations/troubleshooting.md)

## Deployment Options

Each deployment method has its own guide:

- **rpicam-apps:** [../deployments/rpicam.md](../deployments/rpicam.md)
- **Python Direct:** [../deployments/python-direct.md](../deployments/python-direct.md)
- **Frigate NVR:** [../deployments/frigate.md](../deployments/frigate.md)
- **TAPPAS:** [../deployments/tappas.md](../deployments/tappas.md)
- **OpenCV Custom:** [../deployments/opencv-custom.md](../deployments/opencv-custom.md)

## What's Next?

1. **Read your deployment guide** in `docs/deployments/`
2. **Run examples** in `configs/<your-choice>/examples/`
3. **Build your application!**

---

**Total time: 15-30 minutes** (depending on build times)

For complete details, see [setup-details.md](setup-details.md).

