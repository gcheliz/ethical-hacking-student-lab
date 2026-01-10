#!/bin/bash
################################################################################
# Configure Static IP for Host-Only Network
# Ensures eth1 (Host-Only adapter) has correct static IP
################################################################################

set -e

# Expected configuration
EXPECTED_IP="192.168.56.101"
NETMASK="255.255.255.0"
IFACE="eth1"  # Host-Only adapter (eth0 is NAT for SSH)

echo "================================"
echo "Static IP Configuration"
echo "================================"
echo ""

# Check if network is already configured correctly
echo "[1/2] Checking current configuration..."
CURRENT_IP=$(ip addr show $IFACE | grep "inet " | awk '{print $2}' | cut -d'/' -f1 2>/dev/null || echo "")

if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
    echo "  ✓ Static IP already configured"
    echo "  Interface: $IFACE"
    echo "  IP: $EXPECTED_IP"
    echo ""
    echo "No configuration needed!"
    echo ""
    exit 0
fi

echo "  Current IP: ${CURRENT_IP:-none}"
echo "  Expected IP: $EXPECTED_IP"
echo "  Need to configure static IP..."
echo ""

# Configure static IP
echo "[2/2] Configuring static IP on $IFACE..."

# Method 1: Kill DHCP client
echo "  Stopping DHCP client..."
sudo pkill dhclient 2>/dev/null || true
sleep 1

# Method 2: Flush current IP and set static
echo "  Setting static IP..."
sudo ip addr flush dev $IFACE
sudo ip addr add $EXPECTED_IP/24 dev $IFACE
sudo ip link set $IFACE up

# Add route to local subnet ONLY (do NOT change default route - that's for SSH!)
echo "  Adding route to 192.168.56.0/24..."
sudo ip route add 192.168.56.0/24 dev $IFACE 2>/dev/null || true

# Verify configuration
sleep 2
CURRENT_IP=$(ip addr show $IFACE | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "")

if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
    echo "  ✓ Static IP configured successfully"
else
    echo "  ✗ Configuration failed!"
    echo "  Current IP: $CURRENT_IP"
    exit 1
fi

# Make configuration persistent
echo "  Creating persistent configuration..."
sudo tee /etc/network/interfaces.d/$IFACE > /dev/null << EOF
# Host-Only Network - Static IP Configuration
# HTA Exploit Lab
# NOTE: No gateway - default route stays on eth0 (NAT) for SSH
auto $IFACE
iface $IFACE inet static
    address $EXPECTED_IP
    netmask $NETMASK
    post-up ip route add 192.168.56.0/24 dev $IFACE || true
EOF

echo "  ✓ Persistent configuration saved"

echo ""
echo "================================"
echo "✓ Static IP Configured"
echo "================================"
echo "  Interface: $IFACE"
echo "  IP: $EXPECTED_IP"
echo "  Network: 192.168.56.0/24"
echo "  Note: Default route stays on eth0 (for SSH)"
echo "================================"
echo ""
