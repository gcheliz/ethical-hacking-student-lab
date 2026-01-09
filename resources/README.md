# Resources Directory

This directory contains the Adobe Reader 9.5.0 installer required for the lab.

## For Repository Maintainers

### Creating the ZIP file

The Adobe Reader installer should be compressed and committed to the repository:

**On Windows (PowerShell):**
```powershell
# Step 1: Obtain Adobe Reader 9.5.0 (50MB file)
# Download from: https://www.oldversion.com/windows/adobe-reader-9-5-0

# Step 2: Rename the file
Rename-Item "AdbeRdr950_en_US.exe" "AdobeReader_9.5.exe"

# Step 3: Verify size (should be ~50MB)
Get-Item AdobeReader_9.5.exe | Select-Object Name, @{Name="SizeMB";Expression={[math]::Round($_.Length / 1MB, 2)}}

# Step 4: Compress with ZIP
Compress-Archive -Path AdobeReader_9.5.exe -DestinationPath AdobeReader_9.5.zip -CompressionLevel Optimal

# Step 5: Move to resources folder
Move-Item AdobeReader_9.5.zip resources\

# Step 6: Add to git
git add resources/AdobeReader_9.5.zip
git commit -m "Add Adobe Reader 9.5.0 installer (zipped)"
git push
```

**On Linux/macOS:**
```bash
# Step 1: Obtain Adobe Reader 9.5.0 (50MB file)
# Download from: https://www.oldversion.com/windows/adobe-reader-9-5-0

# Step 2: Rename the file
mv AdbeRdr950_en_US.exe AdobeReader_9.5.exe

# Step 3: Verify size (should be ~52MB)
ls -lh AdobeReader_9.5.exe

# Step 4: Compress with ZIP
zip AdobeReader_9.5.zip AdobeReader_9.5.exe

# Step 5: Move to resources folder
mv AdobeReader_9.5.zip resources/

# Step 6: Add to git
git add resources/AdobeReader_9.5.zip
git commit -m "Add Adobe Reader 9.5.0 installer (zipped)"
git push
```

### File Details

- **Original File:** AdbeRdr950_en_US.exe
- **Renamed To:** AdobeReader_9.5.exe
- **Size:** ~52,428,800 bytes (50 MB)
- **Compressed:** AdobeReader_9.5.zip (~40-45 MB)

**Important:** The uncompressed .exe file is ignored by git (see .gitignore). Only the .zip file should be committed.

## For Students

**You don't need to do anything!**

The setup script (`setup.ps1` or `setup.sh`) will automatically extract the installer from `AdobeReader_9.5.zip` when you run it.

The extraction process:
1. Setup script checks for `resources/AdobeReader_9.5.zip`
2. Extracts the .exe file to `resources/AdobeReader_9.5.exe`
3. Verifies the file is approximately 50MB
4. Continues with lab setup

## Troubleshooting

### If AdobeReader_9.5.zip is missing

**Error you'll see:**
```
[ERROR] Adobe Reader ZIP archive not found!
The file resources\AdobeReader_9.5.zip is missing.
```

**Solution:**
Contact your instructor to obtain the `AdobeReader_9.5.zip` file.

### Verify the ZIP file

**Windows:**
```powershell
# Check if file exists
Test-Path resources\AdobeReader_9.5.zip

# Check file size
Get-Item resources\AdobeReader_9.5.zip | Select-Object Name, @{Name="SizeMB";Expression={[math]::Round($_.Length / 1MB, 2)}}

# Test extraction
Expand-Archive -Path resources\AdobeReader_9.5.zip -DestinationPath test-extract -Force
Get-ChildItem test-extract
Remove-Item test-extract -Recurse -Force
```

**Linux/macOS:**
```bash
# Check if file exists
ls -lh resources/AdobeReader_9.5.zip

# Test the ZIP integrity
unzip -t resources/AdobeReader_9.5.zip

# View contents without extracting
unzip -l resources/AdobeReader_9.5.zip
```

Should show: `AdobeReader_9.5.exe` (or `AdbeRdr950_en_US.exe`)

### Manual Extraction (if automatic fails)

**Windows:**
1. Right-click `resources\AdobeReader_9.5.zip`
2. Select "Extract All..."
3. Extract to a temporary folder
4. Copy the .exe file to `resources\AdobeReader_9.5.exe`
5. Run `.\setup.ps1` again

**Linux/macOS:**
```bash
unzip resources/AdobeReader_9.5.zip -d temp
mv temp/*.exe resources/AdobeReader_9.5.exe
rmdir temp
./setup.sh
```

## Security Note

Adobe Reader 9.5.0 is an **intentionally vulnerable** version used for educational security demonstrations. This software should **NEVER** be used in production environments or connected to the internet.
