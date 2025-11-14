# x86 Models (16KB Page Size)

These models were compiled with 16KB DMA descriptor page size and are designed for x86/server platforms.

## Models

- `yolov8n.hef` - YOLOv8 Nano (8.1MB)
- `yolov8s.hef` - YOLOv8 Small (19MB)  
- `yolov8m.hef` - YOLOv8 Medium (29MB)

## Raspberry Pi 5 Compatibility

⚠️ **Limited Compatibility on Pi 5**

These models will **FAIL** when used with:
- Python Direct API
- Frigate NVR
- Custom OpenCV pipelines

Error message:
```
[HailoRT] [error] CHECK failed - max_desc_page_size given 16384 is bigger than hw max desc page size 4096
```

## Working Solutions on Pi 5

✅ **rpicam-apps**: These models WORK with rpicam-apps because it handles the page size limitation at a lower level.

```bash
cd open-hailo
./configs/rpicam/install.sh
rpicam-hello --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json
```

## Getting Pi-Compatible Models

For Python API and other deployment methods, you need 4KB page size models:

1. Check `../pi5-compatible/` directory
2. Download from Hailo Model Zoo (Pi-specific builds)
3. Compile your own with: `--page-size 4096`

See `../README.md` for more details.

