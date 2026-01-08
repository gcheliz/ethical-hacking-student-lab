# Quick Start Guide
## Ethical Hacking PDF Exploit Lab

**Time to complete: 5 minutes**

---

## Prerequisites

Before starting, ensure you have:

- ✅ VirtualBox 7.0+ installed
- ✅ Vagrant 2.3+ installed
- ✅ 40GB free disk space
- ✅ 8GB RAM (16GB recommended)

---

## Setup (One Command)

**For Windows (PowerShell):**
```powershell
git clone https://github.com/your-org/ethical-hacking-pdf-lab.git
cd ethical-hacking-pdf-lab
.\setup.ps1
```

**For Linux/macOS (Bash):**
```bash
git clone https://github.com/your-org/ethical-hacking-pdf-lab.git
cd ethical-hacking-pdf-lab
./setup.sh
```

**Wait 15-30 minutes for setup to complete.**

---

## Quick Attack Demonstration

### Step 1: Access Kali Linux

```bash
cd vagrant
vagrant ssh kali
```

### Step 2: Start the Attack

```bash
cd /vagrant/exploits
./start_attack.sh
```

This will:
- Start a Metasploit listener on port 4444
- Wait for the victim to open the PDF

### Step 3: Open PDF on Windows

1. Access Windows VM:
   - VirtualBox window should be open
   - Or run: `vagrant rdp win2k8`

2. On Windows Desktop:
   - Navigate to: `C:\vagrant\exploits`
   - Find: `JOAN-ESPINACH-TRD.pdf`
   - Double-click to open with Adobe Reader

### Step 4: Get Meterpreter Shell

Back in Kali terminal, you should see:

```
[*] Meterpreter session 1 opened
meterpreter >
```

### Step 5: Try These Commands

```bash
sysinfo              # System information
getuid               # Current user
screenshot           # Take a screenshot
shell                # Get Windows command shell
```

---

## Reset Lab (30 seconds)

**Windows:**
```powershell
.\reset.ps1
```

**Linux/macOS:**
```bash
./reset.sh
```

This restores both VMs to clean state.

---

## Complete Cleanup

**Windows:** `.\cleanup.ps1`
**Linux/macOS:** `./cleanup.sh`

This removes all VMs and frees disk space.

---

## Troubleshooting

### VMs won't start
```bash
# Check VirtualBox is running
VBoxManage --version

# Check Vagrant status
cd vagrant
vagrant status
```

### Network issues
```bash
# Test connectivity from Kali
vagrant ssh kali
ping 192.168.56.102
```

### PDF exploit doesn't work
```bash
# Regenerate PDFs
vagrant ssh kali
cd /vagrant/exploits
./generate_pdf.sh
```

---

## IP Address Reference

| System | IP Address | Credentials |
|--------|------------|-------------|
| Kali Linux | 192.168.56.101 | vagrant / vagrant |
| Windows Server | 192.168.56.102 | vagrant / vagrant |

---

## Next Steps

1. Read the full **LAB_GUIDE.pdf** for detailed explanations
2. Review **LEARNING_OBJECTIVES.md** for educational goals
3. Check **TROUBLESHOOTING.md** for common issues

---

## Safety Reminder

⚠️ **This lab is for educational purposes only!**

- Only use in isolated lab environment
- Never test on systems you don't own
- Understand the ethics of penetration testing

---

**Need Help?**

See: `TROUBLESHOOTING.md` or `docs/INSTRUCTOR_GUIDE.pdf`
