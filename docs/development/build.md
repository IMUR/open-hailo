# Build Guide

Building rpicam-apps with Hailo support and other components from source.

---

## 🏗️ Building rpicam-apps with Hailo

### Automated Build (Recommended):

```bash
./scripts/build/build_hailo_preview_local.sh
```

**Installs to:** `~/local/bin/` (no sudo required)  
**Time:** 30-50 minutes

### Prerequisites

Before building, ensure you have:
- ✅ TAPPAS core installed
- ✅ HailoRT 4.23.0 installed
- ✅ OpenCV installed
- ✅ Build tools (meson, ninja, gcc)

Verify with:
```bash
pkg-config --modversion hailo-tappas-core  # Should show 5.1.x
pkg-config --modversion opencv4             # Should show 4.x
```

---

## 🔧 Build Process Details

### What the Build Script Does:

1. **Clones rpicam-apps** from Raspberry Pi GitHub
2. **Patches meson.build** to make TAPPAS optional
3. **Configures with:** `-Denable_hailo=enabled -Denable_opencv=enabled`
4. **Compiles** using ninja (all CPU cores)
5. **Installs** binaries and config files

### Build Outputs:

```
~/local/bin/
├── rpicam-hello    # Live preview with post-processing
├── rpicam-vid      # Video recording with overlays
├── rpicam-still    # Still capture with annotations
├── rpicam-jpeg     # JPEG capture
└── rpicam-raw      # Raw capture

~/local/share/rpi-camera-assets/
├── hailo_yolov8_inference.json
├── hailo_yolov6_inference.json
├── hailo_yolox_inference.json
├── hailo_yolov8_pose.json
├── hailo_classifier.json
└── (more configs)
```

---

## 🐛 Common Build Issues

### Issue: "HailoRT not found" or "Found 4.20.0 but need 4.23.0"

**Fix symlink:**
```bash
sudo rm /usr/local/lib/libhailort.so
sudo ln -s /usr/local/lib/libhailort.so.4.23.0 /usr/local/lib/libhailort.so
sudo ldconfig
```

**Fix CMake configs:**
```bash
sudo sed -i 's/"4\.20\.0"/"4.23.0"/g' /usr/local/lib/cmake/HailoRT/HailoRTConfigVersion.cmake
sudo sed -i 's/4\.20\.0/4.23.0/g' /usr/local/lib/cmake/HailoRT/HailoRTTargets-release.cmake  
sudo sed -i 's/MINOR_VERSION=20/MINOR_VERSION=23/g' /usr/local/lib/cmake/HailoRT/HailoRTTargets-release.cmake
```

### Issue: "TAPPAS not found"

**Verify TAPPAS is installed:**
```bash
pkg-config --modversion hailo-tappas-core
ls /usr/lib/*/gstreamer-1.0/*hailo*
```

**If not installed**, go back to setup step 3.

### Issue: "OpenCV not found"

```bash
sudo apt install -y libopencv-dev
```

### Issue: "Boost not found"

```bash
sudo apt install -y libboost-dev libboost-program-options-dev
```

### Issue: "Out of memory during compilation"

**Reduce parallel jobs:**
Edit `scripts/build/build_hailo_preview_local.sh`:
```bash
# Change: ninja -C build -j$(nproc)
# To:     ninja -C build -j2
```

**Or increase swap:**
```bash
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile  # Set CONF_SWAPSIZE=4096
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

---

## 🔨 Building HailoRT Examples

To build the C++ examples in `apps/`:

```bash
./scripts/build/build.sh
```

**Builds:**
- `apps/build/simple_example` - Basic Hailo device test
- `apps/build/device_test` - Device capabilities test
- `apps/build/camera_hailo_test` - Camera + Hailo integration

**Time:** 5-10 minutes

---

## 🎯 Build Variants

### Local Install (No Sudo):
```bash
./scripts/build/build_hailo_preview_local.sh
```
- Installs to `~/local/bin/`
- Doesn't affect system binaries
- Recommended for development

### System Install (Requires Sudo):
```bash
./scripts/build/build_hailo_preview.sh
```
- Installs to `/usr/local/bin/`
- Available system-wide
- Requires sudo for installation

---

## 📁 Build Artifacts

### Temporary (Safe to Delete):

```
~/rpicam-apps-build/        # Build directory
~/rpicam-apps-build/build/  # Ninja build files
```

### Permanent (Keep):

```
~/local/bin/rpicam-*        # Your compiled binaries
~/local/share/              # Config files
```

---

## ⚡ Build Optimization Tips

1. **Use ccache** (already enabled if available) - Speeds up rebuilds
2. **Limit parallel jobs** on low-RAM systems
3. **Clean build directory** between attempts:
   ```bash
   rm -rf ~/rpicam-apps-build/build
   ```
4. **Monitor resources**: Run `htop` in another terminal

---

## 🔄 Rebuilding

If you need to rebuild after code changes:

```bash
cd .
rm -rf ~/rpicam-apps-build    # Clean slate
./scripts/build/build_hailo_preview_local.sh
```

---

## 📚 Build Dependencies

### Required:
- meson (>= 0.55)
- ninja-build
- gcc/g++ (>= 9.0)
- cmake (>= 3.10)
- pkg-config

### Libraries:
- libcamera-dev
- libboost-dev + libboost-program-options-dev
- libopencv-dev (opencv4)
- libgstreamer1.0-dev + plugins-base-dev + plugins-bad-dev
- HailoRT >= 4.23.0
- hailo-tappas-core >= 5.1.0

Install all at once:
```bash
./scripts/setup/install_build_deps.sh
./scripts/setup/install_tappas_deps.sh
```
