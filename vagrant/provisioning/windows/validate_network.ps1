# Network Validation Script for Windows
# Verifies Windows VM can communicate with Kali over host-only network

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Network Configuration Validation (Windows)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host

$KALI_IP = "192.168.56.101"
$EXPECTED_IP = "192.168.56.102"
$LISTEN_PORT = 4444
$ValidationFailed = $false

# Check 1: Verify host-only adapter exists and has correct IP
Write-Host "[1/5] Checking host-only network adapter..." -NoNewline
$hostOnlyAdapter = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {
    $_.IPAddress -ne $null -and $_.IPAddress -match "192.168.56"
}

if ($hostOnlyAdapter) {
    $currentIP = $hostOnlyAdapter.IPAddress | Where-Object {$_ -match "192.168.56"} | Select-Object -First 1

    if ($currentIP -eq $EXPECTED_IP) {
        Write-Host " PASSED" -ForegroundColor Green
        Write-Host "    IP: $currentIP (host-only adapter)" -ForegroundColor Gray
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "    Expected: $EXPECTED_IP, Got: $currentIP" -ForegroundColor Red
        $ValidationFailed = $true
    }
} else {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "    No adapter with 192.168.56.x IP found" -ForegroundColor Red
    $ValidationFailed = $true
}

Write-Host

# Check 2: Verify routing table
Write-Host "[2/5] Checking routing table..." -NoNewline
$route = route print | Select-String "192.168.56.0"
if ($route) {
    Write-Host " PASSED" -ForegroundColor Green
    Write-Host "    Route to 192.168.56.0 network exists" -ForegroundColor Gray
} else {
    Write-Host " WARNING" -ForegroundColor Yellow
    Write-Host "    No explicit route, using adapter default" -ForegroundColor Yellow
}

Write-Host

# Check 3: Test ping to Kali
Write-Host "[3/5] Testing ping to Kali ($KALI_IP)..." -NoNewline
if (Test-Connection $KALI_IP -Count 2 -Quiet) {
    Write-Host " PASSED" -ForegroundColor Green
    Write-Host "    Can ping Kali VM" -ForegroundColor Gray
} else {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "    Cannot ping Kali VM" -ForegroundColor Red
    $ValidationFailed = $true
}

Write-Host

# Check 4: Test TCP connection to Kali port 4444
Write-Host "[4/5] Testing TCP connection to Kali port $LISTEN_PORT..." -NoNewline
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connection = $tcpClient.BeginConnect($KALI_IP, $LISTEN_PORT, $null, $null)
    $wait = $connection.AsyncWaitHandle.WaitOne(3000, $false)

    if ($wait) {
        $tcpClient.EndConnect($connection)
        $tcpClient.Close()
        Write-Host " PASSED" -ForegroundColor Green
        Write-Host "    Can connect to Kali:$LISTEN_PORT" -ForegroundColor Gray
    } else {
        $tcpClient.Close()
        Write-Host " WARNING" -ForegroundColor Yellow
        Write-Host "    No listener on Kali:$LISTEN_PORT (expected if attack not started)" -ForegroundColor Yellow
    }
} catch {
    Write-Host " WARNING" -ForegroundColor Yellow
    Write-Host "    Cannot connect to Kali:$LISTEN_PORT (listener may not be running yet)" -ForegroundColor Yellow
}

Write-Host

# Check 5: Verify source IP for outbound connections
Write-Host "[5/5] Verifying outbound connection source IP..." -NoNewline
try {
    $testSocket = New-Object System.Net.Sockets.Socket([System.Net.Sockets.AddressFamily]::InterNetwork,
                                                         [System.Net.Sockets.SocketType]::Stream,
                                                         [System.Net.Sockets.ProtocolType]::Tcp)
    $testSocket.Connect($KALI_IP, 22)  # Try SSH port
    $localEndpoint = $testSocket.LocalEndPoint.Address.ToString()
    $testSocket.Close()

    if ($localEndpoint -eq $EXPECTED_IP) {
        Write-Host " PASSED" -ForegroundColor Green
        Write-Host "    Outbound connections use $localEndpoint" -ForegroundColor Gray
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "    Outbound connections use $localEndpoint (expected $EXPECTED_IP)" -ForegroundColor Red
        Write-Host "    This means Windows is NOT using the host-only adapter!" -ForegroundColor Red
        $ValidationFailed = $true
    }
} catch {
    Write-Host " WARNING" -ForegroundColor Yellow
    Write-Host "    Could not determine outbound IP" -ForegroundColor Yellow
}

Write-Host
Write-Host "================================================================" -ForegroundColor Cyan

if (-not $ValidationFailed) {
    Write-Host "  VALIDATION PASSED - Network is correctly configured" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host
    Write-Host "Network Summary:" -ForegroundColor Cyan
    Write-Host "  Windows IP:  $currentIP (host-only adapter)" -ForegroundColor Gray
    Write-Host "  Kali IP:     $KALI_IP (target)" -ForegroundColor Gray
    Write-Host "  Port:        $LISTEN_PORT (Metasploit listener)" -ForegroundColor Gray
    Write-Host
    Write-Host "Ready to open malicious PDFs!" -ForegroundColor Green
} else {
    Write-Host "  VALIDATION FAILED - Fix errors before opening PDFs" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host
    Write-Host "Please fix the errors above." -ForegroundColor Red
    Write-Host "You may need to rebuild the Windows VM." -ForegroundColor Yellow
}
