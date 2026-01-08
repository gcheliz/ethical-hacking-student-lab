################################################################################
# Cleanup Lab Environment (Windows PowerShell)
# Description: Remove all VMs and clean up resources
# Usage: .\cleanup.ps1
################################################################################

#Requires -Version 5.1

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║           CLEANUP LAB ENVIRONMENT                              ║" -ForegroundColor Cyan
Write-Host "║           Remove All VMs and Resources                         ║" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  WARNING: This will destroy all VMs and cannot be undone!" -ForegroundColor Red
Write-Host ""
Write-Host "This will remove:"
Write-Host "  • Kali Linux VM"
Write-Host "  • Windows Server VM"
Write-Host "  • All snapshots"
Write-Host "  • Vagrant boxes (to free disk space)"
Write-Host ""
Write-Host "NOTE: Your scripts and configuration will NOT be deleted."
Write-Host "      You can rebuild the lab anytime with .\setup.ps1"
Write-Host ""

$confirm = Read-Host "Are you sure you want to continue? Type 'yes' to confirm"

if ($confirm -ne "yes") {
    Write-Host ""
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Starting cleanup..." -ForegroundColor Yellow

Push-Location vagrant

# Destroy VMs
Write-Host ""
Write-Host "Destroying VMs..." -ForegroundColor Yellow
vagrant destroy -f

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ VMs destroyed" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Warning: Some VMs may not have been destroyed" -ForegroundColor Yellow
}

# Remove Vagrant boxes to free space
Write-Host ""
Write-Host "Cleaning up Vagrant boxes..." -ForegroundColor Yellow
vagrant box prune -f

Write-Host "  ✓ Vagrant boxes pruned" -ForegroundColor Green

# Optional: Remove downloaded boxes completely
Write-Host ""
$removeBoxes = Read-Host "Also remove downloaded Vagrant boxes? (saves ~10GB) (y/n)"

if ($removeBoxes -eq "y") {
    Write-Host ""
    Write-Host "Removing Vagrant boxes..." -ForegroundColor Yellow

    vagrant box remove kalilinux/rolling --all 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Removed Kali box" -ForegroundColor Green
    }

    vagrant box remove rapid7/metasploitable3-win2k8 --all 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Removed Windows box" -ForegroundColor Green
    }
}

Pop-Location

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✓ Cleanup Complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "All VMs have been removed."
Write-Host ""
Write-Host "To rebuild the lab:"
Write-Host "  .\setup.ps1"
Write-Host ""
Write-Host "Disk space freed: Run 'Get-PSDrive' to check" -ForegroundColor Cyan
Write-Host ""
