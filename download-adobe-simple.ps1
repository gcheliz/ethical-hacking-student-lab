################################################################################
# Adobe Reader Simple Download Script (Windows PowerShell)
# Usage: .\download-adobe-simple.ps1
################################################################################

#Requires -Version 5.1

Write-Host ""
Write-Host "======================================================================"
Write-Host "  Adobe Reader 9.5.0 Downloader" -ForegroundColor Cyan
Write-Host "======================================================================"
Write-Host ""

# Create resources directory
New-Item -ItemType Directory -Force -Path "resources" | Out-Null

$outputFile = "resources\AdobeReader_9.5.exe"

# Download URLs to try
$urls = @(
    "https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe"
)

$downloaded = $false

foreach ($url in $urls) {
    if ($downloaded) { break }

    Write-Host "Attempting download from:" -ForegroundColor Cyan
    Write-Host "  $url"
    Write-Host ""

    try {
        # Download with progress
        $webClient = New-Object System.Net.WebClient

        Write-Host "Downloading... (this may take a few minutes)" -ForegroundColor Yellow
        $webClient.DownloadFile($url, (Resolve-Path "resources").Path + "\AdobeReader_9.5.exe")
        $webClient.Dispose()

        # Check if successful
        if (Test-Path $outputFile) {
            $fileSize = [math]::Round((Get-Item $outputFile).Length / 1MB, 2)

            if ($fileSize -ge 40) {
                Write-Host ""
                Write-Host "  [SUCCESS] Downloaded successfully!" -ForegroundColor Green
                Write-Host "  File size: $fileSize MB"
                $downloaded = $true
            } else {
                Write-Host ""
                Write-Host "  [ERROR] Download incomplete" -ForegroundColor Red
                Write-Host "  File size: $fileSize MB (expected ~50MB)"
                Remove-Item $outputFile -Force
            }
        }
    } catch {
        Write-Host ""
        Write-Host "  [ERROR] Download failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
    }
}

Write-Host ""

if (-not $downloaded) {
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host "  Automatic Download Failed" -ForegroundColor Red
    Write-Host "======================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download manually:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1 - Internet Archive (Recommended):" -ForegroundColor Cyan
    Write-Host "  https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe"
    Write-Host ""
    Write-Host "Option 2 - OldVersion.com:" -ForegroundColor Cyan
    Write-Host "  http://www.oldversion.com/windows/adobe-reader-9-5-0"
    Write-Host ""
    Write-Host "After downloading:" -ForegroundColor Yellow
    Write-Host "  1. Rename to: AdobeReader_9.5.exe"
    Write-Host "  2. Move to: $((Get-Location).Path)\resources\"
    Write-Host "  3. Verify size is about 50MB"
    Write-Host "  4. Run: .\setup-simple.ps1"
    Write-Host ""
    exit 1
}

Write-Host "======================================================================" -ForegroundColor Green
Write-Host "  Adobe Reader Ready!" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Location: $outputFile"
Write-Host ""
Write-Host "Next step: Run .\setup-simple.ps1" -ForegroundColor Cyan
Write-Host ""
