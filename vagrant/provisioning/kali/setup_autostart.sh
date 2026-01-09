#!/bin/bash
# Setup automatic HTTP server on boot

echo "Setting up automatic HTTP server on boot..."

# Ensure .msf4/local directory exists
mkdir -p /home/vagrant/.msf4/local

# Create systemd service file for HTTP server
sudo tee /etc/systemd/system/pdf-server.service > /dev/null << 'EOF'
[Unit]
Description=Malicious PDF HTTP Server
After=network-online.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/home/vagrant/.msf4/local
# Bind only to host-only interface (192.168.56.101)
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 192.168.56.101
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable the HTTP server service (will start on boot)
sudo systemctl daemon-reload
sudo systemctl enable pdf-server.service

# Try to start now if PDF exists
if [ -f "/home/vagrant/.msf4/local/JOAN-ESPINACH-TRD.pdf" ]; then
    sudo systemctl start pdf-server.service

    # Wait a moment and check status
    sleep 2
    if sudo systemctl is-active --quiet pdf-server.service; then
        echo "✓ HTTP server started successfully on port 8080"
        echo "  PDF URL: http://192.168.56.101:8080/JOAN-ESPINACH-TRD.pdf"
    else
        echo "⚠ HTTP server failed to start, but will start on next boot"
    fi
else
    echo "⚠ PDF not found yet, HTTP server will start on next boot"
    echo "  Service enabled and will start automatically"
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
