#!/bin/bash
################################################################################
# Verify and Configure Network (Fallback)
# Since auto_config is now enabled, this should only run if auto-config failed
################################################################################

set -e

# Expected configuration
EXPECTED_IP="192.168.56.101"
NETMASK="255.255.255.0"
GATEWAY="192.168.56.1"

echo "================================"
echo "Network Configuration Check"
echo "================================"
echo ""

# Check if network is already configured correctly by Vagrant
echo "[1/2] Checking if network is already configured..."
if ip addr show eth1 | grep -q "$EXPECTED_IP"; then
    echo "  ✓ Network already configured correctly by Vagrant"
    echo "  Interface: eth1"
    echo "  IP: $EXPECTED_IP"
    echo ""
    echo "No manual configuration needed!"
    echo ""
    exit 0
fi

echo "  ⚠ Auto-config didn't set IP, configuring manually..."
echo ""

# Auto-config failed, configure manually as fallback
echo "[2/2] Applying manual network configuration..."

# Find host-only interface
IFACE=""
for iface in eth1 eth2 enp0s8 enp0s9; do
    if ip link show "$iface" &>/dev/null; then
        # Check it's not the NAT interface
        CURRENT_IP=$(ip addr show "$iface" | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "")
        if [[ ! "$CURRENT_IP" =~ ^10\.0\.2\. ]]; then
            IFACE="$iface"
            echo "  Found interface: $IFACE"
            break
        fi
    fi
done

if [ -z "$IFACE" ]; then
    echo "  ✗ Could not find host-only interface!"
    echo "  Available interfaces:"
    ip addr show | grep -E "^[0-9]+:"
    exit 1
fi

# Configure the interface
echo "  Configuring $IFACE..."

# Method 1: Try ifupdown
sudo tee /etc/network/interfaces.d/$IFACE > /dev/null << EOF
auto $IFACE
iface $IFACE inet static
    address $EXPECTED_IP
    netmask $NETMASK
    post-up ip route add 192.168.56.0/24 dev $IFACE || true
EOF

sudo ifdown "$IFACE" 2>/dev/null || true
sudo ifup "$IFACE" 2>/dev/null || true

# Verify
sleep 2
CURRENT_IP=$(ip addr show "$IFACE" | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "")

if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
    echo "  ✓ Interface configured successfully"
else
    # Method 2: Manual IP configuration as last resort
    echo "  Trying manual IP configuration..."
    sudo ip addr flush dev "$IFACE"
    sudo ip addr add "$EXPECTED_IP/24" dev "$IFACE"
    sudo ip link set "$IFACE" up
    sudo ip route add 192.168.56.0/24 dev "$IFACE" 2>/dev/null || true

    # Final verification
    sleep 1
    CURRENT_IP=$(ip addr show "$IFACE" | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "")
    if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
        echo "  ✓ Manual configuration successful"
    else
        echo "  ✗ Configuration failed!"
        echo "  Current IP: $CURRENT_IP"
        exit 1
    fi
fi

echo ""
echo "================================"
echo "✓ Network Configured"
echo "================================"
echo "  Interface: $IFACE"
echo "  IP: $EXPECTED_IP"
echo "  Netmask: $NETMASK"
echo "================================"
echo ""
