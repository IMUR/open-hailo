#!/bin/bash
# Live camera preview with Hailo-8 detection overlays

rpicam-hello \
  --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json \
  --width 1920 --height 1080

