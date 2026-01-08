# Maintainer Setup Instructions

This guide is for repository maintainers who need to add the Adobe Reader installer to the repository.

---

## 📦 Adding Adobe Reader 9.5.0 to Repository

The Adobe Reader installer must be compressed and committed to avoid download issues.

### Step 1: Download Adobe Reader 9.5.0

**Download from a reliable source:**
- **OldVersion.com:** http://www.oldversion.com/windows/adobe-reader-9-5-0
- **Direct Link:** http://ardownload.adobe.com/pub/adobe/reader/win/9.x/9.5.0/enu/AdbeRdr950_en_US.exe

**File Details:**
- Original name: `AdbeRdr950_en_US.exe`
- Size: ~52,428,800 bytes (50 MB)
- MD5: Verify it's a complete download

### Step 2: Rename the File

```bash
mv AdbeRdr950_en_US.exe AdobeReader_9.5.exe
```

### Step 3: Compress with tar.gz

**On Linux/macOS:**
```bash
tar -czf AdobeReader_9.5.tar.gz AdobeReader_9.5.exe
```

**On Windows (Git Bash):**
```bash
tar -czf AdobeReader_9.5.tar.gz AdobeReader_9.5.exe
```

**On Windows (PowerShell with 7-Zip installed):**
```powershell
& "C:\Program Files\7-Zip\7z.exe" a -tgzip AdobeReader_9.5.tar.gz AdobeReader_9.5.exe
```

**Expected result:**
- Compressed file: `AdobeReader_9.5.tar.gz`
- Size: ~40-45 MB (compressed)

### Step 4: Move to resources folder

```bash
mv AdobeReader_9.5.tar.gz resources/
```

### Step 5: Add to Git

```bash
# Add the compressed file
git add resources/AdobeReader_9.5.tar.gz

# Commit
git commit -m "Add Adobe Reader 9.5.0 installer (compressed)"

# Push
git push origin main
```

### Step 6: Verify .gitignore

The `.gitignore` file should already contain:

```gitignore
# Adobe Reader installer (uncompressed)
resources/AdobeReader_9.5.exe

# Keep the compressed version
!resources/AdobeReader_9.5.tar.gz
```

This ensures:
- ✅ The compressed `.tar.gz` file is tracked in git
- ✅ The uncompressed `.exe` file is ignored (students extract it locally)

---

## 🔍 Verification

### Verify the tar.gz file

**Linux/macOS/Git Bash:**
```bash
tar -tzf resources/AdobeReader_9.5.tar.gz
```

**Should output:**
```
AdobeReader_9.5.exe
```

### Test Extraction

**On Windows (PowerShell):**
```powershell
cd resources
C:\Windows\System32\tar.exe -xzf AdobeReader_9.5.tar.gz
Get-Item AdobeReader_9.5.exe | Select-Object Name, Length
```

**On Linux/macOS:**
```bash
cd resources
tar -xzf AdobeReader_9.5.tar.gz
ls -lh AdobeReader_9.5.exe
```

**Expected:**
- Extracted file: `AdobeReader_9.5.exe`
- Size: ~50 MB

---

## 📚 Alternative: Using Git LFS

For better Git performance with large files, consider using Git LFS:

### Install Git LFS

```bash
# Linux
sudo apt install git-lfs

# macOS
brew install git-lfs

# Windows
# Download from: https://git-lfs.github.com/
```

### Setup Git LFS

```bash
# Initialize Git LFS
git lfs install

# Track tar.gz files
git lfs track "*.tar.gz"

# Add .gitattributes
git add .gitattributes

# Commit
git commit -m "Configure Git LFS for large files"

# Add Adobe Reader
git add resources/AdobeReader_9.5.tar.gz
git commit -m "Add Adobe Reader 9.5.0 installer via Git LFS"
git push
```

**Benefits of Git LFS:**
- Faster cloning (large files downloaded on-demand)
- Better repository performance
- Efficient storage

**Note:** Students will need Git LFS installed to clone.

---

## 🚨 Important Notes

1. **Only commit the compressed .tar.gz file** - never commit the uncompressed .exe
2. **Verify file size** - must be ~40-45 MB compressed
3. **Test extraction** - ensure students can extract on Windows 10+
4. **Update documentation** - if using Git LFS, update README.md

---

## 🔄 Updating the Installer

If Adobe Reader needs to be updated (e.g., version 9.5.1):

1. Download new version
2. Rename to match pattern: `AdobeReader_X.X.exe`
3. Compress: `tar -czf AdobeReader_X.X.tar.gz AdobeReader_X.X.exe`
4. Update setup scripts to reference new filename
5. Update Vagrantfile provisioning scripts
6. Test full setup process
7. Commit and push

---

## 📞 Support

If you encounter issues:
- Check `.gitignore` is configured correctly
- Verify tar.gz file integrity
- Test extraction on target platforms
- Consult: `resources/README.md` for details

---

**Repository is ready when:**
- ✅ `resources/AdobeReader_9.5.tar.gz` exists and is tracked
- ✅ File size is 40-45 MB (compressed)
- ✅ Extraction works on Windows 10+, Linux, macOS
- ✅ Setup scripts reference the tar.gz file
- ✅ `.gitignore` properly configured
