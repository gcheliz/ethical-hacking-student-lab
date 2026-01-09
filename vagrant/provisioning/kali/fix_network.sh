#!/bin/bash
################################################################################
# Fix Network Interface - Ensure eth1 is up with correct IP
# This script ensures the private network interface comes up properly
################################################################################

EXPECTED_IP="192.168.56.101"
NETMASK="255.255.255.0"
WINDOWS_IP="192.168.56.102"
MAX_RETRIES=30
RETRY_DELAY=2

echo "════════════════════════════════════════════════════════════════"
echo "  Configuring Private Network Interface (eth1)"
echo "════════════════════════════════════════════════════════════════"
echo

# Check if NetworkManager is managing eth1 (can cause conflicts)
if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    echo "[0/4] Checking NetworkManager..."
    if nmcli device status 2>/dev/null | grep -q "eth1.*connected"; then
        echo "  ⚠ NetworkManager is managing eth1 - setting to unmanaged..."
        nmcli device set eth1 managed no 2>/dev/null || true
        echo "  ✓ eth1 set to unmanaged mode"
    else
        echo "  ✓ NetworkManager not interfering with eth1"
    fi
    echo
fi

# Wait for eth1 to exist (Vagrant might still be creating it)
echo "[1/4] Waiting for eth1 interface to exist..."
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    if ip link show eth1 > /dev/null 2>&1; then
        echo "  ✓ eth1 interface exists"
        break
    fi

    RETRY=$((RETRY + 1))
    if [ $RETRY -eq $MAX_RETRIES ]; then
        echo "  ✗ eth1 never appeared after $MAX_RETRIES attempts!"
        echo "  Available interfaces:"
        ip link show
        exit 1
    fi

    sleep $RETRY_DELAY
done

echo

# Bring eth1 up if it's down
echo "[2/4] Ensuring eth1 is UP..."
ETH1_STATE=$(ip link show eth1 | grep -o "state [A-Z]*" | awk '{print $2}')
if [ "$ETH1_STATE" != "UP" ]; then
    echo "  eth1 is DOWN - bringing it up..."
    sudo ip link set eth1 up
    sleep 2
    echo "  ✓ eth1 is now UP"
else
    echo "  ✓ eth1 is already UP"
fi

echo

# Configure IP address with retries
echo "[3/4] Configuring IP address $EXPECTED_IP..."
RETRY=0
MANUAL_CONFIG_THRESHOLD=5  # Start manual config after 5 attempts
while [ $RETRY -lt $MAX_RETRIES ]; do
    CURRENT_IP=$(ip -4 addr show eth1 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1)

    if [ "$CURRENT_IP" = "$EXPECTED_IP" ]; then
        echo "  ✓ eth1 has correct IP: $EXPECTED_IP"
        break
    fi

    RETRY=$((RETRY + 1))

    # After threshold attempts, force manual configuration
    if [ $RETRY -ge $MANUAL_CONFIG_THRESHOLD ]; then
        if [ -z "$CURRENT_IP" ]; then
            echo "  No IP detected - manually configuring (attempt $RETRY/$MAX_RETRIES)..."
        else
            echo "  Wrong IP: $CURRENT_IP (expected: $EXPECTED_IP) - fixing..."
        fi

        # Manual configuration
        sudo ip addr flush dev eth1 2>/dev/null || true
        sudo ip addr add $EXPECTED_IP/24 dev eth1
        sudo ip link set eth1 up

        # Ensure route is configured
        sudo ip route add 192.168.56.0/24 dev eth1 2>/dev/null || true
        sleep 1
    else
        # Give Vagrant a chance first
        if [ -z "$CURRENT_IP" ]; then
            echo "  Waiting for Vagrant auto-config (attempt $RETRY/$MANUAL_CONFIG_THRESHOLD)..."
        fi
    fi

    if [ $RETRY -eq $MAX_RETRIES ]; then
        echo "  ✗ Failed to configure IP after $MAX_RETRIES attempts!"
        echo "  eth1 status:"
        ip addr show eth1
        exit 1
    fi

    sleep $RETRY_DELAY
done

echo

# Verify configuration
echo "[4/4] Verifying network configuration..."
echo "  Interface status:"
ip -4 addr show eth1 | grep inet | sed 's/^/    /'

# Test basic routing
echo
echo "  Testing routing..."
if ip route get $WINDOWS_IP 2>/dev/null | grep -q "dev eth1"; then
    echo "  ✓ Route to Windows network configured correctly"
else
    echo "  ⚠ Route to Windows may not be optimal"
    echo "  This might work anyway, but connectivity may be affected"
fi

# Test if we can ping Windows (if it's up)
echo
echo "  Testing connectivity to Windows ($WINDOWS_IP)..."
if ping -c 2 -W 2 $WINDOWS_IP > /dev/null 2>&1; then
    echo "  ✓ Can reach Windows VM"
else
    echo "  ⚠ Cannot reach Windows (this is OK if Windows isn't built yet)"
fi

echo
echo "════════════════════════════════════════════════════════════════"
echo "  ✓ Network Configuration Complete"
echo "════════════════════════════════════════════════════════════════"
echo
echo "  Kali IP:    $EXPECTED_IP (eth1)"
echo "  Windows IP: $WINDOWS_IP (target)"
echo
