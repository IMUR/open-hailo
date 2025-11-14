# OpenCV Custom Pipeline Deployment Guide

Build custom computer vision pipelines with OpenCV and Hailo-8.

## Overview

Integrate Hailo-8 into your existing OpenCV applications or build custom CV pipelines.

## When to Use This

✅ **Existing OpenCV codebase** - Add Hailo to your app  
✅ **Custom preprocessing** - Full control over image preparation  
✅ **Complex pipelines** - Multi-stage processing  
✅ **Research/experimentation** - Trying new approaches  

## Installation

```bash
./setup.sh
# Choose option 9: OpenCV Custom

# Or directly:
./configs/opencv-custom/install.sh
```

This uses the same setup as Python Direct.

## Requirements

Same as [python-direct.md](python-direct.md):
- Pi-compatible HEF models (4KB page size)
- Python virtual environment
- OpenCV + hailo_platform

## Example Pipeline

```python
import cv2
from hailo_platform import VDevice, HEF

# Initialize Hailo
vdevice = VDevice()
hef = HEF("models/pi5-compatible/yolov8s_pi5.hef")

# OpenCV camera
cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    # Your custom preprocessing
    processed = your_preprocess(frame)
    
    # Hailo inference
    results = hailo_inference(processed)
    
    # Your custom postprocessing
    annotated = your_postprocess(frame, results)
    
    cv2.imshow('Detection', annotated)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
```

## Examples

See `configs/opencv-custom/examples/` for complete working examples.

## More Information

- Start with: [python-direct.md](python-direct.md)
- OpenCV docs: https://docs.opencv.org
- Config guide: `../../configs/opencv-custom/README.md`

