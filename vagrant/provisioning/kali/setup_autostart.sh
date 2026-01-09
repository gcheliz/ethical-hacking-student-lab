#!/bin/bash
# Setup automatic HTTP server on boot

echo "Setting up automatic HTTP server on boot..."

# Ensure .msf4/local directory exists
mkdir -p /home/vagrant/.msf4/local

# Create systemd service file for HTTP server
sudo tee /etc/systemd/system/pdf-server.service > /dev/null << 'EOF'
[Unit]
Description=Malicious PDF HTTP Server
After=network.target
After=vagrant.mount
Requires=network.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/home/vagrant/.msf4/local
# Wait for the interface to have IP 192.168.56.101 before starting
ExecStartPre=/bin/bash -c 'for i in {1..30}; do ip addr show | grep -q "192.168.56.101" && exit 0; sleep 1; done; exit 1'
# Explicitly bind to 192.168.56.101 (host-only network)
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 192.168.56.101
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the HTTP server service
sudo systemctl daemon-reload
sudo systemctl enable pdf-server.service

# Try to start now
echo "Starting HTTP server..."
sudo systemctl start pdf-server.service

# Wait a moment for startup
sleep 2

# Check status
if sudo systemctl is-active --quiet pdf-server.service; then
    echo "✓ HTTP server started successfully"
    echo "  Listening on: 0.0.0.0:8080"
    echo "  Accessible from Windows: http://192.168.56.101:8080"

    # Show available PDFs
    if [ -f "/home/vagrant/.msf4/local/JOAN-ESPINACH-TRD.pdf" ]; then
        echo "  PDF URL: http://192.168.56.101:8080/JOAN-ESPINACH-TRD.pdf"
    fi
else
    echo "⚠ HTTP server not running yet"
    echo "  Service is enabled and will start on boot"
    echo "  To check status later: sudo systemctl status pdf-server"
    echo "  To view logs: sudo journalctl -u pdf-server -n 50"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  HTTP Server Configuration Complete"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "HTTP Server: 192.168.56.101:8080"
echo "Will start automatically on boot."
echo ""
echo "To manually start Metasploit listener:"
echo "  cd /vagrant/exploits && ./start_attack.sh"
