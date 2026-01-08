# How to Use the Lab - Two Modes

## EASY MODE (Recommended for Beginners) 🎯

**No HTTP server needed! PDFs are already on the Desktop!**

### Step 1: Start the attack listener on Kali
```bash
vagrant ssh kali
cd /vagrant/exploits
./start_attack.sh
```

### Step 2: Open the PDF on Windows
On the Windows VM, **simply double-click** one of these PDFs on the Desktop:
- `JOAN-ESPINACH-TRD.pdf` (primary exploit)
- `JOAN-ESPINACH-ALT.pdf` (alternative exploit)

### Step 3: Get Meterpreter shell!
You should see "Meterpreter session opened" on Kali. Type `sessions -i 1` to interact.

**That's it!** No HTTP server, no downloads, no complexity.

---

## ADVANCED MODE (HTTP Server Simulation) 🌐

**Simulates real-world phishing/web-based attack**

This mode demonstrates how attackers deliver malicious files via HTTP (like phishing emails with links).

### Step 1: Start HTTP server on Kali
```bash
vagrant ssh kali
/vagrant/exploits/serve_pdf.sh
```

Keep this terminal open - the server runs in foreground.

### Step 2: Start attack listener (NEW terminal)
```bash
vagrant ssh kali
cd /vagrant/exploits
./start_attack.sh
```

### Step 3: Download and open PDF on Windows
On Windows Desktop, double-click: `download_and_open.ps1`

This PowerShell script will:
1. Download the PDF from `http://192.168.56.101:8080/`
2. Save it to Desktop
3. Open it with Adobe Reader
4. Trigger the exploit

### Step 4: Get Meterpreter shell!
Same as Easy Mode - check your listener terminal.

---

## Which Mode Should I Use?

| Feature | Easy Mode | Advanced Mode |
|---------|-----------|---------------|
| **Setup Time** | Instant | 2-3 minutes |
| **Complexity** | Very simple | Moderate |
| **Learning Value** | Exploit basics | Real-world delivery |
| **HTTP Server** | Not needed | Required |
| **Best For** | First time, quick demos | Understanding attack chains |
| **Troubleshooting** | Minimal | May need server fixes |

---

## How PDFs Get to Windows Desktop

### Easy Mode:
1. Kali VM starts first and generates PDFs
2. PDFs are copied to `/vagrant/exploits/` (shared folder)
3. Windows VM provisions and **copies PDFs directly to Desktop**
4. You just double-click!

### Advanced Mode:
1. Same setup as Easy Mode
2. **Plus** you manually start HTTP server on Kali
3. Windows downloads from HTTP server (simulates web attack)
4. More realistic but more complex

---

## Troubleshooting

### Easy Mode - "PDF doesn't open"
1. Check if PDF exists on Desktop:
   ```powershell
   dir C:\Users\vagrant\Desktop\*.pdf
   ```
2. If missing, reprovision Windows VM:
   ```bash
   vagrant destroy win2k8 -f
   vagrant up win2k8
   ```

### Advanced Mode - "Cannot download PDF"
See `QUICK_FIX_HTTP_SERVER.md` for HTTP server troubleshooting.

---

## Recommended Learning Path

### Day 1: Easy Mode
- Get familiar with Metasploit listener
- Understand how exploit works
- See Meterpreter in action
- Practice post-exploitation commands

### Day 2: Advanced Mode
- Learn about HTTP-based delivery
- Understand attack simulation
- Practice network monitoring
- Observe HTTP traffic

### Day 3: Customization
- Generate your own PDFs with different payloads
- Modify listener settings
- Try different Meterpreter commands
- Document your findings

---

## Quick Reference

**Easy Mode - Minimal Commands:**
```bash
# Terminal 1: Start listener
vagrant ssh kali
cd /vagrant/exploits && ./start_attack.sh

# Windows VM: Double-click PDF on Desktop
```

**Advanced Mode - Full Simulation:**
```bash
# Terminal 1: HTTP Server
vagrant ssh kali
/vagrant/exploits/serve_pdf.sh

# Terminal 2: Listener
vagrant ssh kali
cd /vagrant/exploits && ./start_attack.sh

# Windows VM: Run download_and_open.ps1
```

---

**For most students: Use Easy Mode!** It's faster, more reliable, and focuses on understanding the exploit itself rather than HTTP delivery mechanisms.
