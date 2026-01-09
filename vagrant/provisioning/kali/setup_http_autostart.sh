#!/bin/bash
################################################################################
# Setup HTTP Server Autostart
# Creates systemd service to start HTTP server on boot for LNK exploit
################################################################################

set -e

echo "=================================="
echo "Setting up HTTP server autostart"
echo "=================================="
echo

# Configuration
HTTP_PORT="8080"
EXPLOIT_DIR="/home/vagrant/exploits/lnk"  # Non-shared directory
SERVICE_NAME="lnk-http-server"

# ============================================================================
# Create systemd service file
# ============================================================================
echo "[1/3] Creating systemd service..."

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=LNK Exploit HTTP Server
After=network-online.target vagrant.mount
Wants=network-online.target
Requires=vagrant.mount

[Service]
Type=simple
User=vagrant
Group=vagrant
WorkingDirectory=${EXPLOIT_DIR}
ExecStartPre=/bin/sleep 5
ExecStartPre=/bin/bash -c 'timeout 30 bash -c "until [ -f ${EXPLOIT_DIR}/shell.ps1 ]; do sleep 1; done"'
ExecStart=/usr/bin/python3 -m http.server ${HTTP_PORT}
Restart=always
RestartSec=10
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
echo "[2/3] Enabling service..."

# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable ${SERVICE_NAME}.service

# Start service now
sudo systemctl start ${SERVICE_NAME}.service

echo "✓ Service enabled and started"
echo

# ============================================================================
# Verify service is running
# ============================================================================
echo "[3/3] Verifying service..."

# Wait a moment for service to start
sleep 2

# Check service status
if sudo systemctl is-active --quiet ${SERVICE_NAME}.service; then
    echo "✓ HTTP server is running on port ${HTTP_PORT}"

    # Get service status
    sudo systemctl status ${SERVICE_NAME}.service --no-pager -l | head -10

    echo
    echo "HTTP server is now accessible at:"
    echo "  http://192.168.56.101:${HTTP_PORT}/"
    echo
    echo "Files being served from:"
    echo "  ${EXPLOIT_DIR}/"
    echo
    echo "Service will start automatically on boot!"
else
    echo "✗ HTTP server failed to start"
    echo
    echo "Check logs with:"
    echo "  sudo journalctl -u ${SERVICE_NAME}.service -n 50"
    exit 1
fi

echo
echo "=================================="
echo "HTTP autostart setup complete!"
echo "=================================="
echo
echo "Useful commands:"
echo "  sudo systemctl status ${SERVICE_NAME}    # Check status"
echo "  sudo systemctl stop ${SERVICE_NAME}      # Stop server"
echo "  sudo systemctl start ${SERVICE_NAME}     # Start server"
echo "  sudo systemctl restart ${SERVICE_NAME}   # Restart server"
echo "  sudo journalctl -u ${SERVICE_NAME} -f    # View logs"
echo
