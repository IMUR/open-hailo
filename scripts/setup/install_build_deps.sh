#!/bin/bash
# Install Build Dependencies for rpicam-apps with Hailo
# Run this in a REGULAR TERMINAL (not AI interface) where sudo works

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Installing Build Dependencies for rpicam-apps         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  This requires sudo. Run in a regular terminal!"
echo ""

set -e

echo "Installing required packages..."
echo ""

sudo apt update

sudo apt install -y \
    meson \
    ninja-build \
    pkg-config \
    build-essential \
    git \
    libboost-dev \
    libboost-program-options-dev \
    libgnutls28-dev \
    openssl \
    libssl-dev \
    libdrm-dev \
    libexif-dev \
    libjpeg-dev \
    libtiff5-dev \
    libpng-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavformat-dev \
    libswresample-dev \
    libcamera-dev \
    libepoxy-dev \
    libglib2.0-dev \
    libegl1-mesa-dev \
    libgles2-mesa-dev \
    libx11-dev

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║            Dependencies Installed! ✅                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Now you can run the build script:"
echo "  cd /home/crtr/Projects/open-hailo"
echo "  ./build_hailo_preview_local.sh"
echo ""

