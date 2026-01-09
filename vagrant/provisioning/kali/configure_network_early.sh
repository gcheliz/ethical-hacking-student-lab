#!/bin/bash
################################################################################
# Configure Static IP for NAT Network
# NAT Network uses DHCP by default, but we need static IPs for the exploit
################################################################################

set -e

# Expected configuration
EXPECTED_IP="192.168.56.101"
NETMASK="255.255.255.0"
GATEWAY="192.168.56.1"
IFACE="eth0"  # Single NAT Network adapter

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

# Set default route through NAT Network gateway
echo "  Setting default gateway..."
sudo ip route add default via $GATEWAY dev $IFACE 2>/dev/null || true

# Add route to local subnet
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
# NAT Network - Static IP Configuration
# LNK Exploit Lab
auto $IFACE
iface $IFACE inet static
    address $EXPECTED_IP
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers 8.8.8.8 8.8.4.4
    post-up ip route add 192.168.56.0/24 dev $IFACE || true
EOF

echo "  ✓ Persistent configuration saved"

echo ""
echo "================================"
echo "✓ Static IP Configured"
echo "================================"
echo "  Interface: $IFACE"
echo "  IP: $EXPECTED_IP"
echo "  Gateway: $GATEWAY"
echo "  Network: 192.168.56.0/24"
echo "================================"
echo ""
