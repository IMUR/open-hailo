# Setup Guide - Hailo-8 AI Vision System

Complete setup guide for Hailo-8 + Raspberry Pi 5 + OV5647 camera with YOLOv8 live preview.

---

## 🚀 Quick Start

### One-Command Automated Setup:

```bash
cd /home/crtr/Projects/open-hailo
./setup
```

**Time: ~65 minutes** (runs all steps automatically)

### Or Follow Manual Steps Below

---

## 📋 Installation Steps

### Step 1: Install Dependencies (5 min)

```bash
# Build tools and libraries
./scripts/setup/install_build_deps.sh

# TAPPAS dependencies (GStreamer, etc.)
./scripts/setup/install_tappas_deps.sh
```

**Installs:** Boost, GStreamer dev libraries, Cairo, OpenCV, and other required packages.

---

### Step 2: Download AI Models (5 min)

```bash
./scripts/setup/download_yolov8_models.sh
```

**Downloads:**
- YOLOv8n (8 MB) - Fastest, 100+ FPS
- YOLOv8s (19 MB) - Recommended, 60-80 FPS ⭐
- YOLOv8m (29 MB) - Most accurate, 30-50 FPS

**Models saved to:** `models/` directory

---

### Step 3: Install TAPPAS Core (15 min)

**Create HailoRT symlink (if not done):**
```bash
mkdir -p ~/tappas/hailort
ln -s /home/crtr/Projects/open-hailo/runtime/hailort ~/tappas/hailort/sources
```

**Patch for uv (if not done):**
```bash
cd ~/tappas
cp install.sh install.sh.backup
sed -i 's/python3 -m virtualenv --system-site-packages/uv venv --python python3 --system-site-packages/g' install.sh
sed -i 's/python3 -m virtualenv/uv venv --python python3/g' install.sh
sed -i 's/pip3 install/uv pip install/g' install.sh
```

**Install TAPPAS:**
```bash
cd ~/tappas
./install.sh --target-platform rpi5 --skip-hailort --core-only
```

**What TAPPAS provides:**
- GStreamer Hailo plugins
- YOLOv5/v6/v8 post-processing
- Pose estimation, segmentation, classification
- Python bindings

---

### Step 4: Build rpicam-apps with Hailo (45 min)

```bash
cd /home/crtr/Projects/open-hailo
./scripts/build/build_hailo_preview_local.sh
```

**What this builds:**
- rpicam-hello with Hailo inference overlays
- rpicam-vid for annotated video recording
- rpicam-still for annotated photos
- All Hailo config files

**Installs to:** `~/local/bin/` (no sudo needed)

---

### Step 5: Run Live Preview! 🎥

```bash
export PATH="$HOME/local/bin:$PATH"
rpicam-hello -t 0 --post-process-file test/hailo_yolov8_custom.json
```

**You'll see:**
- Live camera feed with real-time bounding boxes
- Object labels (person, car, dog, etc.)
- Confidence scores
- 60-80 FPS performance

---

## ⚙️ Configuration

### Model Selection

Edit `test/hailo_yolov8_custom.json`:

```json
{
    "hailo_yolo_inference": {
        "hef_file": "/home/crtr/Projects/open-hailo/models/yolov8s.hef",
        // Change to yolov8n.hef (faster) or yolov8m.hef (more accurate)
    }
}
```

### Detection Threshold

```json
{
    "hailo_yolo_inference": {
        "threshold": 0.5,       // 0.0-1.0 (higher = more confident)
        "max_detections": 20    // Max boxes to display
    }
}
```

**Recommended thresholds:**
- YOLOv8n: 0.4-0.5 (faster model needs lower threshold)
- YOLOv8s: 0.5 (balanced)
- YOLOv8m: 0.5-0.6 (accurate model can use higher)

### Display Style

```json
{
    "object_detect_draw_cv": {
        "line_thickness": 3,    // Bounding box width (1-5)
        "font_size": 1.0       // Label text size (0.5-2.0)
    }
}
```

### Temporal Filtering (Smoothing)

```json
{
    "temporal_filter": {
        "tolerance": 0.1,       // Movement tolerance
        "factor": 0.75,         // Smoothing strength
        "visible_frames": 6,    // Frames before showing
        "hidden_frames": 3      // Frames before hiding
    }
}
```

---

## 🎬 Usage Examples

### Live Detection:
```bash
rpicam-hello -t 0 --post-process-file test/hailo_yolov8_custom.json
```

### Record Annotated Video (10 seconds):
```bash
rpicam-vid -t 10000 -o output.h264 \
    --post-process-file test/hailo_yolov8_custom.json
```

### Capture Annotated Photo:
```bash
rpicam-still -o photo.jpg \
    --post-process-file test/hailo_yolov8_custom.json
```

### Higher Resolution:
```bash
rpicam-hello -t 0 --width 1920 --height 1080 \
    --post-process-file test/hailo_yolov8_custom.json
```

### Pose Estimation:
```bash
rpicam-hello -t 0 --post-process-file \
    ~/local/share/rpi-camera-assets/hailo_yolov8_pose.json
```

---

## 🧪 Testing & Validation

### Quick Hardware Test (10 seconds):
```bash
./scripts/utils/run_test.sh
```

Tests: Hailo device, model files, camera, runtime

### Comprehensive Test (30 seconds):
```bash
./scripts/utils/run_complete_test.sh
```

Tests: Full stack including DMA memory, temperature monitoring

### Verify Setup After Each Step:

**After dependencies:**
```bash
pkg-config --modversion gstreamer-1.0
# Should show: 1.26.x
```

**After TAPPAS:**
```bash
pkg-config --modversion hailo-tappas-core
# Should show: 5.1.x
```

**After build:**
```bash
~/local/bin/rpicam-hello --version
ls ~/local/share/rpi-camera-assets/hailo*.json
```

---

## 📊 Model Comparison

| Model | Size | FPS | Latency | Best For |
|-------|------|-----|---------|----------|
| YOLOv8n | 8 MB | 100+ | ~10ms | Maximum speed |
| YOLOv8s | 19 MB | 60-80 | ~15ms | **Balanced** ⭐ |
| YOLOv8m | 29 MB | 30-50 | ~25ms | Maximum accuracy |
| YOLOv5m | 16 MB | 40-60 | ~20ms | Already included |

**Detects:** 80 COCO object classes (person, car, dog, cat, bicycle, chair, etc.)

Full class list: https://github.com/ultralytics/ultralytics/blob/main/ultralytics/cfg/datasets/coco.yaml

---

## 🔍 Troubleshooting

### TAPPAS Installation Issues

**"HailoRT sources not found":**
```bash
# Create symlink to your HailoRT sources
mkdir -p ~/tappas/hailort
ln -s /home/crtr/Projects/open-hailo/runtime/hailort ~/tappas/hailort/sources
```

**"No module named virtualenv":**
```bash
# Patch install.sh to use uv instead
cd ~/tappas
sed -i 's/python3 -m virtualenv/uv venv --python python3/g' install.sh
sed -i 's/pip3 install/uv pip install/g' install.sh
```

**"Out of memory":**
```bash
# Use fewer cores
./install.sh --target-platform rpi5 --skip-hailort --core-only --compile-num-of-cores 2
```

### Build Issues

**"HailoRT version mismatch":**
```bash
# Fix symlink
sudo rm /usr/local/lib/libhailort.so
sudo ln -s /usr/local/lib/libhailort.so.4.23.0 /usr/local/lib/libhailort.so
sudo ldconfig

# Update CMake configs
sudo sed -i 's/"4\.20\.0"/"4.23.0"/g' /usr/local/lib/cmake/HailoRT/HailoRTConfigVersion.cmake
sudo sed -i 's/4\.20\.0/4.23.0/g' /usr/local/lib/cmake/HailoRT/HailoRTTargets-release.cmake
sudo sed -i 's/MINOR_VERSION=20/MINOR_VERSION=23/g' /usr/local/lib/cmake/HailoRT/HailoRTTargets-release.cmake
```

**"OpenCV not found":**
```bash
sudo apt install -y libopencv-dev
```

**"Boost not found":**
```bash
sudo apt install -y libboost-dev libboost-program-options-dev
```

### Runtime Issues

**"No detections showing":**
- Lower threshold to 0.3
- Ensure good lighting
- Try different model

**"Low FPS":**
- Use YOLOv8n (fastest)
- Lower resolution
- Check: `htop` for CPU usage

**"rpicam-hello not found":**
```bash
export PATH="$HOME/local/bin:$PATH"
# Or add to ~/.bashrc permanently
```

---

## 📚 Resources

- **Hailo Model Zoo**: https://github.com/hailo-ai/hailo_model_zoo
- **TAPPAS GitHub**: https://github.com/hailo-ai/tappas
- **RPi Camera Docs**: https://www.raspberrypi.com/documentation/computers/camera_software.html
- **Hailo Community**: https://community.hailo.ai/
- **YOLOv8 Docs**: https://docs.ultralytics.com/

---

## ⏱️ Timeline

| Step | Task | Time | Cumulative |
|------|------|------|------------|
| 1 | Install dependencies | 5 min | 5 min |
| 2 | Download models | 5 min | 10 min |
| 3 | Install TAPPAS | 15 min | 25 min |
| 4 | Build rpicam-apps | 45 min | 70 min |
| 5 | Test | 1 min | 71 min |

**Total:** ~70 minutes from zero to AI vision

---

## ✅ Setup Checklist

- [ ] Run hardware tests (`./scripts/utils/run_complete_test.sh`)
- [ ] Install build dependencies
- [ ] Install TAPPAS dependencies  
- [ ] Download YOLOv8 models
- [ ] Create HailoRT symlink for TAPPAS
- [ ] Patch TAPPAS install.sh for uv
- [ ] Install TAPPAS core
- [ ] Build rpicam-apps with Hailo
- [ ] Add ~/local/bin to PATH
- [ ] Test live preview
- [ ] Configure threshold and parameters
- [ ] Celebrate! 🎉
