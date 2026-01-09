#!/bin/bash
################################################################################
# Fix Network Interface - Ensure eth1 is up with correct IP
# This script ensures the private network interface comes up properly
################################################################################

EXPECTED_IP="192.168.56.101"
NETMASK="255.255.255.0"

echo "Checking network interface eth1..."

# Check if eth1 exists
if ! ip link show eth1 > /dev/null 2>&1; then
    echo "  ✗ eth1 does not exist!"
    echo "  Available interfaces:"
    ip link show
    exit 1
fi

echo "  ✓ eth1 interface exists"

# Check if eth1 is up
ETH1_STATE=$(ip link show eth1 | grep -o "state [A-Z]*" | awk '{print $2}')
if [ "$ETH1_STATE" != "UP" ]; then
    echo "  eth1 is DOWN - bringing it up..."
    sudo ip link set eth1 up
    sleep 2
fi

# Check if eth1 has the correct IP
CURRENT_IP=$(ip -4 addr show eth1 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1)

if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
    echo "  ✓ eth1 already has IP $EXPECTED_IP"
else
    echo "  eth1 has IP: $CURRENT_IP (expected: $EXPECTED_IP)"
    echo "  Configuring eth1 with correct IP..."

    # Remove any existing IP
    if [ -n "$CURRENT_IP" ]; then
        sudo ip addr flush dev eth1
    fi

    # Add the correct IP
    sudo ip addr add $EXPECTED_IP/24 dev eth1

    # Bring interface up
    sudo ip link set eth1 up

    # Wait for interface to be ready
    sleep 2

    # Verify
    NEW_IP=$(ip -4 addr show eth1 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1)
    if [ "$NEW_IP" = "$EXPECTED_IP" ]; then
        echo "  ✓ eth1 configured successfully with IP $EXPECTED_IP"
    else
        echo "  ✗ Failed to configure eth1!"
        exit 1
    fi
fi

# Show final interface status
echo
echo "Network interface status:"
ip -4 addr show eth1

echo
echo "✓ Network interface ready"
