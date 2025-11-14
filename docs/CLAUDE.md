# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Open Hailo provides real-time AI object detection on Raspberry Pi 5 using Hailo-8 AI accelerator with live camera integration. The project integrates rpicam-apps with Hailo-8 for hardware-accelerated YOLOv8 inference with live preview overlays.

**Key Technologies:**
- Hailo-8 AI Processor (PCIe device: 0001:01:00.0)
- HailoRT 4.23.0 (runtime library and kernel driver)
- rpicam-apps (Raspberry Pi camera framework)
- TAPPAS (Hailo's application library)
- YOLOv8 models (nano, small, medium)
- OpenCV for visualization
- OV5647 Camera Module

**Project Focus:** Live camera inference with bounding box overlays at 30-100 FPS

## Build Commands

### Full Automated Setup
```bash
# Complete setup from scratch (60-75 minutes)
./setup

# This runs:
# 1. Install build dependencies
# 2. Install TAPPAS dependencies
# 3. Download YOLOv8 models
# 4. Install TAPPAS core (from ~/tappas)
# 5. Build rpicam-apps with Hailo support
```

### Manual Setup Steps
```bash
# Install dependencies
./scripts/setup/install_build_deps.sh      # Build tools
./scripts/setup/install_tappas_deps.sh     # TAPPAS requirements
./scripts/setup/download_yolov8_models.sh  # YOLOv8 models to models/

# Install TAPPAS core (required for rpicam-apps)
cd ~/tappas
./install.sh --target-platform rpi5 --skip-hailort --core-only

# Build rpicam-apps with Hailo support (30-60 min)
cd .
./scripts/build/build_hailo_preview_local.sh
# Installs to ~/local/bin (no sudo needed)
```

### Building C++ Examples
```bash
# Build example applications
cd apps
mkdir -p build && cd build
cmake ..
make -j$(nproc)

# Available applications:
# - device_test: Device connectivity, temperature, power
# - simple_example: Enumerate devices and capabilities
# - simple_inference_example: Full inference pipeline (requires HEF)
# - camera_hailo_test: Camera + Hailo integration test
```

### Running Live Preview
```bash
# Add rpicam binaries to PATH
export PATH="$HOME/local/bin:$PATH"

# Run live object detection with YOLOv8
rpicam-hello -t 0 --post-process-file test/hailo_yolov8_custom.json

# Other rpicam commands:
rpicam-vid -t 10000 -o output.h264 --post-process-file test/hailo_yolov8_custom.json
rpicam-still -o photo.jpg --post-process-file test/hailo_yolov8_custom.json
```

### Device Verification
```bash
# Check Hailo device
hailortcli scan
hailortcli fw-control identify
lspci | grep Hailo
ls -la /dev/hailo*

# Check camera
rpicam-hello --list-cameras
libcamera-hello --list-cameras

# Monitor device
hailortcli measure temp
hailortcli measure power
watch -n 1 'hailortcli measure temp'
```

## Testing Commands

```bash
# Quick hardware test
cd test && ./run_test.sh

# Complete system test (camera + Hailo + models)
cd test && ./run_complete_test.sh

# Test C++ examples
cd apps/build
./device_test           # Device connectivity, temperature, power
./simple_example        # Enumerate devices and capabilities
./camera_hailo_test     # Camera + Hailo integration

# Run inference test (requires HEF model in models/)
./simple_inference_example ../models/yolov8s.hef

# Test camera separately
rpicam-hello --list-cameras
rpicam-hello -t 5000

# Monitor kernel module
lsmod | grep hailo
sudo dmesg | grep hailo
sudo modprobe -r hailo_pci  # Unload
sudo modprobe hailo_pci      # Load
```

## Architecture

### Full System Architecture
```
┌─────────────────────────────────────────────┐
│  rpicam-apps (rpicam-hello, rpicam-vid)     │  User commands
├─────────────────────────────────────────────┤
│  Post-processing Pipeline                    │  JSON config files
│  ├─ Camera frame capture (640x640 RGB)      │
│  ├─ hailo_yolo_inference stage              │  TAPPAS integration
│  └─ object_detect_draw_cv stage             │  OpenCV overlays
├─────────────────────────────────────────────┤
│  HailoRT C++ API (libhailort.so)            │  Runtime library
│  ├─ VDevice / NetworkGroup                   │
│  ├─ VStreams (input/output)                 │
│  └─ HEF model loading (.hef files)          │
├─────────────────────────────────────────────┤
│  Device Node (/dev/hailo0)                  │  Kernel interface
├─────────────────────────────────────────────┤
│  Kernel Driver (hailo_pci.ko)               │  PCIe driver
│  ├─ DMA transfers                            │
│  ├─ Firmware loading                         │
│  └─ Power/thermal management                 │
├─────────────────────────────────────────────┤
│  Hailo-8 Hardware (0001:01:00.0)            │  AI accelerator
└─────────────────────────────────────────────┘

Camera: OV5647 → libcamera → rpicam-apps → Hailo inference → Display
```

### Directory Structure
```
open-hailo/
├── setup                       # One-command automated setup
├── scripts/                    # Organized by function
│   ├── setup/                  # Installation scripts (5)
│   ├── build/                  # Build scripts (3)
│   ├── preview/                # Camera visualization (2)
│   └── utils/                  # Testing utilities (4)
├── hailort/                    # HailoRT consolidated
│   ├── drivers/                # PCIe driver source
│   └── runtime/                # HailoRT SDK source
├── apps/                       # C++ examples
├── models/                     # YOLOv8 HEF models (downloaded)
├── test/                       # JSON configs for rpicam-apps
├── docs/                       # All documentation
└── logs/                       # Centralized logs
```

### Key API Patterns

The HailoRT API uses an Expected<T> pattern for error handling:

```cpp
// Virtual device creation (required first step)
auto vdevice = VDevice::create();
if (!vdevice) {
    // Handle error using vdevice.status()
}

// Get physical devices
auto devices = vdevice.value()->get_physical_devices();

// All API calls return Expected<T> or hailo_status
auto result = device.some_operation();
if (result.has_value()) {
    auto value = result.value();
    // Use value
}
```

### Driver-Firmware-Runtime Relationship

- **Kernel Driver** (`hailort/drivers/`): Manages PCIe communication, DMA transfers, device initialization
- **Firmware** (`hailo8_fw.4.23.0.bin`): Loaded by driver at init, stored in `/lib/firmware/hailo/`
- **Runtime** (`hailort/runtime/`): User-space library providing HailoRT C++ API
- **TAPPAS** (external, `~/tappas`): Post-processing stages for rpicam-apps integration
- **Version**: Currently using HailoRT 4.23.0 (driver + runtime + firmware must align)

### rpicam-apps + Hailo Integration

The project uses rpicam-apps post-processing pipeline for live inference:

1. **JSON Configuration** (`test/hailo_yolov8_custom.json`):
   - Specifies HEF model path (`models/yolov8s.hef`)
   - Sets inference parameters (threshold, max_detections)
   - Configures visualization (line_thickness, font_size)

2. **Post-processing Stages**:
   - `hailo_yolo_inference`: Runs YOLOv8 inference on camera frames
   - `object_detect_draw_cv`: Draws bounding boxes with OpenCV

3. **Camera Pipeline**:
   - Camera captures frames → libcamera → rpicam-apps
   - Lores stream (640x640 RGB) → Hailo inference
   - Main stream → Display with overlays

4. **TAPPAS Integration**:
   - Provides post-processing stages for rpicam-apps
   - Requires patched meson build (TAPPAS optional)
   - Installs to `~/local/share/rpi-camera-assets/`

### C++ Inference Workflow

For standalone C++ applications (`apps/simple_inference_example.cpp`):
```cpp
// 1. Load HEF model
auto hef = Hef::create("models/yolov8s.hef");

// 2. Configure device with model
auto configure_params = hef->create_configure_params(HAILO_STREAM_INTERFACE_PCIE);
auto network_groups = vdevice->configure(hef.value(), configure_params.value());

// 3. Create input/output virtual streams
auto input_vstreams = VStreamsBuilder::create_input_vstreams(network_group, params);
auto output_vstreams = VStreamsBuilder::create_output_vstreams(network_group, params);

// 4. Run inference
input_vstream.write(input_data);
network_group->wait_for_activation(HAILO_ACTIVATE_NETWORK_GROUP_DURATION_MS);
output_vstream.read(output_data);
```

### Build System

The project has two parallel build systems:

1. **rpicam-apps Build** (Meson + Ninja):
   - Source: `~/rpicam-apps-build/` (cloned during build)
   - Build dir: `~/rpicam-apps-build/build/`
   - Install prefix: `~/local/` (no sudo required)
   - Binaries: `~/local/bin/rpicam-*`
   - Assets: `~/local/share/rpi-camera-assets/`
   - Patches: TAPPAS made optional in meson.build

2. **C++ Examples Build** (CMake):
   - Source: `apps/*.cpp`
   - Build dir: `apps/build/`
   - Links against system HailoRT: `/usr/local/lib/libhailort.so`

3. **HailoRT Library** (Pre-installed):
   - Headers: `/usr/local/include/hailo/`
   - Library: `/usr/local/lib/libhailort.so`
   - CLI tool: `/usr/local/bin/hailortcli`
   - Installed via HailoRT 4.23.0 package

## Important Implementation Details

### Device Initialization Sequence
1. Create VDevice (virtual device container)
2. Get physical devices from VDevice
3. Query device capabilities (architecture, firmware version)
4. Configure device for specific workload (when using models)

### Memory Management
- DMA buffers must be created with `Buffer::create_shared()` using `HAILO_DMA_BUFFER_DIRECTION`
- Default buffer size for testing: 1MB
- Buffers are automatically freed when out of scope

### Error Handling
- All HailoRT functions return `hailo_status` or `Expected<T>`
- Common status codes: `HAILO_SUCCESS`, `HAILO_INVALID_OPERATION`, `HAILO_TIMEOUT`
- Device operations can timeout (default: 10s for most operations)

### Temperature and Power Monitoring
- Temperature sensors: TS0 and TS1 (in Celsius)
- Power measurement requires enabling via `set_power_measurement()` first
- Not all features supported on all firmware versions

## Available Models

YOLOv8 models are pre-compiled and downloaded by `scripts/setup/download_yolov8_models.sh`:

- **yolov8n.hef** (8 MB): Nano model, 100+ FPS, lowest latency (~10ms)
- **yolov8s.hef** (19 MB): Small model, 60-80 FPS, balanced (~15ms) - **Recommended**
- **yolov8m.hef** (29 MB): Medium model, 30-50 FPS, highest accuracy (~25ms)

All models detect 80 COCO object classes (person, car, dog, cat, etc.)

To switch models, edit `test/hailo_yolov8_custom.json`:
```json
{
    "hailo_yolo_inference": {
        "hef_file": "./models/yolov8n.hef",
        "threshold": 0.5,
        "max_detections": 20
    }
}
```

## Known Limitations

1. **Model Conversion**: HEF files require Hailo Dataflow Compiler (proprietary)
2. **TAPPAS Dependency**: rpicam-apps requires TAPPAS core for post-processing stages
3. **Firmware**: Binary blob required (hailo8_fw.bin), cannot be built from source
4. **Platform**: Currently validated only on Raspberry Pi 5 + OV5647 camera
5. **Build Time**: rpicam-apps compilation takes 30-60 minutes on Pi 5

## Debugging Tips

```bash
# Enable verbose driver logging
sudo modprobe -r hailo_pci
sudo modprobe hailo_pci dbg_level=5

# Check for firmware loading issues
sudo dmesg | grep -i hailo | tail -20
sudo journalctl -u systemd-modules-load | grep hailo

# Verify PCIe link status (should be Gen3)
sudo lspci -vv -s $(lspci | grep Hailo | cut -d' ' -f1) | grep LnkSta

# Monitor device temperature during operations
watch -n 1 'hailortcli measure temp'

# Check rpicam-apps installation
which rpicam-hello
rpicam-hello --version
rpicam-hello --list-cameras

# Verify model files
ls -lh models/*.hef
hailortcli parse-hef models/yolov8s.hef

# Check TAPPAS installation
ls -la ~/tappas/
pkg-config --exists hailo_tappas && echo "TAPPAS found" || echo "TAPPAS not found"

# Test JSON config parsing
rpicam-hello -t 1000 --post-process-file test/hailo_yolov8_custom.json -n
```

## Project Organization Rules

From `.cursor/rules/project_rules.md`:

1. **Documentation Management**:
   - Always update existing docs in `docs/` rather than creating new files
   - No temporary or duplicate documentation files
   - Each topic has one canonical document

2. **Script Organization**:
   - All scripts must be in `scripts/` subdirectories:
     - `scripts/setup/` - Installation and configuration
     - `scripts/build/` - Compilation
     - `scripts/preview/` - Camera and visualization
     - `scripts/utils/` - Testing and utilities

3. **File Organization**:
   - C++ examples → `apps/`
   - Test configs → `test/`
   - Models → `models/`
   - All logs → `logs/` (with timestamps)
   - No scattered files in project root

## File Locations

### System Files
- Kernel module: `/lib/modules/$(uname -r)/extra/hailo_pci.ko`
- Firmware: `/lib/firmware/hailo/hailo8_fw.bin` (hailo8_fw.4.23.0.bin)
- Udev rules: `/etc/udev/rules.d/51-hailo-udev.rules`
- Device node: `/dev/hailo0` (created dynamically)

### HailoRT Installation
- Headers: `/usr/local/include/hailo/`
- Library: `/usr/local/lib/libhailort.so`
- CLI tool: `/usr/local/bin/hailortcli`
- PKG_CONFIG: `/usr/local/lib/pkgconfig/hailort.pc`

### rpicam-apps Installation (User-space)
- Binaries: `~/local/bin/rpicam-*` (hello, vid, still, etc.)
- Assets: `~/local/share/rpi-camera-assets/hailo*.json`
- Must add to PATH: `export PATH="$HOME/local/bin:$PATH"`

### Project Files
- Models: `models/*.hef` (yolov8n, yolov8s, yolov8m)
- Configs: `test/hailo_yolo*.json`
- Scripts: `scripts/{setup,build,preview,utils}/*.sh`
- Examples: `apps/*.cpp` → `apps/build/`
- Logs: `logs/` (centralized)

### External Dependencies
- TAPPAS: `~/tappas/` (cloned and installed separately)
- rpicam-apps build: `~/rpicam-apps-build/` (temporary, created during build)

## Quick Reference

### Most Common Commands
```bash
# Run live preview with YOLOv8
export PATH="$HOME/local/bin:$PATH"
rpicam-hello -t 0 --post-process-file test/hailo_yolov8_custom.json

# Check device status
hailortcli scan
hailortcli fw-control identify

# Test hardware
cd test && ./run_complete_test.sh

# Build C++ examples
cd apps && mkdir -p build && cd build && cmake .. && make -j$(nproc)

# Run full setup (if starting fresh)
./setup
```

### Key Configuration Files
- `test/hailo_yolov8_custom.json` - Main config for rpicam-apps (model path, threshold)
- `test/hailo_yolov5m_custom.json` - Alternative YOLOv5 config
- `apps/CMakeLists.txt` - C++ examples build configuration
- `scripts/build/build_hailo_preview_local.sh` - rpicam-apps build script

### Performance Expectations
- YOLOv8n: 100+ FPS, ~10ms latency
- YOLOv8s: 60-80 FPS, ~15ms latency (recommended)
- YOLOv8m: 30-50 FPS, ~25ms latency
- Power consumption: ~2.5W for Hailo-8
- Detection: 80 COCO object classes

### Troubleshooting Checklist
1. Device not found: Check `lspci | grep Hailo` and `ls /dev/hailo*`
2. Camera issues: Run `rpicam-hello --list-cameras`
3. Model loading fails: Verify paths in JSON config match `models/*.hef`
4. TAPPAS errors: Ensure `~/tappas/install.sh` completed successfully
5. rpicam-apps not found: Add `~/local/bin` to PATH
6. Build failures: Check dependencies with scripts in `scripts/setup/`