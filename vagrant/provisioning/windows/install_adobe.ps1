# Install Adobe Reader 9.5.0 and configure for exploitation

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Installing Adobe Reader 9.5.0" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
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
        Write-Host "Adobe Reader installed successfully" -ForegroundColor Green
    } else {
        Write-Host "Installation returned code: $($process.ExitCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host

# Configure Adobe Reader for exploitation
Write-Host "Configuring Adobe Reader security settings..." -ForegroundColor Yellow

# Apply settings to HKLM (system-wide, all users)
$hklmPaths = @(
    "HKLM:\Software\Adobe\Acrobat Reader\9.0\Privileged",
    "HKLM:\Software\Adobe\Acrobat Reader\9.0\TrustManager",
    "HKLM:\Software\Adobe\Acrobat Reader\9.0\FeatureLockDown",
    "HKLM:\Software\Adobe\Acrobat Reader\9.0\AVGeneral"
)

foreach ($path in $hklmPaths) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
}

# SYSTEM-WIDE settings (HKLM)
Set-ItemProperty -Path "HKLM:\Software\Adobe\Acrobat Reader\9.0\Privileged" -Name bProtectedMode -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\Software\Adobe\Acrobat Reader\9.0\TrustManager" -Name bEnhancedSecurityStandalone -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\Software\Adobe\Acrobat Reader\9.0\TrustManager" -Name bEnhancedSecurityInBrowser -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\Software\Adobe\Acrobat Reader\9.0\FeatureLockDown" -Name bDisableJavaScript -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\Software\Adobe\Acrobat Reader\9.0\AVGeneral" -Name bDontShowMsgAtLaunch -Value 1 -Type DWord -Force

# Also apply to current user (HKCU) for immediate effect
$hkcuPaths = @(
    "HKCU:\Software\Adobe\Acrobat Reader\9.0\Privileged",
    "HKCU:\Software\Adobe\Acrobat Reader\9.0\TrustManager",
    "HKCU:\Software\Adobe\Acrobat Reader\9.0\FeatureLockDown",
    "HKCU:\Software\Adobe\Acrobat Reader\9.0\AVGeneral"
)

foreach ($path in $hkcuPaths) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
}

Set-ItemProperty -Path "HKCU:\Software\Adobe\Acrobat Reader\9.0\Privileged" -Name bProtectedMode -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Adobe\Acrobat Reader\9.0\TrustManager" -Name bEnhancedSecurityStandalone -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Adobe\Acrobat Reader\9.0\TrustManager" -Name bEnhancedSecurityInBrowser -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Adobe\Acrobat Reader\9.0\FeatureLockDown" -Name bDisableJavaScript -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Adobe\Acrobat Reader\9.0\AVGeneral" -Name bDontShowMsgAtLaunch -Value 1 -Type DWord -Force

Write-Host "  Protected Mode disabled (system-wide)" -ForegroundColor Green
Write-Host "  Enhanced Security disabled (system-wide)" -ForegroundColor Green
Write-Host "  JavaScript enabled (system-wide)" -ForegroundColor Green
Write-Host "  Startup messages disabled (system-wide)" -ForegroundColor Green

# Disable ASLR (Address Space Layout Randomization) for Adobe Reader
Write-Host
Write-Host "Disabling ASLR for Adobe Reader..." -ForegroundColor Yellow
try {
    # Disable system-wide ASLR via registry
    if (-not (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management")) {
        New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name MoveImages -Value 0 -Type DWord -Force
    Write-Host "  ASLR disabled system-wide (requires reboot)" -ForegroundColor Green
} catch {
    Write-Host "  Warning: Could not disable ASLR: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host
Write-Host "Adobe Reader 9.5.0 configured for exploitation" -ForegroundColor Green
