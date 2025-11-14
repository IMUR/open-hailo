# Documentation

Welcome to the open-hailo documentation!

## Quick Navigation

### 🚀 Getting Started

New to Hailo-8 on Raspberry Pi? Start here:

- **[Quick Start](getting-started/quickstart.md)** ⭐ Get running in 15-30 minutes
- **[Complete Setup Guide](getting-started/setup-details.md)** - Detailed step-by-step
- **[Hardware Compatibility](getting-started/hardware.md)** - Pi models, cameras, specs
- **[Model Compatibility](getting-started/models.md)** - Understanding HEF page sizes

### 🎯 Deployment Guides

Choose your deployment method:

- **[rpicam-apps](deployments/rpicam.md)** ⭐ Recommended - works with any models
- **[Python Direct API](deployments/python-direct.md)** - Custom applications
- **[Frigate NVR](deployments/frigate.md)** - Video surveillance system
- **[TAPPAS Pipelines](deployments/tappas.md)** - GStreamer (under development)
- **[OpenCV Custom](deployments/opencv-custom.md)** - Advanced pipelines

### 🔧 Development

Building or extending the system:

- **[Build Guide](development/build.md)** - Compile from source
- **[API Reference](development/api.md)** - HailoRT APIs
- **[Development Guide](development/development-guide.md)** - Project structure & workflow
- **[Contributing](development/contributing.md)** - How to contribute
- **[Install Dependencies](development/install-deps.md)** - Development dependencies

### 🔨 Operations

Running and maintaining the system:

- **[Troubleshooting](operations/troubleshooting.md)** - Problem solving guide

### 📎 Appendices

- **[Claude AI Notes](appendices/claude.md)** - AI assistant guidance

---

## Recommended Reading Paths

### For New Users

1. [Quick Start](getting-started/quickstart.md) - Get running fast
2. [rpicam Deployment](deployments/rpicam.md) - Easiest path
3. [Troubleshooting](operations/troubleshooting.md) - If issues arise

### For Developers

1. [API Reference](development/api.md) - Learn the API
2. [Development Guide](development/development-guide.md) - Project structure
3. [Build Guide](development/build.md) - Compile from source
4. [Contributing](development/contributing.md) - Join the project

### For Operators (Frigate/NVR)

1. [Frigate Deployment](deployments/frigate.md) - Setup NVR
2. [Hardware Compatibility](getting-started/hardware.md) - Storage requirements
3. [Troubleshooting](operations/troubleshooting.md) - Common issues

### For Python Developers

1. [Python Direct Deployment](deployments/python-direct.md) - Requirements
2. [Model Compatibility](getting-started/models.md) - Page size issue
3. [API Reference](development/api.md) - Python API details

---

## External Resources

- **Hailo Developer Zone:** https://hailo.ai/developer-zone/
- **Hailo Model Zoo:** https://github.com/hailo-ai/hailo_model_zoo
- **Hailo Community:** https://community.hailo.ai
- **TAPPAS:** https://github.com/hailo-ai/tappas
- **Raspberry Pi Cameras:** https://www.raspberrypi.com/documentation/computers/camera_software.html

---

## Documentation Structure

```
docs/
├── README.md (you are here)
├── getting-started/
│   ├── quickstart.md
│   ├── setup-details.md
│   ├── hardware.md
│   └── models.md
├── deployments/
│   ├── rpicam.md
│   ├── python-direct.md
│   ├── frigate.md
│   ├── tappas.md
│   └── opencv-custom.md
├── development/
│   ├── api.md
│   ├── build.md
│   ├── development-guide.md
│   ├── contributing.md
│   └── install-deps.md
├── operations/
│   └── troubleshooting.md
└── appendices/
    └── claude.md
```

---

**Everything you need to get Hailo-8 working on Raspberry Pi OS Trixie!** 🎯
