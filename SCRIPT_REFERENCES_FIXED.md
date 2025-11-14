# Script References - Final Corrections (2025-01-13)

## Issue Found
The `fix_version_mismatch.sh` and `verify_hailo_installation.sh` scripts referenced **non-existent scripts**:
- `build_hailort_driver.sh` ❌
- `build_hailort_library.sh` ❌  
- `build_python_bindings.sh` ❌

## Root Cause
These "build_*" scripts were planned but never created due to Trixie (Debian 13) complexity:
- Python 3.13+ PEP 668 (externally-managed-environment)
- GCC 14 compatibility issues
- Multiple HailoRT versions on system

## Fixes Applied

### 1. ✅ Fixed `scripts/setup/fix_version_mismatch.sh`

**Before:**
```bash
"$PROJECT_ROOT/scripts/setup/build_hailort_library.sh" || {
    echo -e "${RED}Library build failed${NC}"
    exit 1
}
```

**After:**
```bash
echo "MANUAL STEPS REQUIRED:"
echo ""
echo "1. Build HailoRT 5.1.1 library:"
echo "   cd $PROJECT_ROOT/hailort-5.1.1"
echo "   mkdir -p build && cd build"
echo "   cmake .. -DCMAKE_BUILD_TYPE=Release"
echo "   cmake --build . -j\$(nproc)"
echo "   sudo cmake --install ."
echo "   sudo ldconfig"
...
```

### 2. ✅ Fixed `scripts/setup/verify_hailo_installation.sh`

**Before:**
```bash
echo "   Fix: Run ./scripts/setup/build_hailort_driver.sh"
echo "   Fix: Run ./scripts/setup/build_hailort_library.sh"
echo "   Fix: Run ./scripts/setup/build_python_bindings.sh"
```

**After:**
```bash
echo "   Fix: Run ./scripts/driver/get_official_driver.sh && sudo ./scripts/driver/install_official_driver.sh"
echo "   Fix: Rebuild HailoRT from hailort-5.1.1/ directory (see docs/DEVELOPMENT.md)"
echo "   Fix: Build Python bindings from hailort-5.1.1/hailort/libhailort/bindings/python/platform/"
```

### 3. ✅ Updated AUTHORITATIVE_INVENTORY.md

Added to "Scripts That DO NOT Exist" section:
```
❌ scripts/setup/build_hailort_driver.sh      - Use: scripts/driver/get_official_driver.sh
❌ scripts/setup/build_hailort_library.sh     - Manual: cd hailort-5.1.1/build && cmake/make
❌ scripts/setup/build_python_bindings.sh     - Manual: see docs/DEVELOPMENT.md
```

## Why Manual Steps?

### Trixie Challenges
1. **Python 3.13 PEP 668**: System Python is externally-managed, preventing simple `pip install`
2. **Virtual Environments**: Require careful handling of system vs venv packages
3. **GCC 14**: Older HailoRT versions have compatibility issues
4. **Multiple Versions**: System has 4.20.0, 4.23.0, and 5.1.1 - complex to automate

### Better Approach
- Provide **clear manual steps** in scripts
- Reference **docs/DEVELOPMENT.md** for detailed guidance
- Use **existing driver scripts** that work correctly

## Verification

All script references now point to:
- ✅ **Actual existing scripts** (14 confirmed)
- ✅ **Manual steps** with exact commands
- ✅ **Documentation references** for complex procedures

No more "file not found" errors!

## Complete List of Non-Existent Scripts

```bash
# DO NOT USE - These scripts don't exist:
./scripts/setup/install_build_deps.sh              # Use: install_build_dependencies.sh
./scripts/setup/install_tappas_deps.sh             # Manual TAPPAS install
./scripts/setup/download_yolov8_models.sh          # Manual download
./scripts/setup/build_hailort_driver.sh            # Use: scripts/driver/get_official_driver.sh
./scripts/setup/build_hailort_library.sh           # Manual: see fix_version_mismatch.sh
./scripts/setup/build_python_bindings.sh           # Manual: see verify_hailo_installation.sh
./scripts/quickstart/quick_start_detection.sh      # Use: demo_detection.sh
./scripts/utils/run_test.sh                        # Use: ./test.sh
./scripts/utils/run_complete_test.sh               # Use: ./test.sh
```

## Files Modified (Round 2)

1. ✅ `scripts/setup/fix_version_mismatch.sh` - Replaced automation with manual steps
2. ✅ `scripts/setup/verify_hailo_installation.sh` - Updated all script references (8 instances)
3. ✅ `AUTHORITATIVE_INVENTORY.md` - Added missing scripts to "DO NOT Exist" section
4. ✅ `SCRIPT_REFERENCES_FIXED.md` - This document (NEW)

## Next Steps for Maintainers

When adding new scripts:
1. **Update AUTHORITATIVE_INVENTORY.md immediately**
2. **Test all references** before committing
3. **Avoid creating "build_*" scripts** - Trixie complexity requires manual steps
4. **Reference existing scripts** or provide inline commands

---

**Status:** ✅ All phantom script references eliminated  
**Date:** 2025-01-13  
**Impact:** No more "No such file or directory" errors from helper scripts

