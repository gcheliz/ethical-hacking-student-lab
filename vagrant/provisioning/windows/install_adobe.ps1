# Install Adobe Reader 9.5.0 and configure for exploitation

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Installing Adobe Reader 9.5.0" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host

$installer = "C:\AdobeReader_9.5.exe"

# Check if installer exists
if (-not (Test-Path $installer)) {
    Write-Host "ERROR: Adobe Reader installer not found at $installer" -ForegroundColor Red
    exit 1
}

Write-Host "Installer found: $(Get-Item $installer | Select -ExpandProperty Name)" -ForegroundColor Green
$fileSize = (Get-Item $installer).Length / 1MB
Write-Host "File size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
Write-Host

# Install Adobe Reader silently
Write-Host "Installing Adobe Reader (this may take 2-3 minutes)..." -ForegroundColor Yellow
try {
    $process = Start-Process -FilePath $installer -ArgumentList "/sAll /rs /msi EULA_ACCEPT=YES" -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "✓ Adobe Reader installed successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠ Installation returned code: $($process.ExitCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host

# Configure Adobe Reader for exploitation
Write-Host "Configuring Adobe Reader security settings..." -ForegroundColor Yellow

# Create registry paths
$regPaths = @(
    "HKCU:\Software\Adobe\Acrobat Reader\9.0\Privileged",
    "HKCU:\Software\Adobe\Acrobat Reader\9.0\TrustManager",
    "HKCU:\Software\Adobe\Acrobat Reader\9.0\FeatureLockDown",
    "HKCU:\Software\Adobe\Acrobat Reader\9.0\AVGeneral"
)

foreach ($path in $regPaths) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
}

# Disable Protected Mode
Set-ItemProperty -Path "HKCU:\Software\Adobe\Acrobat Reader\9.0\Privileged" -Name bProtectedMode -Value 0 -Type DWord -Force
Write-Host "  ✓ Protected Mode disabled" -ForegroundColor Green

# Disable Enhanced Security
Set-ItemProperty -Path "HKCU:\Software\Adobe\Acrobat Reader\9.0\TrustManager" -Name bEnhancedSecurityStandalone -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Adobe\Acrobat Reader\9.0\TrustManager" -Name bEnhancedSecurityInBrowser -Value 0 -Type DWord -Force
Write-Host "  ✓ Enhanced Security disabled" -ForegroundColor Green

# Enable JavaScript (needed for some exploits)
Set-ItemProperty -Path "HKCU:\Software\Adobe\Acrobat Reader\9.0\FeatureLockDown" -Name bDisableJavaScript -Value 0 -Type DWord -Force
Write-Host "  ✓ JavaScript enabled" -ForegroundColor Green

# Disable EULA and startup screens
Set-ItemProperty -Path "HKCU:\Software\Adobe\Acrobat Reader\9.0\AVGeneral" -Name bDontShowMsgAtLaunch -Value 1 -Type DWord -Force
Write-Host "  ✓ Startup messages disabled" -ForegroundColor Green

Write-Host
Write-Host "Adobe Reader 9.5.0 configured for exploitation" -ForegroundColor Green
