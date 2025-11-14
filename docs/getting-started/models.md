# Model Compatibility Guide

Understanding HEF model compatibility on Raspberry Pi 5 with Hailo-8.

## The Page Size Issue

### What's the Problem?

Hailo-8 models (`.hef` files) are compiled with a specific DMA descriptor page size. The Raspberry Pi 5 hardware has a **4KB (4096 bytes) maximum** page size, but many pre-compiled models use **16KB (16384 bytes)**.

### Error Message

When using incompatible models:
```
[HailoRT] [error] CHECK failed - max_desc_page_size given 16384 is bigger than hw max desc page size 4096
[HailoRT] [error] HAILO_INTERNAL_FAILURE(8)
```

## Model Categories

### x86-models (16KB)
**Location:** `models/x86-models/`

- Compiled for x86/server platforms
- **NOT compatible** with Python Direct API on Pi 5
- **Compatible** with rpicam-apps (auto-handled)

**Current models:**
- yolov8n.hef (8.1MB)
- yolov8s.hef (19MB)
- yolov8m.hef (30MB)

### pi5-compatible (4KB)
**Location:** `models/pi5-compatible/`

- Compiled specifically for Raspberry Pi 5
- **Compatible** with ALL deployment methods
- **Currently empty** - requires acquisition

## Compatibility Matrix

| Deployment Method | x86 Models (16KB) | Pi5 Models (4KB) |
|-------------------|-------------------|------------------|
| rpicam-apps | ✅ Works | ✅ Works |
| Python Direct | ❌ Fails | ✅ Works |
| Frigate NVR | ❌ Fails | ✅ Works |
| TAPPAS | ⚠️ Depends | ✅ Works |
| OpenCV Custom | ❌ Fails | ✅ Works |

## Getting Pi-Compatible Models

### Option 1: Hailo Model Zoo
Download from official sources:
```bash
# Check Hailo's model zoo for Pi-specific builds
# https://github.com/hailo-ai/hailo_model_zoo
```

### Option 2: Compile Your Own
With Hailo Dataflow Compiler:
```bash
hailo compile model.onnx --page-size 4096 -o model_pi5.hef
```

### Option 3: Community
Request from Hailo community forum:
- https://community.hailo.ai

## Recommended Approach

**For Raspberry Pi 5:**

1. **Start with rpicam-apps** (`configs/rpicam/`)
   - Works with existing 16KB models
   - No model compilation needed
   - Best performance

2. **Get Pi-compatible models** (if you need Python API)
   - See options above
   - Place in `models/pi5-compatible/`
   - Use with `configs/python-direct/`

## More Information

- Model organization: `models/README.md`
- rpicam configuration: `configs/rpicam/README.md`
- Python Direct: `configs/python-direct/README.md`

