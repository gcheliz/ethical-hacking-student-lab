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

        # Get local endpoint to verify source IP
        $localIP = $tcpClient.Client.LocalEndPoint.Address.ToString()
        $tcpClient.Close()

        Write-Host " PASSED" -ForegroundColor Green
        Write-Host "    Successfully connected to Kali:$LISTEN_PORT" -ForegroundColor Gray
        Write-Host "    Connection source IP: $localIP" -ForegroundColor Gray

        if ($localIP -eq $EXPECTED_IP) {
            Write-Host "    ✓ Using host-only adapter ($localIP)" -ForegroundColor Green
        } else {
            Write-Host "    ✗ WARNING: Using wrong adapter" -ForegroundColor Red
            Write-Host "      Current: $localIP, Expected: $EXPECTED_IP" -ForegroundColor Red
            $ValidationFailed = $true
        }
    } else {
        $tcpClient.Close()
        Write-Host " WARNING" -ForegroundColor Yellow
        Write-Host "    No listener on Kali:$LISTEN_PORT" -ForegroundColor Yellow
        Write-Host "    This is OK if Metasploit listener has not started yet" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "    To start listener on Kali, run:" -ForegroundColor Yellow
        Write-Host "      vagrant ssh kali" -ForegroundColor Gray
        Write-Host "      cd /vagrant/exploits" -ForegroundColor Gray
        Write-Host "      ./start_attack.sh" -ForegroundColor Gray
    }
} catch {
    Write-Host " WARNING" -ForegroundColor Yellow
    Write-Host "    Cannot connect to Kali:$LISTEN_PORT" -ForegroundColor Yellow
    Write-Host "    Listener may not be running yet (this is OK during setup)" -ForegroundColor Yellow
}

Write-Host

# Check 5: Create manual test script on Desktop
Write-Host "[5/5] Creating TCP test script on Desktop..." -NoNewline

$testScriptPath = "C:\Users\vagrant\Desktop\Test-Kali-Connection.ps1"
$testScript = @'
# Test TCP Connection to Kali Metasploit Listener
# Run this script when Metasploit listener is active

$KALI_IP = "192.168.56.101"
$PORT = 4444

Write-Host "Testing TCP connection to Kali Metasploit listener..." -ForegroundColor Cyan
Write-Host "Target: ${KALI_IP}:${PORT}" -ForegroundColor Gray
Write-Host

try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connection = $tcpClient.BeginConnect($KALI_IP, $PORT, $null, $null)
    $wait = $connection.AsyncWaitHandle.WaitOne(5000, $false)

    if ($wait) {
        $tcpClient.EndConnect($connection)
        $localIP = $tcpClient.Client.LocalEndPoint.Address.ToString()
        $localPort = $tcpClient.Client.LocalEndPoint.Port
        $tcpClient.Close()

        Write-Host "SUCCESS: Connected to Kali!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Connection details:" -ForegroundColor Cyan
        Write-Host "  Source IP:   $localIP" -ForegroundColor Gray
        Write-Host "  Source Port: $localPort" -ForegroundColor Gray
        Write-Host "  Target:      ${KALI_IP}:${PORT}" -ForegroundColor Gray
        Write-Host ""

        if ($localIP -eq "192.168.56.102") {
            Write-Host "VALIDATED: Using host-only adapter (192.168.56.102)" -ForegroundColor Green
            Write-Host "The exploit should work correctly!" -ForegroundColor Green
        } else {
            Write-Host "WARNING: Using wrong adapter ($localIP)" -ForegroundColor Red
            Write-Host "Expected to use 192.168.56.102 (host-only adapter)" -ForegroundColor Red
            Write-Host "The exploit may not work!" -ForegroundColor Red
        }
    } else {
        $tcpClient.Close()
        Write-Host "FAILED: Cannot connect to ${KALI_IP}:${PORT}" -ForegroundColor Red
        Write-Host ""
        Write-Host "Make sure:" -ForegroundColor Yellow
        Write-Host "  1. Kali VM is running" -ForegroundColor Yellow
        Write-Host "  2. Metasploit listener is started" -ForegroundColor Yellow
        Write-Host "     Run on Kali: cd /vagrant/exploits; ./start_attack.sh" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to close"
'@

try {
    $testScript | Out-File -FilePath $testScriptPath -Encoding ASCII -Force
    Write-Host " Done" -ForegroundColor Green
    Write-Host "    Created: Test-Kali-Connection.ps1 on Desktop" -ForegroundColor Gray
} catch {
    Write-Host " Failed" -ForegroundColor Yellow
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
