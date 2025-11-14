# Essential Scripts

## 🎯 Simplified Structure (14 scripts total)

```
scripts/
├── build/                    # 1 script
│   └── build_hailo_preview_local.sh
├── driver/                   # 2 scripts  
│   ├── get_official_driver.sh
│   └── install_official_driver.sh
├── frigate/                  # 3 scripts
│   ├── install_frigate_native.sh
│   ├── fix_frigate_install.sh
│   └── setup_frigate_caddy.sh
├── preview/                  # 2 scripts
│   ├── hailo_live_overlay.py
│   └── hailo_preview_no_cv.py
├── setup/                    # 3 scripts
│   ├── install_build_dependencies.sh
│   ├── verify_hailo_installation.sh
│   └── fix_version_mismatch.sh
├── diagnostics/              # 2 scripts
│   ├── check_version_compatibility.sh
│   └── reset_camera.sh
└── utils/                    # 1 script
    └── check_hailo_versions.sh
```

## Quick Reference

### 🚀 Getting Started
```bash
# From project root:
./setup.sh              # Interactive setup menu
./test.sh               # Run tests
./run.sh                # Start detection
```

### 📦 Installation
```bash
scripts/setup/install_build_dependencies.sh    # Install deps
scripts/driver/get_official_driver.sh          # Get driver
scripts/frigate/install_frigate_native.sh      # Install Frigate
```

### 🔍 Troubleshooting
```bash
scripts/diagnostics/check_version_compatibility.sh  # Check versions
scripts/setup/verify_hailo_installation.sh         # Verify install
scripts/diagnostics/reset_camera.sh                # Fix camera
```

### 🎥 Running Detection
```bash
scripts/preview/hailo_live_overlay.py     # With OpenCV
scripts/preview/hailo_preview_no_cv.py    # Without OpenCV
```

## Essential Scripts Only

Each script has a clear, single purpose. No redundancy.