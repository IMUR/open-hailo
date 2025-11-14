# Driver Scripts Fix - Round 3 (2025-01-13)

## Issue Found

The driver scripts had confusing/redundant logic:

1. **`get_official_driver.sh`** - Cloned, built, AND installed the driver (complete solution)
2. **`install_official_driver.sh`** - Expected to find `.ko` files that were already cleaned up

**Result:** Running `install_official_driver.sh` would fail with "Driver not found" even though the driver was already installed!

---

## Root Cause

The `get_official_driver.sh` script does **everything**:
- Clones the repo ✅
- Checks out correct version ✅  
- Builds the driver ✅
- Installs to system ✅
- Loads the module ✅

Then it cleans up the build artifacts (`.ko` files), so `install_official_driver.sh` couldn't find them.

---

## Fixes Applied

### 1. ✅ Fixed `install_official_driver.sh`

**Before:**
```bash
DRIVER_PATH="/home/crtr/Projects/open-hailo/hailort-drivers-official/linux/pcie/hailo_pci.ko"

if [ ! -f "$DRIVER_PATH" ]; then
    echo "❌ Driver not found"
    exit 1
fi
```

**After:**
```bash
# Check if driver directory exists first
if [ ! -d "$DRIVER_DIR" ]; then
    echo "❌ Driver directory not found"
    echo "   Please run ./scripts/driver/get_official_driver.sh first"
    exit 1
fi

# If .ko file doesn't exist, build it now
if [ ! -f "$DRIVER_PATH" ]; then
    echo "⚠️  Driver not built yet. Building now..."
    cd "$DRIVER_DIR"
    make clean 2>/dev/null || true
    make
fi
```

**Improvement:** Now rebuilds if needed instead of just failing.

### 2. ✅ Updated `get_official_driver.sh` Documentation

**Added clear header:**
```bash
# Get, build, and install the official HailoRT driver from GitHub
# This script does everything - no need to run install_official_driver.sh separately
```

**Updated completion message:**
```
✅ Driver cloned, built, and installed!

📝 To rebuild: cd $(pwd) && make clean && make
📝 To reinstall: sudo ./scripts/driver/install_official_driver.sh

Next steps:
  1. Verify installation: ./scripts/setup/verify_hailo_installation.sh
  2. Check versions: ./scripts/utils/check_hailo_versions.sh
  3. Run detection: ./demo_detection.sh
```

### 3. ✅ Updated AUTHORITATIVE_INVENTORY.md

**Clarified script purposes:**
```
✅ get_official_driver.sh           - Clone, build & install driver (does everything!)
✅ install_official_driver.sh       - Reinstall already-built driver (optional)
```

---

## Usage Guide

### First Time Setup (Recommended)

Just run the one script that does everything:

```bash
./scripts/driver/get_official_driver.sh
```

This will:
1. Clone the official driver repo
2. Check out the correct version (matches your firmware)
3. Build the driver for your kernel
4. Install it to the system
5. Load the module
6. Test that it works

**No need to run anything else!**

### Reinstalling Later (Optional)

If you need to reinstall the same driver later (e.g., after kernel update):

```bash
sudo ./scripts/driver/install_official_driver.sh
```

This will:
- Rebuild if `.ko` file is missing
- Install to system
- Load the module

---

## Common Confusion Resolved

### ❓ "Do I need to run both scripts?"

**No!** Just run `get_official_driver.sh` - it does everything.

### ❓ "When do I use install_official_driver.sh?"

Only if:
- You want to reinstall the same driver
- You've updated your kernel and need to rebuild
- You've manually modified the driver source

### ❓ "Why does install_official_driver.sh say 'Driver not found'?"

Because `get_official_driver.sh` cleans up build artifacts after installing. This is now fixed - the script will rebuild if needed.

---

## Testing

After running `get_official_driver.sh`:

```bash
# Check driver is loaded
lsmod | grep hailo

# Check device exists
ls -la /dev/hailo0

# Check versions match
./scripts/utils/check_hailo_versions.sh

# Full verification
./scripts/setup/verify_hailo_installation.sh
```

---

## Files Modified (Round 3)

1. ✅ `scripts/driver/get_official_driver.sh` - Clarified that it does everything
2. ✅ `scripts/driver/install_official_driver.sh` - Added auto-rebuild if .ko missing
3. ✅ `AUTHORITATIVE_INVENTORY.md` - Clarified script purposes
4. ✅ `DRIVER_SCRIPTS_FIXED.md` - This document (NEW)

---

## Summary

| Issue | Before | After |
|-------|--------|-------|
| Redundant scripts | Two scripts, unclear which to use | Clear: use get_official_driver.sh |
| Missing .ko error | Failed with "not found" | Auto-rebuilds if needed |
| Documentation | Confusing workflow | Clear single-script solution |
| User experience | "Which script do I run?" | "Just run get_official_driver.sh" |

---

**Status:** ✅ Driver scripts now work correctly with clear purpose  
**Date:** 2025-01-13  
**Impact:** Users can install driver with single command, no confusion

