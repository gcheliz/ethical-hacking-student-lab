# Resources Directory

Contains Adobe Reader 9.5.0 installer for PDF icon social engineering.

---

## Contents

| File | Size | Purpose |
|------|------|---------|
| `AdobeReader_9.5.zip` | ~32 MB | Compressed Adobe Reader 9.5.0 installer |

---

## For Students

### If AdobeReader_9.5.zip is Missing

You may see during setup:
```
[WARNING] Adobe Reader ZIP not found
HTA files will use default Windows document icon
```

**This is OK!** The lab works fine without it:
- ✅ Exploit functions normally
- ❌ HTA files show Windows doc icon instead of PDF icon
- ⚠️ Social engineering slightly less convincing

**To add PDF icon support:**
1. Get `AdobeReader_9.5.zip` from instructor
2. Place in `resources/` folder
3. Reprovision: `cd vagrant && vagrant provision win2k8`

---

## For Repository Maintainers

### Creating the ZIP File

**Download:**
- Source: https://www.oldversion.com/windows/adobe-reader-9-5-0
- File: `AdbeRdr950_en_US.exe` (~50 MB)

**Prepare:**

| Platform | Commands |
|----------|----------|
| **Windows** | `Rename-Item AdbeRdr950_en_US.exe AdobeReader_9.5.exe`<br/>`Compress-Archive AdobeReader_9.5.exe AdobeReader_9.5.zip` |
| **Linux/macOS** | `mv AdbeRdr950_en_US.exe AdobeReader_9.5.exe`<br/>`zip AdobeReader_9.5.zip AdobeReader_9.5.exe` |

**Commit:**
```bash
git add resources/AdobeReader_9.5.zip
git commit -m "Add Adobe Reader 9.5.0 installer"
git push
```

### File Specifications

| Property | Value |
|----------|-------|
| Original filename | AdbeRdr950_en_US.exe |
| Renamed to | AdobeReader_9.5.exe |
| Uncompressed size | ~50 MB |
| Compressed size | ~32 MB |
| Format | ZIP archive |

---

## Why Adobe Reader 9.5.0?

| Reason | Explanation |
|--------|-------------|
| **Authentic PDF icon** | Provides red Adobe PDF icon for realistic social engineering |
| **Intentionally outdated** | Version from 2010 with known vulnerabilities (educational) |
| **Lab safety** | Old version ensures no accidental production use |

---

## Security Warning

⚠️ **Adobe Reader 9.5.0 is intentionally vulnerable** (2010 version with known CVEs)

**Use ONLY in isolated lab environments. Never:**
- Install on production systems
- Connect to the internet
- Use for real PDF viewing

This is for **security education only**.

---

## Troubleshooting

### Verify ZIP File

**Windows:**
```powershell
Test-Path resources\AdobeReader_9.5.zip
Get-Item resources\AdobeReader_9.5.zip | Select-Object Name, Length
```

**Linux/macOS:**
```bash
ls -lh resources/AdobeReader_9.5.zip
unzip -t resources/AdobeReader_9.5.zip  # Test integrity
```

### Installation Fails

If Adobe won't install, provisioning continues with warning. Lab works normally with Windows document icon instead of PDF icon.

**No action needed** - exploit still functions.

---

**Version:** 2.0 - HTA Exploit Lab
