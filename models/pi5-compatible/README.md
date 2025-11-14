# Pi 5 Compatible Models (4KB Page Size)

This directory contains models compiled with 4KB DMA descriptor page size, specifically for Raspberry Pi 5.

## Status

🚧 **Currently Empty** - No Pi-compatible models available yet.

## Why 4KB Page Size?

The Hailo-8 on Raspberry Pi 5 has a hardware limitation:
- Maximum DMA descriptor page size: **4096 bytes (4KB)**
- Standard x86 models use: **16384 bytes (16KB)**

This mismatch causes the error:
```
[HailoRT] [error] CHECK failed - max_desc_page_size given 16384 is bigger than hw max desc page size 4096
```

## Getting Pi-Compatible Models

### Option 1: Official Hailo Model Zoo
Check for pre-compiled Pi 5 models:
```bash
# Visit: https://github.com/hailo-ai/hailo_model_zoo
# Look for models tagged "raspberry-pi" or "4k-page-size"
```

### Option 2: Compile Your Own
Use Hailo Dataflow Compiler:

```bash
# Install Dataflow Compiler (requires license)
hailo compile your_model.onnx \
  --page-size 4096 \
  --output-dir . \
  -o model_pi5.hef
```

### Option 3: Request from Community
Check the Hailo community forum for shared Pi-compatible models:
- https://community.hailo.ai

### Option 4: Use rpicam-apps (No New Models Needed!)
The rpicam-apps integration works with ANY models, including the 16K ones:

```bash
cd open-hailo
./configs/rpicam/install.sh
# Uses models from ../x86-models/ automatically
```

## Once You Have Models

Place `.hef` files in this directory:

```bash
cp yolov8s_pi5.hef models/pi5-compatible/
```

Then use with Python API:

```bash
cd open-hailo
./configs/python-direct/install.sh
# Edit examples to point to models/pi5-compatible/yolov8s_pi5.hef
```

## Compatibility

✅ **Works with ALL deployment methods:**
- Python Direct API
- rpicam-apps
- Frigate NVR
- TAPPAS pipelines
- Custom OpenCV

## Need Help?

See `../README.md` for the complete compatibility matrix.

