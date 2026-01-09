#!/bin/bash
################################################################################
# Reset Lab Environment
# Description: Restore VMs to clean snapshot state
# Usage: ./reset.sh
################################################################################

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║           RESET LAB ENVIRONMENT                                ║"
echo "║           Restore VMs to Clean State                           ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo

cd vagrant

# Get VM names from VirtualBox
KALI_VM=$(VBoxManage list vms | grep -i kali | head -1 | awk '{print $1}' | tr -d '"')
WINDOWS_VM=$(VBoxManage list vms | grep -i win2k8 | head -1 | awk '{print $1}' | tr -d '"')

if [ -z "$KALI_VM" ] && [ -z "$WINDOWS_VM" ]; then
    echo "✗ No VMs found. Run ./setup.sh first."
    exit 1
fi

echo "Found VMs:"
if [ -n "$KALI_VM" ]; then
    echo "  ✓ Kali Linux: $KALI_VM"
fi
if [ -n "$WINDOWS_VM" ]; then
    echo "  ✓ Windows: $WINDOWS_VM"
fi
echo

# Stop VMs
echo "Stopping VMs..."
vagrant halt

# Wait for VMs to stop
sleep 3

# Restore snapshots
if [ -n "$KALI_VM" ]; then
    echo "Restoring Kali Linux snapshot..."
    if VBoxManage snapshot "$KALI_VM" list | grep -q "Clean_State"; then
        VBoxManage snapshot "$KALI_VM" restore "Clean_State"
        echo "  ✓ Kali snapshot restored"
    else
        echo "  ⚠ Warning: Clean_State snapshot not found for Kali"
    fi
fi

if [ -n "$WINDOWS_VM" ]; then
    echo "Restoring Windows snapshot..."
    if VBoxManage snapshot "$WINDOWS_VM" list | grep -q "Clean_State"; then
        VBoxManage snapshot "$WINDOWS_VM" restore "Clean_State"
        echo "  ✓ Windows snapshot restored"
    else
        echo "  ⚠ Warning: Clean_State snapshot not found for Windows"
    fi
fi

echo

# Start VMs
echo "Starting VMs..."
vagrant up

echo
echo "════════════════════════════════════════════════════════════════"
echo "  ✓ Lab Reset Complete!"
echo "════════════════════════════════════════════════════════════════"
echo
echo "VMs have been restored to clean state."
echo "You can now run the attack again."
echo
echo "Next steps:"
echo "  1. cd vagrant"
echo "  2. vagrant ssh kali"
echo "  3. cd /vagrant/exploits/lnk"
echo "  4. ./start_lnk_attack.sh"
echo

cd ..
