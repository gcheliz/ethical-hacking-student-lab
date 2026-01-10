################################################################################
# Install Adobe Reader 9.0
# Required for PDF icon on malicious HTA files
################################################################################

Write-Host "Installing Adobe Reader 9.0..." -ForegroundColor Cyan

# Adobe Reader 9.0 (vulnerable version for lab)
$AdobeURL = "https://ardownload2.adobe.com/pub/adobe/reader/win/9.x/9.0/enu/AdbeRdr90_en_US.exe"
$InstallerPath = "$env:TEMP\AdbeRdr90_en_US.exe"

Write-Host "  Downloading Adobe Reader 9.0..." -ForegroundColor Yellow
try {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($AdobeURL, $InstallerPath)
    Write-Host "  Download complete" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Download failed: $_" -ForegroundColor Yellow
    Write-Host "  HTA files will use default icon" -ForegroundColor Gray
    exit 0  # Don't fail provisioning
}

Write-Host "  Installing Adobe Reader..." -ForegroundColor Yellow
try {
    # Silent install
    Start-Process -FilePath $InstallerPath -ArgumentList "/sAll /rs /msi EULA_ACCEPT=YES" -Wait -NoNewWindow
    Write-Host "  Installation complete" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Installation failed: $_" -ForegroundColor Yellow
    exit 0  # Don't fail provisioning
}

# Clean up installer
Remove-Item $InstallerPath -Force -ErrorAction SilentlyContinue

Write-Host "Adobe Reader 9.0 installed successfully!" -ForegroundColor Green
