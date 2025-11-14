# rpicam-Compatible Models

This directory is for models that have been specifically tested and verified to work with rpicam-apps integration.

## Status

📁 **Currently Empty** - Symlinks or copies will be placed here during rpicam configuration.

## About rpicam-apps Integration

The rpicam-apps integration with Hailo is special because it:

1. **Auto-handles page size issues** - Works with both 4KB and 16KB models
2. **Direct camera integration** - Low latency, efficient processing
3. **Built-in post-processing** - Detection overlays included

## Using Models with rpicam

You don't need to place models in this directory manually. The rpicam configuration will:

1. Use models from `../x86-models/` (works despite 16KB page size)
2. Configure `/usr/share/pi-camera-assets/hailo_yolov8_inference.json`
3. Point to the correct model file

## Quick Start

```bash
cd open-hailo
./configs/rpicam/install.sh
```

This will set up everything needed for rpicam-apps with Hailo detection.

## Example Usage

```bash
# Live preview with detection overlays
rpicam-hello --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json

# Record with detection
rpicam-vid -t 30000 --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json -o output.h264
```

## Why rpicam-apps is Recommended

For Raspberry Pi 5 + Hailo-8, rpicam-apps is often the best choice because:

- ✅ No page size issues
- ✅ Official Raspberry Pi support
- ✅ Optimized for Pi hardware
- ✅ Simple to use
- ✅ Low latency

## More Information

See `../../configs/rpicam/README.md` for complete documentation.

