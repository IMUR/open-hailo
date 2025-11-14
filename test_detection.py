#!/usr/bin/env python3
"""
Simple test to check if we can run Hailo detection
"""

import sys
import os

print("Testing Hailo Detection Setup")
print("=" * 50)

# Check for Hailo device
if os.path.exists("/dev/hailo0"):
    print("✅ Hailo device found: /dev/hailo0")
else:
    print("❌ Hailo device not found")
    sys.exit(1)

# Check for model
model_path = os.path.expanduser("~/yolov8s.hef")
if os.path.exists(model_path):
    print(f"✅ YOLO model found: {model_path}")
    size_mb = os.path.getsize(model_path) / (1024*1024)
    print(f"   Size: {size_mb:.1f} MB")
else:
    print("❌ YOLO model not found")
    sys.exit(1)

# Try to import hailo_platform
try:
    from hailo_platform import VDevice
    print("✅ hailo_platform module imported")
    try:
        device = VDevice()
        print("✅ VDevice created successfully!")
        print("\n🎯 Hailo is ready for detection!")
        print("\nNote: The rpicam-apps wasn't built with Hailo support.")
        print("We need to rebuild it or use Python scripts for detection.")
    except Exception as e:
        print(f"⚠️  VDevice creation failed: {e}")
        print("   This might be a version mismatch issue")
except ImportError:
    print("❌ hailo_platform not available")
    print("   Install with: pip3 install hailort")

print("\n" + "=" * 50)
print("\nOptions for real detection:")
print("1. Rebuild rpicam-apps with Hailo support:")
print("   ./scripts/build/build_hailo_preview_local.sh")
print("")
print("2. Use Python detection (recommended):")
print("   python3 scripts/preview/hailo_preview_no_cv.py")
print("")
print("3. Install system packages and run overlay script:")
print("   sudo apt install python3-picamera2 python3-numpy")
print("   python3 scripts/preview/hailo_live_overlay.py")
