#!/bin/bash
# Master setup script for Hailo-8 + Raspberry Pi 5

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Hailo-8 + Raspberry Pi 5 Setup                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Choose setup option:"
echo "  1. Install build dependencies"
echo "  2. Setup HailoRT driver"
echo "  3. Install Frigate NVR"
echo "  4. Run diagnostics"
echo "  5. Quick start detection"
echo ""
read -p "Enter option (1-5): " option

case $option in
    1)
        ./scripts/setup/install_build_dependencies.sh
        ;;
    2)
        ./scripts/driver/get_official_driver.sh
        ;;
    3)
        ./scripts/frigate/install_frigate_native.sh
        ;;
    4)
        ./scripts/diagnostics/check_version_compatibility.sh
        ;;
    5)
        ./scripts/quickstart/quick_start_detection.sh
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac
