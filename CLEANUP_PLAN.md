# Project Cleanup Plan

## Files to Remove (Duplicates/Outdated)

### 1. Duplicate/Overlapping Documentation

**exploits/README_PDF_LOCATION.md** (150 lines)
- **Why:** Explains PDF location - should be merged into exploits/README.md
- **Action:** Merge key info into README.md, then delete

### 2. Temporary Debugging Scripts (No longer needed)

**verify-files.ps1** (1.6K)
- **Why:** Created to debug missing provisioning files issue (now fixed)
- **Action:** DELETE - issue is resolved

**fix-missing-files.ps1** (7.3K)
- **Why:** Created to fix missing provisioning files (now fixed)
- **Action:** DELETE - issue is resolved

### 3. Manual Fallback Scripts (Redundant if automated setup works)

**exploits/manual_pdf_setup.sh**
- **Why:** Manual PDF generation - redundant if create_exploits.sh works
- **Action:** DELETE or keep as emergency backup?

**exploits/MANUAL_COPY_PDFS.ps1**
- **Why:** Manual PDF copying - redundant if copy_pdfs_to_desktop.ps1 works
- **Action:** DELETE or keep as emergency backup?

**exploits/diagnose_pdf_generation.sh**
- **Why:** PDF generation diagnostics - useful for troubleshooting
- **Action:** KEEP - still useful for debugging

## Files to Keep (Still Useful)

**windows-troubleshoot.ps1** - PowerShell 2.0 compatible diagnostic
- Actively useful for users troubleshooting exploit issues

**cleanup-vbox.ps1** - VirtualBox VM cleanup
- Different from cleanup.ps1 - fixes VM name conflicts

**cleanup.ps1 / cleanup.sh** - Platform-specific cleanup
- Both needed (Windows vs Linux)

**TROUBLESHOOTING.md** - General troubleshooting
- Keep - general lab issues

**TROUBLESHOOT_EXPLOIT.md** - Exploit-specific troubleshooting
- Keep - PDF exploit specific issues

**KALI_SSH_ISSUES.md** - Kali SSH issues
- Keep - specific to Kali boot problems

## Recommended Actions

### High Priority - Remove Now
1. ❌ DELETE: verify-files.ps1
2. ❌ DELETE: fix-missing-files.ps1
3. ❌ DELETE: exploits/README_PDF_LOCATION.md (merge into README.md first)

### Medium Priority - Consider Removal
4. ⚠️ REVIEW: exploits/manual_pdf_setup.sh
5. ⚠️ REVIEW: exploits/MANUAL_COPY_PDFS.ps1

### Keep - Still Useful
✅ ALL troubleshooting scripts in root
✅ ALL cleanup scripts
✅ windows-troubleshoot.ps1
✅ exploits/diagnose_pdf_generation.sh
✅ exploits/check_network.sh

## Summary

**Total files to delete:** 3 confirmed + 2 optional
**Space saved:** ~12KB documentation + ~9KB scripts
**Result:** Cleaner, more maintainable project structure
