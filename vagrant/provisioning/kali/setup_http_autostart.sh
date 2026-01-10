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
# Wait for Host-Only network interface to have IP 192.168.56.101
ExecStartPre=/bin/bash -c 'timeout 60 bash -c "until ip addr show eth1 | grep -q 192.168.56.101; do sleep 2; done"'
# Wait for payload file to exist
ExecStartPre=/bin/bash -c 'timeout 30 bash -c "until [ -f ${PAYLOAD_DIR}/update.exe ]; do sleep 1; done"'
ExecStart=/usr/bin/python3 -m http.server ${HTTP_PORT} --bind 192.168.56.101
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
echo "[2/2] Enabling and starting service..."

# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable ${SERVICE_NAME}.service

# Start service now
sudo systemctl start ${SERVICE_NAME}.service

# Wait for service to be ready
sleep 2

# Verify service is running
if sudo systemctl is-active --quiet ${SERVICE_NAME}.service; then
    echo "✓ Service enabled and started successfully"
else
    echo "⚠ Warning: Service enabled but not running (will start on boot)"
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
echo "  Status: Running"
echo
echo "HTTP server is now accessible at:"
echo "  http://192.168.56.101:${HTTP_PORT}/"
echo
echo "Useful commands:"
echo "  sudo systemctl status ${SERVICE_NAME}    # Check status"
echo "  sudo systemctl stop ${SERVICE_NAME}      # Stop server"
echo "  sudo systemctl start ${SERVICE_NAME}     # Start server"
echo "  sudo systemctl restart ${SERVICE_NAME}   # Restart server"
echo "  sudo journalctl -u ${SERVICE_NAME} -f    # View logs"
echo
