# 🔧 Dependencies Installation Guide

## ❗ IMPORTANT: Run these in a REGULAR TERMINAL (not AI chat)

The AI environment blocks `sudo`, so you need to open a regular terminal on your Raspberry Pi.

## 1️⃣ Install OpenCV Python Bindings

```bash
# Update package list
sudo apt update

# Install OpenCV for Python
sudo apt install -y python3-opencv

# Verify installation
python3 -c "import cv2; print(f'OpenCV {cv2.__version__} installed!')"
```

## 2️⃣ Install HailoRT Python Bindings (Optional)

### Option A: From system package (if available)
```bash
sudo apt install python3-hailort
```

### Option B: From pip
```bash
pip3 install hailort --break-system-packages
```

### Option C: Build from source
```bash
cd ~/Projects/open-hailo/runtime/hailort
sudo python3 -m pip install libhailort/bindings/python/
```

## 3️⃣ Test Everything

After installation, test with:

```bash
cd .

# Test OpenCV camera preview
python3 scripts/preview/simple_camera_test.py

# Test Hailo + camera (if HailoRT installed)
python3 scripts/preview/hailo_live_preview.py --model models/yolov8s.hef
```

## 🎯 What Works Without These Dependencies

These work RIGHT NOW without any additional installs:

```bash
# Camera test with PIL (no OpenCV needed)
python3 scripts/preview/picamera_only_test.py

# Preview saving frames (no OpenCV needed)
python3 scripts/preview/hailo_preview_no_cv.py

# rpicam-apps (already built)
~/local/bin/rpicam-hello -t 5000
~/local/bin/rpicam-still --zsl -o test.jpg
```

## 📝 Summary

| Dependency | Status | Required For |
|------------|--------|--------------|
| python3-opencv | Not installed | Live preview window with overlays |
| python3-hailort | Not installed | Hailo inference in Python |
| PIL/Pillow | ✅ Installed | Basic image processing |
| picamera2 | ✅ Installed | Camera access |
| rpicam-apps | ✅ Built | Camera utilities |
