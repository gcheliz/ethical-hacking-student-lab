################################################################################
# Configure/Verify Host-Only Network on Windows
# Ensures the second adapter has the correct static IP for VM-to-VM communication
################################################################################

# Expected configuration
$ExpectedIP = "192.168.56.102"
$PrefixLength = 24
$Gateway = "192.168.56.1"
$DNS1 = "8.8.8.8"
$DNS2 = "8.8.4.4"

Write-Host "========================================"
Write-Host "  Host-Only Network Configuration"
Write-Host "========================================"
Write-Host ""

# ============================================================================
# Step 1: Find network adapters
# ============================================================================
Write-Host "[1/4] Detecting network adapters..." -ForegroundColor Yellow

# Get all adapters sorted by InterfaceIndex
$Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Sort-Object InterfaceIndex

if ($Adapters.Count -lt 2) {
    Write-Host "  ERROR: Expected 2 network adapters, found $($Adapters.Count)" -ForegroundColor Red
    Write-Host "  Adapter 1: NAT (for Vagrant WinRM)" -ForegroundColor Yellow
    Write-Host "  Adapter 2: Host-Only (for exploit traffic)" -ForegroundColor Yellow
    exit 1
}

# First adapter is NAT (for Vagrant), second is Host-Only
$NATAdapter = $Adapters[0]
$HostOnlyAdapter = $Adapters[1]

Write-Host "  NAT Adapter: $($NATAdapter.Name) (Interface $($NATAdapter.ifIndex))" -ForegroundColor Cyan
Write-Host "  Host-Only Adapter: $($HostOnlyAdapter.Name) (Interface $($HostOnlyAdapter.ifIndex))" -ForegroundColor Cyan

# ============================================================================
# Step 2: Check current configuration
# ============================================================================
Write-Host ""
Write-Host "[2/4] Checking Host-Only adapter configuration..." -ForegroundColor Yellow

$CurrentIP = (Get-NetIPAddress -InterfaceIndex $HostOnlyAdapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress

if ($CurrentIP -eq $ExpectedIP) {
    Write-Host "  Static IP already configured correctly: $ExpectedIP" -ForegroundColor Green

    # Verify gateway
    $CurrentGateway = (Get-NetRoute -InterfaceIndex $HostOnlyAdapter.ifIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue).NextHop
    if ($CurrentGateway -eq $Gateway) {
        Write-Host "  Gateway configured correctly: $Gateway" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "No configuration changes needed!" -ForegroundColor Green
    Write-Host ""
    exit 0
}

Write-Host "  Current IP: $CurrentIP" -ForegroundColor Yellow
Write-Host "  Expected IP: $ExpectedIP" -ForegroundColor Yellow
Write-Host "  Configuration needed..." -ForegroundColor Yellow

# ============================================================================
# Step 3: Configure static IP
# ============================================================================
Write-Host ""
Write-Host "[3/4] Configuring static IP on Host-Only adapter..." -ForegroundColor Yellow

try {
    # Remove existing IP configuration on Host-Only adapter
    Write-Host "  Removing existing IP configuration..." -ForegroundColor Cyan
    Remove-NetIPAddress -InterfaceIndex $HostOnlyAdapter.ifIndex -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $HostOnlyAdapter.ifIndex -Confirm:$false -ErrorAction SilentlyContinue

    # Wait for cleanup
    Start-Sleep -Seconds 2

    # Set static IP address
    Write-Host "  Setting static IP: $ExpectedIP/$PrefixLength..." -ForegroundColor Cyan
    New-NetIPAddress -InterfaceIndex $HostOnlyAdapter.ifIndex `
        -IPAddress $ExpectedIP `
        -PrefixLength $PrefixLength `
        -ErrorAction Stop | Out-Null

    # Note: We don't set default gateway on Host-Only adapter
    # Default gateway should only be on NAT adapter for internet access

    # Set DNS servers
    Write-Host "  Setting DNS servers..." -ForegroundColor Cyan
    Set-DnsClientServerAddress -InterfaceIndex $HostOnlyAdapter.ifIndex `
        -ServerAddresses @($DNS1, $DNS2) `
        -ErrorAction Stop

    Write-Host "  Configuration applied successfully" -ForegroundColor Green

} catch {
    Write-Host "  ERROR: Failed to configure static IP" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit 1
}

# ============================================================================
# Step 4: Verify configuration
# ============================================================================
Write-Host ""
Write-Host "[4/4] Verifying configuration..." -ForegroundColor Yellow

Start-Sleep -Seconds 2

$NewIP = (Get-NetIPAddress -InterfaceIndex $HostOnlyAdapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress

if ($NewIP -eq $ExpectedIP) {
    Write-Host "  Static IP verified: $NewIP" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Configuration failed!" -ForegroundColor Red
    Write-Host "  Expected: $ExpectedIP" -ForegroundColor Red
    Write-Host "  Current: $NewIP" -ForegroundColor Red
    exit 1
}

# Test connectivity to Host-Only gateway
Write-Host "  Testing connectivity to Kali..." -ForegroundColor Cyan
$PingResult = Test-Connection -ComputerName 192.168.56.101 -Count 2 -Quiet -ErrorAction SilentlyContinue

if ($PingResult) {
    Write-Host "  Kali reachable: 192.168.56.101" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Cannot ping Kali yet (may not be fully booted)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================"
Write-Host "  Host-Only Network Configured"
Write-Host "========================================"
Write-Host "  Adapter: $($HostOnlyAdapter.Name)" -ForegroundColor Cyan
Write-Host "  IP: $ExpectedIP" -ForegroundColor Cyan
Write-Host "  Network: 192.168.56.0/24" -ForegroundColor Cyan
Write-Host "  Kali IP: 192.168.56.101" -ForegroundColor Cyan
Write-Host "========================================"
Write-Host ""
