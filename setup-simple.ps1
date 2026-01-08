################################################################################
# Ethical Hacking Lab - Automated Local Setup (Windows PowerShell)
# Description: One-command setup for complete lab environment
# Requirements: VirtualBox, Vagrant
# Usage: .\setup-simple.ps1
################################################################################

# Requires PowerShell 5.1 or higher
#Requires -Version 5.1

# Configuration
$KALI_IP = "192.168.56.101"
$WINDOWS_IP = "192.168.56.102"
$NETWORK_NAME = "vboxnet0"
$REQUIRED_DISK_GB = 40
$REQUIRED_RAM_GB = 8

Clear-Host

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "    ETHICAL HACKING LAB - AUTOMATED LOCAL SETUP" -ForegroundColor Cyan
Write-Host "    PDF Exploit Demonstration Environment" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# STEP 1: Check Prerequisites
# ============================================================================
Write-Host "[1/8] Checking prerequisites..." -ForegroundColor Yellow
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  Warning: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "  Some operations may fail. Consider running PowerShell as Administrator." -ForegroundColor Yellow
    Write-Host ""
}

# Check VirtualBox
try {
    $vboxPath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
    if (Test-Path $vboxPath) {
        $vboxVersion = & $vboxPath --version 2>$null
        $vboxVersion = $vboxVersion.Split('r')[0]
        Write-Host "  [OK] VirtualBox $vboxVersion installed" -ForegroundColor Green
    } else {
        throw "VirtualBox not found"
    }
} catch {
    Write-Host "  [ERROR] VirtualBox not found" -ForegroundColor Red
    Write-Host "Please install VirtualBox from: https://www.virtualbox.org/"
    exit 1
}

# Check Vagrant
try {
    $vagrantCheck = vagrant --version 2>$null
    if ($vagrantCheck) {
        $vagrantVersion = $vagrantCheck -replace "Vagrant ", ""
        Write-Host "  [OK] Vagrant $vagrantVersion installed" -ForegroundColor Green
    } else {
        throw "Vagrant not found"
    }
} catch {
    Write-Host "  [ERROR] Vagrant not found" -ForegroundColor Red
    Write-Host "Please install Vagrant from: https://www.vagrantup.com/"
    exit 1
}

# Check disk space
$drive = (Get-Location).Drive
$freeSpaceGB = [math]::Round((Get-PSDrive $drive.Name).Free / 1GB, 2)
if ($freeSpaceGB -lt $REQUIRED_DISK_GB) {
    Write-Host "  [ERROR] Insufficient disk space" -ForegroundColor Red
    Write-Host "  Available: ${freeSpaceGB}GB, Required: ${REQUIRED_DISK_GB}GB"
    exit 1
} else {
    Write-Host "  [OK] Sufficient disk space (${freeSpaceGB}GB available)" -ForegroundColor Green
}

# Check memory
$totalMemoryGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
if ($totalMemoryGB -lt $REQUIRED_RAM_GB) {
    Write-Host "  [WARNING] Low memory (${totalMemoryGB}GB total, ${REQUIRED_RAM_GB}GB+ recommended)" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] Sufficient memory (${totalMemoryGB}GB total)" -ForegroundColor Green
}

Write-Host ""

# ============================================================================
# STEP 2: Check Adobe Reader
# ============================================================================
Write-Host "[2/8] Checking Adobe Reader installer..." -ForegroundColor Yellow
Write-Host ""

$adobePath = "resources\AdobeReader_9.5.exe"

if (-not (Test-Path $adobePath)) {
    Write-Host "  [ERROR] Adobe Reader installer not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "======================================================================" -ForegroundColor Yellow
    Write-Host "  MANUAL DOWNLOAD REQUIRED" -ForegroundColor Yellow
    Write-Host "======================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please download Adobe Reader 9.5.0 manually:" -ForegroundColor White
    Write-Host ""
    Write-Host "1. Go to:" -ForegroundColor Cyan
    Write-Host "   https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe"
    Write-Host ""
    Write-Host "2. Download the file (should be about 50MB)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Rename to: AdobeReader_9.5.exe" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "4. Move to: $((Get-Location).Path)\resources\" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "5. Run this script again: .\setup-simple.ps1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "See QUICK_FIX_ADOBE.md for more download options" -ForegroundColor Gray
    Write-Host ""
    exit 1
} else {
    $fileSizeMB = [math]::Round((Get-Item $adobePath).Length / 1MB, 2)
    if ($fileSizeMB -lt 40) {
        Write-Host "  [ERROR] Adobe Reader file is incomplete (${fileSizeMB}MB)" -ForegroundColor Red
        Write-Host "  Expected size: approximately 50MB" -ForegroundColor Yellow
        Write-Host "  Please delete and re-download the file" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  [OK] Adobe Reader installer ready (${fileSizeMB}MB)" -ForegroundColor Green
}

Write-Host ""

# ============================================================================
# STEP 3: Configure VirtualBox Network
# ============================================================================
Write-Host "[3/8] Configuring VirtualBox network..." -ForegroundColor Yellow
Write-Host ""

$vboxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$networks = & $vboxManage list hostonlyifs 2>$null

if ($networks -notmatch "vboxnet0") {
    Write-Host "  Creating host-only network..."
    & $vboxManage hostonlyif create | Out-Null
}

# Configure network
& $vboxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0 2>$null | Out-Null

Write-Host "  [OK] Network configured: 192.168.56.0/24" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 4: Build Kali Linux VM
# ============================================================================
Write-Host "[4/8] Building Kali Linux VM..." -ForegroundColor Yellow
Write-Host "  This will take 5-10 minutes..."
Write-Host ""

Push-Location vagrant

vagrant destroy kali -f 2>$null | Out-Null
vagrant up kali --provider virtualbox

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "  [OK] Kali Linux VM ready" -ForegroundColor Green
    Write-Host "  IP: $KALI_IP"
} else {
    Write-Host ""
    Write-Host "  [ERROR] Failed to build Kali VM" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host ""

# ============================================================================
# STEP 5: Build Windows VM
# ============================================================================
Write-Host "[5/8] Building Windows Server 2008 R2 VM..." -ForegroundColor Yellow
Write-Host "  This will take 20-30 minutes..."
Write-Host ""

vagrant destroy win2k8 -f 2>$null | Out-Null
vagrant up win2k8 --provider virtualbox

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "  [OK] Windows Server VM ready" -ForegroundColor Green
    Write-Host "  IP: $WINDOWS_IP"
} else {
    Write-Host ""
    Write-Host "  [ERROR] Failed to build Windows VM" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host ""

# ============================================================================
# STEP 6: Verify Connectivity
# ============================================================================
Write-Host "[6/8] Verifying network connectivity..." -ForegroundColor Yellow
Write-Host ""

vagrant ssh kali -c "ping -c 2 $WINDOWS_IP" 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Kali -> Windows: Connected" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Network connectivity failed" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# STEP 7: Create Snapshots
# ============================================================================
Write-Host "[7/8] Creating snapshots..." -ForegroundColor Yellow
Write-Host ""

$kaliVM = (& $vboxManage list vms | Select-String "kali" | Select-Object -First 1) -replace '.*"(.+?)".*', '$1'
$windowsVM = (& $vboxManage list vms | Select-String "win2k8" | Select-Object -First 1) -replace '.*"(.+?)".*', '$1'

if ($kaliVM) {
    & $vboxManage snapshot $kaliVM delete "Clean_State" 2>$null | Out-Null
    & $vboxManage snapshot $kaliVM take "Clean_State" | Out-Null
    Write-Host "  [OK] Kali snapshot created" -ForegroundColor Green
}

if ($windowsVM) {
    & $vboxManage snapshot $windowsVM delete "Clean_State" 2>$null | Out-Null
    & $vboxManage snapshot $windowsVM take "Clean_State" | Out-Null
    Write-Host "  [OK] Windows snapshot created" -ForegroundColor Green
}

Write-Host ""

# ============================================================================
# STEP 8: Verify Exploits
# ============================================================================
Write-Host "[8/8] Verifying exploit materials..." -ForegroundColor Yellow
Write-Host ""

vagrant ssh kali -c "ls ~/.msf4/local/JOAN-ESPINACH-TRD.pdf" 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Malicious PDF generated" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Generating PDF now..." -ForegroundColor Yellow
    vagrant ssh kali -c "cd /vagrant/exploits && ./generate_pdf.sh" | Out-Null
}

Write-Host ""

Pop-Location

# ============================================================================
# SUCCESS
# ============================================================================
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "                    SETUP COMPLETE!" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Lab Environment Ready:" -ForegroundColor Cyan
Write-Host "  Kali Linux:      $KALI_IP (vagrant/vagrant)"
Write-Host "  Windows Target:  $WINDOWS_IP (vagrant/vagrant)"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. cd vagrant"
Write-Host "  2. vagrant ssh kali"
Write-Host "  3. cd /vagrant/exploits"
Write-Host "  4. ./start_attack.sh"
Write-Host ""
Write-Host "To reset: .\reset.ps1" -ForegroundColor Cyan
Write-Host "To cleanup: .\cleanup.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Happy Hacking!" -ForegroundColor Green
Write-Host ""
