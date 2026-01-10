# Ethical Hacking Lab - HTA Exploit

**Social Engineering Lab Environment for Students**

[![License](https://img.shields.io/badge/license-Educational-blue.svg)](LICENSE)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-7.0+-blue.svg)](https://www.virtualbox.org/)
[![Vagrant](https://img.shields.io/badge/Vagrant-2.3+-blue.svg)](https://www.vagrantup.com/)

---

## Overview

This repository provides a **fully automated, local ethical hacking lab** that demonstrates social engineering attacks using malicious HTML Application (HTA) files disguised as PDF documents. Students can set up a complete penetration testing environment in **under 30 minutes** with a single command.

### What You'll Learn

- Social engineering attack techniques
- HTA (HTML Application) file exploitation
- PowerShell-based payload delivery
- Metasploit Framework usage
- Post-exploitation with Meterpreter
- Network security concepts
- Defensive security principles
- User awareness importance

---

## Quick Start

### One-Command Setup

**For macOS/Linux:**
```bash
# Clone the repository
git clone https://github.com/gcheliz/ethical-hacking-student-lab.git
cd ethical-hacking-student-lab

# Run automated setup (15-30 minutes)
./setup.sh
```

**For Windows (PowerShell):**
```powershell
# Clone the repository
git clone https://github.com/gcheliz/ethical-hacking-student-lab.git
cd ethical-hacking-student-lab

# Run automated setup (15-30 minutes)
.\setup.ps1
```

### Run Your First Attack

```bash
# 1. Access Kali Linux
cd vagrant
vagrant ssh kali

# 2. Generate exploit payloads
cd /vagrant/exploits/hta
./create_exe_payload.sh

# 3. Start the attack (Metasploit listener + HTTP server)
./start_hta_attack.sh

# 4. On Windows VM, double-click: "Download_Exploit_from_Kali"
# 5. When downloaded, double-click the file
# 6. Get Meterpreter shell!
```

### Using Meterpreter

Once you have a session:
```bash
meterpreter > sysinfo         # System information
meterpreter > getuid          # Current user
meterpreter > screenshot      # Capture screen
meterpreter > shell           # Windows command prompt
```

See [METERPRETER_USAGE_GUIDE.md](docs/METERPRETER_USAGE_GUIDE.md) for complete usage.

### Reset When Done

```bash
./reset.sh
```

---

## Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Windows 10, macOS 10.15, Ubuntu 20.04 | Windows 11, macOS 13+, Ubuntu 22.04 |
| **CPU** | VT-x/AMD-V enabled | 4+ cores |
| **RAM** | 8 GB | 16 GB |
| **Disk** | 40 GB free | 60 GB free (SSD) |
| **Software** | VirtualBox 7.0+, Vagrant 2.3+ | Latest versions |

---

## What Gets Installed

### Virtual Machines

| VM | IP | Role | Software | Resources |
|----|-----|------|----------|-----------|
| **Kali Linux** | 192.168.56.101 | Attacker | Metasploit, msfvenom | 3GB RAM, 2 CPU |
| **Windows Server 2008 R2** | 192.168.56.102 | Target | Security Disabled | 4GB RAM, 2 CPU |

### Network Configuration

- **Network Type**: Host-Only (192.168.56.0/24) + NAT
- **Kali**: 192.168.56.101 (attacker machine)
- **Windows**: 192.168.56.102 (target machine)
- **Isolation**: Fully isolated from your host network
- **Internet**: Both VMs can access internet via NAT

---

## How the Attack Works

### Attack Flow Diagram

```
┌─────────────────┐      1. Generate       ┌────────────────┐
│   Kali Linux    │◄────   Exploit    ─────┤   msfvenom     │
│ 192.168.56.101  │                         └────────────────┘
└────────┬────────┘
         │ 2. HTTP Server
         │    (port 8080)
         │    Serves:
         │    - update.exe (Meterpreter)
         │    - HTA files
         │
         │ 3. Download
         ▼
┌─────────────────┐
│  Windows Target │  4. User Opens HTA
│ 192.168.56.102  │  5. Downloads update.exe
└─────────────────┘  6. Executes payload
         │
         │ 7. Reverse Connection
         │    (port 4444)
         │
         ▼
┌─────────────────┐
│  Meterpreter    │  8. Remote Access!
│    Session      │
└─────────────────┘
```

### Technical Details

1. **Payload Generation**: msfvenom creates Meterpreter EXE
2. **HTA File**: VBScript downloads and executes EXE
3. **Social Engineering**: File disguised as PDF report
4. **Execution**: Hidden PowerShell downloads EXE
5. **Connection**: Meterpreter reverse TCP to Kali

### Why HTA + EXE?

| Method | Reliability |
|--------|-------------|
| In-memory PowerShell shellcode | ✗ Crashes on PowerShell 2.0 |
| **HTA + EXE Download** | **✓ Works on all Windows versions** |

---

## Lab Structure

```
ethical-hacking-student-lab/
├── vagrant/
│   ├── Vagrantfile              # VM configuration
│   └── provisioning/
│       ├── kali/                # Kali setup scripts
│       └── windows/             # Windows setup scripts
├── exploits/
│   └── hta/                     # HTA exploit files
│       ├── create_exe_payload.sh
│       ├── start_hta_attack.sh
│       └── download_hta_powershell.ps1
├── docs/
│   ├── LEARNING_OBJECTIVES.md
│   └── METERPRETER_USAGE_GUIDE.md
└── README.md
```

---

## Learning Objectives

See [LEARNING_OBJECTIVES.md](docs/LEARNING_OBJECTIVES.md) for detailed educational goals.

### Skills Developed

**Offensive Skills:**
- Social engineering techniques
- Payload generation with msfvenom
- Metasploit Framework usage
- Post-exploitation techniques

**Defensive Skills:**
- Attack detection and prevention
- Security hardening
- User awareness training
- Incident response

---

## Safety and Ethics

### Built-in Safety Features

- **Network Isolation**: VMs cannot access your host network
- **Local Only**: Everything runs on your machine
- **No Internet Attacks**: Lab is completely local
- **Easy Cleanup**: One command destroys everything

### Ethical Usage

This lab is for **educational purposes only**. Students must:

- ✓ Only use in isolated lab environment
- ✓ Understand legal implications
- ✓ Practice responsible disclosure
- ✓ Respect privacy and security

**Unauthorized access to computer systems is illegal**. This lab teaches defensive security through understanding offensive techniques.

---

## Troubleshooting

### VMs won't start
```bash
# Check VirtualBox installation
VBoxManage --version

# Check Vagrant
vagrant --version

# Check virtualization support
# macOS: sysctl kern.hv_support
# Linux: grep -E 'vmx|svm' /proc/cpuinfo
# Windows: Get-ComputerInfo | Select HyperVisor*
```

### Network issues
```bash
# On Windows VM, test connectivity:
ping 192.168.56.101

# On Kali, check HTTP server:
systemctl status hta-http-server
curl http://192.168.56.101:8080/
```

### Meterpreter doesn't connect
```bash
# Verify listener is running
# On Kali, in Metasploit:
msf6 > jobs

# Check firewall (should be disabled in lab)
# On Windows VM:
netsh advfirewall show allprofiles
```

---

## Documentation

- [HTA Exploit README](exploits/hta/README.md) - Detailed exploit workflow
- [Meterpreter Usage Guide](docs/METERPRETER_USAGE_GUIDE.md) - Post-exploitation commands
- [Learning Objectives](docs/LEARNING_OBJECTIVES.md) - Educational goals

---

## Credits

**Lab Author:** Gonzalo Cheliz

**Based On:**
- Rapid7 Metasploitable3
- MITRE ATT&CK Framework
- Real-world APT campaigns

**Technologies:**
- Metasploit Framework (Rapid7)
- VirtualBox (Oracle)
- Vagrant (HashiCorp)

---

## License

This project is released for **educational purposes only**. See [LICENSE](LICENSE) for details.

**Disclaimer:** The author is not responsible for any misuse of this educational material. Users are responsible for complying with all applicable laws and regulations.

---

## Support

**Issues:** https://github.com/gcheliz/ethical-hacking-student-lab/issues

**Pull Requests:** Contributions welcome!

---

## MITRE ATT&CK Mapping

| Technique | ID | Description |
|-----------|-----|-------------|
| Mshta | T1218.005 | Execute HTA files via mshta.exe |
| User Execution | T1204.002 | Malicious file execution |
| Ingress Tool Transfer | T1105 | Download payload from external system |
| Command and Scripting Interpreter | T1059.001 | PowerShell execution |
| Obfuscated Files or Information | T1027 | Hide malicious payload |

---

**Remember: With great power comes great responsibility. Use your skills for good!**
