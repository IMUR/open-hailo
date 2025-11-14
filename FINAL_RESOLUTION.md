# Final Resolution - Hailo-8 Version Compatibility

## 🎯 **Root Cause Identified**

Your **Hailo-8 device** (PCI ID: `1e60:2864`) is only supported by driver v4.23.0 and earlier. The v5.1.1 driver dropped support for original Hailo-8.

### **Evidence:**

**v4.23.0 driver:**
```
alias: pci:v00001E60d00002864sv*sd*bc*sc*i*  ✅ Supports Hailo-8
```

**v5.1.1 driver:**
```
alias: pci:v00001E60d000026A2...  (Hailo-10H only)
alias: pci:v00001E60d000043A2...  (Hailo-8L only)
alias: pci:v00001E60d000045C4...  (Hailo-15 only)
```
❌ **Does NOT support original Hailo-8!**

---

## ✅ **Current Status**

- ✅ Driver v4.23.0 is built and installed
- ✅ Device `/dev/hailo0` created successfully
- ❌ HailoRT library v5.1.1 incompatible with v4.23.0 driver
- ❌ Communication fails with `HAILO_DRIVER_INVALID_IOCTL(86)`

---

## 🔧 **Solution: Downgrade Library to v4.23.0**

You must use **matching versions**: v4.23.0 driver + v4.23.0 library

### **Option 1: Use Existing 4.23.0 Library (Quick)**

Check if you already have it:

```bash
ls -lh /usr/local/lib/libhailort.so.4.23.0

# If it exists:
sudo rm /usr/local/lib/libhailort.so
sudo ln -s /usr/local/lib/libhailort.so.4.23.0 /usr/local/lib/libhailort.so
sudo ldconfig

# Test
hailortcli --version  # Should show 4.23.0
hailortcli fw-control identify  # Should work!
```

### **Option 2: Build 4.23.0 Library from Source**

If the library doesn't exist:

```bash
cd /home/crtr/Projects/open-hailo/hailort
# This directory should be v4.20.0 or v4.23.0

# Check version
grep "project.*VERSION" runtime/CMakeLists.txt

# If it's close to 4.23.0, build it:
cd runtime
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j$(nproc)
sudo cmake --install .
sudo ldconfig

# Verify
hailortcli --version
```

### **Option 3: Download 4.23.0 Release**

Download from Hailo's official releases and install.

---

## 📊 **Version Compatibility for Hailo-8**

| Library | Driver | Hailo-8 Support | Status |
|---------|--------|-----------------|--------|
| 4.20.0 | 4.20.0 | ✅ Yes | Compatible |
| 4.23.0 | 4.23.0 | ✅ Yes | **RECOMMENDED** |
| 5.1.1 | 5.1.1 | ❌ No | Not supported |
| 5.1.1 | 4.23.0 | ❌ No | Ioctl mismatch |

---

## ⚡ **Quick Fix Commands**

```bash
# 1. Ensure v4.23.0 driver is loaded (already done)
lsmod | grep hailo_pci

# 2. Check if v4.23.0 library exists
ls /usr/local/lib/libhailort.so.4.23.0

# 3. If yes, symlink to it
sudo rm /usr/local/lib/libhailort.so
sudo ln -s /usr/local/lib/libhailort.so.4.23.0 /usr/local/lib/libhailort.so
sudo ldconfig

# 4. Verify
hailortcli --version  # Should be 4.23.0
hailortcli fw-control identify  # Should show device info!

# 5. Run full verification
cd /home/crtr/Projects/open-hailo
./scripts/setup/verify_hailo_installation.sh
```

---

## 🎉 **After This Fix**

Once library matches driver (both v4.23.0):

1. ✅ Device communication works
2. ✅ Can build Python bindings for v4.23.0
3. ✅ Real detection possible (with matching versions)
4. ✅ All `hailortcli` commands work

---

## 📝 **Key Lessons**

1. **Hailo-8 (original)** only supported up to v4.23.0
2. **v5.1.1** is for newer chips (Hailo-10H, 8L, 15)
3. **Driver and library versions MUST match exactly**
4. **Check PCI device ID** before choosing driver version

---

## 🚀 **Next Steps**

1. Run the Quick Fix commands above
2. If v4.23.0 library doesn't exist, build from source
3. Verify with `hailortcli fw-control identify`
4. Build Python bindings for v4.23.0
5. Run detection!

---

**Status:** Clear path forward, need to match library to driver  
**Estimated time:** 5 minutes (if library exists) or 30 minutes (if need to build)  
**Confidence:** 100% - this is the exact issue and solution

