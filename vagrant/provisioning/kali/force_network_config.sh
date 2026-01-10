#!/bin/bash
################################################################################
# Force Network Configuration - Robust Static IP Setup
# This script WILL configure 192.168.56.101 on the second network interface
################################################################################

set -e

EXPECTED_IP="192.168.56.101"
NETMASK="255.255.255.0"
NETWORK="192.168.56.0/24"

echo "========================================"
echo "  Force Network Configuration"
echo "========================================"
echo

# Wait for VirtualBox to create the network interface
echo "[1/5] Waiting for network interface to be created by VirtualBox..."
MAX_WAIT=30
elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
    IFACE_COUNT=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo" | wc -l)
    if [ $IFACE_COUNT -ge 2 ]; then
        echo "  ✓ Found $IFACE_COUNT network interfaces"
        break
    fi
    echo "  Waiting for second interface... (${elapsed}s)"
    sleep 2
    elapsed=$((elapsed + 2))
done

# Find the second network interface (not lo, not the NAT interface)
echo "[2/5] Identifying network interfaces..."
INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo" | head -2)
ETH0=$(echo "$INTERFACES" | head -1)
ETH1=$(echo "$INTERFACES" | tail -1)

if [ -z "$ETH1" ] || [ "$ETH0" = "$ETH1" ]; then
    echo "  ✗ ERROR: Could not find second network interface!"
    echo "  Available interfaces:"
    ip link show
    exit 1
fi

echo "  First interface (NAT/SSH): $ETH0"
echo "  Second interface (Host-Only): $ETH1"
echo

# Check current IP on second interface
echo "[3/5] Checking current configuration on $ETH1..."
CURRENT_IP=$(ip addr show $ETH1 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "")

if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
    echo "  ✓ Already configured: $EXPECTED_IP"
    echo
    echo "========================================"
    echo "  Network Configuration: OK"
    echo "========================================"
    exit 0
fi

echo "  Current IP: ${CURRENT_IP:-none}"
echo "  Need to configure: $EXPECTED_IP"
echo

# Configure the interface
echo "[4/5] Configuring $ETH1..."

# Stop any DHCP clients
pkill dhclient 2>/dev/null || true
sleep 1

# Bring interface up
ip link set $ETH1 up

# Flush any existing IPs
ip addr flush dev $ETH1 2>/dev/null || true

# Add the static IP
ip addr add ${EXPECTED_IP}/24 dev $ETH1

# Ensure interface is up
ip link set $ETH1 up

# Add route to local subnet
ip route add $NETWORK dev $ETH1 2>/dev/null || true

# Wait for configuration to settle
sleep 2

# Verify
CURRENT_IP=$(ip addr show $ETH1 | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "")

if [ "$CURRENT_IP" != "$EXPECTED_IP" ]; then
    echo "  ✗ Failed to configure IP!"
    echo "  Current state:"
    ip addr show $ETH1
    exit 1
fi

echo "  ✓ IP configured: $EXPECTED_IP"
echo

# Make persistent
echo "[5/5] Making configuration persistent..."

cat > /etc/network/interfaces.d/$ETH1 << EOF
# Host-Only Network - Static IP Configuration
# Ethical Hacking Lab
auto $ETH1
iface $ETH1 inet static
    address $EXPECTED_IP
    netmask $NETMASK
    post-up ip route add $NETWORK dev $ETH1 || true
EOF

echo "  ✓ Configuration saved to /etc/network/interfaces.d/$ETH1"
echo

echo "========================================"
echo "  Network Configuration: SUCCESS"
echo "========================================"
echo "  Interface: $ETH1"
echo "  IP: $EXPECTED_IP"
echo "  Network: $NETWORK"
echo "========================================"
echo

# Show final configuration
echo "Final configuration:"
ip addr show $ETH1 | grep -E "$ETH1|inet " | sed 's/^/  /'
echo

exit 0
