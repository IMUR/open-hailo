#!/bin/bash
# Python Direct API Configuration Installer

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Python Direct API Configuration Installer             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check HailoRT
if ! command -v hailortcli &> /dev/null; then
    echo "❌ HailoRT not installed!"
    echo "Run: ./setup.sh"
    exit 1
fi

# Create/activate venv
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv --system-site-packages .venv
fi

source .venv/bin/activate

# Install dependencies
echo "Installing Python packages..."
pip install --quiet opencv-python pillow picamera2 numpy

# Check hailo_platform
if python3 -c "import hailo_platform" 2>/dev/null; then
    echo "✅ hailo_platform module found"
else
    echo "⚠️  hailo_platform not found. Installing..."
    cd "$PROJECT_ROOT/hailort/hailort-4.23.0/hailort/libhailort/bindings/python/platform"
    python setup.py install
    cd "$PROJECT_ROOT"
fi

# Check for models
echo ""
echo "Checking for Pi-compatible models..."
if ls models/pi5-compatible/*.hef 1> /dev/null 2>&1; then
    echo "✅ Found Pi-compatible models"
else
    echo "⚠️  No Pi-compatible models found"
    echo "See: configs/python-direct/README.md for how to get them"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next: python configs/python-direct/examples/live_detection.py"

