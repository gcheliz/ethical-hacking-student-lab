#!/bin/bash
################################################################################
# Create VirtualBox NAT Network for LNK Exploit Lab
# This script creates a single NAT Network that provides both:
# - VM-to-VM communication
# - Internet access for provisioning
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# NAT Network configuration
NAT_NETWORK_NAME="LNK_Exploit_Lab_Network"
NAT_NETWORK_CIDR="192.168.56.0/24"
NAT_NETWORK_IP="192.168.56.1"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║    VIRTUALBOX NAT NETWORK SETUP                                ║"
echo "║    Single adapter configuration                                ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo

# Check if VBoxManage is available
if ! command -v VBoxManage &> /dev/null; then
    echo -e "${RED}✗ VBoxManage not found${NC}"
    echo "  Please install VirtualBox first"
    exit 1
fi

echo -e "${GREEN}✓ VBoxManage found${NC}"
echo

# Check if NAT Network already exists
echo -e "${YELLOW}Checking for existing NAT Network...${NC}"
if VBoxManage natnetwork list 2>/dev/null | grep -q "$NAT_NETWORK_NAME"; then
    echo -e "${CYAN}  NAT Network '$NAT_NETWORK_NAME' already exists${NC}"
    echo
    echo "Current configuration:"
    VBoxManage natnetwork list | grep -A 10 "$NAT_NETWORK_NAME" | head -11
    echo

    read -p "Do you want to remove and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}  Removing existing NAT Network...${NC}"
        VBoxManage natnetwork remove --netname "$NAT_NETWORK_NAME"
        echo -e "${GREEN}  ✓ Removed${NC}"
        echo
    else
        echo -e "${GREEN}  ✓ Using existing NAT Network${NC}"
        echo
        exit 0
    fi
fi

# Create NAT Network
echo -e "${YELLOW}Creating NAT Network...${NC}"
echo "  Name: $NAT_NETWORK_NAME"
echo "  Network: $NAT_NETWORK_CIDR"
echo "  DHCP: Disabled (using static IPs)"
echo

VBoxManage natnetwork add \
    --netname "$NAT_NETWORK_NAME" \
    --network "$NAT_NETWORK_CIDR" \
    --enable \
    --dhcp off

if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ NAT Network created successfully${NC}"
else
    echo -e "${RED}  ✗ Failed to create NAT Network${NC}"
    exit 1
fi

echo

# Enable IPv6 (optional, but recommended)
echo -e "${YELLOW}Configuring NAT Network settings...${NC}"
VBoxManage natnetwork modify \
    --netname "$NAT_NETWORK_NAME" \
    --ipv6 off 2>/dev/null || true

echo -e "${GREEN}  ✓ Configuration complete${NC}"
echo

# Display final configuration
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  NAT Network Configuration${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo
VBoxManage natnetwork list | grep -A 12 "$NAT_NETWORK_NAME"
echo
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo

# Summary
echo -e "${GREEN}✓ NAT Network Setup Complete!${NC}"
echo
echo "Network Details:"
echo "  Name: $NAT_NETWORK_NAME"
echo "  CIDR: $NAT_NETWORK_CIDR"
echo "  Gateway: $NAT_NETWORK_IP"
echo
echo "VM IP Assignments:"
echo "  Kali Linux:      192.168.56.101"
echo "  Windows Server:  192.168.56.102"
echo
echo "Benefits of NAT Network:"
echo "  ✓ Single network adapter per VM"
echo "  ✓ VMs can communicate with each other"
echo "  ✓ VMs have internet access"
echo "  ✓ Simpler configuration"
echo
echo -e "${YELLOW}Next step: Run ./setup.sh (or setup.ps1 on Windows)${NC}"
echo
