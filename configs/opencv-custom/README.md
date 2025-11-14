# OpenCV Custom Pipeline Configuration

Build custom computer vision pipelines with OpenCV and Hailo-8.

## Overview

This configuration helps you integrate Hailo-8 into existing OpenCV applications or build custom CV pipelines.

## Prerequisites

- Same as Python Direct (`../python-direct/`)
- Pi-compatible HEF models (4KB page size)
- OpenCV Python knowledge

## Installation

```bash
cd open-hailo/configs/opencv-custom
./install.sh
```

## Example: Basic Detection Pipeline

```python
import cv2
from hailo_platform import VDevice, HEF

# Initialize Hailo
vdevice = VDevice()
hef = HEF("../../models/pi5-compatible/yolov8s_pi5.hef")

# OpenCV camera
cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    # Your preprocessing
    processed = cv2.resize(frame, (640, 640))
    
    # Hailo inference
    # ... (see examples/)
    
    # Your postprocessing
    cv2.imshow('Detection', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

## Examples

See `examples/` directory for complete working examples.

## More Information

- Start with: `../python-direct/README.md`
- OpenCV docs: https://docs.opencv.org

