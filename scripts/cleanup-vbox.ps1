# VirtualBox Cleanup Script
# Fixes "VM name already exists" errors by cleaning up leftover VMs and directories

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  VirtualBox Cleanup Script" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host

$vboxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

if (-not (Test-Path $vboxManage)) {
    Write-Host "ERROR: VBoxManage not found" -ForegroundColor Red
    Write-Host "Please install VirtualBox first"
    exit 1
}

Write-Host "This script will clean up leftover VirtualBox VMs and directories." -ForegroundColor Yellow
Write-Host "Use this if you get 'VM name already exists' errors." -ForegroundColor Yellow
Write-Host

# List all VMs
Write-Host "Current VirtualBox VMs:" -ForegroundColor Cyan
& $vboxManage list vms
Write-Host

# Find lab VMs
$labVMs = & $vboxManage list vms | Select-String "(Kali_PDF_Exploit_Lab|Windows_PDF_Target_Lab)"

if (-not $labVMs) {
    Write-Host "No lab VMs found. Nothing to clean up." -ForegroundColor Green
    exit 0
}

Write-Host "Found lab VMs to remove:" -ForegroundColor Yellow
foreach ($vm in $labVMs) {
    Write-Host "  - $vm" -ForegroundColor Gray
}
Write-Host

$confirm = Read-Host "Do you want to remove these VMs? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host
Write-Host "Removing VMs..." -ForegroundColor Cyan

foreach ($vm in $labVMs) {
    $vmName = $vm -replace '.*"(.+?)".*', '$1'
    Write-Host "  Removing: $vmName..." -NoNewline

    try {
        # Power off if running
        & $vboxManage controlvm "$vmName" poweroff 2>$null | Out-Null
        Start-Sleep -Seconds 2

        # Unregister and delete
        & $vboxManage unregistervm "$vmName" --delete 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Host " Done" -ForegroundColor Green
        } else {
            Write-Host " Failed (may already be removed)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host " Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host
Write-Host "Cleaning up Vagrant state..." -ForegroundColor Cyan

Push-Location vagrant -ErrorAction SilentlyContinue

if (Test-Path ".vagrant") {
    Remove-Item -Path ".vagrant" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed .vagrant directory" -ForegroundColor Green
}

Pop-Location

Write-Host
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  Cleanup Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host
Write-Host "You can now run .\setup.ps1 to rebuild the lab." -ForegroundColor Cyan
Write-Host
