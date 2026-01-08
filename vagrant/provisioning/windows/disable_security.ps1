# Disable ALL security features for lab environment

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Disabling Windows Security Features" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host

# 1. Disable Windows Firewall
Write-Host "[1/6] Disabling Windows Firewall..." -NoNewline
try {
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False -ErrorAction Stop
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. Disable Windows Defender
Write-Host "[2/6] Disabling Windows Defender..." -NoNewline
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
    Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. Disable UAC
Write-Host "[3/6] Disabling UAC..." -NoNewline
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -Value 0 -Force
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Failed" -ForegroundColor Red
}

# 4. Disable AppLocker
Write-Host "[4/6] Disabling AppLocker..." -NoNewline
try {
    Stop-Service AppIDSvc -Force -ErrorAction SilentlyContinue
    Set-Service AppIDSvc -StartupType Disabled -ErrorAction Stop
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 5. Remove Software Restriction Policies
Write-Host "[5/6] Removing Software Restriction Policies..." -NoNewline
try {
    Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Already removed" -ForegroundColor Gray
}

# 6. Disable SmartScreen
Write-Host "[6/6] Disabling SmartScreen..." -NoNewline
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name SmartScreenEnabled -Value "Off" -Force
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host
Write-Host "Security features disabled successfully" -ForegroundColor Green
