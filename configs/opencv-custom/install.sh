#!/bin/bash
# OpenCV Custom Pipeline Installer
# Uses same setup as python-direct

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "Installing OpenCV custom pipeline configuration..."
echo "This uses the same environment as python-direct"
echo ""

# Run python-direct install
"$PROJECT_ROOT/configs/python-direct/install.sh"

echo ""
echo "✅ Ready for custom OpenCV pipelines"
echo "See: configs/opencv-custom/examples/"

