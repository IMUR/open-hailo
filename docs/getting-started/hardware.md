# Hardware Compatibility

Supported hardware configurations for Hailo-8 AI acceleration.

## Validated Configuration

### ✅ Fully Tested & Working

**Computer:**
- Raspberry Pi 5 (8GB recommended, 4GB minimum)
- PCIe port (required for Hailo-8)

**AI Accelerator:**
- Hailo-8 PCIe module
- Firmware: 4.23.0
- HailoRT: 4.23.0

**Camera:**
- OV5647 Camera Module (5MP)
- Also compatible with: IMX219, IMX477, IMX708

**Operating System:**
- Raspberry Pi OS Trixie (Debian 13)
- Kernel: 6.12.47+rpt-rpi-2712
- Python: 3.13+
- GCC: 14

## Other Pi Models

### Raspberry Pi 4

**Status:** ⚠️ Not Officially Tested

The Hailo-8 requires PCIe, which Pi 4 doesn't have natively. Options:

1. **PCIe HAT** - Some HATs provide PCIe on Pi 4
2. **USB Adapter** - PCIe-to-USB adapters (reduced performance)

Not covered by this repository. See Hailo documentation for Pi 4 support.

### Raspberry Pi 3 and Earlier

**Status:** ❌ Not Compatible

No PCIe support. Consider:
- Hailo-8L USB version (different setup)
- Upgrade to Pi 5

## Camera Modules

### Official Raspberry Pi Cameras

**Tested:**
- ✅ Camera Module v1 (OV5647) - 5MP
- ✅ Camera Module v2 (IMX219) - 8MP
- ✅ Camera Module v3 (IMX708) - 12MP
- ✅ HQ Camera (IMX477) - 12.3MP

**Connection:** CSI ribbon cable to camera port

### USB Cameras

**Status:** ⚠️ Should Work (untested)

Standard USB webcams should work via:
- V4L2 (`/dev/video0`)
- Frigate NVR configuration
- Python OpenCV capture

Performance may vary. CSI cameras recommended for best results.

### Network Cameras (RTSP)

**Status:** ✅ Compatible with Frigate

Use Frigate configuration for RTSP streams:
```yaml
cameras:
  network_cam:
    ffmpeg:
      inputs:
        - path: rtsp://camera.local/stream
```

See `configs/frigate/README.md`

## Hailo Modules

### Hailo-8

**Status:** ✅ Primary Target

- 26 TOPS performance
- PCIe interface
- This repository's focus

### Hailo-8L

**Status:** ⚠️ May Work

- 13 TOPS performance
- Similar PCIe interface
- Should be compatible but untested
- May need minor configuration changes

### Hailo-10H

**Status:** ❌ Not Supported

- Different architecture
- Requires different software stack
- Not covered by this repository

## Storage Recommendations

### Minimum

- 32GB SD card
- For OS + basic operation

### Recommended

- 64GB+ SD card **OR**
- External SSD via USB 3.0
  - Much faster
  - Better for Frigate recording
  - Longer lifespan

### For Frigate NVR

- 128GB+ SSD minimum
- 500GB+ for multi-camera 24/7 recording

## Power Requirements

### Raspberry Pi 5

**Official PSU:** 27W USB-C (5.1V/5A)

**With Hailo-8:**
- Add ~5W for Hailo module
- **Total:** ~32W peak

**Recommendation:** Use official Raspberry Pi 27W PSU - it handles the load well.

## Cooling

### Hailo-8 Module

- Passive cooling (heatsink) usually sufficient
- Active cooling (fan) recommended for:
  - Continuous 24/7 operation
  - Enclosed cases
  - Warm environments

### Raspberry Pi 5

- Active Cooler recommended (official or third-party)
- Gets hot under AI workload

## Network

### Wired (Recommended)

- Gigabit Ethernet
- Stable, low latency
- Best for Frigate

### Wireless

- Works for testing
- May have latency issues for real-time detection
- Not recommended for production Frigate deployments

## Compatibility Checklist

Before starting:

- [ ] Raspberry Pi 5 (4GB or 8GB)
- [ ] Hailo-8 PCIe module installed
- [ ] CSI camera connected (or USB/network camera ready)
- [ ] 32GB+ SD card or SSD
- [ ] 27W USB-C power supply
- [ ] Active cooler/fan
- [ ] Raspberry Pi OS Trixie installed
- [ ] Internet connection for setup

## Troubleshooting

### Hailo Not Detected

```bash
lspci | grep Hailo
# Should show: Hailo Technologies Ltd. Hailo-8 AI Processor
```

If not found:
1. Check PCIe connection
2. Reboot Pi
3. Update firmware: `sudo rpi-eeprom-update`

### Camera Not Detected

```bash
rpicam-hello --list-cameras
# Should show your camera
```

If not found:
1. Check ribbon cable connection
2. Enable camera in `raspi-config`
3. Reboot

### Performance Issues

- Check cooling - thermal throttling?
- Use wired network
- Consider SSD instead of SD card

## More Information

- Official Pi 5 specs: https://www.raspberrypi.com/products/raspberry-pi-5/
- Hailo-8 datasheet: https://hailo.ai/products/hailo-8/
- Setup guide: `docs/SETUP.md`

