# Disable security features for HTA exploit lab
# Only disables what's REQUIRED for the exploit to work
# Compatible with Windows Server 2008 R2

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Disabling Windows Security Features" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host

# 1. Disable Windows Firewall
# REQUIRED: Allows incoming Meterpreter reverse TCP connection
Write-Host "[1/3] Disabling Windows Firewall..." -NoNewline
try {
    # Use netsh for Server 2008 R2 compatibility
    netsh advfirewall set allprofiles state off | Out-Null
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. Disable IE Enhanced Security Configuration
# REQUIRED: Allows downloading HTA and EXE files from Kali
Write-Host "[2/3] Disabling IE Enhanced Security..." -NoNewline
try {
    # Disable for Administrators
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 -Force -ErrorAction SilentlyContinue
    # Disable for Users
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0 -Force -ErrorAction SilentlyContinue
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. Disable UAC
# OPTIONAL: Prevents prompts when executing downloaded files
Write-Host "[3/3] Disabling UAC..." -NoNewline
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -Value 0 -Force
    Write-Host " Done" -ForegroundColor Green
} catch {
    Write-Host " Failed" -ForegroundColor Red
}

Write-Host
Write-Host "Security features disabled successfully" -ForegroundColor Green
Write-Host
Write-Host "What was disabled:" -ForegroundColor Gray
Write-Host "  - Windows Firewall (allows Meterpreter connection)" -ForegroundColor Gray
Write-Host "  - IE Enhanced Security (allows file downloads)" -ForegroundColor Gray
Write-Host "  - UAC (prevents execution prompts)" -ForegroundColor Gray
Write-Host
Write-Host "What was NOT disabled (not needed for HTA exploit):" -ForegroundColor Gray
Write-Host "  - AppLocker (not enabled by default)" -ForegroundColor Gray
Write-Host "  - Software Restriction Policies (not configured by default)" -ForegroundColor Gray
Write-Host "  - DEP (not needed for basic Meterpreter payloads)" -ForegroundColor Gray
Write-Host "  - Windows Defender (doesn't exist on Server 2008 R2)" -ForegroundColor Gray
