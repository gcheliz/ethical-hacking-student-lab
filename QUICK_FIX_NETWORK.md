# Quick Fix: Kali Network Not Working

## Problem
Kali doesn't have IP 192.168.56.101 on eth1 interface, preventing Windows from connecting.

## Symptoms
```bash
./test_connection.sh
# Shows: ✗ Kali does NOT have IP 192.168.56.101!
```

## Quick Fix (For Running VM)

**SSH to Kali:**
```bash
vagrant ssh kali
```

**Run these commands:**
```bash
# Bring up eth1 interface
sudo ip link set eth1 up

# Add the IP address
sudo ip addr add 192.168.56.101/24 dev eth1

# Verify it worked
ip addr show eth1
# Should show: inet 192.168.56.101/24
```

**Test it:**
```bash
cd /vagrant/exploits
./test_connection.sh
# Should now show: ✓ Kali has IP 192.168.56.101
```

## Permanent Fix (Rebuild VM)

This issue is now fixed in the provisioning scripts. Rebuild Kali:

```bash
# From host (Windows PowerShell or Linux)
cd vagrant
vagrant destroy kali -f
vagrant up kali
```

The new provisioning includes `fix_network.sh` which ensures eth1 comes up correctly.

## Why This Happens

Vagrant's private_network configuration sometimes doesn't bring up eth1 automatically on Kali Linux. The fix_network.sh script now forces it up during provisioning.

## Verify the Fix Works

After applying either fix:

```bash
vagrant ssh kali
cd /vagrant/exploits

# Should show all green checkmarks
./test_connection.sh

# Start the listener
./start_attack.sh
```

Then on Windows, open the PDF - it should connect!
