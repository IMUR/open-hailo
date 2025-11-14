# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository implements an AI vision system combining Hailo-8 NPU acceleration with Raspberry Pi 5 and camera modules for real-time object detection. The project supports multiple deployment methods (rpicam-apps, Python Direct API, Frigate NVR, TAPPAS, OpenCV) and includes comprehensive tooling for setup, testing, and diagnostics.

**Target Platform:** Raspberry Pi OS Trixie (Debian 13) on Raspberry Pi 5
**Hardware:** Hailo-8 PCIe accelerator + Pi Camera (OV5647, IMX219, IMX477, etc.)
**Key Technologies:** HailoRT 4.23.0, rpicam-apps, GStreamer/TAPPAS, Python 3.13+

## Essential Commands

### Building and Testing

```bash
# Build C++ examples (device tests, camera integration tests)
cd apps
mkdir -p build && cd build
cmake ..
make

# Run device validation test
./build/device_test

# Run camera + Hailo integration test
./build/camera_hailo_test

# Run comprehensive system verification
./scripts/setup/verify_hailo_installation.sh

# Install the recommended rpicam-apps stack (same as setup option 5)
./configs/rpicam/install.sh
```

### Running Detection

```bash
# Live preview with object detection (rpicam-apps method - recommended)
rpicam-hello --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json

# Record video with detection overlays
rpicam-vid -t 30000 \
  --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json \
  -o output.h264

# Capture still image with detection
rpicam-still \
  --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json \
  -o photo.jpg
```

### Installation and Setup

```bash
# Interactive setup menu (recommended starting point)
./setup.sh

# Install build dependencies
./scripts/setup/install_build_dependencies.sh

# Setup HailoRT driver + library
./scripts/driver/get_official_driver.sh

# Run diagnostics
./scripts/diagnostics/check_version_compatibility.sh
```

### Deployment Configurations

Each deployment method has its own install script:

```bash
# rpicam-apps (recommended - works with any HEF models)
./configs/rpicam/install.sh

# Python Direct API (requires 4KB page size models)
./configs/python-direct/install.sh

# Frigate NVR
./configs/frigate/docker/  # Docker deployment
./configs/frigate/native/install_frigate_native.sh  # Native

# TAPPAS GStreamer pipelines
./configs/tappas/install.sh

# OpenCV custom pipelines
./configs/opencv-custom/install.sh
```

## Architecture

### Core System Layers

1. **Hardware Layer**
   - Hailo-8 PCIe accelerator accessed via `/dev/hailo0`
   - Pi Camera modules using libcamera API
   - DMA buffers for efficient data transfer

2. **Driver & Runtime Layer**
   - `hailo_pci` kernel driver (located in `hailort/hailort-drivers-4.23.0/`)
   - HailoRT library (`libhailort.so`) - C++ runtime for device management
   - Python bindings via `hailo_platform` module

3. **Application Layer**
   - **rpicam-apps**: Native camera integration with Hailo post-processing
   - **TAPPAS**: GStreamer-based pipelines for video processing
   - **Custom C++**: Direct HailoRT API usage (see `apps/`)
   - **Python**: High-level API for custom applications

### Key Integration Points

**HEF Model Loading Flow:**
```
Model file (.hef) → HailoRT::Hef → VDevice → ConfiguredNetworkGroup → InferModel → Results
```

**rpicam-apps Detection Pipeline:**
```
Camera → libcamera → YUV frames → Hailo post-processor → Inference → Overlay → Display/Encode
```

**Version Dependencies (Critical):**
- HailoRT library version MUST match firmware version
- Firmware is embedded in HEF files
- Mismatch causes "Unsupported firmware" errors
- Default install: HailoRT 4.23.0 matches Hailo-8 firmware 4.23.0

### Directory Structure & Purpose

```
apps/               # C++ examples using HailoRT API directly
├── device_test.cpp         # Comprehensive device validation
├── camera_hailo_test.cpp   # Camera + Hailo integration test
└── CMakeLists.txt          # Build configuration

configs/            # Deployment-specific configurations
├── rpicam/         # rpicam-apps setup (recommended path)
├── python-direct/  # Python API examples and setup
├── frigate/        # NVR deployment (Docker + native)
├── tappas/         # GStreamer pipeline configs
└── opencv-custom/  # Custom OpenCV integrations

hailort/            # HailoRT source code
├── hailort-4.23.0/         # Library source
└── hailort-drivers-4.23.0/ # Kernel driver source

scripts/            # Organized automation scripts
├── setup/          # Installation scripts
├── driver/         # Driver management
├── diagnostics/    # Troubleshooting tools
├── demos/          # Demo scripts
├── build/          # Build orchestration (only when necessary)
└── utils/          # Helper utilities

models/             # HEF model files storage
├── x86-models/     # Works with rpicam-apps (any page size)
├── pi5-compatible/ # 4KB page size models
└── rpicam-compatible/

docs/               # Comprehensive documentation
├── getting-started/
├── deployments/
├── development/
└── operations/
```

## Critical Build Considerations

### HailoRT Version Compatibility

The most common build issue is HailoRT version mismatches:

- **Symptom**: rpicam-apps fails with "HailoRT not found" or "Found 4.20.0 but need 4.23.0"
- **Root cause**: Symlink points to wrong version or CMake config has stale version
- **Fix approach**:
  1. Check actual library: `ls -la /usr/local/lib/libhailort.so*`
  2. Update symlink: `sudo ln -sf /usr/local/lib/libhailort.so.4.23.0 /usr/local/lib/libhailort.so`
  3. Fix CMake version strings in `/usr/local/lib/cmake/HailoRT/`
  4. Run `sudo ldconfig`

### Page Size Issue with HEF Models

**Important**: Not all HEF models work on all platforms due to memory page size differences.

- **x86 systems**: Use 4KB page size (standard)
- **Raspberry Pi 5**: Uses 16KB page size (ARM64 default)
- **rpicam-apps**: Handles both automatically via TAPPAS layer
- **Python Direct API**: Requires Pi-compatible models (4KB page size explicitly)

Models in `models/x86-models/` work with rpicam-apps but may fail with Python Direct API.

### CMake Build System

The `apps/` directory uses CMake:
- Requires `HailoRT::libhailort` package (found via `find_package`)
- C++14 standard required
- Links against HailoRT shared library
- Common flags: `-Wall -Wextra -O2`

When adding new C++ examples:
1. Create `.cpp` file in `apps/`
2. Add executable in `apps/CMakeLists.txt`
3. Link with `HailoRT::libhailort`
4. Rebuild from `apps/build/`

### rpicam-apps Build Process

Built via Meson (not CMake):
- Requires TAPPAS core library (`hailo-tappas-core`)
- Requires OpenCV 4.x
- Build time: 30-50 minutes on Pi 5
- Installs to `~/local/bin/` by default (local build) or `/usr/local/bin/` (system)

The build script (`scripts/build/build_hailo_preview_local.sh`) patches meson.build to make TAPPAS optional if needed.

## Testing Strategy

### Hardware Validation Sequence

1. **Driver check**: `lsmod | grep hailo_pci`
2. **Device check**: `ls -la /dev/hailo0`
3. **Runtime check**: `hailortcli fw-control identify`
4. **Model inference**: `hailortcli run models/yolov8s.hef --measure-fps`
5. **Full stack**: `./scripts/setup/verify_hailo_installation.sh`

### C++ Test Executables

- `device_test`: Validates Hailo device detection and capabilities
- `camera_hailo_test`: Tests camera + Hailo integration
- `simple_example`: Minimal HailoRT API usage
- `simple_inference`: Demonstrates HEF loading and inference

Run from `apps/build/` after building.

## Common Workflows

### Adding a New Deployment Configuration

1. Create directory in `configs/<name>/`
2. Add `install.sh` script
3. Add `README.md` with usage instructions
4. Update main `setup.sh` menu
5. Add deployment guide in `docs/deployments/<name>.md`

### Debugging Inference Issues

1. Verify device communication: `hailortcli fw-control identify`
2. Test model loading: `hailortcli parse-hef models/yolov8s.hef`
3. Run basic inference: `hailortcli run models/yolov8s.hef --measure-fps`
4. Check for version mismatch: Look for "Unsupported firmware" in output
5. Review kernel logs: `dmesg | grep hailo`

### Adjusting Detection Parameters

Edit inference JSON configs (e.g., `/usr/share/pi-camera-assets/hailo_yolov8_inference.json`):

```json
{
  "hailo_yolo_inference": {
    "hef_file": "../../models/x86-models/yolov8s.hef",
    "threshold": 0.5,        // 0.0-1.0 confidence threshold
    "max_detections": 20,     // Max objects per frame
    "temporal_filter": {      // Smooth detections over time
      "tolerance": 0.1,
      "factor": 0.75,
      "visible_frames": 6,
      "hidden_frames": 3
    }
  }
}
```

## Important Constraints

- **Platform**: Only Raspberry Pi OS Trixie (Debian 13) officially supported
- **Python**: Requires 3.13+ due to OS version
- **Memory**: rpicam-apps build can use significant RAM; consider reducing parallel jobs or increasing swap
- **Page size**: Python Direct API has model compatibility restrictions
- **Firmware**: HailoRT version must match device firmware version exactly

## Useful Diagnostic Commands

```bash
# Check Hailo device PCIe status
lspci | grep -i hailo

# Verify driver is loaded
lsmod | grep hailo_pci

# Check device permissions
stat -c "%a" /dev/hailo0

# Get device firmware version
hailortcli fw-control identify

# Test model inference performance
hailortcli run models/yolov8s.hef --measure-fps

# List available cameras
rpicam-hello --list-cameras

# Check library dependencies
ldd /usr/local/lib/libhailort.so

# Verify TAPPAS installation
pkg-config --modversion hailo-tappas-core
```

## Key Files to Review

- `setup.sh`: Main entry point for all setup operations
- `scripts/setup/verify_hailo_installation.sh`: Comprehensive system validator
- `apps/CMakeLists.txt`: C++ build configuration
- `configs/rpicam/README.md`: Recommended deployment path documentation
- `docs/getting-started/models.md`: Critical page size compatibility info
