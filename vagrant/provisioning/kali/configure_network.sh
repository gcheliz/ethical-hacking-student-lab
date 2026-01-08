#!/bin/bash
# Configure static IP on host-only network

echo "Waiting for network interface to come up..."
sleep 5

# Find the interface with the 192.168.56.x subnet
IFACE=$(ip -o addr show | grep "192.168.56" | awk '{print $2}' | head -n1)

if [ -z "$IFACE" ]; then
    echo "⚠ Warning: Could not find network interface with 192.168.56.x subnet"
    echo "Available interfaces:"
    ip addr show | grep "^[0-9]" | awk '{print $2}'

    # Try common interface names
    for iface in eth1 enp0s8 ens8; do
        if ip addr show $iface 2>/dev/null | grep -q "inet "; then
            IFACE=$iface
            echo "Using interface: $IFACE"
            break
        fi
    done
fi

# Verify IP configuration
if [ -n "$IFACE" ]; then
    IP_ADDR=$(ip addr show $IFACE | grep "inet " | awk '{print $2}' | cut -d'/' -f1)

    if [ "$IP_ADDR" == "192.168.56.101" ]; then
        echo "✓ IP address configured correctly: $IP_ADDR on $IFACE"
    else
        echo "⚠ Warning: IP is $IP_ADDR (expected 192.168.56.101) on $IFACE"
    fi
else
    echo "✗ Could not find appropriate network interface"
    IP_ADDR=""
fi

# Test connectivity to Windows (may not be up yet)
if [ -n "$IP_ADDR" ]; then
    ping -c 2 192.168.56.102 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Can reach Windows target"
    else
        echo "⚠ Windows target not reachable yet (this is OK during initial setup)"
    fi
fi

echo "✓ Network configuration complete"
