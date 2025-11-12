#!/bin/bash
# Install TAPPAS Dependencies
# Run this in a regular terminal (requires sudo)

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Installing TAPPAS Dependencies                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "Installing missing packages..."
echo ""

sudo apt update

sudo apt install -y \
    x11-utils \
    python-gi-dev \
    python3-gi \
    libcairo2-dev \
    libgirepository1.0-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    libzmq3-dev \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-libav

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Dependencies Installed! ✅                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Now install TAPPAS:"
echo "  cd ~/tappas"
echo "  ./install.sh --target-platform rpi5 --skip-hailort"
echo ""
echo "Note: We skip HailoRT installation since you already have 4.23.0"
echo ""

