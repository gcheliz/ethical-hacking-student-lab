#!/bin/bash
# Verify HTTP Server Status on Kali

echo "================================================================"
echo "  Verifying HTTP Server on Kali"
echo "================================================================"
echo

# Test 1: Check if systemd service is running
echo "[1/5] Checking pdf-server systemd service status..."
if sudo systemctl is-active --quiet pdf-server.service; then
    echo "  ✓ Service is running"
else
    echo "  ✗ Service is NOT running"
    echo "  Attempting to start service..."
    sudo systemctl start pdf-server.service
    sleep 2
    if sudo systemctl is-active --quiet pdf-server.service; then
        echo "  ✓ Service started successfully"
    else
        echo "  ✗ Service failed to start"
        echo "  Service logs:"
        sudo journalctl -u pdf-server -n 20 --no-pager
    fi
fi
echo

# Test 2: Check if port 8080 is listening
echo "[2/5] Checking if port 8080 is listening..."
if netstat -tlnp 2>/dev/null | grep -q ":8080 "; then
    echo "  ✓ Port 8080 is listening"
    netstat -tlnp 2>/dev/null | grep ":8080 " | head -1
else
    echo "  ✗ Port 8080 is NOT listening"
    echo "  All listening ports:"
    netstat -tlnp 2>/dev/null | grep LISTEN | head -10
fi
echo

# Test 3: Check network interfaces and IPs
echo "[3/5] Network interfaces and IP addresses..."
ip addr show | grep -E "^[0-9]+:|inet " | grep -v "127.0.0.1"
echo

# Test 4: Check if 192.168.56.101 is configured
echo "[4/5] Checking for 192.168.56.101..."
if ip addr show | grep -q "192.168.56.101"; then
    echo "  ✓ IP 192.168.56.101 is configured"
    IFACE=$(ip addr show | grep -B 2 "192.168.56.101" | head -1 | awk '{print $2}' | tr -d ':')
    echo "  Interface: $IFACE"
else
    echo "  ✗ IP 192.168.56.101 is NOT configured!"
    echo "  This is the problem - Kali doesn't have the correct IP"
fi
echo

# Test 5: Test HTTP server locally
echo "[5/5] Testing HTTP server with local request..."
if curl -s -I http://localhost:8080 > /dev/null 2>&1; then
    echo "  ✓ HTTP server responds on localhost:8080"
elif curl -s -I http://192.168.56.101:8080 > /dev/null 2>&1; then
    echo "  ✓ HTTP server responds on 192.168.56.101:8080"
else
    echo "  ✗ HTTP server is not responding"
fi
echo

# Test 6: Check PDF files
echo "PDF files in /home/vagrant/.msf4/local:"
ls -lh /home/vagrant/.msf4/local/*.pdf 2>/dev/null || echo "  No PDF files found"
echo

echo "================================================================"
echo "  Diagnostic Complete"
echo "================================================================"
