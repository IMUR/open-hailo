#!/bin/bash
# TAPPAS Core Installation for Raspberry Pi 5 + Debian Trixie
# Based on successful installation from archive branch

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  TAPPAS Core Installation (Raspberry Pi 5)                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "This installs ONLY the C++ post-processing libraries (.so files)"
echo "needed by rpicam-apps for Hailo inference."
echo ""
echo "What this installs:"
echo "  ✅ TAPPAS core C++ libraries (system-wide)"
echo "  ✅ pkg-config files for rpicam-apps to find libraries"
echo ""
echo "What this does NOT install:"
echo "  ❌ TAPPAS Python tools (not needed for rpicam-apps)"
echo "  ❌ GStreamer plugins (not needed for rpicam-apps)"
echo "  ❌ Python virtual environment (C++ only, no Python)"
echo ""
echo "Time: ~15 minutes"
echo ""

# Step 1: Check prerequisites
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1/5: Checking Prerequisites"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check HailoRT
if ! command -v hailortcli &> /dev/null; then
    echo "❌ HailoRT not found!"
    echo "Please install HailoRT first:"
    echo "  cd $PROJECT_ROOT"
    echo "  ./setup.sh → option 2"
    exit 1
fi

HAILORT_VERSION=$(hailortcli --version 2>&1 | grep -oP 'HailoRT-CLI version \K[0-9.]+' || echo "Unknown")
echo "✅ HailoRT $HAILORT_VERSION found"

# Note: We do NOT need uv for --core-only installation
# The core C++ libraries don't require Python virtual environments
# uv is only needed if you're installing full TAPPAS with Python tools

# Check GStreamer
if ! pkg-config --exists gstreamer-1.0; then
    echo "❌ GStreamer development libraries not found"
    echo "Run: ./scripts/setup/install_build_dependencies.sh"
    exit 1
fi

echo "✅ GStreamer $(pkg-config --modversion gstreamer-1.0)"

# Check OpenCV
if ! pkg-config --exists opencv4; then
    echo "❌ OpenCV not found"
    echo "Run: sudo apt install libopencv-dev"
    exit 1
fi

echo "✅ OpenCV $(pkg-config --modversion opencv4)"
echo ""

# Step 2: Clone TAPPAS
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2/5: Cloning TAPPAS Repository"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TAPPAS_DIR="$HOME/tappas"

if [ -d "$TAPPAS_DIR" ]; then
    echo "⚠️  TAPPAS directory already exists at $TAPPAS_DIR"
    read -p "Remove and re-clone? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$TAPPAS_DIR"
    else
        echo "Keeping existing TAPPAS directory"
    fi
fi

if [ ! -d "$TAPPAS_DIR" ]; then
    echo "Cloning TAPPAS (this may take a few minutes)..."
    git clone https://github.com/hailo-ai/tappas.git "$TAPPAS_DIR"
    echo "✅ TAPPAS cloned to $TAPPAS_DIR"
else
    echo "✅ Using existing TAPPAS at $TAPPAS_DIR"
fi

cd "$TAPPAS_DIR"
echo ""

# Step 3: Create HailoRT symlink
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3/5: Creating HailoRT Symlink"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# TAPPAS expects HailoRT sources at hailort/sources
mkdir -p "$TAPPAS_DIR/hailort"

HAILORT_SRC="$PROJECT_ROOT/hailort/hailort-${HAILORT_VERSION}"
if [ ! -d "$HAILORT_SRC" ]; then
    echo "⚠️  HailoRT source not found at $HAILORT_SRC"
    echo "Looking for any HailoRT source directory..."
    HAILORT_SRC=$(find "$PROJECT_ROOT/hailort" -maxdepth 1 -type d -name "hailort-*" | head -1)
fi

if [ -d "$HAILORT_SRC" ]; then
    ln -sf "$HAILORT_SRC" "$TAPPAS_DIR/hailort/sources"
    echo "✅ Symlink created: $TAPPAS_DIR/hailort/sources → $HAILORT_SRC"
else
    echo "❌ Cannot find HailoRT source directory in $PROJECT_ROOT/hailort"
    exit 1
fi

echo ""

# Step 4: Note about patching (NOT needed for core-only)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4/5: Preparing Installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Note: No patching needed for --core-only installation
# The --core-only flag skips Python virtual environment creation
# It only builds and installs the C++ post-processing libraries

echo "✅ Using --core-only flag (no Python venv needed)"
echo ""

# Step 5: Install TAPPAS
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5/5: Installing TAPPAS Core"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will take ~15 minutes..."
echo ""

# Run TAPPAS installation
# --target-platform rpi5: Raspberry Pi 5 target
# --skip-hailort: We already have HailoRT installed
# --core-only: Only install core libraries (not full apps)
./install.sh --target-platform rpi5 --skip-hailort --core-only

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           TAPPAS INSTALLATION COMPLETE! ✅                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Verify installation
echo "Verifying TAPPAS installation..."
if pkg-config --exists hailo-tappas-core; then
    TAPPAS_VERSION=$(pkg-config --modversion hailo-tappas-core)
    echo "✅ TAPPAS Core $TAPPAS_VERSION installed successfully"
else
    echo "⚠️  TAPPAS pkg-config not found, but installation may have succeeded"
    echo "   Check: ls -la $TAPPAS_DIR/core/"
fi

echo ""
echo "Next steps:"
echo "  1. Build rpicam-apps with Hailo support:"
echo "     ./scripts/build/build_hailo_preview_local.sh"
echo ""
echo "  2. Or continue with setup.sh → option 5"
echo ""
