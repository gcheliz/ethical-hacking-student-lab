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

[Service]
Type=simple
User=vagrant
WorkingDirectory=/home/vagrant/.msf4/local
# Bind to all interfaces (accessible from 192.168.56.101)
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable the HTTP server service (will start on boot)
sudo systemctl daemon-reload
sudo systemctl enable pdf-server.service

# Try to start now
echo "Starting HTTP server..."
if sudo systemctl start pdf-server.service 2>/dev/null; then
    # Wait a moment and check status
    sleep 3
    if sudo systemctl is-active --quiet pdf-server.service; then
        echo "✓ HTTP server started successfully"
        if [ -f "/home/vagrant/.msf4/local/JOAN-ESPINACH-TRD.pdf" ]; then
            echo "  PDF URL: http://192.168.56.101:8080/JOAN-ESPINACH-TRD.pdf"
        fi
    else
        echo "⚠ HTTP server not running yet (network may still be initializing)"
        echo "  Service will start automatically on boot"
    fi
else
    echo "⚠ Could not start HTTP server during provisioning"
    echo "  Service enabled and will start on next boot"
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
