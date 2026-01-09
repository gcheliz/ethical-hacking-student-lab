# Apply Network Adapter Fix - Complete Guide

## What Was Fixed

The Vagrantfile now explicitly configures network adapters for both VMs:

**Before (Broken):**
- Kali: No adapter specified, auto_config: true
- Windows: No adapter specified, NO auto_config
- Result: eth1 interface doesn't come up on Kali

**After (Fixed):**
- Both VMs: `adapter: 2` explicitly set
- Both VMs: `auto_config: true`
- Both VMs: `virtualbox__intnet: false` (host-only, not internal)
- Result: Both VMs get proper private network IPs

## Network Architecture

```
┌────────────────────────────────────────────────────────┐
│  Adapter 1 (NAT) - Default                             │
│  ├─ Kali eth0:    10.0.2.15                           │
│  └─ Windows NIC1: 10.0.2.15                           │
│  Purpose: Internet access, Vagrant management          │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│  Adapter 2 (Host-Only) - 192.168.56.0/24               │
│  ├─ Kali eth1:    192.168.56.101 ← Listener here!     │
│  └─ Windows NIC2: 192.168.56.102 ← Connects from here!│
│  Purpose: VM-to-VM communication, exploit traffic      │
└────────────────────────────────────────────────────────┘
```

## How to Apply the Fix

### Option 1: Rebuild VMs (Recommended - Clean Start)

```bash
# Pull latest fixes
git pull origin claude/create-lab-guide-fo5F2

# Destroy both VMs
cd vagrant
vagrant destroy -f

# Rebuild (will use new network config)
cd ..
.\setup.ps1   # Windows
# OR
./setup.sh    # Linux/Mac
```

### Option 2: Reload VMs (Faster - Applies Network Config)

```bash
# Pull latest fixes
git pull origin claude/create-lab-guide-fo5F2

# Reload VMs to apply new network config
cd vagrant
vagrant reload kali
vagrant reload win2k8
```

**Note:** This recreates the network adapters with new config.

### Option 3: Quick Manual Fix (For Testing Only)

**Only use if you need to test immediately without rebuilding:**

```bash
# SSH to Kali
vagrant ssh kali

# Manually configure eth1
sudo ip link set eth1 up
sudo ip addr add 192.168.56.101/24 dev eth1

# Verify
ip addr show eth1
# Should show: inet 192.168.56.101/24

# Test connection
cd /vagrant/exploits
./test_connection.sh
```

**Warning:** This fix is temporary and will be lost on reboot!

## Verification Steps

### Step 1: Check Network Configuration

**On Kali:**
```bash
vagrant ssh kali
ip addr show

# Should see:
# eth0: inet 10.0.2.15/24      (NAT)
# eth1: inet 192.168.56.101/24 (Host-Only) ← This is the key!
```

**On Windows (PowerShell):**
```powershell
vagrant winrm win2k8 -c "ipconfig"

# Should see:
# Ethernet adapter Local Area Connection:
#   IPv4 Address: 10.0.2.15          (NAT)
#
# Ethernet adapter Local Area Connection 2:
#   IPv4 Address: 192.168.56.102     (Host-Only) ← This!
```

### Step 2: Test Connectivity

**On Kali:**
```bash
cd /vagrant/exploits
./test_connection.sh

# Expected output:
# ✓ Kali has IP 192.168.56.101
# ✓ eth1 interface exists
# ✓ Windows is reachable
# ✓ No firewall blocking port 4444
```

### Step 3: Test the Exploit

**On Kali - Start listener:**
```bash
cd /vagrant/exploits
./start_attack.sh

# Should show:
# [*] Started reverse TCP handler on 192.168.56.101:4444
```

**On Windows - Open PDF:**
- Double-click `JOAN-ESPINACH-TRD.pdf` on Desktop
- Adobe Reader opens the PDF

**Expected Result on Kali:**
```
[*] Sending stage (176198 bytes) to 192.168.56.102
[*] Meterpreter session 1 opened (192.168.56.101:4444 -> 192.168.56.102:49xxx)

meterpreter >
```

**Test commands:**
```
meterpreter > sysinfo
Computer        : WIN-TARGET
OS              : Windows 2008 R2 (6.1 Build 7600)
Architecture    : x64
System Language : en_US

meterpreter > getuid
Server username: WIN-TARGET\vagrant

meterpreter > pwd
C:\Program Files (x86)\Adobe\Reader 9.0\Reader
```

## Troubleshooting

### Issue: eth1 still not showing up

**Check VirtualBox adapter:**
```bash
# On host
cd vagrant
vagrant ssh kali -c "VBoxManage showvminfo $(cat .vagrant/machines/kali/virtualbox/id) | grep NIC"

# Should show:
# NIC 1: ... Type: NAT
# NIC 2: ... Type: Host-only, IP: 192.168.56.101
```

**If NIC 2 is missing:**
```bash
vagrant destroy kali -f
vagrant up kali
```

### Issue: Windows can ping Kali but PDF doesn't connect

**Check listener is bound to correct interface:**
```bash
vagrant ssh kali
netstat -tlnp | grep 4444

# Should show:
# 0.0.0.0:4444  (listening on ALL interfaces)
# OR
# 192.168.56.101:4444  (listening on eth1)

# Should NOT show:
# 127.0.0.1:4444  (localhost only - WRONG!)
```

**If bound to localhost:**
- Check `start_attack.sh` has `LHOST="192.168.56.101"`
- Restart the listener

### Issue: Firewall blocking

**On Kali:**
```bash
sudo iptables -L INPUT -n | grep 4444

# Should have rule allowing port 4444
# If not:
sudo iptables -I INPUT -p tcp --dport 4444 -s 192.168.56.0/24 -j ACCEPT
```

## Success Indicators

✅ **Network is properly configured when:**
1. Kali has eth1 with 192.168.56.101
2. Windows has adapter 2 with 192.168.56.102
3. `ping 192.168.56.102` works from Kali
4. `Test-Connection 192.168.56.101` works from Windows
5. `./test_connection.sh` shows all green checkmarks
6. Opening PDF creates Meterpreter session

## Files Changed

- `vagrant/Vagrantfile` - Network adapter configuration
- `vagrant/provisioning/kali/fix_network.sh` - Auto-fix for eth1
- `exploits/test_connection.sh` - Network diagnostics

## Additional Resources

- `QUICK_FIX_NETWORK.md` - Quick manual fix commands
- `TROUBLESHOOT_EXPLOIT.md` - Exploit troubleshooting guide
- `windows-troubleshoot.ps1` - Windows diagnostics
