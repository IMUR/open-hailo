# Developer Guide

## Architecture Overview

Open Hailo provides a clean, layered architecture for Hailo AI HAT+ integration:

```
┌─────────────────────────────────────┐
│        User Applications            │  ← Your code here
├─────────────────────────────────────┤
│        HailoRT C++ API             │  ← libhailort.so
├─────────────────────────────────────┤
│        Device Node (/dev/hailo0)   │  ← Kernel interface
├─────────────────────────────────────┤
│        Kernel Driver (hailo_pci)   │  ← PCIe communication
├─────────────────────────────────────┤
│        Hailo-8 Hardware            │  ← AI accelerator
└─────────────────────────────────────┘
```

## Key APIs and Patterns

### Device Initialization

```cpp
#include "hailo/hailort.hpp"
using namespace hailort;

// Create virtual device (container for physical devices)
auto vdevice = VDevice::create();
if (!vdevice) {
    // Handle error: vdevice.status()
    return -1;
}

// Get physical devices
auto devices = vdevice.value()->get_physical_devices();
for (auto& device_ref : devices.value()) {
    auto& device = device_ref.get();
    // Use device...
}
```

### Error Handling Pattern

HailoRT uses `Expected<T>` for error handling:

```cpp
auto result = device.some_operation();
if (result.has_value()) {
    auto value = result.value();
    // Success - use value
} else {
    auto status = result.status();
    // Handle error
}
```

### Memory Management

```cpp
// Allocate DMA buffer for optimal performance
size_t buffer_size = 1024 * 1024; // 1MB
auto buffer = Buffer::create_shared(buffer_size, 
                                   BufferStorageParams::create_dma());
if (buffer.has_value()) {
    // Use buffer->data(), buffer->size()
}
```

## Development Workflow

### 1. Environment Setup

```bash
# Install development dependencies
sudo apt install -y build-essential cmake git
sudo apt install -y linux-headers-$(uname -r) dkms pciutils pkg-config

# Clone and build the project
git clone https://github.com/your-username/open-hailo.git
cd open-hailo
./build.sh
```

### 2. Building Applications

```bash
cd apps
mkdir -p build && cd build
cmake ..
make
```

### 3. Testing Changes

```bash
# Test basic device functionality
./device_test

# Check driver status
sudo dmesg | grep hailo
lsmod | grep hailo

# Verify device detection
hailortcli scan
```

## Common Development Tasks

### Adding New Applications

1. Create new `.cpp` file in `apps/`
2. Update `apps/CMakeLists.txt`:

```cmake
add_executable(my_app my_app.cpp)
target_link_libraries(my_app PRIVATE HailoRT::libhailort)
```

### Debugging Tips

```bash
# Enable verbose driver logging
sudo modprobe -r hailo_pci
sudo modprobe hailo_pci dbg_level=5

# Monitor kernel messages
sudo journalctl -f | grep hailo

# Check PCIe link status
sudo lspci -vv -s $(lspci | grep Hailo | cut -d' ' -f1) | grep LnkSta
```

### Performance Optimization

1. **Use DMA buffers** for data transfer
2. **Pre-allocate memory** to avoid runtime allocation
3. **Batch operations** when possible
4. **Monitor temperature** during intensive workloads

## Contributing Areas

### High Priority
- **Model Examples**: Working inference examples with popular models
- **Performance Benchmarks**: Timing and throughput measurements
- **Cross-Platform Support**: Testing on other ARM64 systems
- **Python Bindings**: Python wrapper for the C++ API

### Medium Priority
- **CI/CD Pipeline**: Automated testing and builds
- **Docker Support**: Containerized development environment
- **Additional Platforms**: Support for other Hailo devices
- **Advanced Examples**: Multi-stream, batch processing demos

### Documentation
- **Tutorials**: Step-by-step application development guides
- **API Reference**: Detailed function documentation
- **Troubleshooting**: Common issues and solutions
- **Performance Guide**: Optimization best practices

## Project Standards

### Code Style
- **C++14 standard** minimum
- **4 spaces** for indentation
- **Meaningful names** for variables and functions
- **RAII patterns** for resource management
- **Error handling** for all API calls

### Testing
- **Device validation** must pass
- **Memory leak checks** with valgrind
- **Cross-compilation** testing when possible
- **Documentation updates** for new features

### Git Workflow
1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes and test thoroughly
4. Update documentation if needed
5. Submit pull request with clear description

## Resources

- **HailoRT Documentation**: `/usr/local/include/hailo/`
- **Hailo Community**: https://community.hailo.ai/
- **Device Specifications**: Check `hailortcli fw-control identify`
- **Kernel Driver Source**: `drivers/hailort-drivers/`
- **Runtime Source**: `runtime/hailort/`

## Getting Help

1. **Check existing issues** on GitHub
2. **Read the documentation** in `docs/`
3. **Test with device_test** to isolate problems
4. **Include system info** when reporting issues:
   - OS version and kernel
   - Hailo device model
   - Driver and firmware versions
   - Relevant log output

Happy coding! 🚀
