# Test Stack

Complete validation of Camera → Hailo inference pipeline.

## Contents

- `yolov5m.hef` - YOLOv5 medium model (17 MB, pre-compiled for Hailo-8)
- `run_test.sh` - Complete stack test runner

## Quick Test

```bash
cd test
./run_test.sh
```

## What Gets Tested

1. **Hailo Device**: Verifies Hailo-8 is accessible
2. **Model Loading**: Tests HEF model can be loaded
3. **Camera**: Validates OV5647 camera capture
4. **Complete Pipeline**: End-to-end readiness check

## Expected Output

```
✓ Hailo device detected
✓ Model loaded successfully
✓ Camera operational
✓ Stack ready for inference
```
