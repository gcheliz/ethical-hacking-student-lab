# Test Kali Connectivity
# Quick diagnostic to verify Windows can reach Kali

$KALI_IP = "192.168.56.101"
$HTTP_PORT = 8080

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Testing Connectivity to Kali" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host

# Test 1: Ping Kali
Write-Host "[1/3] Testing ICMP (ping) to Kali..." -NoNewline
try {
    $ping = Test-Connection -ComputerName $KALI_IP -Count 2 -Quiet -ErrorAction Stop
    if ($ping) {
        Write-Host " SUCCESS" -ForegroundColor Green
        Write-Host "    Kali is reachable at $KALI_IP" -ForegroundColor Gray
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "    Cannot ping $KALI_IP" -ForegroundColor Red
    }
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
}

Write-Host

# Test 2: Check TCP connectivity to port 8080
Write-Host "[2/3] Testing TCP connection to port ${HTTP_PORT}..." -NoNewline
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect($KALI_IP, $HTTP_PORT)
    Write-Host " SUCCESS" -ForegroundColor Green
    Write-Host "    Port $HTTP_PORT is open on Kali" -ForegroundColor Gray
    $tcpClient.Close()
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "    Port $HTTP_PORT is not reachable" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Gray
}

Write-Host

# Test 3: Try HTTP request
Write-Host "[3/3] Testing HTTP request to Kali server..." -NoNewline
try {
    $response = Invoke-WebRequest -Uri "http://${KALI_IP}:${HTTP_PORT}/" -Method Head -TimeoutSec 5 -ErrorAction Stop
    Write-Host " SUCCESS" -ForegroundColor Green
    Write-Host "    HTTP server is responding" -ForegroundColor Gray
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "    HTTP server not responding" -ForegroundColor Red
}

Write-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Network Configuration on Windows" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host

# Show Windows network configuration
$hostOnlyAdapter = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null -and $_.IPAddress -contains "192.168.56.102" }

if ($hostOnlyAdapter) {
    Write-Host "Host-only adapter found:" -ForegroundColor Green
    Write-Host "  IP Address:  $($hostOnlyAdapter.IPAddress[0])" -ForegroundColor Gray
    Write-Host "  Subnet Mask: $($hostOnlyAdapter.IPSubnet[0])" -ForegroundColor Gray
    if ($hostOnlyAdapter.DefaultIPGateway) {
        Write-Host "  Gateway:     $($hostOnlyAdapter.DefaultIPGateway[0])" -ForegroundColor Gray
    } else {
        Write-Host "  Gateway:     (not set)" -ForegroundColor Yellow
    }
} else {
    Write-Host "ERROR: No adapter with IP 192.168.56.102 found!" -ForegroundColor Red
}

Write-Host
Write-Host "Routing table (relevant entries):" -ForegroundColor Cyan
route print | Select-String "192.168.56"

Write-Host
