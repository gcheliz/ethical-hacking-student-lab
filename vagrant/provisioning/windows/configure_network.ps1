# Configure static IP and routing on host-only network

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Configuring Network and Routing" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host

# Get host-only adapter (use WMI for Server 2008 R2 compatibility)
Write-Host "[1/4] Detecting host-only network adapter..." -NoNewline
$hostOnlyAdapter = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {
    $_.IPAddress -ne $null -and $_.IPAddress -match "192.168.56"
}

if ($hostOnlyAdapter) {
    $currentIP = $hostOnlyAdapter.IPAddress | Where-Object {$_ -match "192.168.56"} | Select-Object -First 1
    $interfaceIndex = $hostOnlyAdapter.InterfaceIndex
    Write-Host " Found" -ForegroundColor Green
    Write-Host "    Interface Index: $interfaceIndex" -ForegroundColor Gray
    Write-Host "    Current IP: $currentIP" -ForegroundColor Gray

    if ($currentIP -ne "192.168.56.102") {
        Write-Host "    WARNING: Expected 192.168.56.102, got $currentIP" -ForegroundColor Yellow
    }
} else {
    Write-Host " Not Found" -ForegroundColor Red
    Write-Host "ERROR: No network adapter found with 192.168.56.x IP" -ForegroundColor Red
    exit 1
}

Write-Host

# Lower metric on host-only adapter to prioritize it for 192.168.56.0/24 traffic
Write-Host "[2/4] Configuring interface metric..." -NoNewline
try {
    # Set low metric (5) to prioritize this interface for local network
    netsh interface ip set interface $interfaceIndex metric=5 | Out-Null
    Write-Host " Done" -ForegroundColor Green
    Write-Host "    Set metric=5 for faster routing" -ForegroundColor Gray
} catch {
    Write-Host " Warning" -ForegroundColor Yellow
    Write-Host "    Could not set metric: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host

# Verify routing table
Write-Host "[3/4] Verifying routing table..." -NoNewline
$route = route print | Select-String "192.168.56.0"
if ($route) {
    Write-Host " OK" -ForegroundColor Green
    Write-Host "    Route exists for 192.168.56.0 network" -ForegroundColor Gray
} else {
    Write-Host " Warning" -ForegroundColor Yellow
    Write-Host "    No explicit route found, using interface default" -ForegroundColor Yellow
}

Write-Host

# Test connectivity to Kali
Write-Host "[4/4] Testing connectivity to Kali (192.168.56.101)..." -NoNewline
if (Test-Connection 192.168.56.101 -Count 2 -Quiet) {
    Write-Host " Success" -ForegroundColor Green

    # Verify return route uses correct interface
    $traceRoute = Test-Connection 192.168.56.101 -Count 1 -Source $currentIP -ErrorAction SilentlyContinue
    if ($traceRoute) {
        Write-Host "    Bidirectional connectivity confirmed" -ForegroundColor Gray
    }
} else {
    Write-Host " Failed" -ForegroundColor Yellow
    Write-Host "    Kali may not be running yet, this is OK during setup" -ForegroundColor Yellow
}

Write-Host
Write-Host "===================================================" -ForegroundColor Green
Write-Host "  Network Configuration Complete" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green
Write-Host
Write-Host "Configuration Summary:" -ForegroundColor Cyan
Write-Host "  Windows IP:  $currentIP (host-only adapter)" -ForegroundColor Gray
Write-Host "  Kali IP:     192.168.56.101 (target)" -ForegroundColor Gray
Write-Host "  Metric:      5 (prioritized for exploit traffic)" -ForegroundColor Gray
Write-Host
