################################################################################
# Reset Lab Environment (Windows PowerShell)
# Description: Restore VMs to clean snapshot state
# Usage: .\reset.ps1
################################################################################

#Requires -Version 5.1

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║           RESET LAB ENVIRONMENT                                ║" -ForegroundColor Cyan
Write-Host "║           Restore VMs to Clean State                           ║" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Push-Location vagrant

# Get VM names from VirtualBox
$vboxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

$kaliVM = (& $vboxManage list vms | Select-String "kali" | Select-Object -First 1) -replace '.*"(.+?)".*', '$1'
$windowsVM = (& $vboxManage list vms | Select-String "win2k8" | Select-Object -First 1) -replace '.*"(.+?)".*', '$1'

if (-not $kaliVM -and -not $windowsVM) {
    Write-Host "✗ No VMs found. Run .\setup.ps1 first." -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "Found VMs:" -ForegroundColor Cyan
if ($kaliVM) {
    Write-Host "  ✓ Kali Linux: $kaliVM" -ForegroundColor Green
}
if ($windowsVM) {
    Write-Host "  ✓ Windows: $windowsVM" -ForegroundColor Green
}
Write-Host ""

# Stop VMs
Write-Host "Stopping VMs..." -ForegroundColor Yellow
vagrant halt

# Wait for VMs to stop
Start-Sleep -Seconds 3

# Restore snapshots
if ($kaliVM) {
    Write-Host "Restoring Kali Linux snapshot..." -ForegroundColor Yellow
    $snapshots = & $vboxManage snapshot $kaliVM list 2>$null
    if ($snapshots -match "Clean_State") {
        & $vboxManage snapshot $kaliVM restore "Clean_State" | Out-Null
        Write-Host "  ✓ Kali snapshot restored" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Warning: Clean_State snapshot not found for Kali" -ForegroundColor Yellow
    }
}

if ($windowsVM) {
    Write-Host "Restoring Windows snapshot..." -ForegroundColor Yellow
    $snapshots = & $vboxManage snapshot $windowsVM list 2>$null
    if ($snapshots -match "Clean_State") {
        & $vboxManage snapshot $windowsVM restore "Clean_State" | Out-Null
        Write-Host "  ✓ Windows snapshot restored" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Warning: Clean_State snapshot not found for Windows" -ForegroundColor Yellow
    }
}

Write-Host ""

# Start VMs
Write-Host "Starting VMs..." -ForegroundColor Yellow
vagrant up

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✓ Lab Reset Complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "VMs have been restored to clean state."
Write-Host "You can now run the attack again."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. cd vagrant"
Write-Host "  2. vagrant ssh kali"
Write-Host "  3. cd /vagrant/exploits/hta"
Write-Host "  4. ./start_hta_attack.sh"
Write-Host ""

Pop-Location
