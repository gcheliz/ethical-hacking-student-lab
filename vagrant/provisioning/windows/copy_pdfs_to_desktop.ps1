# Copy malicious PDFs from shared folder to Desktop
# This runs AFTER Kali has generated the PDFs

Write-Host "============================================================"
Write-Host "  Copying Malicious PDFs to Desktop"
Write-Host "============================================================"
Write-Host

$DesktopPath = "C:\Users\vagrant\Desktop"
$VagrantPath = "C:\vagrant\exploits"

# PDFs to copy
$PDFs = @(
    "JOAN-ESPINACH-TRD.pdf",
    "JOAN-ESPINACH-ALT.pdf"
)

$CopiedCount = 0

foreach ($PDF in $PDFs) {
    $SourcePath = Join-Path $VagrantPath $PDF
    $DestPath = Join-Path $DesktopPath $PDF

    if (Test-Path $SourcePath) {
        try {
            Copy-Item -Path $SourcePath -Destination $DestPath -Force
            $FileSize = (Get-Item $DestPath).Length
            Write-Host "[OK] Copied $PDF ($FileSize bytes)" -ForegroundColor Green
            $CopiedCount++
        } catch {
            Write-Host "[WARNING] Failed to copy $PDF : $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] $PDF not found in shared folder - skipping" -ForegroundColor Cyan
        Write-Host "       You can copy it manually later from Kali VM" -ForegroundColor Cyan
    }
}

Write-Host
if ($CopiedCount -gt 0) {
    Write-Host "[OK] $CopiedCount PDF(s) copied to Desktop" -ForegroundColor Green
    Write-Host
    Write-Host "EASY MODE READY!" -ForegroundColor Green
    Write-Host "  1. Start listener on Kali: ./start_attack.sh"
    Write-Host "  2. Double-click PDF on this Desktop"
    Write-Host "  3. Get Meterpreter shell!"
} else {
    Write-Host "[WARNING] No PDFs copied - they may not be generated yet" -ForegroundColor Yellow
    Write-Host
    Write-Host "To copy PDFs manually later:" -ForegroundColor Yellow
    Write-Host "  1. SSH to Kali: vagrant ssh kali"
    Write-Host "  2. Generate PDFs: cd /vagrant/exploits && ./generate_pdf.sh"
    Write-Host "  3. PDFs will appear in C:\vagrant\exploits\"
    Write-Host "  4. Copy to Desktop manually"
}

Write-Host
Write-Host "============================================================"
