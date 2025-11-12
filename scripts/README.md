# Scripts Directory

Organized collection of setup, build, and utility scripts for your Hailo-8 system.

---

## 📁 Directory Structure

```
scripts/
├── setup/          # Installation and setup scripts
├── build/          # Build and compilation scripts  
├── preview/        # Preview and visualization tools
└── utils/          # Testing and utility scripts
```

---

## 🚀 **setup/** - Installation Scripts

Scripts for installing dependencies and downloading models:

### `install_tappas_deps.sh`
**Purpose:** Install TAPPAS dependencies (GStreamer, Cairo, etc.)  
**Requires:** sudo  
**Time:** ~5 minutes

```bash
./scripts/setup/install_tappas_deps.sh
```

### `install_build_deps.sh`
**Purpose:** Install build dependencies (Boost, libcamera-dev, etc.)  
**Requires:** sudo  
**Time:** ~2-3 minutes

```bash
./scripts/setup/install_build_deps.sh
```

### `download_yolov8_models.sh`
**Purpose:** Download YOLOv8 models (nano/small/medium) from Hailo Model Zoo  
**Requires:** internet connection  
**Time:** ~2-5 minutes  
**Downloads:** ~55 MB total

```bash
./scripts/setup/download_yolov8_models.sh
```

---

## 🔨 **build/** - Build Scripts

Scripts for compiling components:

### `build_hailo_preview_local.sh` ⭐ **Recommended**
**Purpose:** Build rpicam-apps with Hailo support (local install to ~/local)  
**Requires:** Dependencies installed, TAPPAS installed  
**Time:** ~30-50 minutes  
**Output:** `~/local/bin/rpicam-hello` with Hailo support

```bash
./scripts/build/build_hailo_preview_local.sh
```

**Features:**
- Installs to your home directory (no sudo for install)
- Automatically patches TAPPAS requirements
- Enables Hailo and OpenCV support

### `build_hailo_preview.sh`
**Purpose:** Build rpicam-apps with Hailo support (system install)  
**Requires:** sudo, dependencies installed, TAPPAS installed  
**Time:** ~30-50 minutes  
**Output:** `/usr/local/bin/rpicam-hello` with Hailo support

```bash
./scripts/build/build_hailo_preview.sh
```

**Note:** Requires sudo for installation. Use `build_hailo_preview_local.sh` instead if you don't have sudo access.

### `build.sh`
**Purpose:** Original project build script (builds HailoRT examples)  
**Time:** ~5-10 minutes

```bash
./scripts/build/build.sh
```

---

## 🎥 **preview/** - Preview & Visualization

Scripts for running live preview and visualization:

### `live_preview.py`
**Purpose:** Interactive preview launcher with multiple modes  
**Requires:** Python 3  
**Modes:**
1. Official RPi + Hailo integration
2. OpenCV custom preview
3. Capture & save (headless)
4. GStreamer pipeline

```bash
cd scripts/preview
python3 live_preview.py
```

### `hailo_live_preview.sh`
**Purpose:** Simple continuous capture for headless preview  
**Output:** Frames to `/tmp/hailo_preview/`

```bash
./scripts/preview/hailo_live_preview.sh
```

---

## 🧪 **utils/** - Testing & Utilities

Utility and testing scripts:

### `run_test.sh` (also in test/)
**Purpose:** Quick hardware validation test  
**Time:** ~10 seconds  
**Tests:**
- Hailo device detection
- Model file presence
- Camera detection
- Runtime operational

```bash
./scripts/utils/run_test.sh
```

### `run_complete_test.sh` (also in test/)
**Purpose:** Comprehensive stack validation  
**Time:** ~30 seconds  
**Tests:**
- Hailo accelerator status
- YOLOv5m model validation
- Camera capture test
- Runtime test
- DMA memory test

```bash
./scripts/utils/run_complete_test.sh
```

---

## 📊 **Quick Reference**

### First Time Setup:

```bash
# 1. Install dependencies
./scripts/setup/install_tappas_deps.sh
./scripts/setup/install_build_deps.sh

# 2. Download models
./scripts/setup/download_yolov8_models.sh

# 3. Install TAPPAS (from ~/tappas)
cd ~/tappas
./install.sh --target-platform rpi5 --skip-hailort --core-only

# 4. Build rpicam-apps
cd /home/crtr/Projects/open-hailo
./scripts/build/build_hailo_preview_local.sh

# 5. Run preview!
export PATH="$HOME/local/bin:$PATH"
rpicam-hello -t 0 --post-process-file test/hailo_yolov8_custom.json
```

### Testing:

```bash
# Quick test
./scripts/utils/run_test.sh

# Comprehensive test
./scripts/utils/run_complete_test.sh
```

### Preview:

```bash
# Interactive launcher
python3 scripts/preview/live_preview.py

# Headless capture
./scripts/preview/hailo_live_preview.sh
```

---

## 🔍 **Script Categories**

### Setup Scripts (run once)
- Install dependencies
- Download models
- Initial configuration

### Build Scripts (run once per update)
- Compile components
- Build applications
- Install binaries

### Preview Scripts (run anytime)
- Launch live preview
- Capture frames
- Visualize results

### Utility Scripts (run as needed)
- Test hardware
- Validate stack
- Debug issues

---

## 💡 **Usage Tips**

1. **Run setup scripts first** - They install required dependencies
2. **Run build scripts next** - They compile applications
3. **Use preview scripts last** - After everything is built
4. **Test anytime** - Utility scripts verify everything works

---

## 🆘 **Troubleshooting**

### Script Permission Denied

```bash
chmod +x scripts/**/*.sh scripts/**/*.py
```

### Script Not Found

Make sure you're in the project root:
```bash
cd /home/crtr/Projects/open-hailo
```

### Dependencies Missing

Run setup scripts in order:
```bash
./scripts/setup/install_build_deps.sh
./scripts/setup/install_tappas_deps.sh
```

---

## 📝 **Related Documentation**

- **Setup Guide**: [../docs/setup/COMPLETE_SETUP_GUIDE.md](../docs/setup/COMPLETE_SETUP_GUIDE.md)
- **Build Guide**: [../docs/guides/BUILD_INSTRUCTIONS.md](../docs/guides/BUILD_INSTRUCTIONS.md)
- **TAPPAS Guide**: [../docs/setup/INSTALL_TAPPAS_GUIDE.md](../docs/setup/INSTALL_TAPPAS_GUIDE.md)

---

**All scripts organized and documented!** 🎉
