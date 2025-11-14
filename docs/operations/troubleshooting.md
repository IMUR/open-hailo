# Troubleshooting Guide

Common issues and solutions for Hailo-8 on Raspberry Pi 5 with Trixie.

## Quick Diagnostics

Run the built-in diagnostics:
```bash
cd .
./scripts/setup/verify_hailo_installation.sh
./scripts/diagnostics/check_version_compatibility.sh
```

## Common Issues

### 1. "No Hailo device found at /dev/hailo0"

**Symptoms:**
- `/dev/hailo0` doesn't exist
- `lspci` doesn't show Hailo

**Solutions:**

**Check hardware connection:**
```bash
lspci | grep Hailo
# Should show: 0001:01:00.0 Co-processor: Hailo Technologies Ltd. Hailo-8 AI Processor
```

If not found:
```bash
# Reseat the Hailo module
sudo poweroff
# Remove and reinsert Hailo PCIe card
# Power on
```

**Check driver:**
```bash
lsmod | grep hailo
# Should show: hailo_pci

# If not loaded:
sudo modprobe hailo_pci
```

**Reinstall driver:**
```bash
./scripts/driver/get_official_driver.sh
sudo reboot
```

### 2. "HAILO_DRIVER_INVALID_IOCTL(86)"

**Symptoms:**
```
[HailoRT] [error] Ioctl HAILO_QUERY_DRIVER_INFO failed
[HailoRT] [error] HAILO_DRIVER_INVALID_IOCTL(86)
```

**Cause:** Version mismatch between HailoRT library and driver

**Solution:**
```bash
# Check versions
hailortcli --version
modinfo hailo_pci | grep version

# They must match! Reinstall:
./scripts/driver/get_official_driver.sh
sudo reboot
```

### 3. "max_desc_page_size given 16384 is bigger than hw max desc page size 4096"

**Symptoms:**
```
[HailoRT] [error] CHECK failed - max_desc_page_size given 16384...
HAILO_INTERNAL_FAILURE(8)
```

**Cause:** Using 16KB page size model with Python API

**Solutions:**

**Option A:** Use rpicam-apps (handles this automatically)
```bash
./configs/rpicam/install.sh
```

**Option B:** Get Pi-compatible (4KB) models
See: `docs/MODEL_COMPATIBILITY.md`

### 4. Camera Not Detected

**Symptoms:**
```
rpicam-hello --list-cameras
# Shows: No cameras available
```

**Solutions:**

**Enable camera:**
```bash
sudo raspi-config
# Interface Options -> Camera -> Enable
sudo reboot
```

**Check connection:**
```bash
vcgencmd get_camera
# Should show: supported=1 detected=1
```

**Reset camera:**
```bash
./scripts/diagnostics/reset_camera.sh
```

**Check if another process is using it:**
```bash
ps aux | grep -E "frigate|rpicam|libcamera"
# Kill any processes using the camera
```

### 5. "No module named 'hailo_platform'"

**Symptoms:**
```python
ModuleNotFoundError: No module named 'hailo_platform'
```

**Cause:** Python bindings not installed

**Solution:**
```bash
cd .
./configs/python-direct/install.sh
```

Or manually:
```bash
cd ./hailort-4.23.0/hailort/libhailort/bindings/python/platform
source ./.venv/bin/activate
python setup.py install
```

### 6. Frigate Won't Start

**Docker:**
```bash
cd ./configs/frigate/docker
docker compose logs -f
# Check for errors
```

**Native:**
```bash
sudo systemctl status frigate
sudo journalctl -u frigate -f
```

**Common issues:**
- Camera in use by another process
- Hailo device permissions
- Config file errors

### 7. Performance Issues / Slow FPS

**Check thermal throttling:**
```bash
vcgencmd get_throttled
# 0x0 = no throttling
# Anything else = throttled
```

**Solutions:**
- Add/improve cooling
- Lower resolution
- Use faster model (yolov8n instead of yolov8m)

**Check CPU usage:**
```bash
htop
```

### 8. Build Errors with GCC 14

**Symptoms:**
```
error: invalid conversion from 'const void*' to 'void*'
```

**Cause:** Trixie uses GCC 14, some older code not compatible

**Solution:** Usually already patched in this repo. If you see this:
```bash
# Report issue on GitHub
# Workaround: use older HailoRT version or wait for patch
```

### 9. Python 3.13 "externally-managed-environment"

**Symptoms:**
```
error: externally-managed-environment
```

**Cause:** PEP 668 - Python 3.13 prevents system-wide pip install

**Solution:** Always use virtual environment
```bash
# Already handled by install scripts
source .venv/bin/activate
pip install package
```

### 10. Frigate "Pipeline handler in use by another process"

**Symptoms:**
```
ERROR: failed to acquire camera
Pipeline handler in use by another process
```

**Cause:** Another process (rpicam, Python script) is using the camera

**Solution:**
```bash
# Find and kill processes using camera
ps aux | grep -E "rpicam|python.*camera|picamera"
pkill -f "rpicam|hailo_live|hailo_preview"

# Or reboot to clear everything
sudo reboot
```

## System-Wide Issues

### Kernel Panic / Won't Boot

**After driver install:**

1. Boot into recovery mode
2. Remove driver module:
```bash
sudo rm /lib/modules/$(uname -r)/kernel/drivers/misc/hailo_pci.ko.xz
sudo depmod -a
sudo reboot
```

### System Freeze During Inference

**Possible causes:**
- Insufficient power
- Overheating
- Bad driver

**Solutions:**
- Check PSU (need 27W minimum)
- Improve cooling
- Update firmware: `sudo rpi-eeprom-update`

## Getting Help

### 1. Run Diagnostics

```bash
./scripts/setup/verify_hailo_installation.sh > diagnostic.txt 2>&1
./scripts/diagnostics/check_version_compatibility.sh >> diagnostic.txt 2>&1
```

### 2. Check Logs

```bash
# HailoRT logs
cat logs/hailort*.log

# System logs
sudo journalctl -u hailo* --no-pager

# Kernel messages
dmesg | grep -i hailo
```

### 3. Community Resources

- Hailo Community: https://community.hailo.ai
- GitHub Issues: [Your repo]
- Raspberry Pi Forums: https://forums.raspberrypi.com

### 4. Report Issues

Include:
- Output of diagnostic scripts
- Hardware model
- OS version (`cat /etc/os-release`)
- Error messages (full text)
- What you were trying to do

## Prevention

### Regular Maintenance

```bash
# Keep system updated
sudo apt update && sudo apt upgrade

# Check for Hailo driver updates
cd hailort-drivers-4.23.0/linux/pcie
git pull

# Backup working configuration
tar -czf hailo-backup-$(date +%Y%m%d).tar.gz ./configs
```

### Best Practices

1. **Always use virtual environment** for Python
2. **Reboot after driver changes**
3. **Check versions match** (driver/library/firmware)
4. **Monitor temperatures** during long runs
5. **Use wired network** for production
6. **Keep backups** of working configs

## More Information

- Setup guide: `docs/SETUP.md`
- Hardware compatibility: `docs/HARDWARE_COMPATIBILITY.md`
- Model compatibility: `docs/MODEL_COMPATIBILITY.md`
- Development guide: `docs/DEVELOPMENT.md`

