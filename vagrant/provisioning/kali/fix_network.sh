#!/bin/bash
################################################################################
# Configure Persistent Static Network for eth1
# This script permanently configures eth1 with static IP 192.168.56.101
################################################################################

EXPECTED_IP="192.168.56.101"
NETMASK="255.255.255.0"
WINDOWS_IP="192.168.56.102"

echo "════════════════════════════════════════════════════════════════"
echo "  Configuring Persistent Network for eth1"
echo "════════════════════════════════════════════════════════════════"
echo

# Step 1: Disable NetworkManager for eth1 (prevents conflicts)
echo "[1/4] Disabling NetworkManager for eth1..."
if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    # Create NetworkManager config to ignore eth1
    sudo tee /etc/NetworkManager/conf.d/10-ignore-eth1.conf > /dev/null << 'EOF'
[keyfile]
unmanaged-devices=interface-name:eth1
EOF

    # Set eth1 to unmanaged immediately
    nmcli device set eth1 managed no 2>/dev/null || true

    echo "  ✓ NetworkManager will ignore eth1"
else
    echo "  ✓ NetworkManager not running"
fi

echo

# Step 2: Create persistent network configuration
echo "[2/4] Creating persistent network configuration..."

# Use ifupdown (Debian standard) for static IP
sudo tee /etc/network/interfaces.d/eth1 > /dev/null << EOF
# Private network interface for exploit lab
# Managed by ifupdown, not NetworkManager
auto eth1
iface eth1 inet static
    address $EXPECTED_IP
    netmask $NETMASK
EOF

echo "  ✓ Created /etc/network/interfaces.d/eth1"

echo

# Step 3: Apply configuration immediately
echo "[3/4] Applying network configuration..."

# Bring down eth1 if it exists
sudo ifdown eth1 2>/dev/null || true
sudo ip addr flush dev eth1 2>/dev/null || true

# Bring up eth1 with new configuration
sudo ifup eth1 2>/dev/null || {
    # Fallback if ifup fails
    echo "  ifup failed, using ip commands..."
    sudo ip link set eth1 up
    sudo ip addr add $EXPECTED_IP/24 dev eth1
    sudo ip route add 192.168.56.0/24 dev eth1 2>/dev/null || true
}

# Wait for IP to be applied
sleep 2

# Verify
CURRENT_IP=$(ip -4 addr show eth1 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1)

if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
    echo "  ✓ eth1 configured: $CURRENT_IP"
else
    echo "  ✗ Failed to configure IP!"
    echo "  Current: $CURRENT_IP, Expected: $EXPECTED_IP"
    exit 1
fi

# Step 4: Configure firewall (allow exploit traffic)
echo
echo "[4/4] Configuring firewall for exploit lab..."

# Check if iptables has restrictive rules
RULE_COUNT=$(sudo iptables -L INPUT -n --line-numbers 2>/dev/null | wc -l)

if [ $RULE_COUNT -gt 2 ]; then
    # Allow incoming connections on port 4444 from private network
    sudo iptables -I INPUT -p tcp --dport 4444 -s 192.168.56.0/24 -j ACCEPT
    # Allow all traffic on private network interface
    sudo iptables -I INPUT -i eth1 -j ACCEPT
    echo "  ✓ Firewall rules added for port 4444 and eth1"
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
