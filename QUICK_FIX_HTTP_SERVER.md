# HTTP Server Quick Fix

## The Problem
The Windows VM cannot download the PDF because the HTTP server on Kali is not running or is running from the wrong directory (`/tmp` instead of `/home/vagrant/.msf4/local`).

## Quick Solution (2 Steps)

### Step 1: SSH into Kali VM
From your host machine (where you ran `vagrant up`):

```bash
cd vagrant
vagrant ssh kali
```

### Step 2: Run the Server Script
On the Kali VM, run ONE of these commands (they all work the same):

**Option A - Simplest (Recommended):**
```bash
/vagrant/exploits/serve_pdf.sh
```

**Option B - Alternative:**
```bash
/vagrant/exploits/start_http_server.sh
```

**Option C - From exploits directory:**
```bash
cd /vagrant/exploits
./serve_pdf.sh
```

The script will:
- ✓ Generate PDFs if they don't exist
- ✓ Kill any old servers on port 8080
- ✓ Serve from the CORRECT directory: `/home/vagrant/.msf4/local`
- ✓ Show you the exact URL to use

**Keep this terminal window open** - the server runs in the foreground.

### Step 3: Test from Windows VM

On the Windows VM, run the desktop shortcut or open PowerShell:

```powershell
C:\Users\vagrant\Desktop\download_and_open.ps1
```

The PDF should download and open successfully!

---

## What You Should See

### On Kali (when server is running correctly):

```
================================================================
  PDF Web Server
================================================================

Serving from: /home/vagrant/.msf4/local
Port:         8080
IP Address:   192.168.56.101

Available PDFs:
  → http://192.168.56.101:8080/JOAN-ESPINACH-TRD.pdf (45K)

Press Ctrl+C to stop server
================================================================

Serving HTTP on 0.0.0.0 port 8080 (http://0.0.0.0:8080/) ...
```

### On Windows (when download works):

```
================================================================
  PDF Download and Open Script
================================================================

Download URL: http://192.168.56.101:8080/JOAN-ESPINACH-TRD.pdf
Save to: C:\Users\vagrant\Desktop\JOAN-ESPINACH-TRD.pdf

Downloading PDF... Done
File downloaded: 45678 bytes

Opening PDF with Adobe Reader...
```

---

## Why This Fixes It

The old scripts were:
- ❌ Copying PDFs to `/tmp/pdf_server`
- ❌ Serving from temporary directories
- ❌ Not handling missing PDFs

The new scripts:
- ✅ Always serve from `/home/vagrant/.msf4/local`
- ✅ Auto-generate PDFs if missing
- ✅ Kill old servers to prevent conflicts
- ✅ Can be run from ANY directory

---

## Still Not Working?

### Check 1: Are both VMs running?

```bash
# From host machine
cd vagrant
vagrant status
```

Should show both `kali` and `win2k8` as **running**.

If not:
```bash
vagrant up
```

### Check 2: Can Windows ping Kali?

On Windows VM PowerShell:
```powershell
Test-Connection 192.168.56.101 -Count 3
```

Should show successful replies. If not, the network isn't configured correctly.

### Check 3: Is the server actually running?

On Kali (in a NEW SSH session - keep the server running):
```bash
vagrant ssh kali
curl http://localhost:8080/
```

Should show HTML directory listing with PDF files.

### Check 4: Is port 8080 listening?

On Kali:
```bash
sudo netstat -tlnp | grep 8080
```

Should show:
```
tcp    0    0 0.0.0.0:8080    0.0.0.0:*    LISTEN    12345/python3
```

If you see nothing, the server isn't running.

### Check 5: Do the PDF files exist?

On Kali:
```bash
ls -lh ~/.msf4/local/*.pdf
```

Should show:
```
-rw-r--r-- 1 vagrant vagrant 45K ... JOAN-ESPINACH-TRD.pdf
```

If not, generate them:
```bash
cd /vagrant/exploits
./generate_pdf.sh
```

---

## Manual Test

If automated scripts fail, try this manual test:

**On Kali:**
```bash
# 1. Go to PDF directory
cd /home/vagrant/.msf4/local

# 2. Verify PDFs exist
ls -lh *.pdf

# 3. Start server manually
python3 -m http.server 8080
```

**On Windows PowerShell:**
```powershell
# Test connection
Invoke-WebRequest -Uri "http://192.168.56.101:8080/" -UseBasicParsing

# Download PDF
Invoke-WebRequest -Uri "http://192.168.56.101:8080/JOAN-ESPINACH-TRD.pdf" -OutFile "$env:USERPROFILE\Desktop\test.pdf"

# Check if downloaded
Get-Item "$env:USERPROFILE\Desktop\test.pdf"
```

---

## Need More Help?

See these files:
- `exploits/HTTP_SERVER_GUIDE.md` - Detailed troubleshooting
- `TROUBLESHOOTING.md` - General lab issues
- `exploits/diagnose_server.sh` - Run diagnostics on Kali

Or run the diagnostic script:
```bash
vagrant ssh kali
cd /vagrant/exploits
./diagnose_server.sh
```
