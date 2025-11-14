# Hailo Model Files

This directory contains YOLOv8 and other AI models in Hailo's `.hef` format, organized by compatibility.

## Directory Structure

### `x86-models/`
Models compiled with **16KB page size** - compatible with x86 systems and some server platforms.

**⚠️ NOT COMPATIBLE** with Raspberry Pi 5 Python API due to DMA descriptor page size limitations.

**Use with:**
- rpicam-apps (auto-handles page size issues)
- x86/server platforms

### `pi5-compatible/`
Models compiled with **4KB page size** - specifically for Raspberry Pi 5.

**✅ COMPATIBLE** with:
- Raspberry Pi 5 Python API
- rpicam-apps
- All Hailo deployment methods on Pi

### `rpicam-compatible/`
Models that work seamlessly with rpicam-apps integration, regardless of page size.

## Current Models

### x86-models/
- `yolov8n.hef` (8.1MB) - YOLOv8 Nano (fastest, least accurate)
- `yolov8s.hef` (19MB) - YOLOv8 Small (balanced)
- `yolov8m.hef` (29MB) - YOLOv8 Medium (slower, more accurate)

**Page Size:** 16384 bytes  
**Issue:** Causes `HAILO_INTERNAL_FAILURE(8)` with Python API on Pi 5

## Getting Pi-Compatible Models

### Option 1: Hailo Model Zoo
Download pre-compiled models from the official Hailo Model Zoo:
```bash
# Coming soon - official Pi-compatible models
```

### Option 2: Compile Your Own
Use Hailo Dataflow Compiler with `--page-size 4096`:
```bash
hailo compile model.onnx --page-size 4096 -o model_pi5.hef
```

### Option 3: Use rpicam-apps
The rpicam-apps integration handles page size issues automatically, so you can use the existing x86-models.

## Compatibility Matrix

| Deployment Method | x86-models (16K) | pi5-compatible (4K) |
|-------------------|------------------|---------------------|
| rpicam-apps       | ✅ Works         | ✅ Works            |
| Python Direct     | ❌ Fails         | ✅ Works            |
| Frigate NVR       | ❌ Fails         | ✅ Works            |
| TAPPAS            | ⚠️ Depends       | ✅ Works            |
| OpenCV Custom     | ❌ Fails         | ✅ Works            |

## Error Messages

If you see:
```
[HailoRT] [error] CHECK failed - max_desc_page_size given 16384 is bigger than hw max desc page size 4096
```

This means you're using a 16K page size model with a deployment method that requires 4K models.

**Solution:** Either:
1. Use rpicam-apps configuration (handles this automatically)
2. Get/compile 4K page size models
3. Use models from `pi5-compatible/` directory

## More Information

- See `configs/rpicam/README.md` for rpicam-apps usage
- See `configs/python-direct/README.md` for Python API requirements
- See `docs/MODEL_COMPATIBILITY.md` for detailed compatibility guide

