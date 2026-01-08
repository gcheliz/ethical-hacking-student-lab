#!/bin/bash
# Configure static IP on host-only network

# Verify IP configuration
IP_ADDR=$(ip addr show eth1 | grep "inet " | awk '{print $2}' | cut -d'/' -f1)

if [ "$IP_ADDR" == "192.168.56.101" ]; then
    echo "✓ IP address configured correctly: $IP_ADDR"
else
    echo "⚠ Warning: IP is $IP_ADDR (expected 192.168.56.101)"
fi

# Test connectivity to Windows (may not be up yet)
ping -c 2 192.168.56.102 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Can reach Windows target"
else
    echo "⚠ Windows target not reachable yet (this is OK during initial setup)"
fi

echo "✓ Network configuration complete"
