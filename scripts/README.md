# Utility Scripts

Helper scripts for managing and troubleshooting the lab environment.

## Cleanup Utilities

### cleanup-vbox.ps1
**Purpose:** Clean up leftover VirtualBox VMs and directories
**Use When:** Getting "VM name already exists" errors
**Platform:** Windows (PowerShell)

```powershell
.\scripts\cleanup-vbox.ps1
```

Removes:
- Kali_PDF_Exploit_Lab_* VMs
- Windows_PDF_Target_Lab_* VMs
- Orphaned VM directories in `VirtualBox VMs\`

## Diagnostic Scripts

### windows-troubleshoot.ps1
**Purpose:** Comprehensive Windows VM diagnostics
**Use When:** PDF exploit not working
**Platform:** Windows Server 2008 R2 (PowerShell 2.0 compatible)

**Copy to Windows VM and run:**
```powershell
# On Windows VM
.\windows-troubleshoot.ps1
```

Checks:
- PDF files on Desktop
- Windows Firewall status
- Network connectivity to Kali
- Port 4444 reachability
- Adobe Reader installation
- UAC status

## Development Utilities

### fix-line-endings.sh
**Purpose:** Fix CRLF/LF line ending issues
**Use When:** Scripts fail with "bad interpreter" or "\r" errors
**Platform:** Linux/macOS

```bash
./scripts/fix-line-endings.sh
```

Ensures all `.sh` scripts use LF (Unix) line endings.

## Main Scripts (in root)

For primary lab operations, use scripts in the root directory:
- `setup.ps1` / `setup.sh` - Initial lab setup
- `reset.ps1` / `reset.sh` - Reset VMs to clean state
- `cleanup.ps1` / `cleanup.sh` - Destroy all lab VMs

## Related Resources
- Exploit scripts: `../exploits/`
- Documentation: `../docs/`
