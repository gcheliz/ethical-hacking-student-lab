################################################################################
# Install Adobe Reader 9.0 from Local ZIP Archive
# Extracts and installs from resources/AdobeReader_9.5.zip
################################################################################

Write-Host "Installing Adobe Reader 9.0..." -ForegroundColor Cyan
Write-Host ""

$resourcesPath = "C:\vagrant\resources"
$adobeZip = "$resourcesPath\AdobeReader_9.5.zip"
$adobeExe = "$env:TEMP\AdobeReader_9.5.exe"

# Check if ZIP file exists
if (-not (Test-Path $adobeZip)) {
    Write-Host "[WARNING] Adobe Reader ZIP not found" -ForegroundColor Yellow
    Write-Host "  Expected: $adobeZip" -ForegroundColor Gray
    Write-Host "  HTA files will use default Windows document icon" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To add PDF icon support:" -ForegroundColor Cyan
    Write-Host "  1. Download Adobe Reader 9.5.0" -ForegroundColor Gray
    Write-Host "  2. Compress to AdobeReader_9.5.zip" -ForegroundColor Gray
    Write-Host "  3. Place in: resources\AdobeReader_9.5.zip" -ForegroundColor Gray
    Write-Host "  4. Run: vagrant provision win2k8" -ForegroundColor Gray
    Write-Host ""
    exit 0  # Don't fail provisioning
}

Write-Host "[1/3] Extracting Adobe Reader from ZIP..." -ForegroundColor Yellow
try {
    # Extract to temp directory
    $tempExtractPath = "$env:TEMP\adobe_extract"

    # Remove temp directory if exists
    if (Test-Path $tempExtractPath) {
        Remove-Item -Path $tempExtractPath -Recurse -Force
    }

    # Extract ZIP
    Expand-Archive -Path $adobeZip -DestinationPath $tempExtractPath -Force

    # Find the .exe file
    $extractedExe = Get-ChildItem -Path $tempExtractPath -Filter "*.exe" -Recurse | Select-Object -First 1

    if ($extractedExe) {
        # Copy to temp location
        Copy-Item -Path $extractedExe.FullName -Destination $adobeExe -Force

        # Cleanup temp directory
        Remove-Item -Path $tempExtractPath -Recurse -Force

        $fileSizeMB = [math]::Round((Get-Item $adobeExe).Length / 1MB, 2)
        Write-Host "  Extracted successfully (${fileSizeMB}MB)" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] No .exe file found in ZIP" -ForegroundColor Red
        exit 0  # Don't fail provisioning
    }
} catch {
    Write-Host "  [ERROR] Extraction failed: $_" -ForegroundColor Red
    exit 0  # Don't fail provisioning
}
Write-Host ""

Write-Host "[2/3] Installing Adobe Reader..." -ForegroundColor Yellow
try {
    # Silent install
    $installArgs = "/sAll /rs /msi EULA_ACCEPT=YES"
    Start-Process -FilePath $adobeExe -ArgumentList $installArgs -Wait -NoNewWindow
    Write-Host "  Installation complete" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Installation failed: $_" -ForegroundColor Yellow
    exit 0  # Don't fail provisioning
}
Write-Host ""

Write-Host "[3/3] Cleaning up..." -ForegroundColor Yellow
Remove-Item $adobeExe -Force -ErrorAction SilentlyContinue
Write-Host "  Cleanup complete" -ForegroundColor Green
Write-Host ""

Write-Host "Adobe Reader 9.0 installed successfully!" -ForegroundColor Green
Write-Host "  PDF icons will now display correctly" -ForegroundColor Gray
Write-Host ""
