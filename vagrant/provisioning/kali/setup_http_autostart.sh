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
PAYLOAD_DIR="/home/vagrant/lnk_payloads"  # Non-shared directory for generated files
SERVICE_NAME="lnk-http-server"

# ============================================================================
# Create systemd service file
# ============================================================================
echo "[1/2] Creating systemd service..."

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=LNK Exploit HTTP Server
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
ExecStartPre=/bin/bash -c 'timeout 30 bash -c "until [ -f ${PAYLOAD_DIR}/shell.ps1 ]; do sleep 1; done"'
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
# Enable service (don't start during provisioning)
# ============================================================================
echo "[2/2] Enabling service for automatic startup on boot..."

# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot (don't start now to avoid timeout)
sudo systemctl enable ${SERVICE_NAME}.service

echo "✓ Service enabled"
echo
echo "Note: Service will start automatically on next boot"
echo "      (Not started now to avoid provisioning timeout)"

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
echo "The HTTP server will start automatically on boot."
echo "After reboot, it will be accessible at:"
echo "  http://192.168.56.101:${HTTP_PORT}/"
echo
echo "Useful commands:"
echo "  sudo systemctl status ${SERVICE_NAME}    # Check status"
echo "  sudo systemctl stop ${SERVICE_NAME}      # Stop server"
echo "  sudo systemctl start ${SERVICE_NAME}     # Start server"
echo "  sudo systemctl restart ${SERVICE_NAME}   # Restart server"
echo "  sudo journalctl -u ${SERVICE_NAME} -f    # View logs"
echo
