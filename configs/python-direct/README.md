# Python Direct API Configuration

Direct Python API access to Hailo-8 for custom AI applications.

## ⚠️ Important: Model Compatibility

This configuration requires **4KB page size HEF models** specifically compiled for Raspberry Pi 5.

**Current Status:** The existing models in `../../models/x86-models/` have 16KB page size and will **NOT work** with this configuration.

### Error You'll See with Wrong Models:
```
[HailoRT] [error] CHECK failed - max_desc_page_size given 16384 is bigger than hw max desc page size 4096
HAILO_INTERNAL_FAILURE(8)
```

## Prerequisites

- Raspberry Pi 5
- Hailo-8 PCIe module installed
- HailoRT 4.23.0 (driver + library)
- Python 3.13+ with virtual environment
- **Pi-compatible HEF models (4KB page size)**

## When to Use This Configuration

Choose Python Direct API when you need:

- ✅ **Custom detection pipelines** - Full control over inference flow
- ✅ **Integration with existing Python apps** - Add Hailo to your codebase
- ✅ **Pre/post-processing flexibility** - Custom image preparation and result handling
- ✅ **Multiple model management** - Load/switch models dynamically
- ✅ **Advanced use cases** - Multi-threaded inference, model ensembles, etc.

## When NOT to Use This

Consider alternatives if:

- ❌ **You don't have Pi-compatible models** → Use `configs/rpicam/` instead
- ❌ **You just want live camera detection** → Use `configs/rpicam/` (simpler)
- ❌ **You're building a video surveillance system** → Use `configs/frigate/` (purpose-built)

## Installation

```bash
cd open-hailo
./configs/python-direct/install.sh
```

This will:
1. Verify HailoRT installation
2. Create/activate Python virtual environment
3. Install required Python packages
4. Verify `hailo_platform` module works
5. Check for compatible models

## Getting Pi-Compatible Models

### Option 1: Hailo Model Zoo (Recommended)
Download pre-compiled models:
```bash
cd models/pi5-compatible
# Check Hailo's official model zoo for Pi-compatible versions
wget https://hailo-model-zoo.s3.amazonaws.com/ModelZoo/compiled/v2.12.0/hailo8/yolov8s_pi5.hef
```

### Option 2: Compile Your Own
If you have access to Hailo Dataflow Compiler:
```bash
hailo compile model.onnx --page-size 4096 -o model_pi5.hef
```

### Option 3: Request from Community
Check the Hailo community forum:
- https://community.hailo.ai

## Quick Start

### 1. Activate Environment
```bash
cd open-hailo
source .venv/bin/activate
```

### 2. Test Hailo Platform
```python
from hailo_platform import VDevice

vd = VDevice()
devices = vd.get_physical_devices()
print(f"Found {len(devices)} Hailo device(s)")
# Output: Found 1 Hailo device(s)
```

### 3. Run Detection (with compatible model)
```bash
# Edit examples/live_detection.py to point to your Pi-compatible model
python configs/python-direct/examples/live_detection.py
```

## Examples

See `examples/` directory:

- `live_detection.py` - Real-time camera detection with overlays
- `image_inference.py` - Process single images
- `video_inference.py` - Process video files
- `simulator_mode.py` - Test camera without Hailo (no inference)

## Python API Overview

### Basic Inference Flow

```python
from hailo_platform import HEF, VDevice, ConfigureParams, InferVStreams
import numpy as np

# 1. Create device
vdevice = VDevice()

# 2. Load HEF model (MUST be 4KB page size!)
hef = HEF("models/pi5-compatible/yolov8s_pi5.hef")

# 3. Configure network
configure_params = ConfigureParams.create_from_hef(hef, interface=HailoStreamInterface.PCIe)
network_group = vdevice.configure(hef, configure_params)[0]

# 4. Create input/output streams
with InferVStreams(network_group, network_group.get_input_vstream_infos(), 
                    network_group.get_output_vstream_infos()) as infer_pipeline:
    
    # 5. Prepare input data (640x640x3 for YOLOv8)
    input_data = np.random.randn(640, 640, 3).astype(np.uint8)
    
    # 6. Run inference
    results = infer_pipeline.infer({input_name: input_data})
    
    # 7. Process results
    for output_name, output_data in results.items():
        print(f"{output_name}: {output_data.shape}")
```

## Performance Tuning

### Batch Size
```python
# Process multiple frames at once
configure_params.batch_size = 4  # Process 4 frames per inference
```

### Threading
```python
# Enable multi-threaded inference
infer_pipeline = InferVStreams(
    network_group, 
    input_vstream_info,
    output_vstream_info,
    mode=InferMode.ASYNC  # Asynchronous inference
)
```

### Power Mode
```python
# Set power mode
vdevice.set_power_measurement(PowerMeasurementTypes.AUTO)
```

## Troubleshooting

### "No module named 'hailo_platform'"

Python bindings not installed:
```bash
cd hailort/hailort-4.23.0/hailort/libhailort/bindings/python/platform
source .venv/bin/activate
python setup.py install
```

### "HAILO_INTERNAL_FAILURE(8)" or "max_desc_page_size" Error

Your HEF model has 16KB page size. You need 4KB models. See "Getting Pi-Compatible Models" above.

### "No Hailo device found"

Check driver:
```bash
lsmod | grep hailo
ls /dev/hailo*
../../scripts/setup/verify_hailo_installation.sh
```

### Camera Not Accessible

Another process might be using it:
```bash
# Check if Frigate or rpicam-apps is running
ps aux | grep -E "frigate|rpicam"
../../scripts/diagnostics/reset_camera.sh
```

## Integration Examples

### Flask Web API
```python
from flask import Flask, request, jsonify
from hailo_platform import HEF, VDevice
import numpy as np

app = Flask(__name__)
vdevice = VDevice()
hef = HEF("models/pi5-compatible/yolov8s_pi5.hef")

@app.route('/detect', methods=['POST'])
def detect():
    image = request.files['image'].read()
    # ... process with Hailo ...
    return jsonify(results)
```

### OpenCV Integration
```python
import cv2
from hailo_platform import VDevice, HEF

cap = cv2.VideoCapture(0)
vdevice = VDevice()
hef = HEF("models/pi5-compatible/yolov8s_pi5.hef")

while True:
    ret, frame = cap.read()
    # ... Hailo inference ...
    cv2.imshow('Detection', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
```

## API Documentation

Full API reference:
- HailoRT Python API: https://hailo.ai/developer-zone/documentation/hailort-v4-23-0/
- Examples: https://github.com/hailo-ai/Hailo-Application-Code-Examples

## More Information

- Model compatibility: `../../models/README.md`
- General setup: `../../docs/SETUP.md`
- Troubleshooting: `../../docs/TROUBLESHOOTING.md`
- Alternative (easier) option: `../rpicam/README.md`

