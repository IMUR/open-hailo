# Hailo-8 + Raspberry Pi 5 + OV5647 - AI Vision System

Real-time object detection with live camera preview and AI inference overlays.

**Status**: ✅ Hardware validated | 🚀 Ready to build

---

## ⚡ Quick Start

```bash
# Interactive setup menu
./setup.sh
```

**Quick commands:**

```bash
# Test system
./test.sh

# Start detection
./run.sh

# Check compatibility
./scripts/diagnostics/check_version_compatibility.sh

# Install Frigate NVR
./scripts/frigate/install_frigate_native.sh

# Get official driver
./scripts/driver/get_official_driver.sh
```

📖 **Detailed guide:** [docs/SETUP.md](docs/SETUP.md)

---

## 📁 Structure

```
open-hailo/
├── setup.sh                     # Interactive setup menu
├── test.sh                      # Run system tests  
├── run.sh                       # Start detection
├── docs/                        # 📚 Consolidated documentation
│   ├── SETUP.md                 # ⭐ Complete setup guide
│   ├── BUILD.md                 # Build instructions
│   ├── API.md                   # API reference
│   ├── DEVELOPMENT.md           # Developer guide
│   └── README.md                # Docs index
├── hailort/                     # 🧠 HailoRT consolidated
│   ├── drivers/                 # PCIe drivers & firmware
│   └── runtime/                 # HailoRT SDK source
├── scripts/                     # 🔧 Organized scripts
│   ├── build/                   # Build rpicam-apps (3)
│   ├── driver/                  # Driver management (11)
│   ├── frigate/                 # Frigate NVR (5)
│   ├── preview/                 # Camera testing (8)
│   ├── setup/                   # Installation (11)
│   ├── diagnostics/             # Troubleshooting (5)
│   ├── quickstart/              # Quick start (3)
│   └── utils/                   # Utilities (5)
├── apps/                        # 💻 C++ examples
├── models/                      # 🤖 YOLOv8 models
├── test/                        # 🧪 Test configs
└── logs/                        # 📝 Log files
```

---

## 🎯 Current Status

### ✅ Completed:
- Hardware validated (all tests passing)
- HailoRT 4.23.0 installed and working
- YOLOv8 models downloaded (55 MB)
- TAPPAS repository cloned (445 MB)
- All scripts and configs created

### ⏳ Remaining:
- Install TAPPAS dependencies (5 min)
- Build & install TAPPAS core (15 min)
- Build rpicam-apps with Hailo (45 min)
- Run live preview!

**Total time to completion:** ~65 minutes

---

## 📊 Performance

### With Hailo-8 + RPi5:

| Model | Size | FPS | Latency | Best For |
|-------|------|-----|---------|----------|
| YOLOv8n | 8 MB | 100+ | ~10ms | Max speed |
| YOLOv8s | 19 MB | 60-80 | ~15ms | **Recommended** |
| YOLOv8m | 29 MB | 30-50 | ~25ms | Max accuracy |
| YOLOv5m | 16 MB | 40-60 | ~20ms | Already included |

**Detection:** 80 COCO object classes (person, car, dog, cat, etc.)

---

## 🎥 Features

✅ **Real-time Inference** - 30-100 FPS depending on model  
✅ **Live Overlays** - Bounding boxes, labels, confidence scores  
✅ **80 Object Classes** - Full COCO dataset support  
✅ **Low Latency** - 10-25ms per frame  
✅ **Low Power** - ~2.5W for Hailo-8  
✅ **Hardware Accelerated** - Hailo NPU + RPi GPU  
✅ **Easy Configuration** - JSON config files  
✅ **Multiple Models** - YOLOv5/v6/v8 support

---

## 🧪 Testing

### Quick Hardware Test:
```bash
cd test && ./run_test.sh
```

### Complete Stack Test:
```bash
cd test && ./run_complete_test.sh
```

### All Tests Passing:
- ✅ Hailo-8 device detected
- ✅ Models loaded successfully  
- ✅ OV5647 camera operational
- ✅ HailoRT runtime working
- ✅ DMA memory allocation successful

---

## 📚 Documentation

- **[docs/SETUP.md](docs/SETUP.md)** - Complete setup guide ⭐
- **[docs/BUILD.md](docs/BUILD.md)** - Building from source
- **[docs/API.md](docs/API.md)** - API reference & technical details
- **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)** - Developer guide

**Index:** [docs/README.md](docs/README.md)

---

## 🔧 Scripts

- **[scripts/setup/](scripts/setup/)** - Installation & downloads (3)
- **[scripts/build/](scripts/build/)** - Build automation (3)
- **[scripts/preview/](scripts/preview/)** - Visualization (2)
- **[scripts/utils/](scripts/utils/)** - Testing (2)

**Index:** [scripts/README.md](scripts/README.md)

---

## 🎬 Usage Examples

### Live Object Detection:
```bash
rpicam-hello -t 0 --post-process-file test/hailo_yolov8_custom.json
```

### Record Annotated Video:
```bash
rpicam-vid -t 10000 -o output.h264 \
    --post-process-file test/hailo_yolov8_custom.json
```

### Capture Annotated Photo:
```bash
rpicam-still -o photo.jpg \
    --post-process-file test/hailo_yolov8_custom.json
```

### Adjust Detection Threshold:

Edit `test/hailo_yolov8_custom.json`:
```json
{
    "hailo_yolo_inference": {
        "threshold": 0.5,     // Range: 0.0-1.0
        "max_detections": 20  // Max objects to show
    }
}
```

---

## 🆘 Troubleshooting

### Build Issues
See [docs/guides/BUILD_INSTRUCTIONS.md](docs/guides/BUILD_INSTRUCTIONS.md#troubleshooting)

### TAPPAS Issues
See [docs/setup/INSTALL_TAPPAS_GUIDE.md](docs/setup/INSTALL_TAPPAS_GUIDE.md#troubleshooting)

### Model Issues
See [docs/setup/SETUP_YOLOV8.md](docs/setup/SETUP_YOLOV8.md#troubleshooting)

### Run Tests
```bash
./scripts/utils/run_complete_test.sh
```

---

## 🌟 Hardware Specifications

**Validated Configuration:**
- **Accelerator**: Hailo-8 (PCIe) - Firmware 4.23.0
- **Computer**: Raspberry Pi 5
- **Camera**: OV5647 Camera Module
- **Runtime**: HailoRT 4.23.0
- **OS**: Raspberry Pi OS (Debian 12+)

---

## 📚 Resources

- **Hailo TAPPAS**: https://github.com/hailo-ai/tappas
- **Hailo Model Zoo**: https://github.com/hailo-ai/hailo_model_zoo
- **RPi Camera Docs**: https://www.raspberrypi.com/documentation/computers/camera_software.html
- **Hailo Community**: https://community.hailo.ai/
- **YOLOv8**: https://docs.ultralytics.com/

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

---

## 📝 License

- **HailoRT**: Hailo Technologies Ltd.
- **rpicam-apps**: BSD-2-Clause (Raspberry Pi)
- **TAPPAS**: LGPL v2.1 (Hailo)
- **This repository scripts**: MIT

---

## 🎉 Quick Commands

```bash
# Full automated setup
./setup

# Or step by step:
./scripts/setup/download_yolov8_models.sh          # Download models
./scripts/setup/install_tappas_deps.sh             # Install deps
cd ~/tappas && ./install.sh --target-platform rpi5 --skip-hailort --core-only
./scripts/build/build_hailo_preview_local.sh       # Build everything

# Test hardware
./scripts/utils/run_complete_test.sh

# Run preview
export PATH="$HOME/local/bin:$PATH"
rpicam-hello -t 0 --post-process-file test/hailo_yolov8_custom.json
```

---

**Your jerry-rigged Hailo-8 AI vision system - organized and documented!** 🚀✨