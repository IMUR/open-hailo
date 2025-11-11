# Hailo Inference API Documentation

## Overview

This document provides the complete inference API workflow discovered through source code exploration and testing. All patterns are based on actual HailoRT source examples and working code.

## API Workflow

The complete inference pipeline follows this pattern:

```
VDevice::create() → Hef::create() → configure() → VStreams → inference
```

## Step-by-Step API Usage

### 1. Device Creation

```cpp
#include "hailo/hailort.hpp"
using namespace hailort;

// Create virtual device container
auto vdevice = VDevice::create();
if (!vdevice) {
    // Handle error: vdevice.status()
}
```

### 2. Model Loading (HEF Files)

```cpp
// Load Hailo Executable Format model
auto hef = Hef::create("path/to/model.hef");
if (!hef) {
    // Handle error: hef.status()
}
```

**HEF File Requirements:**
- Models must be in Hailo Executable Format (HEF)
- Created using Hailo's Dataflow Compiler (DFC) - proprietary tool
- Cannot be created with open-source tools (current limitation)

### 3. Device Configuration

```cpp
// Create configuration parameters
auto configure_params = hef->create_configure_params(HAILO_STREAM_INTERFACE_PCIE);
if (!configure_params) {
    // Handle error
}

// Configure device with the model
auto network_groups = vdevice.value()->configure(hef.value(), configure_params.value());
if (!network_groups || network_groups->empty()) {
    // Handle error
}

auto& network_group = network_groups->at(0);
```

### 4. Stream Creation

```cpp
// Create input stream parameters
auto input_vstreams_params = hef->make_input_vstream_params(
    network_group, 
    HAILO_FORMAT_TYPE_AUTO,
    HAILO_DEFAULT_VSTREAM_TIMEOUT_MS, 
    HAILO_DEFAULT_VSTREAM_QUEUE_SIZE
);

// Create output stream parameters  
auto output_vstreams_params = hef->make_output_vstream_params(
    network_group,
    HAILO_FORMAT_TYPE_AUTO,
    HAILO_DEFAULT_VSTREAM_TIMEOUT_MS,
    HAILO_DEFAULT_VSTREAM_QUEUE_SIZE
);

// Create actual streams
auto input_vstreams = VStreamsBuilder::create_input_vstreams(
    network_group, 
    input_vstreams_params.value()
);

auto output_vstreams = VStreamsBuilder::create_output_vstreams(
    network_group, 
    output_vstreams_params.value()
);
```

### 5. Data Preparation

```cpp
// Get input requirements
auto& input_stream = input_vstreams->at(0);
auto input_info = input_stream.get_info();

// Calculate input size
size_t input_size = input_info.shape.width * 
                   input_info.shape.height * 
                   input_info.shape.features;

// Prepare your input data (image, sensor data, etc.)
std::vector<uint8_t> input_data(input_size);
// ... fill with actual data ...

// Prepare output buffers
std::vector<std::vector<uint8_t>> output_buffers;
for (auto& output_stream : output_vstreams.value()) {
    auto output_info = output_stream.get_info();
    size_t output_size = output_info.shape.width * 
                        output_info.shape.height * 
                        output_info.shape.features;
    output_buffers.emplace_back(output_size);
}
```

### 6. Inference Execution

```cpp
// Write input data to device
auto write_status = input_stream.write(
    MemoryView(input_data.data(), input_data.size())
);
if (HAILO_SUCCESS != write_status) {
    // Handle error
}

// Read output data from device
for (size_t i = 0; i < output_vstreams->size(); i++) {
    auto& output_stream = output_vstreams->at(i);
    auto read_status = output_stream.read(
        MemoryView(output_buffers[i].data(), output_buffers[i].size())
    );
    if (HAILO_SUCCESS != read_status) {
        // Handle error
    }
}
```

## Key Data Structures

### Stream Information

```cpp
auto info = stream.get_info();
// info.name - stream name
// info.shape.width - input/output width
// info.shape.height - input/output height  
// info.shape.features - number of channels/features
```

### Memory Management

```cpp
// Use MemoryView for zero-copy data transfer
MemoryView input_view(data_ptr, data_size);
stream.write(input_view);

// Or use Buffer for DMA-optimized transfers
auto buffer = Buffer::create_shared(size, BufferStorageParams::create_dma());
```

## Model Information Discovery

### Getting Model Details

```cpp
// Inspect input requirements
for (auto& stream : input_vstreams.value()) {
    auto info = stream.get_info();
    std::cout << "Input: " << info.name 
              << " [" << info.shape.width 
              << "x" << info.shape.height 
              << "x" << info.shape.features << "]" << std::endl;
}

// Inspect output format
for (auto& stream : output_vstreams.value()) {
    auto info = stream.get_info();
    std::cout << "Output: " << info.name 
              << " [" << info.shape.width 
              << "x" << info.shape.height 
              << "x" << info.shape.features << "]" << std::endl;
}
```

## Performance Considerations

### Optimization Tips

1. **Pre-allocate Buffers**: Create buffers once, reuse for multiple inferences
2. **Use DMA Buffers**: `BufferStorageParams::create_dma()` for best performance
3. **Batch Processing**: Process multiple inputs when model supports it
4. **Stream Management**: Keep streams alive for multiple inferences

### Timing Measurements

```cpp
auto start = std::chrono::high_resolution_clock::now();
// ... inference code ...
auto end = std::chrono::high_resolution_clock::now();
auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
```

## Error Handling Patterns

### Expected<T> Pattern

```cpp
auto result = some_hailo_operation();
if (result.has_value()) {
    auto value = result.value();
    // Success - use value
} else {
    auto status = result.status();
    // Handle error based on status
}
```

### Status Codes

```cpp
auto status = some_operation();
if (HAILO_SUCCESS == status) {
    // Success
} else {
    // Handle specific error codes:
    // HAILO_TIMEOUT, HAILO_INVALID_OPERATION, etc.
}
```

## Model Sources

### Where to Get HEF Models

1. **Hailo Model Zoo**: https://github.com/hailo-ai/hailo_model_zoo
2. **Hailo Community Examples**: Check community repositories
3. **Convert Your Own**: Use Hailo Dataflow Compiler (DFC) - requires Hailo account
4. **Pre-converted Models**: Some community members share HEF files

### Model Conversion (Proprietary)

```bash
# This requires Hailo's DFC tool (not open-source)
hailo compiler compile --ckpt model.onnx --output model.hef
```

## Hardware Integration

### Camera Integration (V4L2)

```cpp
// Discovered hardware:
// /dev/video0-7   - Camera Serial Interface
// /dev/video20-35 - Pi Image Signal Processor

// Example V4L2 capture (pseudo-code):
int fd = open("/dev/video0", O_RDWR);
// ... V4L2 setup ...
// ... capture frame ...
// ... convert to model input format ...
// ... run inference ...
```

### Device Capabilities

```cpp
// Check what's available
auto devices = vdevice.value()->get_physical_devices();
for (auto& device_ref : devices.value()) {
    auto& device = device_ref.get();
    
    // Get device info
    auto identity = device.identify();
    if (identity.has_value()) {
        std::cout << "Device: " << identity->board_name << std::endl;
        std::cout << "Firmware: " << (int)identity->fw_version.major << "."
                  << (int)identity->fw_version.minor << "."
                  << (int)identity->fw_version.revision << std::endl;
    }
    
    // Check temperature
    auto temp = device.get_chip_temperature();
    if (temp.has_value()) {
        std::cout << "Temperature: " << temp->ts0_temperature << "°C" << std::endl;
    }
}
```

## Complete Working Example

See [`simple_inference_example.cpp`](../apps/simple_inference_example.cpp) for a complete, runnable example that demonstrates all these concepts.

## Limitations & Next Steps

### Current Limitations

- **HEF Models Required**: No open-source model conversion available
- **Proprietary DFC**: Model conversion requires Hailo's tools
- **Model Availability**: Limited public HEF model repositories

### Future Development

1. **Get HEF Models**: Obtain models from Hailo Model Zoo or community
2. **Camera Integration**: Add V4L2 capture pipeline
3. **Performance Benchmarking**: Measure real inference speeds
4. **End-to-End Examples**: Complete vision pipeline examples
5. **Model Optimization**: Explore quantization and optimization techniques

## Resources

- **HailoRT Headers**: `/usr/local/include/hailo/`
- **Examples in Source**: `runtime/hailort/libhailort/examples/`
- **Hailo Community**: https://community.hailo.ai/
- **Model Zoo**: https://github.com/hailo-ai/hailo_model_zoo
- **Documentation**: HailoRT API documentation

This API documentation is based on actual source code exploration and represents the real, working patterns for Hailo inference on open-source systems.