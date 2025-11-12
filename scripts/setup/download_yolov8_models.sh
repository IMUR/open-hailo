#!/bin/bash
# Download YOLOv8 HEF Models for Hailo-8

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       Downloading YOLOv8 Models for Hailo-8               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

MODEL_DIR="/home/crtr/Projects/open-hailo/models"
mkdir -p "$MODEL_DIR"

cd "$MODEL_DIR"

echo "Downloading YOLOv8 models from Hailo Model Zoo..."
echo ""

# YOLOv8 models for Hailo-8 (not 8L)
declare -A MODELS=(
    ["yolov8n"]="https://hailo-model-zoo.s3.eu-west-2.amazonaws.com/ModelZoo/Compiled/v2.11.0/hailo8/yolov8n.hef"
    ["yolov8s"]="https://hailo-model-zoo.s3.eu-west-2.amazonaws.com/ModelZoo/Compiled/v2.11.0/hailo8/yolov8s.hef"
    ["yolov8m"]="https://hailo-model-zoo.s3.eu-west-2.amazonaws.com/ModelZoo/Compiled/v2.11.0/hailo8/yolov8m.hef"
)

for model in "${!MODELS[@]}"; do
    url="${MODELS[$model]}"
    filename="${model}.hef"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Downloading: $filename"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if wget -q --show-progress "$url" -O "$filename"; then
        SIZE=$(stat -c%s "$filename")
        SIZE_MB=$((SIZE / 1024 / 1024))
        echo "✓ Downloaded: $filename (${SIZE_MB} MB)"
    else
        echo "✗ Failed to download: $filename"
        echo "  URL: $url"
    fi
    echo ""
done

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    DOWNLOAD COMPLETE                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if ls *.hef 1> /dev/null 2>&1; then
    echo "Downloaded models:"
    ls -lh *.hef
    echo ""
    
    echo "Model Details:"
    echo "  • yolov8n.hef - Nano (fastest, ~6MB)"
    echo "  • yolov8s.hef - Small (balanced, ~22MB)"  
    echo "  • yolov8m.hef - Medium (accurate, ~52MB)"
    echo ""
    
    echo "Recommended: yolov8s (best balance of speed and accuracy)"
    echo ""
    
    # Optionally copy to system directory
    read -p "Install to system directory (/usr/share/hailo-models/)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo mkdir -p /usr/share/hailo-models
        sudo cp *.hef /usr/share/hailo-models/
        echo "✓ Models installed to /usr/share/hailo-models/"
    fi
else
    echo "✗ No models downloaded. Check your internet connection."
    echo ""
    echo "Manual download:"
    echo "  wget https://hailo-model-zoo.s3.eu-west-2.amazonaws.com/ModelZoo/Compiled/v2.11.0/hailo8/yolov8s.hef"
fi

echo ""
echo "Next steps:"
echo "1. Build rpicam-apps with Hailo support (if not done):"
echo "   ./build_hailo_preview.sh"
echo ""
echo "2. Run live preview with YOLOv8:"
echo "   rpicam-hello -t 0 --post-process-file \\"
echo "     /home/crtr/Projects/open-hailo/test/hailo_yolov8_custom.json"
echo ""
