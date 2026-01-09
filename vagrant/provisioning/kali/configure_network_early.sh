#!/bin/bash
# Configure Network Early - Run before other provisioning
# Ensures 192.168.56.101 is properly configured on eth1

echo "================================================================"
echo "  Configuring Host-Only Network (Early)"
echo "================================================================"
echo

# Expected configuration
EXPECTED_IP="192.168.56.101"
NETMASK="255.255.255.0"
GATEWAY="192.168.56.1"

# Find the host-only interface (not the NAT one)
echo "[1/4] Detecting host-only network interface..."
for iface in $(ip link show | grep -E "^[0-9]+: (eth|enp)" | awk -F: '{print $2}' | tr -d ' '); do
    # Skip if it's the NAT interface (10.0.2.x)
    CURRENT_IP=$(ip addr show "$iface" | grep "inet " | awk '{print $2}' | cut -d'/' -f1)

    if [[ "$CURRENT_IP" =~ ^10\.0\.2\. ]]; then
        echo "  Skipping $iface (NAT interface: $CURRENT_IP)"
        continue
    fi

    # This should be our host-only interface
    if [ -n "$CURRENT_IP" ]; then
        IFACE="$iface"
        echo "  Found: $IFACE with IP $CURRENT_IP"
        break
    fi

    # Or if it has no IP but exists, assume it's the host-only interface
    if [ -z "$CURRENT_IP" ]; then
        IFACE="$iface"
        echo "  Found: $IFACE (no IP yet)"
        break
    fi
done

if [ -z "$IFACE" ]; then
    echo "  ERROR: Could not find host-only interface!"
    echo "  Available interfaces:"
    ip addr show
    exit 1
fi

echo

# Configure the interface immediately
echo "[2/4] Configuring $IFACE with static IP..."
sudo ip addr flush dev "$IFACE"
sudo ip addr add "$EXPECTED_IP/24" dev "$IFACE"
sudo ip link set "$IFACE" up

# Verify
CURRENT_IP=$(ip addr show "$IFACE" | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
    echo "  ✓ Interface configured: $IFACE = $EXPECTED_IP"
else
    echo "  ✗ Configuration failed!"
    exit 1
fi

echo

# Add route
echo "[3/4] Adding route for 192.168.56.0/24..."
sudo ip route add 192.168.56.0/24 dev "$IFACE" 2>/dev/null || echo "  (route already exists)"

# Add default gateway if needed
if [ -n "$GATEWAY" ]; then
    echo "  Adding gateway $GATEWAY..."
    sudo ip route add default via "$GATEWAY" dev "$IFACE" metric 100 2>/dev/null || echo "  (gateway already exists)"
fi

echo

# Make configuration persistent
echo "[4/4] Creating persistent network configuration..."
sudo tee /etc/network/interfaces.d/$IFACE > /dev/null << EOF
# Host-only network interface for exploit lab
auto $IFACE
iface $IFACE inet static
    address $EXPECTED_IP
    netmask $NETMASK
    gateway $GATEWAY
    post-up ip route add 192.168.56.0/24 dev $IFACE || true
EOF

echo "  ✓ Configuration saved to /etc/network/interfaces.d/$IFACE"
echo

echo "================================================================"
echo "  Network Configuration Complete"
echo "================================================================"
echo "  Interface: $IFACE"
echo "  IP:        $EXPECTED_IP"
echo "  Gateway:   $GATEWAY"
echo "================================================================"
echo
