#!/bin/bash
# Configure static IP on host-only network

echo "Waiting for network configuration..."

# Wait for eth1 to get the IP address (Vagrant assigns it)
MAX_RETRIES=30
RETRY_COUNT=0
IP_FOUND=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Check if eth1 has the expected IP
    IP_ADDR=$(ip addr show eth1 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1)

    if [ "$IP_ADDR" == "192.168.56.101" ]; then
        IP_FOUND=true
        echo "✓ IP address configured correctly: $IP_ADDR on eth1"
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 1
done

if [ "$IP_FOUND" = false ]; then
    echo "⚠ Warning: Expected IP 192.168.56.101 not found on eth1"
    echo "Current IP on eth1: $IP_ADDR"
    echo "This is usually OK - Vagrant may still be configuring the network"
fi

# Test connectivity to Windows (may not be up yet)
if [ "$IP_FOUND" = true ]; then
    echo "Testing connectivity to Windows target..."
    ping -c 2 192.168.56.102 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Can reach Windows target at 192.168.56.102"
    else
        echo "⚠ Windows target not reachable yet (this is OK during initial setup)"
    fi
fi

# Configure firewall to allow exploit traffic
echo "Configuring firewall for exploit lab..."

# Check if iptables has any rules
RULE_COUNT=$(sudo iptables -L INPUT -n --line-numbers 2>/dev/null | wc -l)

if [ $RULE_COUNT -gt 2 ]; then
    echo "  Firewall rules detected, ensuring port 4444 is allowed..."

    # Allow incoming connections on port 4444 (Metasploit listener)
    sudo iptables -I INPUT -p tcp --dport 4444 -s 192.168.56.0/24 -j ACCEPT

    # Allow all traffic on private network interface
    sudo iptables -I INPUT -i eth1 -j ACCEPT

    echo "  ✓ Port 4444 allowed from 192.168.56.0/24"
else
    echo "  ✓ No restrictive firewall rules found"
fi

echo "✓ Network configuration complete"
