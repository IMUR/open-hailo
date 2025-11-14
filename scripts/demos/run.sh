#!/bin/bash
# Run Hailo detection preview

if [ -f scripts/quickstart/hailo_detect.sh ]; then
    ./scripts/quickstart/hailo_detect.sh
else
    echo "Starting Frigate..."
    sudo systemctl start frigate
    echo "Access at: http://$(hostname -I | cut -d' ' -f1):5000"
fi
