#!/bin/bash
# Record video with Hailo-8 detection overlays

OUTPUT_FILE="${1:-detection_$(date +%Y%m%d_%H%M%S).h264}"
DURATION="${2:-30000}"  # 30 seconds default

echo "Recording $((DURATION/1000)) seconds to: $OUTPUT_FILE"
echo "Press Ctrl+C to stop early"
echo ""

rpicam-vid \
  -t "$DURATION" \
  --post-process-file /usr/share/pi-camera-assets/hailo_yolov8_inference.json \
  --width 1920 --height 1080 \
  --framerate 30 \
  -o "$OUTPUT_FILE"

echo ""
echo "✅ Recorded to: $OUTPUT_FILE"
echo ""
echo "To play:"
echo "  vlc $OUTPUT_FILE"
echo "Or convert to MP4:"
echo "  ffmpeg -i $OUTPUT_FILE -c:v copy ${OUTPUT_FILE%.h264}.mp4"

