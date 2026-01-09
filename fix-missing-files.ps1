# Fix missing provisioning files
# This script helps diagnose and fix missing file issues

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     PROVISIONING FILES DIAGNOSTIC AND FIX SCRIPT               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check current directory
$currentDir = Get-Location
Write-Host "Current directory: $currentDir" -ForegroundColor Gray
Write-Host ""

# Check git status
Write-Host "[1/4] Checking git repository status..." -ForegroundColor Yellow
Write-Host ""

try {
    $gitBranch = git branch --show-current 2>&1
    Write-Host "  Current branch: $gitBranch" -ForegroundColor Green

    $gitRemote = git remote -v 2>&1 | Select-String "origin.*fetch"
    Write-Host "  Remote: $gitRemote" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Not a git repository or git not installed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check for uncommitted changes
Write-Host "[2/4] Checking for uncommitted changes..." -ForegroundColor Yellow
Write-Host ""

$gitStatus = git status --porcelain 2>&1
if ($gitStatus) {
    Write-Host "  WARNING: You have uncommitted changes:" -ForegroundColor Yellow
    $gitStatus | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "  These won't be affected by pulling" -ForegroundColor Gray
} else {
    Write-Host "  ✓ Working directory is clean" -ForegroundColor Green
}

Write-Host ""

# Check if provisioning files exist
Write-Host "[3/4] Checking provisioning files..." -ForegroundColor Yellow
Write-Host ""

$missingFiles = @()
$requiredFiles = @(
    "vagrant\provisioning\kali\install_tools.sh",
    "vagrant\provisioning\kali\configure_network.sh",
    "vagrant\provisioning\kali\create_exploits.sh",
    "vagrant\provisioning\kali\setup_autostart.sh",
    "vagrant\provisioning\windows\disable_security.ps1",
    "vagrant\provisioning\windows\install_adobe.ps1",
    "vagrant\provisioning\windows\configure_network.ps1",
    "vagrant\provisioning\windows\create_shortcuts.ps1",
    "vagrant\provisioning\windows\copy_pdfs_to_desktop.ps1"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ MISSING: $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

Write-Host ""

if ($missingFiles.Count -eq 0) {
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    ALL FILES PRESENT                           ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "All provisioning files exist. You can run setup.ps1 now." -ForegroundColor Green
    exit 0
}

# Files are missing - attempt to fix
Write-Host "[4/4] Fixing missing files..." -ForegroundColor Yellow
Write-Host ""

Write-Host "  Found $($missingFiles.Count) missing file(s)" -ForegroundColor Red
Write-Host ""
Write-Host "  Attempting to restore files from git..." -ForegroundColor Yellow
Write-Host ""

# First, fetch latest changes
Write-Host "  Step 1: Fetching latest changes from remote..." -ForegroundColor Cyan
git fetch origin 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✓ Fetch complete" -ForegroundColor Green
} else {
    Write-Host "    ✗ Fetch failed" -ForegroundColor Red
}

# Reset the specific files from the remote branch
Write-Host ""
Write-Host "  Step 2: Restoring files from origin/claude/create-lab-guide-fo5F2..." -ForegroundColor Cyan

try {
    # Checkout the provisioning directory from the remote branch
    git checkout origin/claude/create-lab-guide-fo5F2 -- vagrant/provisioning/ 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "    ✓ Files restored from remote branch" -ForegroundColor Green
    } else {
        Write-Host "    ⚠ Checkout had issues" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    ✗ Failed to restore: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "  Step 3: Verifying files..." -ForegroundColor Cyan

$stillMissing = @()
foreach ($file in $missingFiles) {
    if (Test-Path $file) {
        Write-Host "    ✓ Restored: $file" -ForegroundColor Green
    } else {
        Write-Host "    ✗ Still missing: $file" -ForegroundColor Red
        $stillMissing += $file
    }
}

Write-Host ""

if ($stillMissing.Count -eq 0) {
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    FIX SUCCESSFUL!                             ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "All files have been restored. You can now run:" -ForegroundColor Green
    Write-Host "  .\setup.ps1" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                  MANUAL ACTION REQUIRED                        ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "Some files could not be restored automatically." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please try these steps:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Stash any local changes:" -ForegroundColor Cyan
    Write-Host "     git stash" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. Pull latest changes:" -ForegroundColor Cyan
    Write-Host "     git pull origin claude/create-lab-guide-fo5F2" -ForegroundColor White
    Write-Host ""
    Write-Host "  3. If that fails, try a hard reset (CAUTION: loses local changes):" -ForegroundColor Cyan
    Write-Host "     git reset --hard origin/claude/create-lab-guide-fo5F2" -ForegroundColor White
    Write-Host ""
    Write-Host "  4. Re-run this script to verify:" -ForegroundColor Cyan
    Write-Host "     .\fix-missing-files.ps1" -ForegroundColor White
    Write-Host ""
}
