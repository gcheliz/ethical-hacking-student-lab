# Kali SSH Connection Issues - Troubleshooting

## Problem
Vagrant keeps retrying SSH connection to Kali VM:
```
kali: Warning: Connection reset. Retrying...
kali: Warning: Connection aborted. Retrying...
```

This usually means the VM is booting but SSH isn't ready yet.

---

## Quick Fixes (Try in Order)

### Fix 1: Wait It Out (Most Common)
The SSH timeouts have been increased to 15 minutes. **Just let it run** - Kali can take 5-10 minutes to fully boot the first time.

**What's happening:**
- VM is downloading packages
- SSH service is starting
- Network is configuring

**Be patient!** It will eventually connect.

---

### Fix 2: Enable GUI to See What's Happening

Edit `vagrant/Vagrantfile`:

```ruby
# Change this line:
vb.gui = false  # Headless (use SSH)

# To this:
vb.gui = true  # Show GUI to debug
```

Then restart:
```bash
vagrant reload kali
```

**Look for:**
- Login prompt (means VM booted successfully)
- Error messages on screen
- Kernel panics or boot failures

---

### Fix 3: Increase RAM (If You Have 16GB+)

Kali might be slow due to low RAM. Edit `vagrant/Vagrantfile`:

```ruby
# Change this:
vb.memory = "2048"

# To this:
vb.memory = "4096"
```

Then:
```bash
vagrant reload kali
```

---

### Fix 4: Use Different Kali Box

The `kalilinux/rolling` box sometimes has issues. Try an older stable version:

Edit `vagrant/Vagrantfile`:
```ruby
# Change this:
kali.vm.box = "kalilinux/rolling"

# To this:
kali.vm.box = "kalilinux/2023.3"  # Older stable version
```

Then:
```bash
vagrant destroy kali -f
vagrant up kali
```

---

### Fix 5: Disable Nested Virtualization (Windows Host)

If you're on Windows with Hyper-V, disable it:

**PowerShell (as Administrator):**
```powershell
bcdedit /set hypervisorlaunchtype off
```

Reboot computer, then:
```bash
vagrant up kali
```

---

### Fix 6: Manual SSH Connection Test

While Vagrant is retrying, try manual SSH in another terminal:

```bash
# Get VM IP
VBoxManage guestproperty get "Kali_PDF_Exploit_Lab_*" "/VirtualBox/GuestInfo/Net/0/V4/IP"

# Try manual SSH
ssh -i .vagrant/machines/kali/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@192.168.56.101
```

**If this works:** The VM is fine, Vagrant just needs more time

**If this fails:** VM has a boot problem (check GUI)

---

### Fix 7: Clean Slate

Completely destroy and rebuild:

```bash
# Destroy everything
vagrant destroy -f

# Remove cached box
vagrant box remove kalilinux/rolling

# Start fresh
vagrant up
```

---

## Understanding the Retries

**Normal behavior:**
- 5-10 retries: Normal for Kali first boot
- Eventually connects: All good!

**Problem behavior:**
- 30+ retries: VM might be stuck
- Never connects: Boot failure
- Connection then immediate disconnect: SSH config issue

---

## Common Causes

### 1. Slow First Boot
**Symptoms:** Retries for 5-10 minutes then works
**Solution:** Wait it out

### 2. Not Enough RAM
**Symptoms:** Very slow, eventually works or crashes
**Solution:** Increase RAM to 4GB

### 3. Network Timing
**Symptoms:** Connects then disconnects repeatedly
**Solution:** Wait for network to stabilize

### 4. Corrupted Box
**Symptoms:** Never connects, errors in GUI
**Solution:** Remove and re-download box

### 5. Host Virtualization Issues
**Symptoms:** VM crashes or hangs
**Solution:** Check VT-x/AMD-V enabled, disable Hyper-V

---

## Emergency: Skip Kali and Use Windows Only

If Kali won't start, you can still use the lab in "Advanced Mode" with HTTP server:

1. Start only Windows:
   ```bash
   vagrant up win2k8
   ```

2. PDFs are already on Windows Desktop

3. Just start a Metasploit listener on your host machine or use a working Kali VM

This isn't ideal, but lets you continue learning while debugging Kali.

---

## Check VM Status

```bash
# List running VMs
VBoxManage list runningvms

# Get VM info
VBoxManage showvminfo "Kali_PDF_Exploit_Lab_*" | grep State

# Check if VM is accessible
vagrant ssh-config kali
```

---

## Still Stuck?

**Collect debug info:**
```bash
# Vagrant debug mode
VAGRANT_LOG=debug vagrant up kali 2>&1 | tee vagrant-debug.log

# Check the log file for errors
```

**Post this info when asking for help:**
- Host OS and version
- VirtualBox version (`VBoxManage --version`)
- Vagrant version (`vagrant --version`)
- RAM available
- First 50 lines of error from debug log
- Whether GUI shows any errors

---

## Prevention for Next Time

After successful setup:

1. **Take a snapshot:**
   ```bash
   vagrant snapshot save kali fresh_install
   ```

2. **Export the box:**
   ```bash
   vagrant package kali --output kali-working.box
   ```

3. **Use your working box:**
   Add to Vagrantfile:
   ```ruby
   kali.vm.box = "kali-working"
   kali.vm.box_url = "file://./kali-working.box"
   ```

Now you have a backup that always works!
