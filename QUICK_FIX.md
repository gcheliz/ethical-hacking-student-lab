# Quick Fix: Skip tar.gz and Use Direct Installer

The tar.gz extraction is causing issues. Here's the fastest way to proceed:

## Option 1: Download and Use Directly (Fastest)

1. **Download Adobe Reader:**
   ```powershell
   .\download-adobe-retry.ps1
   ```

2. **Verify it downloaded correctly:**
   ```powershell
   Get-Item resources\AdobeReader_9.5.exe | Select-Object Name, @{Name="SizeMB";Expression={[math]::Round($_.Length / 1MB, 2)}}
   ```

   Should show approximately 50MB.

3. **Run setup:**
   ```powershell
   .\setup.ps1
   ```

If the download keeps giving you 33MB files, use Option 2.

## Option 2: Manual Download

1. **Download from OldVersion.com:**
   - Go to: https://www.oldversion.com/windows/adobe-reader-9-5-0
   - Click "Download Adobe Reader 9.5.0"
   - Save as `AdobeReader_9.5.exe` in the `resources` folder

2. **Or download from FileHippo:**
   - Go to: https://filehippo.com/download_adobe-reader/9.5.0/
   - Download and rename to `AdobeReader_9.5.exe`
   - Move to `resources` folder

3. **Verify size:**
   ```powershell
   Get-Item resources\AdobeReader_9.5.exe | Select-Object Name, @{Name="SizeMB";Expression={[math]::Round($_.Length / 1MB, 2)}}
   ```

4. **Run setup:**
   ```powershell
   .\setup.ps1
   ```

## Option 3: Create tar.gz Properly (For Repository)

If you successfully downloaded the 50MB file and want to create the tar.gz:

**Using Git Bash:**
```bash
cd resources
tar -czf AdobeReader_9.5.tar.gz AdobeReader_9.5.exe
cd ..
```

**Using 7-Zip:**
```powershell
cd resources
& "C:\Program Files\7-Zip\7z.exe" a -tgzip AdobeReader_9.5.tar.gz AdobeReader_9.5.exe
cd ..
```

**Verify the archive:**
```powershell
.\diagnose-adobe.ps1
```

---

## Why tar.gz Keeps Failing

Your current `resources\AdobeReader_9.5.tar.gz` is **empty or corrupted**. The archive shows no files inside when we try to list its contents.

**Most common causes:**
1. Created empty tar.gz file manually without adding the .exe
2. Compressed the wrong file or directory
3. Used Windows Compress-Archive which creates .zip, not .tar.gz

**The solution:** Use Option 1 or 2 above to just download and use the installer directly. The setup.ps1 script will work with the .exe file already present.
