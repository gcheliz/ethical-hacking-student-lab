# Configure static IP on host-only network

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Configuring Network" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host

# Get current IP (use WMI for Server 2008 R2 compatibility)
$adapter = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPAddress -ne $null -and $_.IPAddress -match "192.168.56"}

if ($adapter) {
    $currentIP = $adapter.IPAddress | Where-Object {$_ -match "192.168.56"} | Select-Object -First 1

    if ($currentIP -eq "192.168.56.102") {
        Write-Host "IP address already configured: $currentIP" -ForegroundColor Green
    } else {
        Write-Host "Current IP: $currentIP" -ForegroundColor Yellow
        Write-Host "Expected IP: 192.168.56.102" -ForegroundColor Yellow
    }
} else {
    Write-Host "No network adapter found with 192.168.56.x IP" -ForegroundColor Yellow
}

# Test connectivity to Kali
Write-Host
Write-Host "Testing connectivity to Kali Linux..." -NoNewline
if (Test-Connection 192.168.56.101 -Count 2 -Quiet) {
    Write-Host " Success" -ForegroundColor Green
} else {
    Write-Host " Failed (Kali may not be running yet)" -ForegroundColor Yellow
}

Write-Host
Write-Host "Network configuration complete" -ForegroundColor Green
