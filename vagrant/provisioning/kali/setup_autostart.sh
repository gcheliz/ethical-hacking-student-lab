#!/bin/bash
# Setup automatic HTTP server on boot

echo "Setting up automatic HTTP server on boot..."

# Create systemd service file
sudo tee /etc/systemd/system/pdf-server.service > /dev/null << 'EOF'
[Unit]
Description=Malicious PDF HTTP Server
After=network.target

[Service]
Type=simple
User=vagrant
WorkingDirectory=/home/vagrant
ExecStart=/home/vagrant/.msf4/local/start_server.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Copy the server startup script
sudo cp /vagrant/vagrant/provisioning/kali/start_http_server.sh /home/vagrant/.msf4/local/start_server.sh
sudo chown vagrant:vagrant /home/vagrant/.msf4/local/start_server.sh
sudo chmod +x /home/vagrant/.msf4/local/start_server.sh

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable pdf-server.service
sudo systemctl start pdf-server.service

# Check status
if sudo systemctl is-active --quiet pdf-server.service; then
    echo "✓ HTTP server started successfully on port 8080"
    echo "  PDF URL: http://192.168.56.101:8080/JOAN-ESPINACH-TRD.pdf"
else
    echo "⚠ HTTP server failed to start (will retry on boot)"
fi
