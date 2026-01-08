# Adobe Reader 9.5.0 Download with Multiple Sources and Retries
# This script tries multiple download sources automatically

#Requires -Version 5.1

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Adobe Reader 9.5.0 Multi-Source Downloader" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Create resources directory
New-Item -ItemType Directory -Force -Path "resources" | Out-Null

$outputFile = "resources\AdobeReader_9.5.exe"
$expectedSizeMB = 50

# Multiple download sources to try
$downloadSources = @(
    @{
        Name = "Adobe Official CDN"
        URL = "http://ardownload.adobe.com/pub/adobe/reader/win/9.x/9.5.0/enu/AdbeRdr950_en_US.exe"
    },
    @{
        Name = "Internet Archive (Direct)"
        URL = "https://ia801409.us.archive.org/21/items/adobe-reader-9.5/AdbeRdr950_en_US.exe"
    },
    @{
        Name = "Internet Archive (Alt)"
        URL = "https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe"
    }
)

$downloaded = $false

foreach ($source in $downloadSources) {
    if ($downloaded) { break }

    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host "  Trying: $($source.Name)" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Yellow
    Write-Host "  URL: $($source.URL)" -ForegroundColor Gray
    Write-Host ""

    # Try up to 2 times per source
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        if ($downloaded) { break }

        Write-Host "  Attempt $attempt/2..." -ForegroundColor Cyan

        try {
            # Remove incomplete file if exists
            if (Test-Path $outputFile) {
                Remove-Item $outputFile -Force
            }

            # Download using WebClient for better reliability
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0")

            Write-Host "  Downloading... (this may take a few minutes)" -ForegroundColor Yellow

            $webClient.DownloadFile($source.URL, (Resolve-Path "resources").Path + "\AdobeReader_9.5.exe")
            $webClient.Dispose()

            # Check if file exists and verify size
            if (Test-Path $outputFile) {
                $fileSizeMB = [math]::Round((Get-Item $outputFile).Length / 1MB, 2)
                Write-Host ""
                Write-Host "  Downloaded: $fileSizeMB MB" -ForegroundColor Cyan

                if ($fileSizeMB -ge 45) {
                    Write-Host ""
                    Write-Host "  [SUCCESS] Download complete!" -ForegroundColor Green
                    Write-Host "  File size: $fileSizeMB MB" -ForegroundColor Green
                    $downloaded = $true
                } else {
                    Write-Host ""
                    Write-Host "  [WARNING] File incomplete ($fileSizeMB MB, expected ~$expectedSizeMB MB)" -ForegroundColor Red
                    Remove-Item $outputFile -Force

                    if ($attempt -lt 2) {
                        Write-Host "  Retrying in 3 seconds..." -ForegroundColor Yellow
                        Start-Sleep -Seconds 3
                    }
                }
            } else {
                Write-Host ""
                Write-Host "  [ERROR] File not created" -ForegroundColor Red
            }

        } catch {
            Write-Host ""
            Write-Host "  [ERROR] Download failed: $($_.Exception.Message)" -ForegroundColor Red

            if ($attempt -lt 2) {
                Write-Host "  Retrying in 3 seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            }
        }
    }

    if (-not $downloaded) {
        Write-Host ""
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor White

if ($downloaded) {
    Write-Host "  DOWNLOAD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "File Details:" -ForegroundColor Cyan
    Get-Item $outputFile | Format-List Name, Length, LastWriteTime
    Write-Host ""
    Write-Host "Next step: Run .\setup.ps1" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "  DOWNLOAD FAILED FROM ALL SOURCES" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "MANUAL DOWNLOAD REQUIRED:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please try downloading manually from:" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 1 - OldVersion.com (Most Reliable):" -ForegroundColor Cyan
    Write-Host "  1. Go to: http://www.oldversion.com/windows/adobe-reader-9-5-0"
    Write-Host "  2. Click 'Download Adobe Reader 9.5.0'"
    Write-Host "  3. Save the file"
    Write-Host ""
    Write-Host "Option 2 - Direct Link (Try in browser):" -ForegroundColor Cyan
    Write-Host "  http://ardownload.adobe.com/pub/adobe/reader/win/9.x/9.5.0/enu/AdbeRdr950_en_US.exe"
    Write-Host ""
    Write-Host "After downloading:" -ForegroundColor Yellow
    Write-Host "  1. Rename to: AdobeReader_9.5.exe"
    Write-Host "  2. Move to: $((Get-Location).Path)\resources\"
    Write-Host "  3. Verify size is ~50MB (not 33MB!)"
    Write-Host "  4. Run: .\setup.ps1"
    Write-Host ""
    Write-Host "See ADOBE_DOWNLOAD_SOURCES.md for more options" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
