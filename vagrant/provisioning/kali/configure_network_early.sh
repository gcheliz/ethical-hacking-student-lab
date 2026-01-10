#!/bin/bash
################################################################################
# Configure Static IP for Host-Only Network
# Ensures eth1 (Host-Only adapter) has correct static IP
################################################################################

# Expected configuration
EXPECTED_IP="192.168.56.101"
NETMASK="255.255.255.0"
IFACE="eth1"  # Host-Only adapter (eth0 is NAT for SSH)

echo "================================"
echo "Static IP Configuration"
echo "================================"
echo ""

# Wait for VirtualBox to create the interface (it might not exist immediately)
echo "[1/4] Waiting for interface $IFACE to be created..."
MAX_WAIT=30
elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
    if ip link show $IFACE &>/dev/null; then
        echo "  ✓ Interface $IFACE exists"
        break
    fi
    echo "  Waiting... (${elapsed}s)"
    sleep 2
    elapsed=$((elapsed + 2))
done

if ! ip link show $IFACE &>/dev/null; then
    echo "  ✗ ERROR: Interface $IFACE not found after ${MAX_WAIT}s"
    echo "  Available interfaces:"
    ip link show
    exit 0  # Don't block provisioning
fi

# Check if network is already configured correctly
echo "[2/4] Checking current configuration..."
CURRENT_IP=$(ip addr show $IFACE 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "")

if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
    echo "  ✓ Static IP already configured"
    echo "  Interface: $IFACE"
    echo "  IP: $EXPECTED_IP"
    echo ""
    echo "No configuration changes needed!"
    echo ""
    exit 0
fi

echo "  Current IP: ${CURRENT_IP:-none}"
echo "  Expected IP: $EXPECTED_IP"
echo "  Configuring static IP now..."
echo ""

# Configure static IP
echo "[3/4] Configuring static IP on $IFACE..."

# Bring interface up first
echo "  Bringing interface up..."
ip link set $IFACE up 2>/dev/null

# Kill any DHCP clients that might interfere
echo "  Stopping DHCP clients..."
pkill dhclient 2>/dev/null
sleep 1

# Remove any existing IP addresses
echo "  Flushing existing IPs..."
ip addr flush dev $IFACE 2>/dev/null

# Add the static IP
echo "  Adding IP $EXPECTED_IP/24..."
ip addr add $EXPECTED_IP/24 dev $IFACE

# Ensure interface is up
ip link set $IFACE up

# Add route to local subnet (don't change default route - that's for SSH!)
echo "  Adding route to 192.168.56.0/24..."
ip route add 192.168.56.0/24 dev $IFACE 2>/dev/null

# Wait for configuration to settle
sleep 2

# Verify configuration
echo "[4/4] Verifying configuration..."
CURRENT_IP=$(ip addr show $IFACE 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "")

if [ "$CURRENT_IP" != "$EXPECTED_IP" ]; then
    echo "  ✗ Configuration failed!"
    echo "  Current IP: $CURRENT_IP"
    echo ""
    echo "Network state:"
    ip addr show $IFACE
    echo ""
    echo "This is not critical - you can configure manually:"
    echo "  sudo ip addr add 192.168.56.101/24 dev eth1"
    echo "  sudo ip link set eth1 up"
    echo ""
    exit 0  # Don't fail provisioning
fi

echo "  ✓ IP configured successfully: $EXPECTED_IP"
echo ""

# Make configuration persistent
echo "Making configuration persistent..."
cat > /etc/network/interfaces.d/$IFACE << EOF
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
