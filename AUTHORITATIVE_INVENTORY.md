# Authoritative Project Inventory
## Generated: 2025-01-13

This document serves as the **authoritative source of truth** for all scripts, documentation, and structure in the open-hailo project.

---

## 📋 Complete Script Inventory (14 Total)

### Root-Level Scripts (5)
```
✅ setup.sh              - Interactive setup menu (6 options)
✅ demo.sh               - Full demo with web UI
✅ demo_detection.sh     - Real detection demo (4 modes)
✅ test.sh               - Run system tests
✅ run.sh                - Start detection
```

### scripts/setup/ (3)
```
✅ install_build_dependencies.sh    - Install build tools, libraries
✅ verify_hailo_installation.sh     - Verify complete Hailo stack
✅ fix_version_mismatch.sh          - Fix driver/library version issues
```

### scripts/build/ (1)
```
✅ build_hailo_preview_local.sh     - Build rpicam-apps with Hailo
```

### scripts/driver/ (2)
```
✅ get_official_driver.sh           - Clone, build & install driver (does everything!)
✅ install_official_driver.sh       - Reinstall already-built driver (optional)
```

**Note:** `get_official_driver.sh` is a complete solution - it clones, builds, AND installs.
The `install_official_driver.sh` is only needed if you want to rebuild/reinstall later.

### scripts/diagnostics/ (2)
```
✅ check_version_compatibility.sh   - Check OS, Python, kernel, Hailo
✅ reset_camera.sh                  - Reset locked camera
```

### scripts/frigate/ (3)
```
✅ install_frigate_native.sh        - Native Frigate installation
✅ fix_frigate_install.sh           - Fix Python 3.13 compatibility
✅ setup_frigate_caddy.sh           - Configure Caddy reverse proxy
```

### scripts/preview/ (2 Python)
```
✅ hailo_live_overlay.py            - REAL detection (requires hailo_platform)
✅ hailo_preview_no_cv.py           - SIMULATOR (camera test only)
```

### scripts/utils/ (1)
```
✅ check_hailo_versions.sh          - Display all version info
```

---

## 📚 Documentation Structure

### Main Documentation (docs/)
```
✅ README.md            - Documentation index
✅ SETUP.md             - Complete setup guide ⭐
✅ DEVELOPMENT.md       - Developer guide with official driver info
✅ BUILD.md             - Build instructions
✅ API.md               - API reference
✅ CONTRIBUTING.md      - Contribution guidelines
✅ CLAUDE.md            - AI assistant notes
✅ INSTALL_DEPS.md      - Dependency installation
```

### Root Documentation
```
✅ README.md                       - Main project README
✅ LICENSE                         - Project license
✅ AUTHORITATIVE_INVENTORY.md      - This document
```

---

## 🗂️ Directory Structure

```
open-hailo/
├── apps/                          # C++ examples
├── build/                         # Build artifacts
├── docs/                          # Documentation (8 files)
├── hailort/                       # HailoRT 4.20.0
│   ├── drivers/                   # PCIe drivers & firmware
│   └── runtime/                   # SDK source
├── hailort-5.1.1/                 # HailoRT 5.1.1 source (built)
├── hailort-drivers-5.1.1/         # Official drivers 5.1.1
├── hailort-drivers-official/      # Latest official drivers
├── logs/                          # Centralized logs
├── models/                        # YOLOv8 .hef models (3 files)
├── scripts/                       # Organized scripts (14 total)
│   ├── build/      (1 script)
│   ├── diagnostics/ (2 scripts)
│   ├── driver/     (2 scripts)
│   ├── frigate/    (3 scripts)
│   ├── preview/    (2 Python)
│   ├── setup/      (3 scripts)
│   └── utils/      (1 script)
├── test/                          # Test configurations
├── .venv/                         # Python virtual environment
├── demo.sh                        # Full demo launcher
├── demo_detection.sh              # Detection demo
├── hailo_yolov8_inference.json    # rpicam-apps config
├── run.sh                         # Run detection
├── setup.sh                       # Setup menu
├── test.sh                        # Run tests
└── test_detection.py              # Test script
```

---

## ⚙️ System Requirements

**Validated Configuration:**
- **OS**: Raspberry Pi OS Trixie (Debian 13)
- **Python**: 3.13+ (with PEP 668 externally-managed-environment)
- **Kernel**: 6.12.47+rpt-rpi-2712
- **Hardware**: Raspberry Pi 5 + Hailo-8 (PCIe) + OV5647 Camera
- **HailoRT**: 5.1.1 library, 4.23.0 driver
- **Firmware**: 4.23.0

---

## ❌ Scripts That DO NOT Exist

These were referenced in scripts/documentation but **have been removed/never existed**:

```
❌ scripts/setup/install_build_deps.sh        - Use: install_build_dependencies.sh
❌ scripts/setup/install_tappas_deps.sh       - Manual TAPPAS install
❌ scripts/setup/download_yolov8_models.sh    - Manual download from Hailo Zoo
❌ scripts/setup/build_hailort_driver.sh      - Use: scripts/driver/get_official_driver.sh
❌ scripts/setup/build_hailort_library.sh     - Manual: cd hailort-5.1.1/build && cmake/make
❌ scripts/setup/build_python_bindings.sh     - Manual: see docs/DEVELOPMENT.md
❌ scripts/quickstart/                        - Directory doesn't exist
❌ scripts/utils/run_test.sh                  - Use: ./test.sh
❌ scripts/utils/run_complete_test.sh         - Use: ./test.sh
```

**Action Required:** All script references have been updated to actual files or manual steps.

---

## 🎯 Quick Command Reference

### Setup
```bash
./setup.sh                                    # Interactive menu
./scripts/setup/install_build_dependencies.sh # Install deps
./scripts/driver/get_official_driver.sh       # Get driver
```

### Diagnostics
```bash
./scripts/diagnostics/check_version_compatibility.sh
./scripts/setup/verify_hailo_installation.sh
./scripts/utils/check_hailo_versions.sh
```

### Detection
```bash
./demo_detection.sh                           # Interactive demo
python3 scripts/preview/hailo_live_overlay.py # Real detection
python3 scripts/preview/hailo_preview_no_cv.py # Simulator
```

### Frigate
```bash
./scripts/frigate/install_frigate_native.sh
sudo systemctl start frigate
```

---

## 🔄 Version Matrix

| Component | Version | Status |
|-----------|---------|--------|
| OS | Debian 13 (Trixie) | ✅ |
| Python | 3.13.5 | ✅ |
| Kernel | 6.12.47+rpt-rpi-2712 | ✅ |
| HailoRT Library | 5.1.1 | ✅ Installed |
| HailoRT Driver | 4.23.0 | ⚠️ Version mismatch |
| Device Firmware | 4.23.0 | ✅ |
| GCC | 14 (Trixie default) | ⚠️ Compatibility issues |

**Note:** Version mismatch between driver (multiple versions) and library is the primary challenge on Trixie.

---

## 📝 Key Documentation Rules

1. **Always update existing docs** instead of creating new ones
2. **This inventory is authoritative** - scripts not listed here don't exist
3. **No script consolidation** - each script has a single, clear purpose
4. **Documentation must match reality** - verify before referencing scripts
5. **Trixie-specific** - all guidance assumes Debian 13, Python 3.13+

---

## 🚨 Known Issues & Status

### Working ✅
- Hardware detection (Hailo-8, camera)
- HailoRT 5.1.1 library installed
- Models downloaded (yolov8n, yolov8s, yolov8m)
- Camera capture working
- Frigate native installation (with Python 3.13 workarounds)

### Needs Attention ⚠️
- Driver version mismatch (multiple versions: 4.20.0, 4.23.0, 5.1.1)
- Python bindings installation (hailo_platform module)
- Real Hailo inference (currently using simulator)
- TAPPAS installation (Python 3.13 compatibility)

### Not Working ❌
- Real-time Hailo detection overlays (hailo_platform module issues)
- rpicam-apps with Hailo post-processing (TAPPAS dependency)

---

## 📊 Maintenance Log

| Date | Action | Result |
|------|--------|--------|
| 2025-01-13 | Audited all scripts | 14 scripts confirmed |
| 2025-01-13 | Updated docs/SETUP.md | Removed non-existent script refs |
| 2025-01-13 | Updated README.md | Accurate structure & counts |
| 2025-01-13 | Fixed setup.sh | Removed quickstart reference |
| 2025-01-13 | Fixed demo_detection.sh | Added venv, error handling |
| 2025-01-13 | Labeled Python scripts | Simulator vs Real detection |
| 2025-01-13 | Created this inventory | Authoritative reference |
| 2025-01-13 | Fixed fix_version_mismatch.sh | Removed build_hailort_*.sh refs |
| 2025-01-13 | Fixed verify_hailo_installation.sh | Replaced with manual steps |

---

**Last Updated:** 2025-01-13  
**Maintained By:** Project team + AI assistants  
**Purpose:** Eliminate documentation drift, ensure authoritative accuracy


