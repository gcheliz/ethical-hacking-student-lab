# Create helpful desktop shortcuts

Write-Host "Creating desktop shortcuts..." -ForegroundColor Cyan

$DesktopPath = "C:\Users\vagrant\Desktop"

# Create shortcut to lab documentation
if (Test-Path "C:\vagrant\docs") {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$DesktopPath\Lab_Documentation.lnk")
    $Shortcut.TargetPath = "C:\vagrant\docs"
    $Shortcut.Description = "Lab Documentation and Guides"
    $Shortcut.Save()
    Write-Host "Lab Documentation shortcut created" -ForegroundColor Green
}

Write-Host "Desktop shortcuts created" -ForegroundColor Green
