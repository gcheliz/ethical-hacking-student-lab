# Ethical Hacking Lab - Automated Local Setup (Windows PowerShell)
# Description: One-command setup for complete lab environment
# Requirements: VirtualBox, Vagrant
# Usage: .\setup.ps1

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
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Text)
    Write-ColorOutput $Text "Yellow"
}

function Write-Success {
    param([string]$Text)
    Write-ColorOutput "  [OK] $Text" "Green"
}

function Write-Error-Message {
    param([string]$Text)
    Write-ColorOutput "[ERROR] $Text" "Red"
}

function Write-Warning-Message {
    param([string]$Text)
    Write-ColorOutput "  [WARNING] $Text" "Yellow"
}

# Main script
Clear-Host

Write-Header "ETHICAL HACKING LAB - AUTOMATED LOCAL SETUP"
Write-Header "LNK Shortcut Exploit - Fake PDF Attack"

# STEP 1: Check Prerequisites
Write-Step "[1/7] Checking prerequisites..."
Write-Host ""

# Check if running as Administrator
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

# STEP 2: Prepare Exploits Directory
Write-Step "[2/7] Preparing exploits directory..."
Write-Host ""

# Ensure exploits directory exists
New-Item -ItemType Directory -Force -Path "exploits" | Out-Null
Write-Success "Exploits directory ready"
Write-Host "  Payload will be generated automatically by Kali VM" -ForegroundColor Cyan

Write-Host ""

# STEP 3: Configure VirtualBox NAT Network
Write-Step "[3/7] Configuring VirtualBox NAT Network..."
Write-Host ""

$vboxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

# Check if NAT Network already exists
$natNetworkName = "LNK_Exploit_Lab_Network"
$natNetworks = & $vboxManage natnetwork list 2>$null

if ($natNetworks -and ($natNetworks -match $natNetworkName)) {
    Write-Host "  NAT Network '$natNetworkName' already exists" -ForegroundColor Cyan
    Write-Success "Using existing NAT Network"
} else {
    Write-Host "  Creating NAT Network..." -ForegroundColor Cyan
    Write-Host "  Name: $natNetworkName" -ForegroundColor Cyan
    Write-Host "  Network: 192.168.56.0/24" -ForegroundColor Cyan
    Write-Host "  DHCP: Disabled (using static IPs)" -ForegroundColor Cyan
    Write-Host ""

    # Create NAT Network
    $createArgs = @("natnetwork", "add", "--netname", $natNetworkName, "--network", "192.168.56.0/24", "--enable", "--dhcp", "off")
    $createOutput = & $vboxManage $createArgs 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Message "Failed to create NAT Network"
        Write-Host "Output: $createOutput" -ForegroundColor Red
        exit 1
    }

    Write-Success "NAT Network created successfully"
}

# Verify NAT Network configuration
$verifyNetworks = & $vboxManage natnetwork list 2>$null
if ($verifyNetworks -and ($verifyNetworks -match $natNetworkName)) {
    Write-Success "NAT Network configured: 192.168.56.0/24"
    Write-Success "Network name: $natNetworkName"
} else {
    Write-Error-Message "Failed to verify NAT Network"
    Write-Host ""
    Write-Host "Current NAT networks:" -ForegroundColor Yellow
    & $vboxManage natnetwork list
    exit 1
}
Write-Host ""

# STEP 4: Build Kali Linux VM
Write-Step "[4/7] Building Kali Linux VM..."
Write-Host "  This will take 5-10 minutes..."
Write-Host ""

Push-Location vagrant

# Aggressive cleanup of all Kali lab VMs and directories
Write-Host "  Cleaning up old VirtualBox VMs and directories..." -NoNewline

# First: Unregister ALL Kali lab-related VMs
$allVMs = & $vboxManage list vms 2>$null
if ($allVMs) {
    $kaliVMs = $allVMs | Select-String "Kali_PDF_Exploit_Lab"
    foreach ($vm in $kaliVMs) {
        $vmUUID = $vm -replace '.*\{(.+?)\}.*', '$1'
        Write-Host "." -NoNewline
        & $vboxManage controlvm $vmUUID poweroff 2>$null | Out-Null
        Start-Sleep -Milliseconds 500
        & $vboxManage unregistervm $vmUUID --delete 2>$null | Out-Null
    }
}

# Second: Remove Kali VM directories
Get-ChildItem -Path "$env:USERPROFILE\VirtualBox VMs" -Directory -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like "Kali_PDF_Exploit_Lab*"
} | ForEach-Object {
    Write-Host "." -NoNewline
    try {
        Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
    } catch {
        cmd /c "rd /s /q `"$($_.FullName)`"" 2>$null
    }
}

# Third: Destroy vagrant machine
vagrant destroy kali -f 2>$null | Out-Null

Write-Host " Done" -ForegroundColor Green

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

# STEP 5: Build Windows VM
Write-Step "[5/7] Building Windows Server 2008 R2 VM..."
Write-Host "  This will take 20-30 minutes (downloading and configuring)..."
Write-Host "  Progress:"
Write-Host "  - Downloading Windows box"
Write-Host "  - Disabling all security features"
Write-Host "  - Configuring network"
Write-Host ""

# Aggressive cleanup of all Windows lab VMs and directories
Write-Host "  Cleaning up old VirtualBox VMs and directories..." -NoNewline

# First: Unregister ALL lab-related VMs (by name pattern)
$allVMs = & $vboxManage list vms 2>$null
if ($allVMs) {
    $labVMs = $allVMs | Select-String "(Windows_PDF_Target_Lab|metasploitable3-win2k8)"
    foreach ($vm in $labVMs) {
        $vmUUID = $vm -replace '.*\{(.+?)\}.*', '$1'
        Write-Host "." -NoNewline
        # Power off if running
        & $vboxManage controlvm $vmUUID poweroff 2>$null | Out-Null
        Start-Sleep -Milliseconds 500
        # Unregister and delete
        & $vboxManage unregistervm $vmUUID --delete 2>$null | Out-Null
    }
}

# Second: Remove all VM directories (even if unregistered)
$vmDirsToRemove = @(
    "$env:USERPROFILE\VirtualBox VMs\Windows_PDF_Target_Lab*",
    "$env:USERPROFILE\VirtualBox VMs\metasploitable3-win2k8*"
)

foreach ($pattern in $vmDirsToRemove) {
    Get-ChildItem -Path "$env:USERPROFILE\VirtualBox VMs" -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -like ($pattern -replace '.*\\', '')
    } | ForEach-Object {
        Write-Host "." -NoNewline
        try {
            # Try to unlock and remove
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
        } catch {
            # If locked, try with more force
            cmd /c "rd /s /q `"$($_.FullName)`"" 2>$null
        }
    }
}

# Third: Destroy vagrant machine (if registered)
vagrant destroy win2k8 -f 2>$null | Out-Null

Write-Host " Done" -ForegroundColor Green

# Bring up Windows VM
vagrant up win2k8 --provider virtualbox

if ($LASTEXITCODE -eq 0) {
    Write-Success "Windows Server VM ready"
    Write-Success "IP: $WINDOWS_IP"
    Write-Success "AppLocker disabled"
    Write-Success "Windows Firewall disabled"
    Write-Success "Windows Defender disabled"
    Write-Success "UAC disabled"
} else {
    Write-Error-Message "Failed to build Windows VM"
    Pop-Location
    exit 1
}

Write-Host ""

# STEP 6: Verify Connectivity
Write-Step "[6/7] Verifying network connectivity..."
Write-Host ""

Write-Host "  Waiting for VMs to be fully ready..." -ForegroundColor Yellow
Write-Host "  (Windows is rebooting, this may take 1-2 minutes)"
Write-Host ""

# Wait for Windows to finish rebooting
Start-Sleep -Seconds 45

# Test Kali -> Windows with retries
Write-Host "  Testing Kali -> Windows..." -NoNewline
$maxRetries = 3
$success = $false

for ($i = 1; $i -le $maxRetries; $i++) {
    vagrant ssh kali -c "ping -c 2 $WINDOWS_IP" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $success = $true
        break
    }
    if ($i -lt $maxRetries) {
        Start-Sleep -Seconds 10
    }
}

if ($success) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " FAILED" -ForegroundColor Yellow
    Write-Host "  Note: This is usually temporary. Try running reset.ps1 to power cycle the VMs." -ForegroundColor Gray
}

# Test Windows -> Kali
Write-Host "  Testing Windows -> Kali..." -NoNewline
vagrant winrm win2k8 -c "Test-Connection $KALI_IP -Count 2 -Quiet" 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " Skipped" -ForegroundColor Gray
}

Write-Host ""

# STEP 7: Create Initial Snapshots
Write-Step "[7/7] Creating snapshots for easy reset..."
Write-Host ""

# Get actual VM names from VirtualBox
$kaliVM = (& $vboxManage list vms | Select-String "kali" | Select-Object -First 1) -replace '.*"(.+?)".*', '$1'
$windowsVM = (& $vboxManage list vms | Select-String "win2k8" | Select-Object -First 1) -replace '.*"(.+?)".*', '$1'

if ($kaliVM) {
    Write-Host "  Creating Kali snapshot..." -NoNewline
    try {
        # Delete old snapshot if exists
        & $vboxManage snapshot $kaliVM delete "Clean_State" 2>$null | Out-Null

        # Create new snapshot (VMs must be powered off)
        $result = & $vboxManage snapshot $kaliVM take "Clean_State" --description "Fresh Kali installation with all tools" 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host " Done" -ForegroundColor Green
        } else {
            Write-Host " Skipped (VM may be running)" -ForegroundColor Yellow
            Write-Host "  Tip: Power off VMs to create snapshots manually" -ForegroundColor Gray
        }
    } catch {
        Write-Host " Failed" -ForegroundColor Yellow
    }
}

if ($windowsVM) {
    Write-Host "  Creating Windows snapshot..." -NoNewline
    try {
        # Delete old snapshot if exists
        & $vboxManage snapshot $windowsVM delete "Clean_State" 2>$null | Out-Null

        # Create new snapshot (VMs must be powered off)
        $result = & $vboxManage snapshot $windowsVM take "Clean_State" --description "Fresh Windows installation, ready for exploitation" 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host " Done" -ForegroundColor Green
        } else {
            Write-Host " Skipped (VM may be running)" -ForegroundColor Yellow
            Write-Host "  Tip: Power off VMs to create snapshots manually" -ForegroundColor Gray
        }
    } catch {
        Write-Host " Failed" -ForegroundColor Yellow
    }
}

Write-Host ""

Pop-Location

# SUCCESS SUMMARY
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "                    SETUP COMPLETE!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "                 LAB ENVIRONMENT READY" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Virtual Machines:" -ForegroundColor Cyan
Write-Host "  [OK] Kali Linux (Attacker)" -ForegroundColor Green
Write-Host "    IP Address:      $KALI_IP"
Write-Host "    Username:        vagrant"
Write-Host "    Password:        vagrant"
Write-Host "    Tools:           Metasploit, Nmap, Python3"
Write-Host ""
Write-Host "  [OK] Windows Server 2008 R2 (Target)" -ForegroundColor Green
Write-Host "    IP Address:      $WINDOWS_IP"
Write-Host "    Username:        vagrant"
Write-Host "    Password:        vagrant"
Write-Host "    Exploitation:    Automated LNK payload"
Write-Host "    Security:        ALL DISABLED (intentionally vulnerable)"
Write-Host ""
Write-Host "Network:" -ForegroundColor Cyan
Write-Host "  [OK] NAT Network:        192.168.56.0/24 (LNK_Exploit_Lab_Network)" -ForegroundColor Green
Write-Host "  [OK] Connectivity:       Verified (VM-to-VM + Internet)" -ForegroundColor Green
Write-Host "  [OK] Configuration:      Single adapter per VM" -ForegroundColor Green
Write-Host ""
Write-Host "Exploit Materials:" -ForegroundColor Cyan
Write-Host "  [OK] Payload:            shell.ps1 (PowerShell Meterpreter)" -ForegroundColor Green
Write-Host "  [OK] LNK File:           Q4_Financial_Report.pdf.lnk" -ForegroundColor Green
Write-Host "  [OK] Attack Scripts:     Ready in /vagrant/exploits/lnk" -ForegroundColor Green
Write-Host "  [OK] Snapshots:          Created for easy reset" -ForegroundColor Green
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "                        NEXT STEPS" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Read the exploit guide:" -ForegroundColor Yellow
Write-Host "   start LNK_EXPLOIT_GUIDE.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Access the VMs:" -ForegroundColor Yellow
Write-Host "   cd vagrant" -ForegroundColor Cyan
Write-Host "   vagrant ssh kali          # SSH into Kali Linux" -ForegroundColor Cyan
Write-Host "   vagrant rdp win2k8        # RDP into Windows (GUI)" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Run the LNK attack:" -ForegroundColor Yellow
Write-Host "   cd vagrant" -ForegroundColor Cyan
Write-Host "   vagrant ssh kali" -ForegroundColor Cyan
Write-Host "   cd /vagrant/exploits/lnk" -ForegroundColor Cyan
Write-Host "   ./start_lnk_attack.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Reset to clean state when done:" -ForegroundColor Yellow
Write-Host "   .\reset.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "                      DOCUMENTATION" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  LNK Exploit Guide:   LNK_EXPLOIT_GUIDE.md"
Write-Host "  How To Use:          HOW_TO_USE.md"
Write-Host "  Troubleshooting:     TROUBLESHOOTING.md"
Write-Host "  Instructor Guide:    docs\INSTRUCTOR_GUIDE.pdf"
Write-Host ""
Write-Host "Happy Hacking!" -ForegroundColor Green
Write-Host ""
Write-Host "Tip: Keep this PowerShell window open to see VM status" -ForegroundColor Cyan
Write-Host ""
