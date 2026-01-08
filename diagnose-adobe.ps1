# Diagnostic script for Adobe Reader tar.gz extraction
# Run this to diagnose the issue: .\diagnose-adobe.ps1

Write-Host "=== Adobe Reader Archive Diagnostic ===" -ForegroundColor Cyan
Write-Host ""

$tarGzPath = "resources\AdobeReader_9.5.tar.gz"
$expectedPath = "resources\AdobeReader_9.5.exe"

# Check 1: Does tar.gz exist?
Write-Host "[1] Checking if tar.gz file exists..." -ForegroundColor Yellow
if (Test-Path $tarGzPath) {
    $sizeMB = [math]::Round((Get-Item $tarGzPath).Length / 1MB, 2)
    Write-Host "  [OK] Found: $tarGzPath (${sizeMB}MB)" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] File not found: $tarGzPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "You need to create the tar.gz file first."
    Write-Host "See MAINTAINER_SETUP.md for instructions."
    exit 1
}

# Check 2: What's inside the archive?
Write-Host ""
Write-Host "[2] Listing archive contents..." -ForegroundColor Yellow
$tarPath = "C:\Windows\System32\tar.exe"
if (Test-Path $tarPath) {
    $contents = & $tarPath -tzf $tarGzPath 2>&1
    Write-Host "  Archive contains:" -ForegroundColor Green
    foreach ($line in $contents) {
        Write-Host "    $line"
    }
} else {
    Write-Host "  [WARNING] tar.exe not found" -ForegroundColor Yellow
    Write-Host "  You may need Windows 10 1803+ or use 7-Zip/WinRAR"
}

# Check 3: Try extraction to temp location
Write-Host ""
Write-Host "[3] Testing extraction..." -ForegroundColor Yellow
if (Test-Path $tarPath) {
    $tempDir = Join-Path $env:TEMP "adobe_test_extract"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

    try {
        Push-Location $tempDir
        & $tarPath -xzf (Resolve-Path "..\..\$tarGzPath") 2>&1 | Out-Null
        Pop-Location

        $extractedFiles = Get-ChildItem -Path $tempDir -Recurse -File
        if ($extractedFiles) {
            Write-Host "  [OK] Extraction successful!" -ForegroundColor Green
            Write-Host "  Extracted files:" -ForegroundColor Green
            foreach ($file in $extractedFiles) {
                $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
                Write-Host "    - $($file.Name) (${fileSizeMB}MB)"
            }
        } else {
            Write-Host "  [ERROR] No files extracted" -ForegroundColor Red
        }

        # Cleanup
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Pop-Location
        Write-Host "  [ERROR] Extraction failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  [SKIPPED] tar.exe not available" -ForegroundColor Yellow
}

# Check 4: Does extracted file already exist?
Write-Host ""
Write-Host "[4] Checking for existing extracted file..." -ForegroundColor Yellow
if (Test-Path $expectedPath) {
    $sizeMB = [math]::Round((Get-Item $expectedPath).Length / 1MB, 2)
    Write-Host "  [OK] File exists: $expectedPath (${sizeMB}MB)" -ForegroundColor Green
} else {
    Write-Host "  [INFO] File not found: $expectedPath" -ForegroundColor Yellow
    Write-Host "  This is normal if you haven't extracted yet."
}

# Check 5: List all .exe files in resources
Write-Host ""
Write-Host "[5] All .exe files in resources folder..." -ForegroundColor Yellow
$exeFiles = Get-ChildItem -Path "resources" -Filter "*.exe" -ErrorAction SilentlyContinue
if ($exeFiles) {
    Write-Host "  Found:" -ForegroundColor Green
    foreach ($file in $exeFiles) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Host "    - $($file.Name) (${sizeMB}MB)"
    }
} else {
    Write-Host "  [INFO] No .exe files found in resources folder" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Diagnostic Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. If archive contains a different filename, rename it inside the tar.gz"
Write-Host "  2. Or extract manually and rename the .exe to 'AdobeReader_9.5.exe'"
Write-Host "  3. Then run .\setup.ps1 again"
