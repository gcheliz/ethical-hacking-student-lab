# Resources Directory

This directory contains the Adobe Reader 9.5.0 installer required for PDF icon social engineering.

## For Repository Maintainers

### Creating the ZIP file

The Adobe Reader installer should be compressed and added to the repository:

**On Windows (PowerShell):**
```powershell
# Step 1: Download Adobe Reader 9.5.0 (~50MB)
# Source: https://www.oldversion.com/windows/adobe-reader-9-5-0
# Or: https://www.adobe.com/support/downloads/product.jsp?product=10&platform=Windows

# Step 2: Rename the file
Rename-Item "AdbeRdr950_en_US.exe" "AdobeReader_9.5.exe"

# Step 3: Verify size (should be ~50MB)
Get-Item AdobeReader_9.5.exe | Select-Object Name, @{Name="SizeMB";Expression={[math]::Round($_.Length / 1MB, 2)}}

# Step 4: Compress with ZIP
Compress-Archive -Path AdobeReader_9.5.exe -DestinationPath AdobeReader_9.5.zip -CompressionLevel Optimal

# Step 5: Move to resources folder
Move-Item AdobeReader_9.5.zip ..\resources\

# Step 6: Add to git
git add resources/AdobeReader_9.5.zip
git commit -m "Add Adobe Reader 9.5.0 installer (zipped)"
git push
```

**On Linux/macOS:**
```bash
# Step 1: Download Adobe Reader 9.5.0 (~50MB)
# Source: https://www.oldversion.com/windows/adobe-reader-9-5-0

# Step 2: Rename the file
mv AdbeRdr950_en_US.exe AdobeReader_9.5.exe

# Step 3: Verify size (should be ~52MB)
ls -lh AdobeReader_9.5.exe

# Step 4: Compress with ZIP
zip AdobeReader_9.5.zip AdobeReader_9.5.exe

# Step 5: Move to resources folder
mv AdobeReader_9.5.zip ../resources/

# Step 6: Add to git
git add resources/AdobeReader_9.5.zip
git commit -m "Add Adobe Reader 9.5.0 installer (zipped)"
git push
```

### File Details

- **Original File:** AdbeRdr950_en_US.exe
- **Renamed To:** AdobeReader_9.5.exe
- **Size:** ~52,428,800 bytes (50 MB uncompressed)
- **Compressed:** AdobeReader_9.5.zip (~40-45 MB)

**Important:** Only the .zip file should be committed to the repository.

## For Students

### If AdobeReader_9.5.zip is Missing

During provisioning, you may see:
```
[WARNING] Adobe Reader ZIP not found
HTA files will use default Windows document icon
```

This is **not a critical error**. The lab will work, but:
- Malicious HTA files will show Windows document icon instead of PDF icon
- Social engineering is slightly less convincing

**To add PDF icon support:**
1. Contact your instructor for the `AdobeReader_9.5.zip` file
2. Place it in the `resources/` folder
3. Reprovision Windows VM:
   ```bash
   cd vagrant
   vagrant provision win2k8
   ```

### Verify the ZIP file

**Windows:**
```powershell
# Check if file exists
Test-Path resources\AdobeReader_9.5.zip

# Check file size (should be ~40-45 MB)
Get-Item resources\AdobeReader_9.5.zip | Select-Object Name, @{Name="SizeMB";Expression={[math]::Round($_.Length / 1MB, 2)}}
```

**Linux/macOS:**
```bash
# Check if file exists and size
ls -lh resources/AdobeReader_9.5.zip

# Test ZIP integrity
unzip -t resources/AdobeReader_9.5.zip

# View contents
unzip -l resources/AdobeReader_9.5.zip
```

Should show: `AdobeReader_9.5.exe` (approximately 50 MB)

## Why Adobe Reader 9.5.0?

1. **PDF Icon:** Provides authentic Adobe PDF icon for social engineering
2. **Vulnerability:** Intentionally outdated version for security demonstrations
3. **Lab Purpose:** Teaches students to recognize social engineering attacks

## Security Note

Adobe Reader 9.5.0 is an **intentionally vulnerable** version used for educational security demonstrations.

**Never use this in production or connect to the internet!**

This software has known security vulnerabilities and should only be used in isolated lab environments for educational purposes.

## Troubleshooting

### Extraction fails during provisioning

If you see errors during Windows provisioning:
1. Verify ZIP file is not corrupted:
   ```powershell
   # Windows
   Test-Path resources\AdobeReader_9.5.zip
   ```
2. Try manual extraction to test:
   ```powershell
   # Windows
   Expand-Archive resources\AdobeReader_9.5.zip -DestinationPath temp
   Get-ChildItem temp
   Remove-Item temp -Recurse
   ```

3. If corrupted, re-download and recreate the ZIP file

### Adobe won't install

The script is designed to continue even if Adobe installation fails. You'll see:
```
[WARNING] Installation failed
```

**This is OK!** The lab will work with the default Windows document icon instead of the PDF icon.

## Alternative: Skip Adobe Installation

If you don't have the Adobe installer:
1. Lab works fine without it
2. Use Windows built-in document icon (shell32.dll,70)
3. Social engineering is slightly less convincing but still effective
