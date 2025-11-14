# Python Direct API Deployment Guide

Direct Python API access to Hailo-8 for custom applications.

## Overview

Use the HailoRT Python API for full programmatic control of Hailo-8 inference in your applications.

### Why Choose This?

✅ **Custom pipelines** - Full control over inference flow  
✅ **Integration** - Add Hailo to existing Python apps  
✅ **Flexibility** - Custom pre/post-processing  
✅ **Advanced use cases** - Multi-threading, model ensembles  

### ⚠️ Important Limitation

**Requires Pi-compatible HEF models** (4KB page size)

Current models in `models/x86-models/` have 16KB page size and will **NOT work**.

## Installation

```bash
./setup.sh
# Choose option 6: Python Direct

# Or directly:
./configs/python-direct/install.sh
```

## Getting Compatible Models

### Option 1: Use rpicam-apps Instead
If you don't have Pi-compatible models, use [rpicam.md](rpicam.md) which works with existing models.

### Option 2: Get 4KB Models
- Download from Hailo Model Zoo (Pi-specific builds)
- Compile with: `hailo compile --page-size 4096`
- Request from community

See: [../getting-started/models.md](../getting-started/models.md)

## Quick Start

```bash
cd open-hailo
source .venv/bin/activate
python configs/python-direct/examples/live_detection.py
```

## Python API Basics

```python
from hailo_platform import VDevice, HEF

# Create device
vdevice = VDevice()

# Load model (must be 4KB page size!)
hef = HEF("models/pi5-compatible/yolov8s_pi5.hef")

# Configure and run inference
# ... see examples/ for complete code
```

## Examples

See `configs/python-direct/examples/`:
- `live_detection.py` - Real-time camera detection
- `simulator_mode.py` - Test camera without inference

## Troubleshooting

### "HAILO_INTERNAL_FAILURE(8)"

Your model has 16KB page size. Need 4KB models or use rpicam-apps.

### "No module named 'hailo_platform'"

```bash
cd hailort/hailort-4.23.0/hailort/libhailort/bindings/python/platform
source .venv/bin/activate
python setup.py install
```

## More Information

- Full Python guide: `../../configs/python-direct/README.md`
- API reference: [../development/api.md](../development/api.md)
- Model compatibility: [../getting-started/models.md](../getting-started/models.md)

