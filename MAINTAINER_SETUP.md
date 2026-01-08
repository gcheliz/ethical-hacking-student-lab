# Maintainer Setup Guide

This guide is for **repository maintainers** who need to add the Adobe Reader 9.5.0 installer to the repository.

## Overview

The Adobe Reader 9.5.0 installer (approximately 50MB) is required for the lab but is too large to include directly in the repository. Instead, we:

1. Compress the installer into a ZIP file
2. Commit the ZIP file to the repository
3. The setup scripts automatically extract it when students run the lab

## Step-by-Step Instructions

### 1. Obtain Adobe Reader 9.5.0 Installer

You need to obtain the **AdbeRdr950_en_US.exe** file (approximately 50MB).

**Option A: Manual Download**

Download from one of these sources:
- **OldVersion.com**: https://www.oldversion.com/windows/adobe-reader-9-5-0
- **FileHippo**: https://filehippo.com/download_adobe-reader/9.5.0/

**Option B: From Archive**

If you have access to an archived copy, use that.

**IMPORTANT**: Verify the file is approximately **50MB** (not 33MB which is corrupted).

### 2. Rename the Installer

Rename the downloaded file to the standard name:

**Windows:**
```powershell
Rename-Item "AdbeRdr950_en_US.exe" "AdobeReader_9.5.exe"
```

**Linux/macOS:**
```bash
mv AdbeRdr950_en_US.exe AdobeReader_9.5.exe
```

### 3. Create ZIP Archive

**Windows (PowerShell):**
```powershell
# Using built-in Compress-Archive
Compress-Archive -Path AdobeReader_9.5.exe -DestinationPath AdobeReader_9.5.zip -CompressionLevel Optimal

# Verify the ZIP was created
Get-Item AdobeReader_9.5.zip | Select-Object Name, @{Name="SizeMB";Expression={[math]::Round($_.Length / 1MB, 2)}}
```

**Windows (7-Zip - if installed):**
```powershell
& "C:\Program Files\7-Zip\7z.exe" a -tzip AdobeReader_9.5.zip AdobeReader_9.5.exe
```

**Linux/macOS:**
```bash
zip AdobeReader_9.5.zip AdobeReader_9.5.exe

# Verify the ZIP was created
ls -lh AdobeReader_9.5.zip
```

### 4. Move to Resources Folder

**Windows:**
```powershell
Move-Item AdobeReader_9.5.zip resources\
```

**Linux/macOS:**
```bash
mv AdobeReader_9.5.zip resources/
```

### 5. Add to Git and Commit

**All Platforms:**
```bash
# Add the ZIP file to git
git add resources/AdobeReader_9.5.zip

# Commit with descriptive message
git commit -m "Add Adobe Reader 9.5.0 installer (zipped)"

# Push to repository
git push
```

### 6. Verify Setup

After pushing, verify that:

1. The ZIP file is in the repository: `resources/AdobeReader_9.5.zip`
2. The extracted .exe is **NOT** in the repository (it's in .gitignore)
3. File size is approximately 40-45MB (compressed)

## Expected File Sizes

| File | Size | Status |
|------|------|--------|
| `AdobeReader_9.5.exe` | ~50 MB | **NOT** in git (ignored) |
| `AdobeReader_9.5.zip` | ~40-45 MB | **IN** git (tracked) |

## Verification

To verify the setup works correctly:

**Windows:**
```powershell
# Clone the repository fresh
git clone <repository-url> test-clone
cd test-clone

# Run setup
.\setup.ps1
```

**Linux/macOS:**
```bash
# Clone the repository fresh
git clone <repository-url> test-clone
cd test-clone

# Run setup
./setup.sh
```

The setup script should:
1. Find `resources/AdobeReader_9.5.zip`
2. Extract it to `resources/AdobeReader_9.5.exe`
3. Verify the file is approximately 50MB
4. Continue with VM setup

## Troubleshooting

### ZIP file is too large for GitHub

If the ZIP file exceeds GitHub's file size limit (100MB), you have options:

**Option 1: Use Git LFS (Recommended)**

```bash
# Install Git LFS
git lfs install

# Track the ZIP file with LFS
git lfs track "resources/AdobeReader_9.5.zip"

# Add .gitattributes
git add .gitattributes

# Add and commit the file
git add resources/AdobeReader_9.5.zip
git commit -m "Add Adobe Reader installer using Git LFS"
git push
```

**Option 2: Use external hosting**

Upload the ZIP to:
- Google Drive
- Dropbox
- Amazon S3
- Your institution's file server

Then update the setup scripts to download from that URL (requires modifying setup.ps1 and setup.sh).

### Students report "ZIP archive not found"

Verify the file was pushed correctly:

```bash
git ls-files resources/
```

Should show: `resources/AdobeReader_9.5.zip`

### Extraction fails

Verify the ZIP is valid:

**Windows:**
```powershell
Expand-Archive -Path resources\AdobeReader_9.5.zip -DestinationPath test-extract -Force
Get-ChildItem test-extract
```

**Linux/macOS:**
```bash
unzip -t resources/AdobeReader_9.5.zip
```

## Security Note

Adobe Reader 9.5.0 is an **intentionally vulnerable** version used for educational security demonstrations. This software should **NEVER** be used in production environments or connected to the internet.

The lab environment is designed to be:
- Isolated (host-only networking)
- Temporary (VMs can be destroyed after use)
- Educational (demonstrates real security vulnerabilities)

---

## Questions?

If you encounter issues setting up the repository, please:
1. Check the file sizes match the expected values
2. Verify the ZIP extracts correctly on your local machine
3. Test the setup scripts in a fresh clone of the repository
