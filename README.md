# Open Hailo

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Raspberry%20Pi%205-red)](https://www.raspberrypi.org/)
[![Debian](https://img.shields.io/badge/Debian-13%20(Trixie)-blue)](https://www.debian.org/)

Open-source integration for Hailo AI HAT+ on Raspberry Pi 5 and modern Linux distributions.

## 🎯 Mission

Provide a fully open-source, transparent, and community-driven approach to using Hailo AI accelerators without proprietary dependencies or vendor lock-in.

## System Information

- **OS**: Debian 13 (Trixie)
- **Kernel**: 6.12.47+rpt-rpi-2712 aarch64
- **Hardware**: Raspberry Pi 5 with Hailo AI HAT+
- **PCIe Device**: 0001:01:00.0 Co-processor: Hailo Technologies Ltd. Hailo-8 AI Processor

## Project Structure

```
open-hailo/
├── build/      # Build artifacts
├── drivers/    # Kernel driver source
├── runtime/    # HailoRT library source
├── models/     # Model files and converters
├── apps/       # Custom applications
├── docs/       # Documentation
└── venv/       # Python virtual environment
```

## Build Dependencies Installed

- build-essential
- linux-headers-6.12.47+rpt-rpi-2712
- dkms
- pciutils
- pkg-config
- cmake
- gcc 14.2.0
- Python 3.13.5

## Build Process

### Phase 1: Environment Preparation ✓

Environment setup completed with all necessary build tools and directory structure.

### Phase 2: Kernel Driver Build & Installation ✓

Built and installed from source: <https://github.com/hailo-ai/hailort-drivers> (hailo8 branch)

- Compiled kernel module with current kernel headers
- Installed udev rules for device permissions
- Downloaded and installed firmware v4.23.0
- Successfully loaded driver - device available at `/dev/hailo0`

### Phase 3: HailoRT Runtime Compilation ✓

Built and installed from source: <https://github.com/hailo-ai/HailoRT> (hailo8 branch)

- Compiled libhailort.so and hailortcli using CMake
- Installed to /usr/local (library, headers, and CLI tool)
- Updated dynamic linker cache with ldconfig

### Phase 4: Device Validation ✓

- Successfully detected device using `hailortcli scan`
- Device identified as Hailo-8 with firmware v4.23.0
- Device node `/dev/hailo0` is accessible
- Note: Using HailoRT v4.20.0 (driver version) with firmware v4.23.0

### Phase 5: Test Application ✓

Created and successfully ran device_test application that:

- Detected the Hailo-8 device
- Retrieved device information (ID, architecture, firmware version)
- Allocated DMA buffer successfully
- Confirmed basic device connectivity and API functionality

### Phase 6: Model Pipeline & Documentation ✓

Documentation created:

- `docs/BUILD_GUIDE.md` - Complete build instructions for Debian 13
- `docs/MODEL_PIPELINE.md` - Model conversion and inference guide
- `build.sh` - Automated build script
- Test application demonstrating device connectivity

## Summary

Successfully implemented open-source Hailo AI HAT+ support on Debian 13:

- ✓ Built kernel driver from source (v4.20.0)
- ✓ Compiled HailoRT runtime library
- ✓ Validated device detection and basic operations
- ✓ Created reusable build automation
- ✓ Documented entire process for community

## Current Status & Limitations

### ✅ What Works
- Kernel driver built and loaded from source
- HailoRT runtime compiled and installed
- Device detection and basic validation
- DMA buffer allocation
- Full API access for inference

### ⚠️ What's Missing  
- **HEF Model Files**: Inference requires Hailo Executable Format (HEF) models
- **Model Conversion**: The Dataflow Compiler (DFC) for converting ONNX/TF to HEF is proprietary
- **Camera Integration**: Not yet implemented (waiting for model to test with)

### 📋 Next Steps
1. Obtain or convert HEF model files (see [docs/INFERENCE_API.md](docs/INFERENCE_API.md))
2. Test inference API with real models
3. Implement camera capture pipeline
4. Benchmark performance
5. Create end-to-end examples

This project demonstrates that the Hailo AI HAT+ **runtime and driver** can be built and used entirely with open-source tools on modern Linux distributions. Model conversion still requires Hailo's proprietary tools, but the inference runtime is fully open.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/open-hailo.git
cd open-hailo

# Run the automated build script
chmod +x build.sh
./build.sh

# Test the installation
cd apps/build
./device_test
```

## 📚 Documentation

- [Build Guide](docs/BUILD_GUIDE.md) - Detailed build instructions
- [Model Pipeline](docs/MODEL_PIPELINE.md) - Model deployment guide
- [Developer Guide](docs/DEVELOPER_GUIDE.md) - API reference and development workflow
- [Project Summary](docs/SUMMARY.md) - Achievement highlights and technical details
- [API Examples](apps/) - Sample applications (`simple_example.cpp`, `device_test.cpp`)

## 👨‍💻 For Developers

New to Hailo development? Start here:

```bash
# After running ./build.sh, try the simple example
cd apps/build
./simple_example  # Beginner-friendly introduction
./device_test     # Comprehensive device validation
```

**Key Resources:**
- [`simple_example.cpp`](apps/simple_example.cpp) - Perfect starting point for new contributors
- [`DEVELOPER_GUIDE.md`](docs/DEVELOPER_GUIDE.md) - API patterns and development workflow
- [`device_test.cpp`](apps/device_test.cpp) - Advanced API usage examples

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Areas of interest:

- Support for more Linux distributions
- Additional example applications
- Performance optimizations
- Model conversion tools
- Documentation improvements

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Hailo Technologies for open-sourcing kernel drivers and runtime
- Raspberry Pi Foundation for excellent hardware support
- The open-source community for continuous inspiration

## ⚠️ Disclaimer

This is an independent open-source project and is not officially affiliated with or endorsed by Hailo Technologies Ltd.
