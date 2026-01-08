# Quick Fix: Adobe Reader Download Failed

The automatic download of Adobe Reader 9.5.0 failed. Here's how to fix it:

---

## ⚡ Quick Solution

### Step 1: Download Manually

**Choose ONE of these sources:**

**Option A - Internet Archive (Recommended):**
```
https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe
```

**Option B - OldVersion.com:**
1. Visit: http://www.oldversion.com/windows/adobe-reader-9-5-0
2. Click "Download Adobe Reader 9.5.0"

**Option C - FileHorse:**
1. Visit: https://www.filehorse.com/download-adobe-reader/old-versions/
2. Find version 9.5.0
3. Download

### Step 2: Save the File

1. After downloading, **rename** the file to: `AdobeReader_9.5.exe`
2. **Move** it to: `resources\AdobeReader_9.5.exe`
3. **Verify** the file size is approximately **50MB** (not 32MB)

### Step 3: Continue Setup

Run the setup script again:
```powershell
.\setup.ps1
```

---

## 🔍 Why Did This Happen?

The automatic download failed because:
- Adobe FTP servers may have rate limiting
- Network firewall blocking the download
- The file URL changed or is temporarily unavailable
- Download was interrupted

File size should be ~50MB. If you got 32MB, the download was incomplete.

---

## ✅ Verify Your Download

Before continuing, check:
```powershell
Get-Item resources\AdobeReader_9.5.exe | Select-Object Length, Name
```

You should see:
- **Length:** Around 52,428,800 bytes (50MB)
- **Name:** AdobeReader_9.5.exe

If the size is wrong, delete and download again.

---

## 🚀 Alternative: Use Download Script

We've created a PowerShell script with better download handling:

```powershell
.\resources\download_adobe.ps1
```

This script tries multiple mirrors with progress bars.

---

## 💡 Still Having Issues?

If you can't download Adobe Reader:

1. **Check your internet connection**
2. **Disable VPN** (may block downloads)
3. **Temporarily disable antivirus** (may quarantine installer)
4. **Try from a different network**
5. **Ask your instructor** for a copy

---

## ⚠️ Important

Make sure you download the **exact version: 9.5.0**

Other versions will NOT work with the exploit!

---

Once you have the file in place, run `.\setup.ps1` and it will continue from where it left off! 🎯
