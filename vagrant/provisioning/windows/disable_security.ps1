# Disable ALL security features for lab environment
# Compatible with Windows Server 2008 R2

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Disabling Windows Security Features" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host

# 1. Disable Windows Firewall (using netsh for Server 2008 R2 compatibility)
Write-Host "[1/5] Disabling Windows Firewall..." -NoNewline
try {
    # Use netsh instead of Set-NetFirewallProfile (which doesn't exist in Server 2008 R2)
    netsh advfirewall set allprofiles state off | Out-Null
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. Disable UAC
Write-Host "[2/5] Disabling UAC..." -NoNewline
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -Value 0 -Force
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Failed" -ForegroundColor Red
}

# 3. Disable AppLocker
Write-Host "[3/5] Disabling AppLocker..." -NoNewline
try {
    Stop-Service AppIDSvc -Force -ErrorAction SilentlyContinue
    Set-Service AppIDSvc -StartupType Disabled -ErrorAction Stop
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 4. Remove Software Restriction Policies
Write-Host "[4/5] Removing Software Restriction Policies..." -NoNewline
try {
    Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Safer" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Already removed" -ForegroundColor Gray
}

# 5. Disable IE Enhanced Security Configuration (common on Server 2008 R2)
Write-Host "[5/6] Disabling IE Enhanced Security..." -NoNewline
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 -Force -ErrorAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 6. Disable DEP (Data Execution Prevention) - CRITICAL for exploit to work
Write-Host "[6/6] Disabling DEP (Data Execution Prevention)..." -NoNewline
try {
    # Disable DEP for all programs except Windows components
    # 0 = AlwaysOff (disable for everything - most permissive for exploits)
    bcdedit /set nx AlwaysOff | Out-Null
    Write-Host " Done" -ForegroundColor Green
    Write-Host "    DEP will be disabled on next reboot" -ForegroundColor Gray
} catch {
    Write-Host " Warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host
Write-Host "Security features disabled successfully" -ForegroundColor Green
Write-Host "Note: Windows Defender does not exist on Server 2008 R2 (skipped)" -ForegroundColor Gray
