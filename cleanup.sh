#!/bin/bash
################################################################################
# Cleanup Lab Environment
# Description: Remove all VMs and clean up resources
# Usage: ./cleanup.sh
################################################################################

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║           CLEANUP LAB ENVIRONMENT                              ║"
echo "║           Remove All VMs and Resources                         ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo

echo "⚠️  WARNING: This will destroy all VMs and cannot be undone!"
echo
echo "This will remove:"
echo "  • Kali Linux VM"
echo "  • Windows Server VM"
echo "  • All snapshots"
echo "  • Vagrant boxes (to free disk space)"
echo
echo "NOTE: Your scripts and configuration will NOT be deleted."
echo "      You can rebuild the lab anytime with ./setup.sh"
echo

read -p "Are you sure you want to continue? Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo
    echo "Cleanup cancelled."
    exit 0
fi

echo
echo "Starting cleanup..."

cd vagrant

# Destroy VMs
echo
echo "Destroying VMs..."
vagrant destroy -f

if [ $? -eq 0 ]; then
    echo "  ✓ VMs destroyed"
else
    echo "  ⚠ Warning: Some VMs may not have been destroyed"
fi

# Remove Vagrant boxes to free space
echo
echo "Cleaning up Vagrant boxes..."
vagrant box prune -f

echo "  ✓ Vagrant boxes pruned"

# Optional: Remove downloaded boxes completely
read -p "Also remove downloaded Vagrant boxes? (saves ~10GB) (y/n): " remove_boxes

if [ "$remove_boxes" == "y" ]; then
    echo
    echo "Removing Vagrant boxes..."
    vagrant box remove kalilinux/rolling --all 2>/dev/null && echo "  ✓ Removed Kali box"
    vagrant box remove rapid7/metasploitable3-win2k8 --all 2>/dev/null && echo "  ✓ Removed Windows box"
fi

cd ..

echo
echo "════════════════════════════════════════════════════════════════"
echo "  ✓ Cleanup Complete!"
echo "════════════════════════════════════════════════════════════════"
echo
echo "All VMs have been removed."
echo
echo "To rebuild the lab:"
echo "  ./setup.sh"
echo
echo "Disk space freed: Run 'df -h' to check"
echo
