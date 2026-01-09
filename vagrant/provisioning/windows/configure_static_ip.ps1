################################################################################
# Configure Static IP for NAT Network on Windows
# NAT Network uses DHCP by default, but we need static IPs for the exploit
################################################################################

# Expected configuration
$ExpectedIP = "192.168.56.102"
$Netmask = "255.255.255.0"
$PrefixLength = 24
$Gateway = "192.168.56.1"
$DNS1 = "8.8.8.8"
$DNS2 = "8.8.4.4"

Write-Host "========================================"
Write-Host "  Static IP Configuration"
Write-Host "========================================"
Write-Host ""

# ============================================================================
# Step 1: Find the network adapter
# ============================================================================
Write-Host "[1/4] Finding network adapter..." -ForegroundColor Yellow

# Get the first active network adapter (should be the NAT Network adapter)
$Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

if (-not $Adapter) {
    Write-Host "  ERROR: No active network adapter found" -ForegroundColor Red
    exit 1
}

$AdapterName = $Adapter.Name
$InterfaceIndex = $Adapter.ifIndex

Write-Host "  Adapter Name: $AdapterName" -ForegroundColor Cyan
Write-Host "  Interface Index: $InterfaceIndex" -ForegroundColor Cyan

# ============================================================================
# Step 2: Check current configuration
# ============================================================================
Write-Host ""
Write-Host "[2/4] Checking current configuration..." -ForegroundColor Yellow

$CurrentIP = (Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress

if ($CurrentIP -eq $ExpectedIP) {
    Write-Host "  Static IP already configured: $ExpectedIP" -ForegroundColor Green
    Write-Host ""
    Write-Host "No configuration needed!" -ForegroundColor Green
    Write-Host ""
    exit 0
}

Write-Host "  Current IP: $CurrentIP" -ForegroundColor Cyan
Write-Host "  Expected IP: $ExpectedIP" -ForegroundColor Cyan
Write-Host "  Need to configure static IP..." -ForegroundColor Yellow

# ============================================================================
# Step 3: Configure static IP
# ============================================================================
Write-Host ""
Write-Host "[3/4] Configuring static IP..." -ForegroundColor Yellow

try {
    # Remove any existing IP configuration
    Write-Host "  Removing DHCP configuration..." -ForegroundColor Cyan
    Remove-NetIPAddress -InterfaceIndex $InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue

    # Wait a moment for cleanup
    Start-Sleep -Seconds 2

    # Set static IP address
    Write-Host "  Setting static IP address..." -ForegroundColor Cyan
    New-NetIPAddress -InterfaceIndex $InterfaceIndex `
        -IPAddress $ExpectedIP `
        -PrefixLength $PrefixLength `
        -DefaultGateway $Gateway `
        -ErrorAction Stop | Out-Null

    # Set DNS servers
    Write-Host "  Setting DNS servers..." -ForegroundColor Cyan
    Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex `
        -ServerAddresses @($DNS1, $DNS2) `
        -ErrorAction Stop

    Write-Host "  Static IP configured successfully" -ForegroundColor Green

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

$NewIP = (Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress

if ($NewIP -eq $ExpectedIP) {
    Write-Host "  Static IP verified: $NewIP" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Configuration failed!" -ForegroundColor Red
    Write-Host "  Expected: $ExpectedIP" -ForegroundColor Red
    Write-Host "  Current: $NewIP" -ForegroundColor Red
    exit 1
}

# Test gateway connectivity
Write-Host "  Testing gateway connectivity..." -ForegroundColor Cyan
$PingResult = Test-Connection -ComputerName $Gateway -Count 2 -Quiet -ErrorAction SilentlyContinue

if ($PingResult) {
    Write-Host "  Gateway reachable: $Gateway" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Cannot ping gateway" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================"
Write-Host "  Static IP Configured Successfully"
Write-Host "========================================"
Write-Host "  Adapter: $AdapterName" -ForegroundColor Cyan
Write-Host "  IP: $ExpectedIP" -ForegroundColor Cyan
Write-Host "  Gateway: $Gateway" -ForegroundColor Cyan
Write-Host "  Network: 192.168.56.0/24" -ForegroundColor Cyan
Write-Host "========================================"
Write-Host ""
