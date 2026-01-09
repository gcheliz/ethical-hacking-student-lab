#!/bin/bash
################################################################################
# Network Readiness Check
# Waits for network adapters to be fully configured before proceeding
################################################################################

set -e

# Configuration
MAX_WAIT=30
WAIT_COUNT=0
REQUIRED_IP="192.168.56.101"
GATEWAY="192.168.56.1"

echo "================================"
echo "Verifying Network Readiness"
echo "================================"
echo ""

# Function to check if network is ready
check_network() {
    # Check if eth1 exists
    if ! ip link show eth1 &> /dev/null; then
        return 1
    fi

    # Check if eth1 has the correct IP
    if ! ip addr show eth1 | grep -q "$REQUIRED_IP"; then
        return 1
    fi

    # Check if we can reach the gateway
    if ! ping -c 1 -W 1 "$GATEWAY" > /dev/null 2>&1; then
        return 1
    fi

    return 0
}

echo "Waiting for network to be ready..."
echo "  Required IP: $REQUIRED_IP"
echo "  Gateway: $GATEWAY"
echo ""

# Wait loop
while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if check_network; then
        echo ""
        echo "✓ Network is ready!"
        echo ""

        # Show network configuration
        echo "Network Configuration:"
        ip addr show eth1 | grep -E "eth1|inet " | sed 's/^/  /'
        echo ""

        echo "Routing:"
        ip route show | grep "192.168.56" | sed 's/^/  /'
        echo ""

        exit 0
    fi

    echo -n "."
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

# Timeout reached
echo ""
echo "⚠ Warning: Network not ready after $MAX_WAIT seconds"
echo ""
echo "Current network state:"
ip addr show | sed 's/^/  /'
echo ""
echo "Continuing anyway (services may need manual start)..."
echo ""

exit 0  # Don't fail provisioning, just warn
