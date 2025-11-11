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

# Rebuild only the driver (after kernel updates)
cd drivers/hailort-drivers/linux/pcie
make clean && make all && sudo make install
sudo modprobe -r hailo_pci && sudo modprobe hailo_pci

# Build test applications
cd apps
mkdir -p build && cd build
cmake ..
make -j$(nproc)

# Build a single application
make device_test

# Available test applications:
# - device_test: Basic device connectivity test (no model required)
# - simple_example: Device enumeration and capabilities
# - simple_inference_example: Full inference pipeline (requires HEF model)

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
# Run basic device tests (no model required)
cd apps/build
./device_test           # Test device connectivity, temperature, power
./simple_example        # Enumerate devices and capabilities

# Run inference test (requires HEF model)
./simple_inference_example model.hef

# Check temperature and power
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
3. Inference pipeline: HEF → NetworkGroup → VStreams → Device → Results

Full inference workflow (`apps/simple_inference_example.cpp`):
```cpp
// 1. Load HEF model
auto hef = Hef::create("model.hef");

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

## Python Environment

A Python virtual environment is available at `venv/`:
```bash
# Activate virtual environment
source venv/bin/activate

# Install Python bindings (if available)
pip install hailort
```

Note: Python bindings may require separate installation from Hailo's package repository.

## File Locations

- Kernel module: `/lib/modules/$(uname -r)/extra/hailo_pci.ko`
- Firmware: `/lib/firmware/hailo/hailo8_fw.bin`
- Udev rules: `/etc/udev/rules.d/51-hailo-udev.rules`
- Device node: `/dev/hailo0` (created dynamically)