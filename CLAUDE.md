# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Open Hailo is an open-source integration for the Hailo AI HAT+ accelerator on Raspberry Pi 5, focusing on Debian 13 (Trixie) support. The project builds the Hailo kernel driver and runtime library from source, providing a fully transparent, vendor-lock-in-free approach to AI acceleration.

**Key Technologies:**
- Hailo-8 AI Processor (PCIe device: 0001:01:00.0)
- HailoRT C++ API (v4.20.0)
- Kernel module: hailo_pci
- Device node: /dev/hailo0

## Build Commands

```bash
# Full automated build (builds driver, runtime, and test apps)
./build.sh

# Build test application only
cd apps
mkdir -p build && cd build
cmake ..
make

# Run device test
./device_test

# Verify device detection
hailortcli scan
hailortcli fw-control identify

# Check device status
lspci | grep Hailo
ls -la /dev/hailo*
sudo dmesg | grep hailo
```

## Testing Commands

```bash
# Run the C++ device test (no model required)
cd apps/build
./device_test

# Check temperature and power (if supported)
hailortcli measure power
hailortcli measure temp

# Monitor kernel module
lsmod | grep hailo
sudo modprobe -r hailo_pci  # Unload
sudo modprobe hailo_pci      # Load
```

## Architecture

### Component Hierarchy
```
User Application (C++)
        ↓
HailoRT API (libhailort.so)
        ↓
Device Node (/dev/hailo0)
        ↓
Kernel Driver (hailo_pci.ko)
        ↓
PCIe Hardware (Hailo-8)
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

- **Kernel Driver** (`drivers/hailort-drivers/`): Manages PCIe communication, DMA transfers, and device initialization
- **Firmware** (`hailo8_fw.4.23.0.bin`): Loaded by driver at device initialization, controls on-chip operations
- **Runtime** (`runtime/hailort/`): User-space library providing high-level API for inference and device control
- **Version Alignment**: Driver and runtime should match versions (v4.20.0), firmware can be newer

### Model Pipeline Architecture

Models must be converted to HEF (Hailo Executable Format) before inference:
1. Source formats: ONNX, TensorFlow, PyTorch (via ONNX)
2. Conversion tool: Hailo Dataflow Compiler (proprietary, not included)
3. Inference: HEF → VStreams → Device → Results

### Build System

The project uses a two-stage CMake build:
1. **HailoRT library**: Built in `runtime/hailort/build/` with Release configuration
2. **Applications**: Built in `apps/build/` linking against installed HailoRT

Critical paths:
- Headers: `/usr/local/include/hailo/`
- Library: `/usr/local/lib/libhailort.so`
- CLI tool: `/usr/local/bin/hailortcli`

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

## Known Limitations

1. **Model Conversion**: Requires proprietary Hailo Dataflow Compiler (not open-source)
2. **Firmware**: Binary blob required (hailo8_fw.bin), cannot be built from source
3. **Advanced Features**: Some profiling and optimization features require proprietary tools
4. **Documentation**: Limited public documentation for low-level driver interfaces

## Debugging Tips

```bash
# Enable verbose driver logging
sudo modprobe hailo_pci dbg_level=5

# Check for firmware loading issues
sudo journalctl -u systemd-modules-load | grep hailo

# Verify PCIe link status (should be Gen3)
sudo lspci -vv -s $(lspci | grep Hailo | cut -d' ' -f1) | grep LnkSta

# Monitor device during operations
watch -n 1 'hailortcli measure temp'
```

## File Locations

- Kernel module: `/lib/modules/$(uname -r)/extra/hailo_pci.ko`
- Firmware: `/lib/firmware/hailo/hailo8_fw.bin`
- Udev rules: `/etc/udev/rules.d/51-hailo-udev.rules`
- Device node: `/dev/hailo0` (created dynamically)