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
# Create systemd service file with wrapper script
# ============================================================================
echo "[1/3] Creating HTTP server wrapper script..."

# Create a wrapper script that waits for network before starting
sudo tee /usr/local/bin/start-hta-http-server.sh > /dev/null << 'WRAPPER_EOF'
#!/bin/bash
# HTTP Server wrapper - ensures payload directory and network are ready
# This directory is VM-local, NOT a shared folder (immune to Windows VM operations)
PAYLOAD_DIR="/home/vagrant/hta_payloads"
MAX_WAIT=60

# Ensure payload directory exists and is owned by vagrant
# This is a VM-local directory, completely independent of shared folders
if [ ! -d "$PAYLOAD_DIR" ]; then
    mkdir -p "$PAYLOAD_DIR"
    chown vagrant:vagrant "$PAYLOAD_DIR"
fi

# Wait for network interface to be ready
elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
    if ip addr show eth1 2>/dev/null | grep -q '192.168.56.101'; then
        # Network ready, start server from VM-local directory
        cd "$PAYLOAD_DIR" || exit 1
        exec /usr/bin/python3 -m http.server 8080 --bind 192.168.56.101
    fi
    sleep 2
    elapsed=$((elapsed + 2))
done

# If we get here, network not ready after timeout
echo "ERROR: Network interface eth1 (192.168.56.101) not ready after ${MAX_WAIT}s" >&2
exit 1
WRAPPER_EOF

sudo chmod +x /usr/local/bin/start-hta-http-server.sh

echo "[2/3] Creating systemd service..."

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=HTA Exploit HTTP Server (VM-local, no shared folders)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=vagrant
Group=vagrant
ExecStart=/usr/local/bin/start-hta-http-server.sh
# Only restart on failure, not on clean shutdown
Restart=on-failure
# Wait longer between restart attempts to avoid spam during network issues
RestartSec=15
# Give up after 5 restart attempts within 180 seconds
StartLimitBurst=5
StartLimitIntervalSec=180
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
echo "[3/3] Enabling and starting service..."

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
echo "  Wrapper: /usr/local/bin/start-hta-http-server.sh"
echo
echo "How it works:"
echo "  - Serves from /home/vagrant/hta_payloads (VM-local, NOT shared)"
echo "  - Systemd starts wrapper script on boot"
echo "  - Wrapper ensures directory exists and waits for network"
echo "  - Then starts Python HTTP server"
echo "  - Auto-restarts on failure (max 5 times in 3 minutes)"
echo "  - Immune to Windows VM restarts and shared folder operations"
echo
echo "To check status:"
echo "  sudo systemctl status ${SERVICE_NAME}"
echo "  journalctl -u ${SERVICE_NAME} -f"
echo
echo "Access at: http://192.168.56.101:${HTTP_PORT}/"
echo
