################################################################################
# Ethical Hacking Lab - Automated Local Setup (Windows PowerShell)
# Description: One-command setup for complete lab environment
# Requirements: VirtualBox, Vagrant
# Usage: .\setup.ps1
################################################################################

# Requires PowerShell 5.1 or higher
#Requires -Version 5.1

# Configuration
$KALI_IP = "192.168.56.101"
$WINDOWS_IP = "192.168.56.102"
$NETWORK_NAME = "vboxnet0"
$REQUIRED_DISK_GB = 40
$REQUIRED_RAM_GB = 8

# Color functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Text)
    Write-ColorOutput "`n╔════════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║                                                                ║" "Cyan"
    Write-ColorOutput "║    $Text" "Cyan"
    Write-ColorOutput "║                                                                ║" "Cyan"
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
}

function Write-Step {
    param([string]$Text)
    Write-ColorOutput $Text "Yellow"
}

function Write-Success {
    param([string]$Text)
    Write-ColorOutput "  ✓ $Text" "Green"
}

function Write-Error-Message {
    param([string]$Text)
    Write-ColorOutput "✗ $Text" "Red"
}

function Write-Warning-Message {
    param([string]$Text)
    Write-ColorOutput "  ⚠ $Text" "Yellow"
}

# Main script
Clear-Host

Write-Header "    ETHICAL HACKING LAB - AUTOMATED LOCAL SETUP                 "
Write-Header "    PDF Exploit Demonstration Environment                       "

# ============================================================================
# STEP 1: Check Prerequisites
# ============================================================================
Write-Step "[1/8] Checking prerequisites..."
Write-Host ""

# Check if running as Administrator (recommended but not required)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning-Message "Not running as Administrator. Some operations may fail."
    Write-Warning-Message "Consider running PowerShell as Administrator."
    Write-Host ""
}

# Check VirtualBox
try {
    $vboxVersion = & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version 2>$null
    if ($vboxVersion) {
        $vboxVersion = $vboxVersion.Split('r')[0]
        Write-Success "VirtualBox $vboxVersion installed"
    } else {
        throw "VirtualBox not found"
    }
} catch {
    Write-Error-Message "VirtualBox not found"
    Write-Host "Please install VirtualBox from: https://www.virtualbox.org/"
    exit 1
}

# Check Vagrant
try {
    $vagrantVersion = vagrant --version 2>$null
    if ($vagrantVersion) {
        $vagrantVersion = $vagrantVersion -replace "Vagrant ", ""
        Write-Success "Vagrant $vagrantVersion installed"
    } else {
        throw "Vagrant not found"
    }
} catch {
    Write-Error-Message "Vagrant not found"
    Write-Host "Please install Vagrant from: https://www.vagrantup.com/"
    exit 1
}

# Check disk space
$drive = (Get-Location).Drive
$freeSpaceGB = [math]::Round((Get-PSDrive $drive.Name).Free / 1GB, 2)
if ($freeSpaceGB -lt $REQUIRED_DISK_GB) {
    Write-Error-Message "Insufficient disk space"
    Write-Host "  Available: ${freeSpaceGB}GB, Required: ${REQUIRED_DISK_GB}GB"
    exit 1
} else {
    Write-Success "Sufficient disk space (${freeSpaceGB}GB available)"
}

# Check memory
$totalMemoryGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
if ($totalMemoryGB -lt $REQUIRED_RAM_GB) {
    Write-Warning-Message "Low memory (${totalMemoryGB}GB total, ${REQUIRED_RAM_GB}GB+ recommended)"
} else {
    Write-Success "Sufficient memory (${totalMemoryGB}GB total)"
}

Write-Host ""

# ============================================================================
# STEP 2: Download Adobe Reader (if needed)
# ============================================================================
Write-Step "[2/8] Checking Adobe Reader installer..."
Write-Host ""

$adobePath = "resources\AdobeReader_9.5.exe"

if (-not (Test-Path $adobePath)) {
    Write-Host "  Downloading Adobe Reader 9.5.0 (this may take a few minutes)..."
    New-Item -ItemType Directory -Force -Path "resources" | Out-Null

    $downloaded = $false

    # Try Internet Archive
    if (-not $downloaded) {
        Write-Host "  Trying Internet Archive..."
        try {
            $url = "https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe"
            Invoke-WebRequest -Uri $url -OutFile $adobePath -UseBasicParsing
            $downloaded = $true
            Write-Success "Downloaded from Internet Archive"
        } catch {
            Write-Warning-Message "Failed to download from Internet Archive"
        }
    }

    # Try alternative source
    if (-not $downloaded) {
        Write-Host "  Trying alternative source..."
        try {
            $url = "https://ardownload2.adobe.com/pub/adobe/reader/win/9.x/9.5.0/en_US/AdbeRdr950_en_US.exe"
            Invoke-WebRequest -Uri $url -OutFile $adobePath -UseBasicParsing
            $downloaded = $true
            Write-Success "Downloaded from Adobe FTP"
        } catch {
            Write-Warning-Message "Failed to download from alternative source"
        }
    }

    if (-not $downloaded) {
        Write-Error-Message "Failed to download Adobe Reader"
        Write-Host ""
        Write-Host "Please manually download from:"
        Write-Host "  https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe"
        Write-Host "And save to: $adobePath"
        exit 1
    }
} else {
    Write-Success "Adobe Reader installer ready"
}

# Verify file size
$fileSizeMB = [math]::Round((Get-Item $adobePath).Length / 1MB, 2)
if ($fileSizeMB -lt 40) {
    Write-Error-Message "Adobe Reader file seems incomplete (${fileSizeMB}MB)"
    Remove-Item $adobePath -Force
    exit 1
}
Write-Success "File verified (${fileSizeMB}MB)"

Write-Host ""

# ============================================================================
# STEP 3: Configure VirtualBox Network
# ============================================================================
Write-Step "[3/8] Configuring VirtualBox network..."
Write-Host ""

# Check if host-only network exists
$vboxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$networks = & $vboxManage list hostonlyifs 2>$null

if ($networks -notmatch "vboxnet0") {
    Write-Host "  Creating host-only network..."
    & $vboxManage hostonlyif create | Out-Null
    # Get the actual name
    $networkList = & $vboxManage list hostonlyifs
    $NETWORK_NAME = ($networkList | Select-String "Name:\s+(.+)" | Select-Object -First 1).Matches.Groups[1].Value.Trim()
}

# Configure network
& $vboxManage hostonlyif ipconfig $NETWORK_NAME --ip 192.168.56.1 --netmask 255.255.255.0 | Out-Null

# Disable DHCP
try {
    & $vboxManage dhcpserver modify --ifname $NETWORK_NAME --disable 2>$null
} catch {
    & $vboxManage dhcpserver add --ifname $NETWORK_NAME --ip 192.168.56.1 --netmask 255.255.255.0 --lowerip 192.168.56.100 --upperip 192.168.56.200 --disable 2>$null
}

Write-Success "Network configured: 192.168.56.0/24"
Write-Success "Network interface: $NETWORK_NAME"
Write-Host ""

# ============================================================================
# STEP 4: Build Kali Linux VM
# ============================================================================
Write-Step "[4/8] Building Kali Linux VM..."
Write-Host "  This will take 5-10 minutes..."
Write-Host ""

Push-Location vagrant

# Check if Kali is already running
$kaliStatus = vagrant status kali 2>$null | Select-String "running"
if ($kaliStatus) {
    Write-ColorOutput "  Kali VM already running, destroying and rebuilding..." "Cyan"
    vagrant destroy kali -f
}

# Bring up Kali VM
vagrant up kali --provider virtualbox

if ($LASTEXITCODE -eq 0) {
    Write-Success "Kali Linux VM ready"
    Write-Success "IP: $KALI_IP"
    Write-Success "Metasploit Framework installed"
    Write-Success "Exploits pre-generated"
} else {
    Write-Error-Message "Failed to build Kali VM"
    Pop-Location
    exit 1
}

Write-Host ""

# ============================================================================
# STEP 5: Build Windows VM
# ============================================================================
Write-Step "[5/8] Building Windows Server 2008 R2 VM..."
Write-Host "  This will take 20-30 minutes (downloading and configuring)..."
Write-Host "  Progress:"
Write-Host "  - Downloading Windows box"
Write-Host "  - Installing Adobe Reader 9.5.0"
Write-Host "  - Disabling all security features"
Write-Host "  - Configuring network"
Write-Host ""

# Check if Windows is already running
$winStatus = vagrant status win2k8 2>$null | Select-String "running"
if ($winStatus) {
    Write-ColorOutput "  Windows VM already running, destroying and rebuilding..." "Cyan"
    vagrant destroy win2k8 -f
}

# Bring up Windows VM
vagrant up win2k8 --provider virtualbox

if ($LASTEXITCODE -eq 0) {
    Write-Success "Windows Server VM ready"
    Write-Success "IP: $WINDOWS_IP"
    Write-Success "Adobe Reader 9.5.0 installed"
    Write-Success "AppLocker disabled"
    Write-Success "Windows Firewall disabled"
    Write-Success "Windows Defender disabled"
    Write-Success "UAC disabled"
    Write-Success "Adobe security disabled"
} else {
    Write-Error-Message "Failed to build Windows VM"
    Pop-Location
    exit 1
}

Write-Host ""

# ============================================================================
# STEP 6: Verify Connectivity
# ============================================================================
Write-Step "[6/8] Verifying network connectivity..."
Write-Host ""

# Test Kali -> Windows
Write-Host "  Testing Kali → Windows..."
vagrant ssh kali -c "ping -c 2 $WINDOWS_IP" 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Kali → Windows: OK"
} else {
    Write-Error-Message "Kali → Windows: FAILED"
    Write-Host "  Network connectivity issue detected"
    Pop-Location
    exit 1
}

# Test Windows -> Kali
Write-Host "  Testing Windows → Kali..."
vagrant winrm win2k8 -c "Test-Connection $KALI_IP -Count 2 -Quiet" 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Windows → Kali: OK"
} else {
    Write-Warning-Message "Windows → Kali: Could not verify (but probably OK)"
}

Write-Host ""

# ============================================================================
# STEP 7: Create Initial Snapshots
# ============================================================================
Write-Step "[7/8] Creating snapshots for easy reset..."
Write-Host ""

# Get actual VM names from VirtualBox
$kaliVM = (& $vboxManage list vms | Select-String "kali" | Select-Object -First 1) -replace '.*"(.+?)".*', '$1'
$windowsVM = (& $vboxManage list vms | Select-String "win2k8" | Select-Object -First 1) -replace '.*"(.+?)".*', '$1'

if ($kaliVM) {
    # Delete old snapshot if exists
    & $vboxManage snapshot $kaliVM delete "Clean_State" 2>$null | Out-Null
    # Create new snapshot
    & $vboxManage snapshot $kaliVM take "Clean_State" --description "Fresh Kali installation with all tools" | Out-Null
    Write-Success "Kali snapshot created"
}

if ($windowsVM) {
    # Delete old snapshot if exists
    & $vboxManage snapshot $windowsVM delete "Clean_State" 2>$null | Out-Null
    # Create new snapshot
    & $vboxManage snapshot $windowsVM take "Clean_State" --description "Fresh Windows installation, ready for exploitation" | Out-Null
    Write-Success "Windows snapshot created"
}

Write-Host ""

# ============================================================================
# STEP 8: Verify Exploit Files
# ============================================================================
Write-Step "[8/8] Verifying exploit materials..."
Write-Host ""

vagrant ssh kali -c "ls -lh ~/.msf4/local/JOAN-ESPINACH-TRD.pdf" 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Malicious PDF generated"
} else {
    Write-Warning-Message "PDF not found, generating now..."
    vagrant ssh kali -c "cd /vagrant/exploits && ./generate_pdf.sh"
    Write-Success "PDF generated"
}

Write-Host ""

Pop-Location

# ============================================================================
# SUCCESS SUMMARY
# ============================================================================
Write-Host ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════════╗" "Green"
Write-ColorOutput "║                                                                ║" "Green"
Write-ColorOutput "║                    SETUP COMPLETE! ✓                           ║" "Green"
Write-ColorOutput "║                                                                ║" "Green"
Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" "Green"
Write-Host ""
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
Write-ColorOutput "                    LAB ENVIRONMENT READY                      " "Cyan"
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
Write-Host ""
Write-ColorOutput "Virtual Machines:" "Cyan"
Write-ColorOutput "  ✓ Kali Linux (Attacker)" "Green"
Write-Host "    IP Address:      $KALI_IP"
Write-Host "    Username:        vagrant"
Write-Host "    Password:        vagrant"
Write-Host "    Tools:           Metasploit, Nmap, Python3"
Write-Host ""
Write-ColorOutput "  ✓ Windows Server 2008 R2 (Target)" "Green"
Write-Host "    IP Address:      $WINDOWS_IP"
Write-Host "    Username:        vagrant"
Write-Host "    Password:        vagrant"
Write-Host "    Vulnerability:   Adobe Reader 9.5.0"
Write-Host "    Security:        ALL DISABLED (intentionally vulnerable)"
Write-Host ""
Write-ColorOutput "Network:" "Cyan"
Write-ColorOutput "  ✓ Host-Only Network:  192.168.56.0/24" "Green"
Write-ColorOutput "  ✓ Connectivity:       Verified" "Green"
Write-ColorOutput "  ✓ Isolation:          Complete (no internet from VMs)" "Green"
Write-Host ""
Write-ColorOutput "Exploit Materials:" "Cyan"
Write-ColorOutput "  ✓ Malicious PDF:      JOAN-ESPINACH-TRD.pdf" "Green"
Write-ColorOutput "  ✓ Attack Scripts:     Ready in /vagrant/exploits" "Green"
Write-ColorOutput "  ✓ Snapshots:          Created for easy reset" "Green"
Write-Host ""
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
Write-ColorOutput "                        NEXT STEPS                             " "Cyan"
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
Write-Host ""
Write-ColorOutput "1. Read the lab guide:" "Yellow"
Write-ColorOutput "   start docs\LAB_GUIDE.pdf" "Cyan"
Write-Host ""
Write-ColorOutput "2. Access the VMs:" "Yellow"
Write-ColorOutput "   cd vagrant" "Cyan"
Write-ColorOutput "   vagrant ssh kali          # SSH into Kali Linux" "Cyan"
Write-ColorOutput "   vagrant rdp win2k8        # RDP into Windows (GUI)" "Cyan"
Write-Host ""
Write-ColorOutput "3. Run the automated attack:" "Yellow"
Write-ColorOutput "   cd vagrant" "Cyan"
Write-ColorOutput "   vagrant ssh kali" "Cyan"
Write-ColorOutput "   cd /vagrant/exploits" "Cyan"
Write-ColorOutput "   ./start_attack.sh" "Cyan"
Write-Host ""
Write-ColorOutput "4. Reset to clean state when done:" "Yellow"
Write-ColorOutput "   .\reset.ps1" "Cyan"
Write-Host ""
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
Write-ColorOutput "                      DOCUMENTATION                            " "Cyan"
Write-ColorOutput "═══════════════════════════════════════════════════════════════" "Cyan"
Write-Host ""
Write-Host "  📘 Lab Guide:           docs\LAB_GUIDE.pdf"
Write-Host "  📗 Quick Start:         docs\QUICK_START.md"
Write-Host "  📙 Troubleshooting:     TROUBLESHOOTING.md"
Write-Host "  📕 Instructor Guide:    docs\INSTRUCTOR_GUIDE.pdf"
Write-Host ""
Write-ColorOutput "Happy Hacking! 🎯" "Green"
Write-Host ""
Write-ColorOutput "Tip: Keep this PowerShell window open to see VM status" "Cyan"
Write-Host ""
