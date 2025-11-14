#!/bin/bash
# Manual TAPPAS Core Build
# Based on standard meson/ninja build process

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TAPPAS_DIR="$HOME/tappas"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       Manual TAPPAS Core Build                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -d "$TAPPAS_DIR" ]; then
    echo "❌ TAPPAS directory not found at $TAPPAS_DIR"
    echo "Run: ./scripts/setup/install_tappas.sh first"
    exit 1
fi

cd "$TAPPAS_DIR"

echo "Building TAPPAS core libraries manually..."
echo ""

# Step 1: Setup build directory
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Setting up build directory"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BUILD_DIR="$TAPPAS_DIR/build/$(uname -m)"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Build directory: $BUILD_DIR"
echo ""

# Step 2: Configure with meson
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Configuring with meson"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$TAPPAS_DIR/core/hailo"

# Check if HailoRT is available
if ! pkg-config --exists HailoRT; then
    echo "⚠️  HailoRT pkg-config not found, setting PKG_CONFIG_PATH"
    export PKG_CONFIG_PATH="/usr/local/lib/cmake/HailoRT:$PKG_CONFIG_PATH"
fi

# Configure meson with correct options for TAPPAS core
# Point to actual locations of dependencies
# Also set CXXFLAGS to include header directories
export CXXFLAGS="-I$TAPPAS_DIR/sources/xtl/include -I$TAPPAS_DIR/sources/xtensor/include -I$TAPPAS_DIR/sources/xtensor-blas/include -I$TAPPAS_DIR/sources/rapidjson/include $CXXFLAGS"

meson setup "$BUILD_DIR" \
    --prefix=/usr/local \
    --libdir=lib \
    --buildtype=release \
    -Dtarget=libs \
    -Dtarget_platform=rpi5 \
    -Dinclude_python=false \
    -Dlibxtensor="$TAPPAS_DIR/sources/xtensor" \
    -Dlibblas="$TAPPAS_DIR/sources/xtensor-blas" \
    -Dlibcxxopts="$TAPPAS_DIR/sources/cxxopts" \
    -Dlibrapidjson="$TAPPAS_DIR/sources/rapidjson/include" \
    -Dpybind11="$TAPPAS_DIR/sources/pybind11" \
    -Dlibcatch2="$TAPPAS_DIR/sources/Catch2"

echo "✅ Meson configuration complete"
echo ""

# Step 3: Build
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Building with ninja"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ninja -C "$BUILD_DIR"

echo "✅ Build complete"
echo ""

# Step 4: Install
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Installing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sudo ninja -C "$BUILD_DIR" install

echo "✅ Installation complete"
echo ""

# Step 5: Update ldconfig
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5: Updating library cache"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sudo ldconfig

echo "✅ Library cache updated"
echo ""

# Step 6: Install Headers
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 6: Installing headers"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sudo mkdir -p /usr/include/hailo/tappas
sudo cp -r "$TAPPAS_DIR/core/hailo/libs/postprocesses" /usr/include/hailo/tappas/
sudo cp -r "$TAPPAS_DIR/core/hailo/general" /usr/include/hailo/tappas/
sudo cp -r "$TAPPAS_DIR/core/hailo/libs/croppers" /usr/include/hailo/tappas/ 2>/dev/null || true
sudo cp -r "$TAPPAS_DIR/core/hailo/libs/tools" /usr/include/hailo/tappas/ 2>/dev/null || true
sudo cp -r "$TAPPAS_DIR/core/hailo/plugins/common" /usr/include/hailo/tappas/ 2>/dev/null || true

echo "✅ Headers installed to /usr/include/hailo/tappas/"
echo ""

# Step 7: Create pkg-config file
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 7: Creating pkg-config file"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sudo tee /usr/lib/aarch64-linux-gnu/pkgconfig/hailo-tappas-core.pc > /dev/null <<EOF
prefix=/usr
libdir=/usr/lib/aarch64-linux-gnu
tappas_libdir=\${libdir}/hailo/tappas
includedir=\${prefix}/include/hailo/tappas
tappas_sources=$TAPPAS_DIR/sources

Name: hailo-tappas-core
Description: Hailo TAPPAS Core post-processing libraries
Version: 5.1.0
Libs: -L\${tappas_libdir}/post_processes
Cflags: -I\${includedir}/postprocesses -I\${includedir}/general -I\${tappas_sources}/xtensor/include -I\${tappas_sources}/xtl/include -I\${tappas_sources}/rapidjson/include
EOF

echo "✅ pkg-config file created"
echo ""

# Step 8: Verify
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 8: Verifying installation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if pkg-config --exists hailo-tappas-core; then
    TAPPAS_VERSION=$(pkg-config --modversion hailo-tappas-core)
    echo "✅ TAPPAS Core $TAPPAS_VERSION installed"
    echo ""
    echo "Installed to:"
    echo "  Prefix: $(pkg-config --variable=prefix hailo-tappas-core)"
    echo "  Libdir: $(pkg-config --variable=libdir hailo-tappas-core)"
    echo "  Include: $(pkg-config --variable=includedir hailo-tappas-core)"
    echo ""
    echo "Cflags: $(pkg-config --cflags hailo-tappas-core)"

    # List post-processing libraries
    LIBDIR=$(pkg-config --variable=libdir hailo-tappas-core)
    TAPPAS_LIBDIR=$(pkg-config --variable=tappas_libdir hailo-tappas-core 2>/dev/null || echo "$LIBDIR/hailo/tappas")

    if [ -d "$TAPPAS_LIBDIR" ]; then
        echo ""
        echo "TAPPAS libraries:"
        find "$TAPPAS_LIBDIR" -name "*.so" -type f 2>/dev/null | while read lib; do
            echo "  - $(basename $lib)"
        done
    fi
else
    echo "❌ TAPPAS pkg-config still not found"
    echo ""
    echo "Checking for libraries manually..."
    find /usr/local/lib -name "*tappas*" -o -name "*hailo*postproc*" 2>/dev/null || echo "  None found"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║             Manual Build Complete                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Next step: Build rpicam-apps with Hailo support"
echo "  ./configs/rpicam/install.sh"
echo ""
