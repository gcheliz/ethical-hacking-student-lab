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
Write-Header "PDF Exploit Demonstration Environment"

# STEP 1: Check Prerequisites
Write-Step "[1/9] Checking prerequisites..."
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

# STEP 2: Extract Adobe Reader from ZIP archive
Write-Step "[2/9] Preparing Adobe Reader installer..."
Write-Host ""

$adobePath = "resources\AdobeReader_9.5.exe"
$adobeZip = "resources\AdobeReader_9.5.zip"

# Ensure resources directory exists
New-Item -ItemType Directory -Force -Path "resources" | Out-Null

# Check if extracted file already exists
if (Test-Path $adobePath) {
    $fileSizeMB = [math]::Round((Get-Item $adobePath).Length / 1MB, 2)
    Write-Success "Adobe Reader installer ready (${fileSizeMB}MB)"
}

# If not ready, extract from ZIP
if (-not (Test-Path $adobePath)) {
    if (Test-Path $adobeZip) {
        Write-Host "  Extracting Adobe Reader from ZIP archive..."

        try {
            # Extract using PowerShell Expand-Archive
            $tempExtractPath = Join-Path $env:TEMP "adobe_extract_temp"

            # Remove temp directory if exists
            if (Test-Path $tempExtractPath) {
                Remove-Item -Path $tempExtractPath -Recurse -Force
            }

            # Extract to temp directory
            Expand-Archive -Path $adobeZip -DestinationPath $tempExtractPath -Force

            # Find the .exe file (could be in subdirectory or with different name)
            $extractedExe = Get-ChildItem -Path $tempExtractPath -Filter "*.exe" -Recurse | Select-Object -First 1

            if ($extractedExe) {
                # Copy to resources with correct name
                Copy-Item -Path $extractedExe.FullName -Destination $adobePath -Force

                # Cleanup temp directory
                Remove-Item -Path $tempExtractPath -Recurse -Force

                # Verify the copied file
                $fileSizeMB = [math]::Round((Get-Item $adobePath).Length / 1MB, 2)
                Write-Success "Extracted successfully (${fileSizeMB}MB)"
            } else {
                Write-Error-Message "No .exe file found in ZIP archive"
                Write-Host ""
                Write-Host "The ZIP archive may be empty or corrupted."
                Write-Host "Please contact your instructor for the correct AdobeReader_9.5.zip file"

                # Cleanup
                if (Test-Path $tempExtractPath) {
                    Remove-Item -Path $tempExtractPath -Recurse -Force
                }
                exit 1
            }
        } catch {
            Write-Error-Message "Failed to extract: $($_.Exception.Message)"
            Write-Host ""
            Write-Host "Please try extracting manually:"
            Write-Host "  1. Right-click resources\AdobeReader_9.5.zip"
            Write-Host "  2. Select 'Extract All...'"
            Write-Host "  3. Copy the .exe file to resources\AdobeReader_9.5.exe"
            Write-Host "  4. Run setup.ps1 again"
            exit 1
        }
    } else {
        Write-Error-Message "Adobe Reader ZIP archive not found!"
        Write-Host ""
        Write-Host "The file resources\AdobeReader_9.5.zip is missing."
        Write-Host ""
        Write-Host "Required file: resources\AdobeReader_9.5.zip"
        Write-Host "Please contact your instructor to obtain this file."
        Write-Host ""
        exit 1
    }
}

# Final verification
if (Test-Path $adobePath) {
    $fileSizeMB = [math]::Round((Get-Item $adobePath).Length / 1MB, 2)
    Write-Success "File verified (${fileSizeMB}MB)"
} else {
    Write-Error-Message "Adobe Reader installer not found after extraction"
    exit 1
}

Write-Host ""

# STEP 3: Configure VirtualBox Network
Write-Step "[3/9] Configuring VirtualBox network..."
Write-Host ""

# Check if host-only network with correct IP exists
$vboxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$networkList = & $vboxManage list hostonlyifs 2>$null

# Parse all host-only adapters to find one with 192.168.56.1
$NETWORK_NAME = $null
$currentAdapter = $null
$adapterName = $null

if ($networkList) {
    $lines = $networkList -split "`n"
    foreach ($line in $lines) {
        if ($line -match "^Name:\s+(.+)") {
            $adapterName = $Matches[1].Trim()
        }
        if ($line -match "^IPAddress:\s+192\.168\.56\.1") {
            $NETWORK_NAME = $adapterName
            Write-Host "  Found existing network with correct IP: $NETWORK_NAME"
            break
        }
    }
}

# If no network with correct IP exists, find first adapter or create one
if (-not $NETWORK_NAME) {
    if ($networkList) {
        # Use first adapter and reconfigure it
        $lines = $networkList -split "`n"
        foreach ($line in $lines) {
            if ($line -match "^Name:\s+(.+)") {
                $NETWORK_NAME = $Matches[1].Trim()
                Write-Host "  Reconfiguring existing network: $NETWORK_NAME"
                break
            }
        }
    } else {
        # No adapters exist, create one
        Write-Host "  Creating new host-only network..."
        $output = & $vboxManage hostonlyif create 2>&1

        # Parse the output to get the adapter name
        if ($output -match "Interface '(.+)' was successfully created") {
            $NETWORK_NAME = $Matches[1]
        } else {
            # Fallback: get the newest adapter
            $networkList = & $vboxManage list hostonlyifs
            $lines = $networkList -split "`n"
            foreach ($line in $lines) {
                if ($line -match "^Name:\s+(.+)") {
                    $NETWORK_NAME = $Matches[1].Trim()
                    break
                }
            }
        }
        Write-Host "  Created network: $NETWORK_NAME"
    }

    # Configure the network with correct IP
    Write-Host "  Configuring IP: 192.168.56.1/24..."
    & $vboxManage hostonlyif ipconfig $NETWORK_NAME --ip 192.168.56.1 --netmask 255.255.255.0 | Out-Null
}

# Disable DHCP server (static IPs only)
try {
    & $vboxManage dhcpserver modify --ifname $NETWORK_NAME --disable 2>$null | Out-Null
} catch {
    & $vboxManage dhcpserver add --ifname $NETWORK_NAME --ip 192.168.56.1 --netmask 255.255.255.0 --lowerip 192.168.56.100 --upperip 192.168.56.200 --disable 2>$null | Out-Null
}

# Verify configuration
$verifyList = & $vboxManage list hostonlyifs
$verified = $false
$lines = $verifyList -split "`n"
$checkingName = $false
foreach ($line in $lines) {
    if ($line -match "^Name:\s+$([regex]::Escape($NETWORK_NAME))") {
        $checkingName = $true
    }
    if ($checkingName -and $line -match "^IPAddress:\s+192\.168\.56\.1") {
        $verified = $true
        break
    }
    if ($line -match "^Name:\s+" -and -not ($line -match "^Name:\s+$([regex]::Escape($NETWORK_NAME))")) {
        $checkingName = $false
    }
}

if ($verified) {
    Write-Success "Network configured: 192.168.56.0/24"
    Write-Success "Network interface: $NETWORK_NAME"
} else {
    Write-Error-Message "Failed to configure network with IP 192.168.56.1"
    Write-Host ""
    Write-Host "Current network configuration:" -ForegroundColor Yellow
    & $vboxManage list hostonlyifs
    exit 1
}
Write-Host ""

# STEP 4: Build Kali Linux VM
Write-Step "[4/9] Building Kali Linux VM..."
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
Write-Step "[5/9] Building Windows Server 2008 R2 VM..."
Write-Host "  This will take 20-30 minutes (downloading and configuring)..."
Write-Host "  Progress:"
Write-Host "  - Downloading Windows box"
Write-Host "  - Installing Adobe Reader 9.5.0"
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

# STEP 6: Verify Connectivity
Write-Step "[6/9] Verifying network connectivity..."
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
Write-Step "[7/9] Creating snapshots for easy reset..."
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

# STEP 8: Verify Exploit Files
Write-Step "[8/9] Verifying exploit materials..."
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
Write-Host "    Vulnerability:   Adobe Reader 9.5.0"
Write-Host "    Security:        ALL DISABLED (intentionally vulnerable)"
Write-Host ""
Write-Host "Network:" -ForegroundColor Cyan
Write-Host "  [OK] Host-Only Network:  192.168.56.0/24" -ForegroundColor Green
Write-Host "  [OK] Connectivity:       Verified" -ForegroundColor Green
Write-Host "  [OK] Isolation:          Complete (no internet from VMs)" -ForegroundColor Green
Write-Host ""
Write-Host "Exploit Materials:" -ForegroundColor Cyan
Write-Host "  [OK] Malicious PDF:      JOAN-ESPINACH-TRD.pdf" -ForegroundColor Green
Write-Host "  [OK] Attack Scripts:     Ready in /vagrant/exploits" -ForegroundColor Green
Write-Host "  [OK] Snapshots:          Created for easy reset" -ForegroundColor Green
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "                        NEXT STEPS" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Read the lab guide:" -ForegroundColor Yellow
Write-Host "   start docs\LAB_GUIDE.pdf" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Access the VMs:" -ForegroundColor Yellow
Write-Host "   cd vagrant" -ForegroundColor Cyan
Write-Host "   vagrant ssh kali          # SSH into Kali Linux" -ForegroundColor Cyan
Write-Host "   vagrant rdp win2k8        # RDP into Windows (GUI)" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Run the automated attack:" -ForegroundColor Yellow
Write-Host "   cd vagrant" -ForegroundColor Cyan
Write-Host "   vagrant ssh kali" -ForegroundColor Cyan
Write-Host "   cd /vagrant/exploits" -ForegroundColor Cyan
Write-Host "   ./start_attack.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Reset to clean state when done:" -ForegroundColor Yellow
Write-Host "   .\reset.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "                      DOCUMENTATION" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Lab Guide:           docs\LAB_GUIDE.pdf"
Write-Host "  Quick Start:         docs\QUICK_START.md"
Write-Host "  Troubleshooting:     TROUBLESHOOTING.md"
Write-Host "  Instructor Guide:    docs\INSTRUCTOR_GUIDE.pdf"
Write-Host ""
Write-Host "Happy Hacking!" -ForegroundColor Green
Write-Host ""
Write-Host "Tip: Keep this PowerShell window open to see VM status" -ForegroundColor Cyan
Write-Host ""
