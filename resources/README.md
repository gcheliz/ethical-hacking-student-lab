# Resources Directory

This directory contains the Adobe Reader 9.5.0 installer required for the lab.

## For Repository Maintainers

### Creating the tar.gz file

The Adobe Reader installer should be compressed and committed to the repository:

**On Linux/macOS:**
```bash
# Download Adobe Reader 9.5.0 (50MB file)
wget https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe -O AdobeReader_9.5.exe

# Verify size (should be ~52MB)
ls -lh AdobeReader_9.5.exe

# Compress with tar and gzip
tar -czf AdobeReader_9.5.tar.gz AdobeReader_9.5.exe

# Add to git
git add AdobeReader_9.5.tar.gz
git commit -m "Add Adobe Reader 9.5.0 installer"
```

**On Windows (PowerShell 5.1+):**
```powershell
# Download Adobe Reader 9.5.0
# Use download-adobe-retry.ps1 or manual download from OldVersion.com

# Compress using 7-Zip (if installed)
& "C:\Program Files\7-Zip\7z.exe" a -ttar -so AdobeReader_9.5.exe | & "C:\Program Files\7-Zip\7z.exe" a -si AdobeReader_9.5.tar.gz

# Or use built-in PowerShell compression (creates zip, rename to .tar.gz)
Compress-Archive -Path AdobeReader_9.5.exe -DestinationPath AdobeReader_9.5.zip
# Then manually compress with tar/gzip tool
```

**Using Git Bash on Windows:**
```bash
tar -czf AdobeReader_9.5.tar.gz AdobeReader_9.5.exe
```

### File Details

- **Original File:** AdbeRdr950_en_US.exe
- **Renamed To:** AdobeReader_9.5.exe
- **Size:** ~52,428,800 bytes (50 MB)
- **Compressed:** AdobeReader_9.5.tar.gz (~40-45 MB)

## For Students

**You don't need to do anything!**

The setup script (`setup.ps1` or `setup.sh`) will automatically extract the installer from `AdobeReader_9.5.tar.gz` when you run it.

If the compressed file is missing, you'll see instructions on how to download it manually.

## Troubleshooting

### If AdobeReader_9.5.tar.gz is missing

The repository maintainer needs to add it. See instructions above.

Alternatively, download manually:
1. Download from: http://www.oldversion.com/windows/adobe-reader-9-5-0
2. Save as: `resources/AdobeReader_9.5.exe` (uncompressed)
3. Run setup normally

### Verify the compressed file

**Linux/macOS:**
```bash
tar -tzf AdobeReader_9.5.tar.gz
```

**Windows (Git Bash):**
```bash
tar -tzf AdobeReader_9.5.tar.gz
```

Should show: `AdobeReader_9.5.exe`
