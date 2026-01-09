# Verify all provisioning files exist
Write-Host "Verifying provisioning files..." -ForegroundColor Cyan
Write-Host ""

$baseDir = (Get-Item .).FullName
Write-Host "Base directory: $baseDir" -ForegroundColor Gray
Write-Host ""

$files = @(
    "vagrant\provisioning\kali\install_tools.sh",
    "vagrant\provisioning\kali\configure_network.sh",
    "vagrant\provisioning\kali\create_exploits.sh",
    "vagrant\provisioning\kali\setup_autostart.sh",
    "vagrant\provisioning\windows\disable_security.ps1",
    "vagrant\provisioning\windows\install_adobe.ps1",
    "vagrant\provisioning\windows\configure_network.ps1",
    "vagrant\provisioning\windows\create_shortcuts.ps1",
    "vagrant\provisioning\windows\copy_pdfs_to_desktop.ps1"
)

$missing = @()
$found = @()

foreach ($file in $files) {
    $fullPath = Join-Path $baseDir $file
    if (Test-Path $fullPath) {
        $size = (Get-Item $fullPath).Length
        Write-Host "[OK] $file ($size bytes)" -ForegroundColor Green
        $found += $file
    } else {
        Write-Host "[MISSING] $file" -ForegroundColor Red
        $missing += $file
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Found: $($found.Count)" -ForegroundColor Green
Write-Host "  Missing: $($missing.Count)" -ForegroundColor $(if ($missing.Count -gt 0) { "Red" } else { "Green" })

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "ACTION REQUIRED:" -ForegroundColor Yellow
    Write-Host "  Some provisioning files are missing from your Windows checkout."
    Write-Host "  Please run: git pull origin claude/create-lab-guide-fo5F2"
    Write-Host ""
}
