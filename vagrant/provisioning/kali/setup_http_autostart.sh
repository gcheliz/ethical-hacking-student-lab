#!/bin/bash
################################################################################
# Setup HTTP Server Autostart
# Creates systemd service to start HTTP server on boot for HTA exploit
################################################################################

set -e

echo "=================================="
echo "Setting up HTTP server autostart"
echo "=================================="
echo

# Configuration
HTTP_PORT="8080"
PAYLOAD_DIR="/home/vagrant/hta_payloads"  # Non-shared directory for generated files
SERVICE_NAME="hta-http-server"

# ============================================================================
# Create systemd service file
# ============================================================================
echo "[1/2] Creating systemd service..."

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=HTA Exploit HTTP Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=vagrant
Group=vagrant
WorkingDirectory=${PAYLOAD_DIR}
# Simple retry logic: If network/files not ready, service will fail and restart
ExecStart=/usr/bin/python3 -m http.server ${HTTP_PORT} --bind 192.168.56.101
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✓ Service file created: /etc/systemd/system/${SERVICE_NAME}.service"
echo

# ============================================================================
# Enable and start service
# ============================================================================
echo "[2/2] Enabling and starting service..."

# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable ${SERVICE_NAME}.service

# Try to start service now (non-blocking)
# Note: Service may not start if conditions aren't met yet
# It will auto-start on next boot when conditions are satisfied
echo "  Attempting to start service..."
if sudo systemctl start ${SERVICE_NAME}.service 2>/dev/null; then
    sleep 2
    if sudo systemctl is-active --quiet ${SERVICE_NAME}.service; then
        echo "✓ Service enabled and started successfully"
    else
        echo "✓ Service enabled (will start on boot or when conditions are met)"
    fi
else
    echo "✓ Service enabled (will start on boot when conditions are met)"
fi

echo
echo "=================================="
echo "HTTP autostart setup complete!"
echo "=================================="
echo
echo "Service details:"
echo "  Name: ${SERVICE_NAME}"
echo "  Port: ${HTTP_PORT}"
echo "  Bind: 192.168.56.101"
echo "  Directory: ${PAYLOAD_DIR}"
echo
echo "The HTTP server will:"
echo "  - Auto-start on every boot via systemd"
echo "  - Be available after VM restart"
echo
echo "To check status after boot:"
echo "  sudo systemctl status ${SERVICE_NAME}"
echo
echo "Access at: http://192.168.56.101:${HTTP_PORT}/"
echo
