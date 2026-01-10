################################################################################
# Configure/Verify Host-Only Network on Windows Server 2008 R2
# Uses WMI and netsh for compatibility with older PowerShell
################################################################################

# Expected configuration
$ExpectedIP = "192.168.56.102"
$Netmask = "255.255.255.0"
$Gateway = "192.168.56.1"

Write-Host "========================================"
Write-Host "  Host-Only Network Configuration"
Write-Host "========================================"
Write-Host ""

# ============================================================================
# Step 1: Find network adapters using WMI (compatible with Server 2008 R2)
# ============================================================================
Write-Host "[1/4] Detecting network adapters..." -ForegroundColor Yellow

# Get all network adapter configurations
$AllAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }

if ($AllAdapters.Count -lt 1) {
    Write-Host "  ERROR: No active network adapters found" -ForegroundColor Red
    exit 1
}

Write-Host "  Found $($AllAdapters.Count) active network adapter(s)" -ForegroundColor Cyan

# ============================================================================
# Step 2: Check if Host-Only IP is already configured
# ============================================================================
Write-Host ""
Write-Host "[2/4] Checking for Host-Only network..." -ForegroundColor Yellow

$HostOnlyAdapter = $null
$CurrentIP = $null

foreach ($Adapter in $AllAdapters) {
    if ($Adapter.IPAddress -contains $ExpectedIP) {
        $HostOnlyAdapter = $Adapter
        $CurrentIP = $ExpectedIP
        Write-Host "  Host-Only adapter already configured" -ForegroundColor Green
        Write-Host "  Interface: $($Adapter.Description)" -ForegroundColor Cyan
        Write-Host "  IP: $ExpectedIP" -ForegroundColor Cyan
        break
    }
}

# If already configured correctly, exit
if ($CurrentIP -eq $ExpectedIP) {
    Write-Host ""
    Write-Host "No configuration changes needed!" -ForegroundColor Green
    Write-Host ""
    exit 0
}

# ============================================================================
# Step 3: Find the second adapter (Host-Only)
# ============================================================================
Write-Host "  Looking for second network adapter..." -ForegroundColor Yellow

# Vagrant creates adapters in order: first is NAT, second is Host-Only
# Get all adapters (including disabled) and sort by index
$AllNetworkAdapters = Get-WmiObject Win32_NetworkAdapter | Where-Object {
    $_.Name -like "*Intel*" -or $_.Name -like "*AMD*" -or $_.Name -like "*VirtIO*"
} | Sort-Object Index

if ($AllNetworkAdapters.Count -lt 2) {
    Write-Host "  ERROR: Expected 2 network adapters, found $($AllNetworkAdapters.Count)" -ForegroundColor Red
    Write-Host "  Vagrant should create:" -ForegroundColor Yellow
    Write-Host "    Adapter 1: NAT (for WinRM)" -ForegroundColor Yellow
    Write-Host "    Adapter 2: Host-Only (for exploit traffic)" -ForegroundColor Yellow
    exit 1
}

# Second adapter should be Host-Only
$HostOnlyPhysicalAdapter = $AllNetworkAdapters[1]
$AdapterIndex = $HostOnlyPhysicalAdapter.Index

Write-Host "  Second adapter: $($HostOnlyPhysicalAdapter.Name)" -ForegroundColor Cyan
Write-Host "  Index: $AdapterIndex" -ForegroundColor Cyan

# ============================================================================
# Step 4: Configure static IP using netsh
# ============================================================================
Write-Host ""
Write-Host "[3/4] Configuring static IP..." -ForegroundColor Yellow

# Get the adapter's network connection name
$NetworkConnection = Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.Index -eq $AdapterIndex }
$AdapterName = $NetworkConnection.NetConnectionID

if (-not $AdapterName) {
    Write-Host "  ERROR: Could not find network connection name" -ForegroundColor Red
    exit 1
}

Write-Host "  Connection Name: $AdapterName" -ForegroundColor Cyan
Write-Host "  Setting IP: $ExpectedIP" -ForegroundColor Cyan

# Use netsh to configure static IP (compatible with Server 2008 R2)
$netshOutput = netsh interface ip set address name="$AdapterName" static $ExpectedIP $Netmask $Gateway 1 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "  WARNING: netsh returned exit code $LASTEXITCODE" -ForegroundColor Yellow
    Write-Host "  Output: $netshOutput" -ForegroundColor Yellow
    # Don't exit - sometimes netsh returns non-zero but still works
}

# Set DNS servers
Write-Host "  Setting DNS servers..." -ForegroundColor Cyan
netsh interface ip set dns name="$AdapterName" static 8.8.8.8 primary 2>&1 | Out-Null
netsh interface ip add dns name="$AdapterName" 8.8.4.4 index=2 2>&1 | Out-Null

Write-Host "  Configuration applied" -ForegroundColor Green

# ============================================================================
# Step 5: Verify configuration
# ============================================================================
Write-Host ""
Write-Host "[4/4] Verifying configuration..." -ForegroundColor Yellow

Start-Sleep -Seconds 3

# Re-read adapter configuration
$VerifyAdapter = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {
    $_.Index -eq $AdapterIndex
}

if ($VerifyAdapter.IPAddress -contains $ExpectedIP) {
    Write-Host "  Static IP verified: $ExpectedIP" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Could not verify IP immediately" -ForegroundColor Yellow
    Write-Host "  Current IPs: $($VerifyAdapter.IPAddress -join ', ')" -ForegroundColor Yellow
    Write-Host "  Network may need a moment to update..." -ForegroundColor Yellow
}

# Test connectivity to Kali
Write-Host "  Testing connectivity to Kali (192.168.56.101)..." -ForegroundColor Cyan
$PingResult = Test-Connection -ComputerName 192.168.56.101 -Count 2 -Quiet -ErrorAction SilentlyContinue

if ($PingResult) {
    Write-Host "  Kali reachable!" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Cannot ping Kali yet (may not be fully booted)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================"
Write-Host "  Host-Only Network Configured"
Write-Host "========================================"
Write-Host "  Connection: $AdapterName" -ForegroundColor Cyan
Write-Host "  IP: $ExpectedIP" -ForegroundColor Cyan
Write-Host "  Gateway: $Gateway" -ForegroundColor Cyan
Write-Host "  Kali IP: 192.168.56.101" -ForegroundColor Cyan
Write-Host "========================================"
Write-Host ""
