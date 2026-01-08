#!/bin/bash
################################################################################
# Ethical Hacking Lab - Automated Local Setup
# Description: One-command setup for complete lab environment
# Requirements: VirtualBox, Vagrant
# Usage: ./setup.sh
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
KALI_IP="192.168.56.101"
WINDOWS_IP="192.168.56.102"
NETWORK_NAME="vboxnet0"
REQUIRED_DISK_GB=40
REQUIRED_RAM_GB=8

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}║    ETHICAL HACKING LAB - AUTOMATED LOCAL SETUP                 ║${NC}"
echo -e "${BLUE}║    PDF Exploit Demonstration Environment                       ║${NC}"
echo -e "${BLUE}║                                                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

# ============================================================================
# STEP 1: Check Prerequisites
# ============================================================================
echo -e "${YELLOW}[1/8] Checking prerequisites...${NC}"

# Check VirtualBox
if ! command -v VBoxManage &> /dev/null; then
    echo -e "${RED}✗ VirtualBox not found${NC}"
    echo "Please install VirtualBox from: https://www.virtualbox.org/"
    exit 1
fi
VBOX_VERSION=$(VBoxManage --version | cut -d'r' -f1)
echo -e "${GREEN}  ✓ VirtualBox ${VBOX_VERSION} installed${NC}"

# Check Vagrant
if ! command -v vagrant &> /dev/null; then
    echo -e "${RED}✗ Vagrant not found${NC}"
    echo "Please install Vagrant from: https://www.vagrantup.com/"
    exit 1
fi
VAGRANT_VERSION=$(vagrant --version | awk '{print $2}')
echo -e "${GREEN}  ✓ Vagrant ${VAGRANT_VERSION} installed${NC}"

# Check disk space
AVAILABLE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE" -lt "$REQUIRED_DISK_GB" ]; then
    echo -e "${RED}✗ Insufficient disk space${NC}"
    echo "  Available: ${AVAILABLE}GB, Required: ${REQUIRED_DISK_GB}GB"
    exit 1
else
    echo -e "${GREEN}  ✓ Sufficient disk space (${AVAILABLE}GB available)${NC}"
fi

# Check memory
if [ -f /proc/meminfo ]; then
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_MEM" -lt "$REQUIRED_RAM_GB" ]; then
        echo -e "${YELLOW}  ⚠ Warning: Low memory (${TOTAL_MEM}GB total, ${REQUIRED_RAM_GB}GB+ recommended)${NC}"
    else
        echo -e "${GREEN}  ✓ Sufficient memory (${TOTAL_MEM}GB total)${NC}"
    fi
fi

echo

# ============================================================================
# STEP 2: Extract Adobe Reader from ZIP archive
# ============================================================================
echo -e "${YELLOW}[2/8] Preparing Adobe Reader installer...${NC}"

ADOBE_PATH="resources/AdobeReader_9.5.exe"
ADOBE_ZIP="resources/AdobeReader_9.5.zip"

# Ensure resources directory exists
mkdir -p resources

# Check if extracted file already exists
if [ -f "$ADOBE_PATH" ]; then
    FILE_SIZE=$(du -m "$ADOBE_PATH" | cut -f1)
    if [ "$FILE_SIZE" -lt 40 ]; then
        echo "  Existing file is incomplete (${FILE_SIZE}MB), removing..."
        rm "$ADOBE_PATH"
    else
        echo -e "${GREEN}  ✓ Adobe Reader installer ready (${FILE_SIZE}MB)${NC}"
    fi
fi

# If not ready, extract from ZIP
if [ ! -f "$ADOBE_PATH" ]; then
    if [ -f "$ADOBE_ZIP" ]; then
        echo "  Extracting Adobe Reader from ZIP archive..."

        # Create temp directory
        TEMP_DIR=$(mktemp -d)

        # Extract ZIP
        if command -v unzip >/dev/null 2>&1; then
            if unzip -q "$ADOBE_ZIP" -d "$TEMP_DIR"; then
                # Find the .exe file (could be in subdirectory or with different name)
                EXTRACTED_EXE=$(find "$TEMP_DIR" -type f -name "*.exe" | head -n 1)

                if [ -n "$EXTRACTED_EXE" ]; then
                    # Copy to resources with correct name
                    cp "$EXTRACTED_EXE" "$ADOBE_PATH"

                    # Cleanup temp directory
                    rm -rf "$TEMP_DIR"

                    # Verify the copied file
                    FILE_SIZE=$(du -m "$ADOBE_PATH" | cut -f1)
                    echo -e "${GREEN}  ✓ Extracted successfully (${FILE_SIZE}MB)${NC}"
                else
                    echo -e "${RED}✗ No .exe file found in ZIP archive${NC}"
                    echo ""
                    echo "The ZIP archive may be empty or corrupted."
                    echo "Please contact your instructor for the correct AdobeReader_9.5.zip file"
                    rm -rf "$TEMP_DIR"
                    exit 1
                fi
            else
                echo -e "${RED}✗ Failed to extract ZIP archive${NC}"
                rm -rf "$TEMP_DIR"
                exit 1
            fi
        else
            echo -e "${RED}✗ unzip command not found${NC}"
            echo "Please install unzip: sudo apt-get install unzip"
            exit 1
        fi
    else
        echo -e "${RED}✗ Adobe Reader ZIP archive not found!${NC}"
        echo ""
        echo "The file resources/AdobeReader_9.5.zip is missing."
        echo ""
        echo "Required file: resources/AdobeReader_9.5.zip"
        echo "Please contact your instructor to obtain this file."
        echo ""
        exit 1
    fi
fi

# Final verification
if [ -f "$ADOBE_PATH" ]; then
    FILE_SIZE=$(du -m "$ADOBE_PATH" | cut -f1)
    if [ "$FILE_SIZE" -lt 40 ]; then
        echo -e "${RED}✗ Adobe Reader file is incomplete (${FILE_SIZE}MB)${NC}"
        rm "$ADOBE_PATH"
        echo ""
        echo "Expected size: approximately 50MB"
        echo "Please contact your instructor for the correct ZIP file"
        exit 1
    fi
    echo -e "${GREEN}  ✓ File verified (${FILE_SIZE}MB)${NC}"
else
    echo -e "${RED}✗ Adobe Reader installer not found after extraction${NC}"
    exit 1
fi

echo

# ============================================================================
# STEP 3: Configure VirtualBox Network
# ============================================================================
echo -e "${YELLOW}[3/8] Configuring VirtualBox network...${NC}"

# Check if host-only network exists
if ! VBoxManage list hostonlyifs | grep -q "vboxnet0"; then
    echo "  Creating host-only network..."
    VBoxManage hostonlyif create
    # Get the actual name (might be vboxnet0, vboxnet1, etc.)
    NETWORK_NAME=$(VBoxManage list hostonlyifs | grep "^Name" | head -1 | awk '{print $2}')
fi

# Configure network with correct IP range
VBoxManage hostonlyif ipconfig "$NETWORK_NAME" --ip 192.168.56.1 --netmask 255.255.255.0

# Disable DHCP (we use static IPs)
VBoxManage dhcpserver modify --ifname "$NETWORK_NAME" --disable 2>/dev/null || \
VBoxManage dhcpserver add --ifname "$NETWORK_NAME" --ip 192.168.56.1 --netmask 255.255.255.0 --lowerip 192.168.56.100 --upperip 192.168.56.200 --disable

echo -e "${GREEN}  ✓ Network configured: 192.168.56.0/24${NC}"
echo -e "${GREEN}  ✓ Network interface: $NETWORK_NAME${NC}"
echo

# ============================================================================
# STEP 4: Build Kali Linux VM
# ============================================================================
echo -e "${YELLOW}[4/8] Building Kali Linux VM...${NC}"
echo "  This will take 5-10 minutes..."
echo

cd vagrant

# Check if Kali is already running
if vagrant status kali 2>/dev/null | grep -q "running"; then
    echo -e "${CYAN}  Kali VM already running, destroying and rebuilding...${NC}"
    vagrant destroy kali -f
fi

# Bring up Kali VM
vagrant up kali --provider virtualbox

if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Kali Linux VM ready${NC}"
    echo -e "${GREEN}  ✓ IP: $KALI_IP${NC}"
    echo -e "${GREEN}  ✓ Metasploit Framework installed${NC}"
    echo -e "${GREEN}  ✓ Exploits pre-generated${NC}"
else
    echo -e "${RED}✗ Failed to build Kali VM${NC}"
    exit 1
fi

echo

# ============================================================================
# STEP 5: Build Windows VM
# ============================================================================
echo -e "${YELLOW}[5/8] Building Windows Server 2008 R2 VM...${NC}"
echo "  This will take 20-30 minutes (downloading and configuring)..."
echo "  Progress:"
echo "  - Downloading Windows box"
echo "  - Installing Adobe Reader 9.5.0"
echo "  - Disabling all security features"
echo "  - Configuring network"
echo

# Check if Windows is already running
if vagrant status win2k8 2>/dev/null | grep -q "running"; then
    echo -e "${CYAN}  Windows VM already running, destroying and rebuilding...${NC}"
    vagrant destroy win2k8 -f
fi

# Bring up Windows VM
vagrant up win2k8 --provider virtualbox

if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Windows Server VM ready${NC}"
    echo -e "${GREEN}  ✓ IP: $WINDOWS_IP${NC}"
    echo -e "${GREEN}  ✓ Adobe Reader 9.5.0 installed${NC}"
    echo -e "${GREEN}  ✓ AppLocker disabled${NC}"
    echo -e "${GREEN}  ✓ Windows Firewall disabled${NC}"
    echo -e "${GREEN}  ✓ Windows Defender disabled${NC}"
    echo -e "${GREEN}  ✓ UAC disabled${NC}"
    echo -e "${GREEN}  ✓ Adobe security disabled${NC}"
else
    echo -e "${RED}✗ Failed to build Windows VM${NC}"
    exit 1
fi

echo

# ============================================================================
# STEP 6: Verify Connectivity
# ============================================================================
echo -e "${YELLOW}[6/8] Verifying network connectivity...${NC}"

# Test Kali -> Windows
echo "  Testing Kali → Windows..."
vagrant ssh kali -c "ping -c 2 $WINDOWS_IP" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Kali → Windows: OK${NC}"
else
    echo -e "${RED}  ✗ Kali → Windows: FAILED${NC}"
    echo "  Network connectivity issue detected"
    exit 1
fi

# Test Windows -> Kali
echo "  Testing Windows → Kali..."
vagrant winrm win2k8 -c "Test-Connection $KALI_IP -Count 2 -Quiet" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Windows → Kali: OK${NC}"
else
    echo -e "${YELLOW}  ⚠ Windows → Kali: Could not verify (but probably OK)${NC}"
fi

echo

# ============================================================================
# STEP 7: Create Initial Snapshots
# ============================================================================
echo -e "${YELLOW}[7/8] Creating snapshots for easy reset...${NC}"

# Get actual VM names from VirtualBox
KALI_VM=$(VBoxManage list vms | grep kali | head -1 | awk '{print $1}' | tr -d '"')
WINDOWS_VM=$(VBoxManage list vms | grep win2k8 | head -1 | awk '{print $1}' | tr -d '"')

if [ -n "$KALI_VM" ]; then
    # Delete old snapshot if exists
    VBoxManage snapshot "$KALI_VM" delete "Clean_State" 2>/dev/null || true
    # Create new snapshot
    VBoxManage snapshot "$KALI_VM" take "Clean_State" --description "Fresh Kali installation with all tools"
    echo -e "${GREEN}  ✓ Kali snapshot created${NC}"
fi

if [ -n "$WINDOWS_VM" ]; then
    # Delete old snapshot if exists
    VBoxManage snapshot "$WINDOWS_VM" delete "Clean_State" 2>/dev/null || true
    # Create new snapshot
    VBoxManage snapshot "$WINDOWS_VM" take "Clean_State" --description "Fresh Windows installation, ready for exploitation"
    echo -e "${GREEN}  ✓ Windows snapshot created${NC}"
fi

echo

# ============================================================================
# STEP 8: Verify Exploit Files
# ============================================================================
echo -e "${YELLOW}[8/8] Verifying exploit materials...${NC}"

# Check if PDF was generated
vagrant ssh kali -c "ls -lh ~/.msf4/local/JOAN-ESPINACH-TRD.pdf" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✓ Malicious PDF generated${NC}"
else
    echo -e "${YELLOW}  ⚠ PDF not found, generating now...${NC}"
    vagrant ssh kali -c "cd /vagrant/exploits && ./generate_pdf.sh"
    echo -e "${GREEN}  ✓ PDF generated${NC}"
fi

echo

cd ..

# ============================================================================
# SUCCESS SUMMARY
# ============================================================================
echo
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║                    SETUP COMPLETE! ✓                           ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    LAB ENVIRONMENT READY                      ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo
echo -e "${CYAN}Virtual Machines:${NC}"
echo -e "  ${GREEN}✓${NC} Kali Linux (Attacker)"
echo -e "    IP Address:      ${KALI_IP}"
echo -e "    Username:        vagrant"
echo -e "    Password:        vagrant"
echo -e "    Tools:           Metasploit, Nmap, Python3"
echo
echo -e "  ${GREEN}✓${NC} Windows Server 2008 R2 (Target)"
echo -e "    IP Address:      ${WINDOWS_IP}"
echo -e "    Username:        vagrant"
echo -e "    Password:        vagrant"
echo -e "    Vulnerability:   Adobe Reader 9.5.0"
echo -e "    Security:        ALL DISABLED (intentionally vulnerable)"
echo
echo -e "${CYAN}Network:${NC}"
echo -e "  ${GREEN}✓${NC} Host-Only Network:  192.168.56.0/24"
echo -e "  ${GREEN}✓${NC} Connectivity:       Verified"
echo -e "  ${GREEN}✓${NC} Isolation:          Complete (no internet from VMs)"
echo
echo -e "${CYAN}Exploit Materials:${NC}"
echo -e "  ${GREEN}✓${NC} Malicious PDF:      JOAN-ESPINACH-TRD.pdf"
echo -e "  ${GREEN}✓${NC} Attack Scripts:     Ready in /vagrant/exploits"
echo -e "  ${GREEN}✓${NC} Snapshots:          Created for easy reset"
echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                        NEXT STEPS                             ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo
echo -e "${YELLOW}1.${NC} Read the lab guide:"
echo -e "   ${CYAN}open docs/LAB_GUIDE.pdf${NC}"
echo
echo -e "${YELLOW}2.${NC} Access the VMs:"
echo -e "   ${CYAN}cd vagrant${NC}"
echo -e "   ${CYAN}vagrant ssh kali${NC}          # SSH into Kali Linux"
echo -e "   ${CYAN}vagrant rdp win2k8${NC}        # RDP into Windows (GUI)"
echo
echo -e "${YELLOW}3.${NC} Run the automated attack:"
echo -e "   ${CYAN}cd vagrant${NC}"
echo -e "   ${CYAN}vagrant ssh kali${NC}"
echo -e "   ${CYAN}cd /vagrant/exploits${NC}"
echo -e "   ${CYAN}./start_attack.sh${NC}"
echo
echo -e "${YELLOW}4.${NC} Reset to clean state when done:"
echo -e "   ${CYAN}./reset.sh${NC}"
echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                      DOCUMENTATION                            ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo
echo "  📘 Lab Guide:           docs/LAB_GUIDE.pdf"
echo "  📗 Quick Start:         docs/QUICK_START.md"
echo "  📙 Troubleshooting:     TROUBLESHOOTING.md"
echo "  📕 Instructor Guide:    docs/INSTRUCTOR_GUIDE.pdf"
echo
echo -e "${GREEN}Happy Hacking! 🎯${NC}"
echo
echo -e "${CYAN}Tip: Keep this terminal open to see VM status${NC}"
echo
