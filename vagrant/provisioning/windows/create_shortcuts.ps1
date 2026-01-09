# Create helpful desktop shortcuts

Write-Host "Creating desktop shortcuts..." -ForegroundColor Cyan

$DesktopPath = "C:\Users\vagrant\Desktop"
$WshShell = New-Object -ComObject WScript.Shell

# Shortcut 1: Lab Documentation
if (Test-Path "C:\vagrant\docs") {
    $Shortcut = $WshShell.CreateShortcut("$DesktopPath\Lab_Documentation.lnk")
    $Shortcut.TargetPath = "C:\vagrant\docs"
    $Shortcut.Description = "Lab Documentation and Guides"
    $Shortcut.Save()
    Write-Host "  [1/2] Lab Documentation shortcut created" -ForegroundColor Green
}

# Shortcut 2: Download Fake PDF from Kali
$DownloadScriptPath = "C:\vagrant\exploits\lnk\download_lnk_from_kali.ps1"
if (Test-Path $DownloadScriptPath) {
    $Shortcut = $WshShell.CreateShortcut("$DesktopPath\Download_Fake_PDF_from_Kali.lnk")
    $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$DownloadScriptPath`""
    $Shortcut.Description = "Download malicious LNK file from Kali HTTP server (Educational Lab)"
    $Shortcut.IconLocation = "C:\Windows\System32\shell32.dll,13"  # Download icon
    $Shortcut.WorkingDirectory = "$DesktopPath"
    $Shortcut.WindowStyle = 1  # Normal window
    $Shortcut.Save()
    Write-Host "  [2/2] Download Fake PDF shortcut created" -ForegroundColor Green
} else {
    Write-Host "  [2/2] Download script not found at: $DownloadScriptPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Desktop shortcuts created successfully!" -ForegroundColor Green
