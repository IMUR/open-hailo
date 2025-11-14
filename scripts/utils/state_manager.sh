#!/bin/bash
# State Management Utilities for open-hailo
# Tracks installation state, versions, and capabilities

STATE_FILE="${STATE_FILE:-$HOME/.config/open-hailo/state.json}"
LOG_DIR="${LOG_DIR:-$HOME/.config/open-hailo/logs}"

# Initialize state file and log directory
init_state() {
    mkdir -p "$(dirname "$STATE_FILE")"
    mkdir -p "$LOG_DIR"

    if [ ! -f "$STATE_FILE" ]; then
        cat > "$STATE_FILE" << 'EOF'
{
  "version": "1.0.0",
  "last_updated": "",
  "system": {
    "hardware": "",
    "os": "",
    "os_version": "",
    "kernel": "",
    "architecture": "",
    "python_version": ""
  },
  "components": {
    "hailort": {
      "installed": false,
      "version": null,
      "install_date": null,
      "install_method": null,
      "location": null,
      "log_file": null
    },
    "hailo_driver": {
      "installed": false,
      "version": null,
      "install_date": null,
      "loaded": false,
      "log_file": null
    },
    "tappas": {
      "installed": false,
      "version": null,
      "install_date": null,
      "location": null,
      "log_file": null
    },
    "rpicam-apps": {
      "installed": false,
      "version": null,
      "install_date": null,
      "hailo_support": false,
      "install_location": null,
      "log_file": null
    },
    "dependencies": {
      "opencv": {
        "installed": false,
        "version": null
      },
      "gstreamer": {
        "installed": false,
        "version": null
      },
      "boost": {
        "installed": false,
        "version": null
      },
      "uv": {
        "installed": false,
        "version": null,
        "install_method": null
      }
    }
  },
  "models": {
    "available": [],
    "location": null
  },
  "logs": {
    "directory": "$LOG_DIR",
    "retention_days": 30,
    "files": []
  },
  "capabilities": {
    "hailo_device_detected": false,
    "camera_detected": false,
    "can_run_inference": false,
    "can_use_rpicam": false,
    "can_use_python_api": false
  }
}
EOF
    fi
}

# Update system information
update_system_info() {
    init_state

    local hardware=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || echo "Unknown")
    local os=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    local os_version=$(grep VERSION_ID /etc/os-release | cut -d'=' -f2 | tr -d '"')
    local kernel=$(uname -r)
    local arch=$(uname -m)
    local python_ver=$(python3 --version 2>&1 | awk '{print $2}')
    local timestamp=$(date -Iseconds)

    # Use jq if available, otherwise use sed (less reliable)
    if command -v jq &> /dev/null; then
        jq --arg hw "$hardware" \
           --arg os "$os" \
           --arg osv "$os_version" \
           --arg kern "$kernel" \
           --arg arch "$arch" \
           --arg py "$python_ver" \
           --arg ts "$timestamp" \
           '.last_updated = $ts |
            .system.hardware = $hw |
            .system.os = $os |
            .system.os_version = $osv |
            .system.kernel = $kern |
            .system.architecture = $arch |
            .system.python_version = $py' \
           "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    else
        echo "⚠️  jq not installed, using fallback method"
    fi
}

# Set component state
set_component() {
    local component=$1
    local field=$2
    local value=$3

    init_state

    if command -v jq &> /dev/null; then
        local timestamp=$(date -Iseconds)
        jq --arg comp "$component" \
           --arg field "$field" \
           --arg val "$value" \
           --arg ts "$timestamp" \
           '.last_updated = $ts |
            .components[$comp][$field] = $val' \
           "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
}

# Get component state
get_component() {
    local component=$1
    local field=$2

    if [ ! -f "$STATE_FILE" ]; then
        echo "null"
        return
    fi

    if command -v jq &> /dev/null; then
        jq -r ".components.${component}.${field} // \"null\"" "$STATE_FILE"
    else
        echo "null"
    fi
}

# Mark component as installed
mark_installed() {
    local component=$1
    local version=$2
    local location=${3:-""}
    local log_file=${4:-""}

    init_state

    local timestamp=$(date -Iseconds)

    if command -v jq &> /dev/null; then
        jq --arg comp "$component" \
           --arg ver "$version" \
           --arg loc "$location" \
           --arg log "$log_file" \
           --arg ts "$timestamp" \
           '.last_updated = $ts |
            .components[$comp].installed = true |
            .components[$comp].version = $ver |
            .components[$comp].install_date = $ts |
            .components[$comp].location = $loc |
            .components[$comp].log_file = $log' \
           "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi

    echo "✅ Marked $component ($version) as installed"
}

# Detect and update capabilities
update_capabilities() {
    init_state

    local hailo_dev=false
    local camera=false
    local inference=false
    local rpicam=false
    local python_api=false

    # Check Hailo device
    if [ -c /dev/hailo0 ]; then
        hailo_dev=true
    fi

    # Check camera
    if rpicam-hello --list-cameras 2>&1 | grep -q "Available cameras"; then
        camera=true
    fi

    # Check if can run inference
    if command -v hailortcli &> /dev/null && [ -c /dev/hailo0 ]; then
        inference=true
    fi

    # Check rpicam capability
    if command -v rpicam-hello &> /dev/null; then
        rpicam=true
    fi

    # Check Python API
    if python3 -c "import hailo_platform" 2>/dev/null; then
        python_api=true
    fi

    if command -v jq &> /dev/null; then
        local timestamp=$(date -Iseconds)
        jq --argjson hailo "$hailo_dev" \
           --argjson cam "$camera" \
           --argjson inf "$inference" \
           --argjson rpi "$rpicam" \
           --argjson py "$python_api" \
           --arg ts "$timestamp" \
           '.last_updated = $ts |
            .capabilities.hailo_device_detected = $hailo |
            .capabilities.camera_detected = $cam |
            .capabilities.can_run_inference = $inf |
            .capabilities.can_use_rpicam = $rpi |
            .capabilities.can_use_python_api = $py' \
           "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
}

# Show current state
show_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "❌ No state file found. Run a setup script to initialize."
        return 1
    fi

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            Open-Hailo System State                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    if command -v jq &> /dev/null; then
        echo "System Information:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  Hardware: $(jq -r '.system.hardware' "$STATE_FILE")"
        echo "  OS: $(jq -r '.system.os' "$STATE_FILE")"
        echo "  Kernel: $(jq -r '.system.kernel' "$STATE_FILE")"
        echo "  Architecture: $(jq -r '.system.architecture' "$STATE_FILE")"
        echo "  Python: $(jq -r '.system.python_version' "$STATE_FILE")"
        echo ""

        echo "Installed Components:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # HailoRT
        if [ "$(jq -r '.components.hailort.installed' "$STATE_FILE")" = "true" ]; then
            echo "  ✅ HailoRT $(jq -r '.components.hailort.version' "$STATE_FILE")"
        else
            echo "  ❌ HailoRT (not installed)"
        fi

        # TAPPAS
        if [ "$(jq -r '.components.tappas.installed' "$STATE_FILE")" = "true" ]; then
            echo "  ✅ TAPPAS $(jq -r '.components.tappas.version' "$STATE_FILE")"
        else
            echo "  ❌ TAPPAS (not installed)"
        fi

        # rpicam-apps
        if [ "$(jq -r '.components["rpicam-apps"].installed' "$STATE_FILE")" = "true" ]; then
            local hailo_support=$(jq -r '.components["rpicam-apps"].hailo_support' "$STATE_FILE")
            if [ "$hailo_support" = "true" ]; then
                echo "  ✅ rpicam-apps $(jq -r '.components["rpicam-apps"].version' "$STATE_FILE") (with Hailo support)"
            else
                echo "  ⚠️  rpicam-apps $(jq -r '.components["rpicam-apps"].version' "$STATE_FILE") (no Hailo support)"
            fi
        else
            echo "  ❌ rpicam-apps (not installed)"
        fi

        echo ""
        echo "Capabilities:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        if [ "$(jq -r '.capabilities.hailo_device_detected' "$STATE_FILE")" = "true" ]; then
            echo "  ✅ Hailo device detected"
        else
            echo "  ❌ Hailo device not detected"
        fi

        if [ "$(jq -r '.capabilities.camera_detected' "$STATE_FILE")" = "true" ]; then
            echo "  ✅ Camera detected"
        else
            echo "  ❌ Camera not detected"
        fi

        if [ "$(jq -r '.capabilities.can_run_inference' "$STATE_FILE")" = "true" ]; then
            echo "  ✅ Can run inference"
        else
            echo "  ❌ Cannot run inference"
        fi

        if [ "$(jq -r '.capabilities.can_use_rpicam' "$STATE_FILE")" = "true" ]; then
            echo "  ✅ Can use rpicam-apps"
        else
            echo "  ❌ Cannot use rpicam-apps"
        fi

        echo ""
        echo "Last Updated: $(jq -r '.last_updated' "$STATE_FILE")"
        echo "State File: $STATE_FILE"
    else
        echo "❌ jq not installed - cannot parse state file"
        echo "Install jq: sudo apt install jq"
    fi
}

# Export functions for use in other scripts
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being run directly
    case "${1:-}" in
        init)
            init_state
            update_system_info
            echo "✅ State initialized at $STATE_FILE"
            ;;
        show|status)
            show_state
            ;;
        update)
            update_system_info
            update_capabilities
            echo "✅ State updated"
            ;;
        *)
            echo "Usage: $0 {init|show|update}"
            echo ""
            echo "Commands:"
            echo "  init   - Initialize state file"
            echo "  show   - Show current state"
            echo "  update - Update system info and capabilities"
            ;;
    esac
fi
