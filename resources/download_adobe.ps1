################################################################################
# Adobe Reader Download Script (Windows PowerShell)
# Description: Download Adobe Reader 9.5.0 installer with multiple fallbacks
# Usage: .\download_adobe.ps1
################################################################################

#Requires -Version 5.1

$OUTPUT_FILE = "resources\AdobeReader_9.5.exe"
$EXPECTED_SIZE_MB = 50

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║           Adobe Reader 9.5.0 Installer Downloader              ║" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Ensure resources directory exists
New-Item -ItemType Directory -Force -Path "resources" | Out-Null

# Remove incomplete file if exists
if (Test-Path $OUTPUT_FILE) {
    $currentSize = [math]::Round((Get-Item $OUTPUT_FILE).Length / 1MB, 2)
    if ($currentSize -lt 40) {
        Write-Host "Removing incomplete file (${currentSize}MB)..." -ForegroundColor Yellow
        Remove-Item $OUTPUT_FILE -Force
    }
}

$downloadSources = @(
    @{
        Name = "Internet Archive (Primary)"
        URL = "https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe"
    },
    @{
        Name = "FileHorse Mirror"
        URL = "https://static.filehorse.com/download/old-versions/archiving-tools/AdbeRdr950_en_US.exe"
    }
)

$downloaded = $false

foreach ($source in $downloadSources) {
    if ($downloaded) { break }

    Write-Host "Trying: $($source.Name)..." -ForegroundColor Cyan
    Write-Host "  URL: $($source.URL)" -ForegroundColor Gray

    try {
        # Use .NET WebClient for better download with progress
        $webClient = New-Object System.Net.WebClient

        # Add progress handler
        $progressHandler = {
            param($sender, $e)
            $percent = [math]::Round($e.ProgressPercentage, 0)
            Write-Progress -Activity "Downloading Adobe Reader" -Status "$percent% Complete" -PercentComplete $percent
        }

        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action $progressHandler | Out-Null

        # Download the file
        $webClient.DownloadFile($source.URL, (Resolve-Path "resources").Path + "\AdobeReader_9.5.exe")

        # Cleanup
        $webClient.Dispose()
        Get-EventSubscriber | Unregister-Event

        # Verify download
        if (Test-Path $OUTPUT_FILE) {
            $fileSizeMB = [math]::Round((Get-Item $OUTPUT_FILE).Length / 1MB, 2)

            if ($fileSizeMB -ge 40) {
                Write-Host ""
                Write-Host "  ✓ Download successful! (${fileSizeMB}MB)" -ForegroundColor Green
                $downloaded = $true
            } else {
                Write-Host "  ✗ Download incomplete (${fileSizeMB}MB, expected ~${EXPECTED_SIZE_MB}MB)" -ForegroundColor Red
                Remove-Item $OUTPUT_FILE -Force
            }
        }
    } catch {
        Write-Host "  ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

if (-not $downloaded) {
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "  ✗ Automatic download failed from all sources" -ForegroundColor Red
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "MANUAL DOWNLOAD REQUIRED:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please download Adobe Reader 9.5.0 manually:" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 1 - Internet Archive:" -ForegroundColor Cyan
    Write-Host "  https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe"
    Write-Host ""
    Write-Host "Option 2 - OldVersion.com:" -ForegroundColor Cyan
    Write-Host "  http://www.oldversion.com/windows/adobe-reader-9-5-0"
    Write-Host "  (Click 'Download Adobe Reader 9.5.0')"
    Write-Host ""
    Write-Host "Option 3 - FileHorse:" -ForegroundColor Cyan
    Write-Host "  https://www.filehorse.com/download-adobe-reader/old-versions/"
    Write-Host "  (Find version 9.5.0)"
    Write-Host ""
    Write-Host "After downloading:" -ForegroundColor Yellow
    Write-Host "  1. Rename the file to: AdobeReader_9.5.exe"
    Write-Host "  2. Move it to: $((Get-Location).Path)\resources\"
    Write-Host "  3. Verify size is approximately 50MB"
    Write-Host "  4. Run .\setup.ps1 again"
    Write-Host ""
    exit 1
}

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✓ Adobe Reader installer ready!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "File location: $OUTPUT_FILE"
Write-Host "File size: $([math]::Round((Get-Item $OUTPUT_FILE).Length / 1MB, 2))MB"
Write-Host ""
Write-Host "You can now run: .\setup.ps1" -ForegroundColor Cyan
Write-Host ""
