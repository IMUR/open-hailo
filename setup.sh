#!/bin/bash
# Master setup script for Hailo-8 + Raspberry Pi 5 + Trixie (Debian 13)

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Hailo-8 + Raspberry Pi 5 Setup                         ║"
echo "║     Raspberry Pi OS Trixie (Debian 13)                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Choose setup option:"
echo "  1. Install build dependencies"
echo "  2. Setup HailoRT driver (official)"
echo "  3. Install Frigate NVR (native)"
echo "  4. Run diagnostics & version check"
echo "  5. Verify Hailo installation"
echo "  6. Run detection demo"
echo ""
read -p "Enter option (1-6): " option

case $option in
    1)
        ./scripts/setup/install_build_dependencies.sh
        ;;
    2)
        echo "Getting official driver..."
        ./scripts/driver/get_official_driver.sh
        echo ""
        echo "Install driver with:"
        echo "  sudo ./scripts/driver/install_official_driver.sh"
        ;;
    3)
        ./scripts/frigate/install_frigate_native.sh
        ;;
    4)
        ./scripts/diagnostics/check_version_compatibility.sh
        ;;
    5)
        ./scripts/setup/verify_hailo_installation.sh
        ;;
    6)
        ./demo_detection.sh
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac
