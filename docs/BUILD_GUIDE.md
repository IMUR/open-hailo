# Hailo AI HAT+ Open-Source Build Guide for Debian 13

## Prerequisites

- Raspberry Pi 5 with Hailo AI HAT+
- Debian 13 (Trixie) with kernel 6.12.x or later
- Internet connection for downloading sources
- At least 4GB RAM, 8GB+ recommended

## Step-by-Step Build Process

### 1. Install Build Dependencies

```bash
sudo apt update
sudo apt install -y build-essential linux-headers-$(uname -r) dkms pciutils pkg-config cmake git
```

### 2. Build Kernel Driver

```bash
# Clone driver repository
git clone https://github.com/hailo-ai/hailort-drivers.git
cd hailort-drivers
git checkout hailo8  # Important: use hailo8 branch

# Build and install driver
cd linux/pcie
make all
sudo make install

# Install udev rules
sudo cp 51-hailo-udev.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger

# Download and install firmware
cd ../..
./download_firmware.sh
sudo mkdir -p /lib/firmware/hailo
sudo cp hailo8_fw.*.bin /lib/firmware/hailo/hailo8_fw.bin

# Load driver
sudo modprobe hailo_pci
```

### 3. Build HailoRT Runtime

```bash
# Clone HailoRT repository
git clone https://github.com/hailo-ai/hailort.git
cd hailort
git checkout v4.20.0  # Match driver version

# Build with CMake
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
sudo ldconfig
```

### 4. Verify Installation

```bash
# Check device detection
hailortcli scan

# Get device info
hailortcli fw-control identify

# Verify device node
ls -la /dev/hailo*
```

## Troubleshooting

### Driver Loading Issues

1. Check kernel messages: `sudo dmesg | grep hailo`
2. Ensure firmware is in correct location: `/lib/firmware/hailo/hailo8_fw.bin`
3. Verify PCIe detection: `lspci | grep Hailo`

### Version Mismatch

- Driver and runtime versions should match (e.g., both 4.20.0)
- Firmware can be newer but check for warnings

### Permission Issues

- Ensure user is in appropriate groups or use sudo
- Check udev rules are properly installed

## Performance Tips

1. **CPU Governor**: Set to performance mode
   ```bash
   echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```

2. **PCIe Speed**: Verify Gen3 operation
   ```bash
   sudo lspci -vv -s $(lspci | grep Hailo | cut -d' ' -f1) | grep LnkSta
   ```

3. **Memory**: Use DMA buffers for optimal transfer

## Limitations

- Model conversion tools (DFC) are proprietary
- Some advanced features require closed-source components
- Power/temperature monitoring may have limited support

## Contributing

Please share your experiences, patches, and improvements:
- Document any Debian 13-specific issues
- Share performance benchmarks
- Contribute example applications

## Resources

- Hailo Community: https://community.hailo.ai/
- GitHub Issues: Report driver/runtime issues
- This Guide: Fork and improve!
