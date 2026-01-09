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

# Stop NetworkManager from managing this interface
echo "[2/6] Disabling NetworkManager for $IFACE..."
sudo mkdir -p /etc/NetworkManager/conf.d
sudo tee /etc/NetworkManager/conf.d/99-unmanaged.conf > /dev/null << EOF
[keyfile]
unmanaged-devices=interface-name:$IFACE
EOF

# Restart NetworkManager to apply config
sudo systemctl restart NetworkManager 2>/dev/null || true

# Kill any dhclient on this interface
echo "[3/6] Stopping DHCP client on $IFACE..."
sudo pkill -f "dhclient.*$IFACE" 2>/dev/null || true
sleep 1

echo

# Create persistent configuration file FIRST
echo "[4/6] Creating persistent network configuration..."
sudo tee /etc/network/interfaces.d/$IFACE > /dev/null << EOF
# Host-only network interface for exploit lab
# Managed by ifupdown, not NetworkManager
auto $IFACE
iface $IFACE inet static
    address $EXPECTED_IP
    netmask $NETMASK
    gateway $GATEWAY
    post-up ip route add 192.168.56.0/24 dev $IFACE || true
EOF

echo "  ✓ Configuration saved to /etc/network/interfaces.d/$IFACE"
echo

# Now configure the interface using ifupdown
echo "[5/6] Applying configuration with ifupdown..."
# Bring interface down first if it's up
sudo ifdown "$IFACE" 2>/dev/null || true
# Flush any old IP
sudo ip addr flush dev "$IFACE"
# Bring it up with the new config
sudo ifup "$IFACE"

# Verify
sleep 1
CURRENT_IP=$(ip addr show "$IFACE" | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
    echo "  ✓ Interface configured: $IFACE = $EXPECTED_IP"
else
    echo "  ✗ Configuration failed! IP is: $CURRENT_IP"
    echo "  Trying manual configuration as fallback..."
    sudo ip addr add "$EXPECTED_IP/24" dev "$IFACE" 2>/dev/null
    sudo ip link set "$IFACE" up
    sudo ip route add 192.168.56.0/24 dev "$IFACE" 2>/dev/null || true

    # Verify again
    CURRENT_IP=$(ip addr show "$IFACE" | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
        echo "  ✓ Manual configuration successful"
    else
        echo "  ✗ Manual configuration also failed!"
        exit 1
    fi
fi

echo

# Prevent the interface from going down
echo "[6/6] Ensuring interface stays up..."
sudo ip link set "$IFACE" up
echo

echo "================================================================"
echo "  Network Configuration Complete"
echo "================================================================"
echo "  Interface: $IFACE"
echo "  IP:        $EXPECTED_IP"
echo "  Gateway:   $GATEWAY"
echo "================================================================"
echo
