# HailoRT Inference API - Discovered Patterns

## What We Have

Based on exploration of the built HailoRT v4.20.0 and examples:

### Available Headers
```
/usr/local/include/hailo/
├── hef.hpp                  # HEF model loading
├── vdevice.hpp              # Virtual device management
├── network_group.hpp        # Network configuration
├── vstream.hpp              # Virtual streams for I/O
├── stream.hpp               # Raw streams
├── infer_model.hpp          # High-level inference API
├── inference_pipeline.hpp   # Pipeline management
└── device.hpp               # Low-level device access
```

### Inference API Pattern (from vstreams_example.cpp)

```cpp
#include "hailo/hailort.hpp"

using namespace hailort;

// 1. Create VDevice
auto vdevice = VDevice::create();

// 2. Load HEF (Hailo Executable Format) model
auto hef = Hef::create("model.hef");

// 3. Create configuration parameters
auto configure_params = vdevice->create_configure_params(hef.value());

// 4. Configure network group
auto network_groups = vdevice->configure(hef.value(), configure_params.value());
auto network_group = network_groups->at(0);

// 5. Create input/output vstream parameters
auto input_vstream_params = network_group->make_input_vstream_params(
    {},                              // default settings
    HAILO_FORMAT_TYPE_AUTO,         // auto format conversion
    HAILO_DEFAULT_VSTREAM_TIMEOUT_MS,
    HAILO_DEFAULT_VSTREAM_QUEUE_SIZE
);

auto output_vstream_params = network_group->make_output_vstream_params(
    {},
    HAILO_FORMAT_TYPE_AUTO,
    HAILO_DEFAULT_VSTREAM_TIMEOUT_MS,
    HAILO_DEFAULT_VSTREAM_QUEUE_SIZE
);

// 6. Create input/output vstreams
auto input_vstreams = VStreamsBuilder::create_input_vstreams(
    *network_group, input_vstream_params.value()
);

auto output_vstreams = VStreamsBuilder::create_output_vstreams(
    *network_group, output_vstream_params.value()
);

// 7. Run inference
std::vector<uint8_t> input_data(input_vstreams->at(0).get_frame_size());
// ... fill input_data with your data ...

input_vstreams->at(0).write(MemoryView(input_data.data(), input_data.size()));

std::vector<uint8_t> output_data(output_vstreams->at(0).get_frame_size());
output_vstreams->at(0).read(MemoryView(output_data.data(), output_data.size()));
```

## The Missing Piece: HEF Models

**Current Status**: We have the runtime and API, but no HEF models to run.

### Options to Get HEF Models

1. **Hailo Model Zoo (Requires DFC)**
   - Hailo Dataflow Compiler is proprietary
   - Available via Hailo Docker containers
   - Can convert ONNX/TF models to HEF

2. **Pre-compiled Models**
   - Check Hailo RPi5 Examples: `https://github.com/hailo-ai/hailo-rpi5-examples`
   - Community-shared models
   - Hailo Model Zoo pre-converted models

3. **Test with Minimal Model**
   - Request a simple test HEF from Hailo community
   - Use their example HEF files (if available)

## Camera Access on Raspberry Pi 5

### Available Devices
```bash
# Camera Sensor Interface (CSI)
/dev/video0-7    # rp1-cfe (Camera Front End)

# Image Signal Processor
/dev/video20-35  # pispbe (Pi ISP Backend)
```

### Capture Test
```bash
# Test camera capture
v4l2-ctl -d /dev/video0 --list-formats-ext

# Capture a single frame
v4l2-ctl -d /dev/video0 --stream-mmap --stream-count=1 --stream-to=test.raw
```

### Camera Libraries Available
```bash
# Check what's installed
pkg-config --list-all | grep -E "camera|v4l"
ldconfig -p | grep -E "camera|v4l"
```

## Next Steps for MVP

### Immediate (What We Can Do Now)

1. ✅ Device detection and validation (DONE)
2. ✅ DMA buffer allocation (DONE)
3. ✅ Device info retrieval (DONE)

### Requires HEF Model

4. ⏳ Load and configure a network from HEF
5. ⏳ Perform inference on dummy data
6. ⏳ Benchmark inference performance

### Full Pipeline (Camera + Inference)

7. ⏳ Camera frame capture (V4L2 or libcamera)
8. ⏳ Frame preprocessing
9. ⏳ Inference on camera frames
10. ⏳ Post-processing and display

## Example Applications in HailoRT Source

Located in `/home/crtr/Projects/open-hailo/runtime/hailort/hailort/libhailort/examples/cpp/`:

- `vstreams_example/` - Virtual streams (recommended)
- `raw_streams_example/` - Lower-level stream API
- `async_infer_basic_example/` - Asynchronous inference
- `infer_pipeline_example/` - High-level pipeline API
- `multi_network_vstream_example/` - Multi-network execution

## Semantic Discovery Commands

```bash
# Find what examples actually compile and work
cd /home/crtr/Projects/open-hailo/runtime/hailort/build
grep -r "add_subdirectory.*example" ../hailort/libhailort/examples/CMakeLists.txt

# Check if example HEF files exist anywhere
locate "*.hef" 2>/dev/null

# See actual API usage patterns
cd /home/crtr/Projects/open-hailo/runtime/hailort
grep -r "Hef::create" --include="*.cpp" hailort/libhailort/examples/
```

## Recommended Approach

1. **Get a test HEF file** from:
   - Hailo community forum
   - Hailo RPi5 examples repository
   - Hailo support channels

2. **Start with simplest inference**:
   - Load HEF
   - Configure network
   - Run inference on dummy data (zeros/random)
   - Verify output shape and values

3. **Add camera later**:
   - First prove inference works
   - Then add real data input
   - Optimize the pipeline

## Current Limitation

**We cannot proceed with actual inference examples until we have a HEF model file.**

The next commit should focus on documenting:
- How to obtain HEF files
- How to use Hailo's tools to convert models
- Community resources for pre-converted models
