# Ethical Hacking Lab - HTA Exploit

**Automated penetration testing environment for students**
Set up a complete lab in under 30 minutes with one command.

[![License](https://img.shields.io/badge/license-Educational-blue.svg)](LICENSE)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-7.0+-blue.svg)](https://www.virtualbox.org/)
[![Vagrant](https://img.shields.io/badge/Vagrant-2.3+-blue.svg)](https://www.vagrantup.com/)

---

## Overview

This lab demonstrates **social engineering attacks** using malicious HTA files disguised as PDFs. Learn offensive and defensive security in a safe, isolated environment.

### Lab Architecture

```mermaid
graph LR
    Host[Your Computer] -->|VirtualBox| Kali[Kali Linux<br/>192.168.56.101<br/>Attacker]
    Host -->|VirtualBox| Windows[Windows Server 2008<br/>192.168.56.102<br/>Target]
    Kali <-->|Host-Only Network<br/>192.168.56.0/24| Windows

    style Kali fill:#2ea44f,color:#fff
    style Windows fill:#e74c3c,color:#fff
    style Host fill:#3498db,color:#fff
```

### Attack Workflow

```mermaid
flowchart TB
    A[Attacker: Kali Linux] -->|1. Generate| B[Meterpreter EXE]
    A -->|2. Create| C[Malicious HTA File]
    A -->|3. Host on| D[HTTP Server :8080]
    A -->|4. Start| E[Metasploit Listener :4444]

    F[Victim: Windows] -->|5. Downloads| C
    C -->|6. Executes VBScript| G[Downloads update.exe]
    G -->|7. Runs EXE| H[Meterpreter Payload]
    H -->|8. Connects Back| E
    E -->|9. Session Opened| I[Remote Access!]

    style A fill:#2ea44f,color:#fff
    style F fill:#e74c3c,color:#fff
    style I fill:#f39c12,color:#fff
```

---

## Quick Start

### Prerequisites

| Component | Minimum |
|-----------|---------|
| **OS** | Windows 10, macOS 10.15, Ubuntu 20.04 |
| **CPU** | VT-x/AMD-V enabled, 2+ cores |
| **RAM** | 8 GB |
| **Disk** | 40 GB free |
| **Software** | VirtualBox 7.0+, Vagrant 2.3+ |

### Installation

**macOS/Linux:**
```bash
git clone https://github.com/gcheliz/ethical-hacking-student-lab.git
cd ethical-hacking-student-lab
./setup.sh
```

**Windows (PowerShell as Administrator):**
```powershell
git clone https://github.com/gcheliz/ethical-hacking-student-lab.git
cd ethical-hacking-student-lab
.\setup.ps1
```

Setup takes 15-30 minutes and is fully automated.

### First Attack

```bash
# 1. Access Kali
cd vagrant && vagrant ssh kali

# 2. Start attack
cd /vagrant/exploits/hta
./start_hta_attack.sh

# 3. On Windows VM: Double-click "Download_Exploit_from_Kali"
# 4. Double-click downloaded file → Get Meterpreter session!
```

### Basic Meterpreter Commands

```bash
meterpreter> sysinfo        # System info
meterpreter> getuid         # Current user
meterpreter> screenshot     # Capture screen
meterpreter> shell          # Windows command prompt
meterpreter> help           # All commands
```

### Reset Lab

```bash
./reset.sh    # Restore VMs to clean state (30 seconds)
```

---

## Documentation Map

```mermaid
graph TD
    START[START HERE<br/>README.md] --> SETUP{Need to install?}
    SETUP -->|Yes| INSTALL[INSTALLATION.md<br/>Step-by-step setup]
    SETUP -->|No| ATTACK[docs/USER_GUIDE.md<br/>How to run attacks]

    INSTALL --> ATTACK
    ATTACK --> STUCK{Having issues?}
    STUCK -->|Yes| TROUBLE[TROUBLESHOOTING.md<br/>Problem solutions]
    STUCK -->|No| LEARN[docs/LEARNING_OBJECTIVES.md<br/>Educational goals]

    ATTACK --> METERPRETER[docs/METERPRETER_USAGE_GUIDE.md<br/>Command reference]
    ATTACK --> TECHNICAL[exploits/hta/README.md<br/>Technical details]

    style START fill:#2ea44f,color:#fff
    style ATTACK fill:#3498db,color:#fff
    style TROUBLE fill:#e74c3c,color:#fff
```

**Quick Links:**
- **[Installation Guide](INSTALLATION.md)** - System setup
- **[User Guide](docs/USER_GUIDE.md)** - Attack scenarios and usage
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues
- **[Meterpreter Commands](docs/METERPRETER_USAGE_GUIDE.md)** - Post-exploitation reference
- **[Learning Objectives](docs/LEARNING_OBJECTIVES.md)** - Educational outcomes
- **[Technical Details](exploits/hta/README.md)** - HTA exploit deep-dive

---

## What You'll Learn

| Category | Skills |
|----------|--------|
| **Offensive** | Social engineering, HTA exploitation, Meterpreter usage, payload generation |
| **Defensive** | Security controls, attack detection, incident response, user awareness |
| **Tools** | Metasploit Framework, VirtualBox, Vagrant, Kali Linux |
| **Concepts** | Reverse shells, network isolation, post-exploitation, MITRE ATT&CK |

---

## Lab Components

### Virtual Machines

| VM | OS | IP | Role | Security |
|----|----|----|------|----------|
| **kali** | Kali Linux 2024 | 192.168.56.101 | Attacker | Metasploit, HTTP server |
| **win2k8** | Windows Server 2008 R2 | 192.168.56.102 | Target | All defenses disabled |

### Generated Exploit Files

| File | Type | Purpose |
|------|------|---------|
| `update.exe` | EXE (73KB) | Meterpreter reverse TCP payload |
| `Joan_Espinach_hta_social_engineering.pdf.hta` | HTA | VBScript that downloads + executes EXE |

### Network Configuration

```mermaid
graph LR
    subgraph "Host-Only Network: 192.168.56.0/24"
        K[Kali<br/>192.168.56.101] <-->|Isolated| W[Windows<br/>192.168.56.102]
    end

    subgraph "NAT Network (Internet)"
        K -->|Provisioning Only| Internet[Internet]
        W -->|Provisioning Only| Internet
    end

    style K fill:#2ea44f,color:#fff
    style W fill:#e74c3c,color:#fff
```

---

## Safety and Ethics

This lab is for **authorized educational purposes only**.

| Do | Don't |
|----|-------|
| Use in isolated lab environment | Attack real systems without authorization |
| Learn offensive AND defensive techniques | Share exploits for malicious purposes |
| Practice responsible disclosure | Bypass security without permission |
| Follow lab ethical guidelines | Violate computer fraud laws |

**Legal:** Unauthorized computer access is illegal (CFAA, Computer Misuse Act, etc.). Use only in controlled educational settings.

---

## MITRE ATT&CK Mapping

| Technique | ID | Lab Coverage |
|-----------|----|----|
| User Execution: Malicious File | T1204.002 | HTA file execution |
| Mshta | T1218.005 | HTA application abuse |
| Command and Scripting Interpreter: PowerShell | T1059.001 | Download + execute |
| Ingress Tool Transfer | T1105 | EXE download from HTTP |
| Application Layer Protocol | T1071 | HTTP for C2 communication |

---

## Troubleshooting

### Quick Diagnostics

```mermaid
graph TD
    START{Problem?} -->|Setup fails| SETUP[Check: VT-x enabled<br/>Disk space 40GB+<br/>RAM 8GB+]
    START -->|VMs can't communicate| NETWORK[Check: Host-Only network exists<br/>IPs: 192.168.56.101/102<br/>Ping test]
    START -->|HTA doesn't work| HTA[Check: HTTP server running<br/>update.exe exists<br/>Windows firewall off]
    START -->|No Meterpreter session| METERPRETER[Check: Listener on :4444<br/>Network connectivity<br/>Payload executed]

    SETUP --> DOC[See: TROUBLESHOOTING.md]
    NETWORK --> DOC
    HTA --> DOC
    METERPRETER --> DOC

    style START fill:#3498db,color:#fff
    style DOC fill:#2ea44f,color:#fff
```

**Common Fixes:**
- **VMs won't start:** Enable VT-x/AMD-V in BIOS
- **Network issues:** Run `vagrant reload` to reset network
- **HTTP server down:** `sudo systemctl start hta-http-server` on Kali
- **Listener fails:** Check if port 4444 is available

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for comprehensive solutions.

---

## Project Structure

```
ethical-hacking-student-lab/
├── setup.sh / setup.ps1           # Automated installation
├── reset.sh / reset.ps1           # Reset VMs to clean state
├── vagrant/                       # VM configurations
│   ├── Vagrantfile               # VM definitions
│   └── provisioning/             # Automated setup scripts
├── exploits/hta/                 # HTA exploit scripts
│   ├── create_exe_payload.sh    # Generate Meterpreter EXE
│   ├── start_hta_attack.sh      # Launch attack automation
│   └── README.md                # Technical documentation
├── docs/                         # Additional documentation
│   ├── USER_GUIDE.md            # Comprehensive usage guide
│   ├── METERPRETER_USAGE_GUIDE.md  # Command reference
│   └── LEARNING_OBJECTIVES.md   # Educational outcomes
└── resources/                    # Adobe Reader installer
```

---

## Credits

Built with:
- [Kali Linux](https://www.kali.org/) - Penetration testing distribution
- [Metasploit Framework](https://www.metasploit.com/) - Exploitation framework
- [VirtualBox](https://www.virtualbox.org/) - Virtualization platform
- [Vagrant](https://www.vagrantup.com/) - VM automation

---

## License

**Educational Use Only** - See [LICENSE](LICENSE) for details.

This project is intended for authorized security training and education. The authors are not responsible for misuse or illegal activities.

---

## Support

- **Issues:** [GitHub Issues](https://github.com/gcheliz/ethical-hacking-student-lab/issues)
- **Documentation:** See [docs/](docs/) folder
- **Troubleshooting:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Version:** 2.0 - HTA Exploit Lab
**Last Updated:** 2026-01-10

**Ready to start? Run `./setup.sh` and begin learning!**
