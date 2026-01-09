#!/bin/bash
################################################################################
# Configure Persistent Static Network
# Detects the correct interface and configures IP 192.168.56.101
################################################################################

EXPECTED_IP="192.168.56.101"
NETMASK="255.255.255.0"
WINDOWS_IP="192.168.56.102"

echo "════════════════════════════════════════════════════════════════"
echo "  Configuring Persistent Network"
echo "════════════════════════════════════════════════════════════════"
echo

# Step 1: Detect which interface Vagrant configured
echo "[1/4] Detecting network interface..."
IFACE=""
for ifc in eth0 eth1 enp0s3 enp0s8; do
    if ip link show $ifc > /dev/null 2>&1; then
        # Check if this interface has our expected IP or is on the right network
        CURRENT_IP=$(ip -4 addr show $ifc 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1)
        if [ "$CURRENT_IP" = "$EXPECTED_IP" ] || [ "$CURRENT_IP" = "" ]; then
            # Check if it's not the NAT interface (usually 10.0.2.x)
            if [ "$CURRENT_IP" != "10.0.2.15" ]; then
                IFACE=$ifc
                echo "  ✓ Using interface: $IFACE"
                break
            fi
        fi
    fi
done

if [ -z "$IFACE" ]; then
    # Fallback: use eth1 if it exists, otherwise eth0
    if ip link show eth1 > /dev/null 2>&1; then
        IFACE="eth1"
    else
        IFACE="eth0"
    fi
    echo "  ⚠ Auto-detection failed, using: $IFACE"
fi

echo

# Step 2: Disable NetworkManager for this interface
echo "[2/4] Disabling NetworkManager for $IFACE..."
if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    sudo tee /etc/NetworkManager/conf.d/10-ignore-interface.conf > /dev/null << EOF
[keyfile]
unmanaged-devices=interface-name:$IFACE
EOF

    nmcli device set $IFACE managed no 2>/dev/null || true
    echo "  ✓ NetworkManager will ignore $IFACE"
else
    echo "  ✓ NetworkManager not running"
fi

echo

# Step 3: Create persistent network configuration
echo "[3/4] Creating persistent network configuration..."

sudo tee /etc/network/interfaces.d/$IFACE > /dev/null << EOF
# Private network interface for exploit lab
# Managed by ifupdown, not NetworkManager
auto $IFACE
iface $IFACE inet static
    address $EXPECTED_IP
    netmask $NETMASK
EOF

echo "  ✓ Created /etc/network/interfaces.d/$IFACE"

echo

# Step 4: Apply configuration immediately
echo "[4/5] Applying network configuration..."

# Bring down interface if it exists
sudo ifdown $IFACE 2>/dev/null || true
sudo ip addr flush dev $IFACE 2>/dev/null || true

# Bring up interface with new configuration
sudo ifup $IFACE 2>/dev/null || {
    echo "  ifup failed, using ip commands..."
    sudo ip link set $IFACE up
    sudo ip addr add $EXPECTED_IP/24 dev $IFACE
    sudo ip route add 192.168.56.0/24 dev $IFACE 2>/dev/null || true
}

sleep 2

# Verify
CURRENT_IP=$(ip -4 addr show $IFACE 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1)

if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
    echo "  ✓ $IFACE configured: $CURRENT_IP"
else
    echo "  ✗ Failed to configure IP!"
    echo "  Current: $CURRENT_IP, Expected: $EXPECTED_IP"
    exit 1
fi

# Step 5: Configure firewall (allow exploit traffic)
echo
echo "[5/5] Configuring firewall for exploit lab..."

# Check if iptables has restrictive rules
RULE_COUNT=$(sudo iptables -L INPUT -n --line-numbers 2>/dev/null | wc -l)

if [ $RULE_COUNT -gt 2 ]; then
    # Allow incoming connections on port 4444 from private network
    sudo iptables -I INPUT -p tcp --dport 4444 -s 192.168.56.0/24 -j ACCEPT
    # Allow all traffic on private network interface
    sudo iptables -I INPUT -i $IFACE -j ACCEPT
    echo "  ✓ Firewall rules added for port 4444 and $IFACE"
else
    echo "  ✓ No restrictive firewall detected"
fi

echo
echo "════════════════════════════════════════════════════════════════"
echo "  ✓ Network Configuration Complete"
echo "════════════════════════════════════════════════════════════════"
echo
echo "  Kali IP:    $EXPECTED_IP (eth1)"
echo "  Windows IP: $WINDOWS_IP (target)"
echo
echo "  Configuration persists across reboots."
echo "  Metasploit can bind to $EXPECTED_IP:4444"
echo
