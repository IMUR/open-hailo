#!/bin/bash
# Master setup script for Hailo-8 + Raspberry Pi 5 + Trixie (Debian 13)

# Detect hardware
HARDWARE=$(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")
OS_VERSION=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Hailo-8 + Raspberry Pi Setup                          ║"
echo "║     Modular Configuration System                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Detected: $HARDWARE"
echo "OS: $OS_VERSION"
echo ""

# Check if HailoRT is installed
if command -v hailortcli &> /dev/null; then
    HAILORT_VERSION=$(hailortcli --version 2>&1 | grep -oP 'HailoRT-CLI version \K[0-9.]+' || echo "Unknown")
    echo "✅ HailoRT $HAILORT_VERSION installed"
else
    echo "⚠️  HailoRT not installed"
fi
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  SETUP OPTIONS"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Core Setup:"
echo "  1. Install build dependencies"
echo "  2. Setup HailoRT driver + library"
echo "  3. Verify Hailo installation"
echo "  4. Run diagnostics"
echo ""
echo "Deployment Configurations:"
echo "  5. rpicam-apps (recommended - works with any models)"
echo "  6. Python Direct API (requires Pi-compatible models)"
echo "  7. Frigate NVR (network video recorder)"
echo "  8. TAPPAS Pipelines (under development)"
echo "  9. OpenCV Custom (advanced)"
echo ""
echo "  0. Exit"
echo ""
read -p "Enter option (0-9): " option

case $option in
    1)
        echo ""
        echo "Installing build dependencies..."
        ./scripts/setup/install_build_dependencies.sh
        ;;
    2)
        echo ""
        echo "Setting up HailoRT..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ./scripts/driver/get_official_driver.sh
        echo ""
        echo "✅ Driver installed!"
        echo ""
        echo "Next: Run option 3 to verify installation"
        ;;
    3)
        echo ""
        ./scripts/setup/verify_hailo_installation.sh
        ;;
    4)
        echo ""
        ./scripts/diagnostics/check_version_compatibility.sh
        ;;
    5)
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║     rpicam-apps Configuration                             ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        echo "✅ Works with any HEF models (auto-handles page size)"
        echo "✅ Official Raspberry Pi integration"
        echo "✅ Low latency, built-in overlays"
        echo ""
        ./configs/rpicam/install.sh
        ;;
    6)
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║     Python Direct API Configuration                       ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        echo "⚠️  Requires Pi-compatible HEF models (4KB page size)"
        echo "See: configs/python-direct/README.md"
        echo ""
        ./configs/python-direct/install.sh
        ;;
    7)
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║     Frigate NVR Configuration                             ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Choose deployment:"
        echo "  a) Docker (recommended)"
        echo "  b) Native (advanced)"
        echo ""
        read -p "Enter choice (a/b): " frigate_choice
        case $frigate_choice in
            a)
                echo ""
                echo "Starting Frigate with Docker..."
                cd configs/frigate/docker
                docker compose up -d
                echo ""
                echo "✅ Frigate running at http://localhost:5000"
                ;;
            b)
                echo ""
                ./configs/frigate/native/install_frigate_native.sh
                ;;
            *)
                echo "Invalid choice"
                ;;
        esac
        ;;
    8)
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║     TAPPAS Configuration                                  ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        ./configs/tappas/install.sh
        ;;
    9)
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║     OpenCV Custom Configuration                           ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        ./configs/opencv-custom/install.sh
        ;;
    0)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "📖 For more information:"
echo "   - Configuration docs: configs/<name>/README.md"
echo "   - General setup: docs/SETUP.md"
echo "   - Troubleshooting: docs/TROUBLESHOOTING.md"
echo "═══════════════════════════════════════════════════════════"
