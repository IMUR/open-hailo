# Discovery Log: Semantic Approach to Open Hailo

## The Problem with Assumptions

Initial approach: Assume APIs and create examples.
**Better approach**: Discover what actually exists, document findings, build incrementally.

## What We Actually Discovered

### 1. Available Headers (v4.20.0)

```bash
$ ls /usr/local/include/hailo/
buffer.hpp                  hef.hpp                network_group.hpp
device.hpp                  hailort.h              quantization.hpp
dma_mapped_buffer.hpp       hailort.hpp            runtime_statistics.hpp
event.hpp                   hailort_common.hpp     stream.hpp
expected.hpp                hailort_defaults.hpp   transform.hpp
hailo_gst_tensor_metadata.hpp  hailort_dma-heap.h  vdevice.hpp
hailo_session.hpp           infer_model.hpp        vstream.hpp
inference_pipeline.hpp      network_rate_calculator.hpp
```

**Key finding**: Full inference API is present and accessible.

### 2. Actual Inference Pattern

From examining `hailort/libhailort/examples/cpp/vstreams_example/`:

```cpp
// Pattern discovered from actual working code:
VDevice::create() 
  -> Hef::create("model.hef")
  -> vdevice.create_configure_params(hef)
  -> vdevice.configure(hef, params)
  -> network_group.make_input/output_vstream_params()
  -> VStreamsBuilder::create_input/output_vstreams()
  -> vstream.write() / vstream.read()
```

**Not assumed - verified in source code**.

### 3. Camera Hardware (Raspberry Pi 5)

```bash
$ v4l2-ctl --list-devices
rp1-cfe (platform:1f00128000.csi):
    /dev/video0-7      # Camera Serial Interface
pispbe (platform:1000880000.pisp_be):
    /dev/video20-35    # Pi Image Signal Processor
```

**Key finding**: Hardware support exists, driver loaded, devices present.

### 4. What's Actually Missing

#### HEF Model Files
- Runtime: ✅ Built and working
- Driver: ✅ Loaded successfully
- Device: ✅ Detected and accessible
- Models: ❌ **No HEF files available yet**

#### The Bottleneck
Model conversion requires Hailo Dataflow Compiler (DFC), which is:
- Proprietary (not open-source)
- Available in Docker containers
- Can convert ONNX/TF models to HEF

### 5. Examples Found in Source

Located in `runtime/hailort/hailort/libhailort/examples/cpp/`:

```
✓ vstreams_example           - Virtual streams (high-level)
✓ raw_streams_example        - Raw streams (low-level)
✓ async_infer_basic_example  - Asynchronous inference
✓ infer_pipeline_example     - Pipeline API
✓ multi_network_example      - Multi-network execution
```

All use `HEF_FILE` constant pointing to `hefs/shortcut_net.hef`.

## The Semantic Discovery Process

### Step 1: Check What Headers Exist
```bash
ls -la /usr/local/include/hailo/
cat /usr/local/include/hailo/vstream.hpp
```

### Step 2: Find Working Examples
```bash
cd runtime/hailort/hailort/libhailort/examples
grep -r "Hef::create" --include="*.cpp" .
```

### Step 3: Validate Hardware Access
```bash
v4l2-ctl --list-devices
lspci | grep Hailo
ls -la /dev/hailo*
```

### Step 4: Test Incrementally
```cpp
// Start with what works (device_test.cpp):
auto vdevice = VDevice::create();  // ✓ Works
auto devices = vdevice->get_physical_devices();  // ✓ Works
auto buffer = Buffer::create_shared(size, ...);  // ✓ Works

// Next step (needs HEF file):
auto hef = Hef::create("model.hef");  // ⏳ Need model file
```

## Lessons Learned

### ✅ Do This
1. Examine actual installed headers
2. Read working example code
3. Test hardware access directly
4. Build incrementally, one API call at a time
5. Document what actually exists

### ❌ Don't Do This
1. Assume API patterns without checking
2. Write code based on documentation alone
3. Create examples that can't be tested
4. Hide limitations or requirements

## Current Status

### What We Can Demonstrate
- ✅ Device detection and validation
- ✅ DMA buffer allocation
- ✅ Hardware access working
- ✅ API patterns understood and documented
- ✅ Camera hardware present and accessible

### What We Need to Complete
- ⏳ Obtain HEF model file(s)
- ⏳ Test actual inference
- ⏳ Implement camera capture
- ⏳ Create end-to-end pipeline

## Next Steps (In Order)

### 1. Obtain HEF Model
Options:
- Check hailo-rpi5-examples repo for pre-converted models
- Request test model from Hailo community
- Use Hailo Docker container to convert ONNX model
- Find community-shared models

### 2. Test Inference with Dummy Data
```cpp
// Once we have model.hef:
simple_inference model.hef  // Should complete successfully
```

### 3. Add Camera Capture
```cpp
// V4L2 or libcamera integration
// Capture frame -> Preprocess -> Inference -> Postprocess
```

### 4. Benchmark and Optimize
- Measure inference latency
- Test batch processing
- Compare with CPU/GPU baselines

## Repository State

```
open-hailo/
├── README.md                    # Honest about current status
├── docs/
│   ├── BUILD_GUIDE.md          # Complete build instructions
│   ├── MODEL_PIPELINE.md       # Model deployment (future)
│   ├── INFERENCE_API.md        # API patterns discovered ✓
│   └── DISCOVERY_LOG.md        # This file ✓
└── apps/
    ├── device_test.cpp         # Works, tested ✓
    └── simple_inference_example.cpp  # Ready, needs HEF ⏳
```

## Conclusion

**We successfully built and validated the runtime/driver stack.**

The missing piece is not code or capability—it's **model files** (HEF format).

This discovery-first approach:
- Prevented wasted effort on wrong API assumptions
- Identified the actual bottleneck (models, not code)
- Produced honest, testable documentation
- Set realistic expectations for contributors

**The open-source foundation is solid. Now we need content (models) to run on it.**
