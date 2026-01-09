# Network Debugging Guide for Host-Only Networks

## Quick Network Verification

Use this checklist to debug network issues between Kali and Windows VMs.

---

## 1. Verify Both VMs Have Correct IPs

### On Kali

```bash
# SSH into Kali
vagrant ssh kali

# Check IP configuration
ip addr show

# Look for: 192.168.56.101 on eth1 (or similar interface)
```

**Expected output:**
```
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP>
    inet 192.168.56.101/24 brd 192.168.56.255 scope global eth1
```

### On Windows

```powershell
# From host, run:
vagrant winrm win2k8 -c "ipconfig"

# Look for: 192.168.56.102
```

**Expected output:**
```
Ethernet adapter Local Area Connection 2:
   IPv4 Address. . . . . . . . . . . : 192.168.56.102
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
```

---

## 2. Test Basic Connectivity

### From Kali to Windows

```bash
# In Kali VM
ping -c 4 192.168.56.102
```

**If ping fails:**
- Check Windows firewall (see section 4)
- Verify IPs are correct
- Check if Windows VM is fully booted

### From Windows to Kali

```powershell
# On Windows
Test-Connection 192.168.56.101 -Count 4
```

**If ping fails:**
- Check Kali network configuration
- Verify both VMs on same host-only network

---

## 3. Verify Host-Only Network Configuration

### Check VirtualBox Network

```bash
# On host machine
VBoxManage list hostonlynets    # For macOS VirtualBox 7.x
VBoxManage list hostonlyifs     # For Linux/Windows

# Should show:
# Network: 192.168.56.0/24
# LowerIP: 192.168.56.1
```

### Check VM Network Adapters

```bash
# List VMs
VBoxManage list vms

# Check Kali network
VBoxManage showvminfo "Kali_PDF_Exploit_Lab_*" | grep -i "nic"

# Check Windows network
VBoxManage showvminfo "Windows_PDF_Target_Lab_*" | grep -i "nic"
```

**Expected:**
- NIC 1: NAT (for internet/vagrant management)
- NIC 2: Host-only network

---

## 4. Check Windows Firewall

### Verify Firewall Status

```powershell
# On Windows VM
netsh advfirewall show allprofiles state
```

**Expected:** State should be OFF for all profiles (Domain, Private, Public)

### Disable Firewall (if needed)

```powershell
# Disable all firewall profiles
netsh advfirewall set allprofiles state off

# Verify
netsh advfirewall show allprofiles
```

### Allow Specific Ports

If you want firewall on but allow exploitation:

```powershell
# Allow SMB (for EternalBlue)
netsh advfirewall firewall add rule name="SMB" dir=in action=allow protocol=TCP localport=445

# Allow ICMP ping
netsh advfirewall firewall add rule name="ICMPv4" protocol=icmpv4:8,any dir=in action=allow
```

---

## 5. Check Specific Services

### For EternalBlue (SMB)

**On Windows:**
```powershell
# Check SMB service
Get-Service LanmanServer

# Should show: Status = Running

# Check if port 445 is listening
netstat -an | findstr :445

# Should show: 0.0.0.0:445  LISTENING
```

**From Kali:**
```bash
# Check if port 445 is accessible
nc -zv 192.168.56.102 445

# Or use nmap
nmap -p 445 192.168.56.102
```

### For PDF Exploit (HTTP Server)

**On Kali:**
```bash
# Check if HTTP server is running (if using PDF exploit)
netstat -tlnp | grep :8000

# Or check with curl locally
curl http://localhost:8000
```

**From Windows:**
```powershell
# Test HTTP access from Windows to Kali
Invoke-WebRequest http://192.168.56.101:8000
```

---

## 6. Routing Table Verification

### On Kali

```bash
# Show routing table
ip route show

# Should include:
# 192.168.56.0/24 dev eth1 proto kernel scope link src 192.168.56.101
```

### On Windows

```powershell
# Show routing table
route print

# Look for: 192.168.56.0 network route
```

---

## 7. Network Interface Status

### Ensure Interfaces Are Up

**Kali:**
```bash
# Check interface status
ip link show

# Bring up interface if down
sudo ip link set eth1 up

# Verify IP assigned
ip addr show eth1
```

**Windows:**
```powershell
# Check network adapter status
Get-NetAdapter

# Enable adapter if disabled
Enable-NetAdapter -Name "Ethernet 2"  # or appropriate name
```

---

## 8. DNS and Name Resolution (Optional)

While not required for exploitation (using IPs), you can set up hostname resolution:

### On Kali - Edit /etc/hosts

```bash
sudo bash -c 'echo "192.168.56.102 win-target windows-target" >> /etc/hosts'

# Test
ping win-target
```

### On Windows - Edit hosts file

```powershell
# Edit C:\Windows\System32\drivers\etc\hosts
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "192.168.56.101 kali-attacker kali"

# Test
ping kali-attacker
```

---

## 9. Common Network Issues and Fixes

### Issue: Kali doesn't have 192.168.56.101

**Fix:**
```bash
# On Kali
sudo ip addr add 192.168.56.101/24 dev eth1
sudo ip link set eth1 up
sudo ip route add 192.168.56.0/24 dev eth1
```

Or make it persistent:
```bash
# Edit network config
sudo nano /etc/network/interfaces.d/eth1

# Add:
auto eth1
iface eth1 inet static
    address 192.168.56.101
    netmask 255.255.255.0
    gateway 192.168.56.1
```

### Issue: Windows has wrong IP

**Fix:**
```powershell
# On Windows - Set static IP
netsh interface ip set address "Local Area Connection 2" static 192.168.56.102 255.255.255.0 192.168.56.1

# Or via GUI:
# Control Panel > Network > Change Adapter Settings
# Right-click adapter > Properties > IPv4 Properties
# Set: 192.168.56.102 / 255.255.255.0 / 192.168.56.1
```

### Issue: Ping works but exploit doesn't

This means network is OK, but service issue:

**For EternalBlue:**
```powershell
# On Windows - ensure SMB is running
net start LanmanServer
```

**For PDF exploit:**
```bash
# On Kali - check HTTP server
cd ~/exploits
python3 -m http.server 8000
```

---

## 10. Complete Network Reset

If nothing works, reset network configuration:

### Reset VirtualBox Network

```bash
# On host
vagrant halt

# Remove and recreate network (macOS VirtualBox 7.x)
VBoxManage hostonlynet remove --name "LabNet"
VBoxManage hostonlynet add --name "LabNet" --netmask 255.255.255.0 --lower-ip 192.168.56.1 --upper-ip 192.168.56.254

# Restart VMs
vagrant up
```

### Reprovision Network Configuration

```bash
# Reprovision Kali network
vagrant provision kali --provision-with "Configure host-only network"

# Restart networking on Kali
vagrant ssh kali -c "sudo systemctl restart networking"
```

---

## 11. Network Troubleshooting Script

Save this as `test_network.sh` on Kali:

```bash
#!/bin/bash

echo "═══════════════════════════════════════════════════════════════"
echo "  Network Connectivity Test"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Test 1: Check Kali IP
echo "[1/5] Checking Kali IP configuration..."
MY_IP=$(ip addr show | grep "192.168.56.101" | awk '{print $2}')
if [ -n "$MY_IP" ]; then
    echo "  ✓ Kali has correct IP: $MY_IP"
else
    echo "  ✗ Kali does NOT have 192.168.56.101"
    echo "  Fix: sudo ip addr add 192.168.56.101/24 dev eth1"
    exit 1
fi

# Test 2: Ping Windows
echo ""
echo "[2/5] Testing connectivity to Windows (192.168.56.102)..."
if ping -c 2 -W 2 192.168.56.102 > /dev/null 2>&1; then
    echo "  ✓ Windows is reachable"
else
    echo "  ✗ Cannot ping Windows"
    echo "  Check: Windows VM is running, firewall is off"
    exit 1
fi

# Test 3: Check SMB port
echo ""
echo "[3/5] Checking SMB port 445..."
if nc -zv 192.168.56.102 445 2>&1 | grep -q succeeded; then
    echo "  ✓ Port 445 is open"
else
    echo "  ✗ Port 445 is NOT accessible"
    echo "  Check: SMB service on Windows"
    exit 1
fi

# Test 4: SMB protocol check
echo ""
echo "[4/5] Checking SMB protocol..."
nmap -p 445 --script smb-protocols 192.168.56.102 | grep -A 5 "smb-protocols"

# Test 5: Route check
echo ""
echo "[5/5] Checking routing..."
ROUTE=$(ip route | grep "192.168.56.0/24")
if [ -n "$ROUTE" ]; then
    echo "  ✓ Route exists: $ROUTE"
else
    echo "  ✗ No route to 192.168.56.0/24"
    echo "  Fix: sudo ip route add 192.168.56.0/24 dev eth1"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Network Test Complete!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "If all tests passed, network is ready for exploitation."
echo "If any tests failed, follow the suggested fixes above."
echo ""
```

Make it executable:
```bash
chmod +x test_network.sh
./test_network.sh
```

---

## Summary: Network Must-Haves

For exploitation to work, you MUST have:

1. ✓ Kali IP: `192.168.56.101` on eth1 (or similar)
2. ✓ Windows IP: `192.168.56.102` on second adapter
3. ✓ Ping works both directions
4. ✓ Windows firewall OFF (or ports allowed)
5. ✓ Target service running (SMB for EternalBlue)
6. ✓ Both VMs on same host-only network

If all 6 are true, exploitation will work!

---

## Need More Help?

- Check full troubleshooting: [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
- Simpler exploits guide: [SIMPLER_EXPLOITS.md](./SIMPLER_EXPLOITS.md)
- EternalBlue setup: `exploits/eternalblue/README.md`
