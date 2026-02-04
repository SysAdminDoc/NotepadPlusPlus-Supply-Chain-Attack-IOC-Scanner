# Notepad++ Supply Chain Attack IOC Scanner

**Detect and remediate indicators of compromise from the Notepad++ supply chain attack (June - December 2025)**

Attributed to Chinese APT **Lotus Blossom** (Billbug / Raspberry Typhoon), this attack compromised a Notepad++ hosting provider to hijack the WinGUp update mechanism, delivering the **Chrysalis backdoor**, Cobalt Strike beacons, and Metasploit payloads to targeted organizations.

This tool provides both a **GUI** (WPF) and **CLI** scanner with full IOC coverage compiled from Kaspersky GReAT and Rapid7 Labs research, plus automated remediation capabilities.

---

## Features

### Detection

- **Notepad++ version audit** &mdash; flags pre-8.8.9 (vulnerable) and pre-8.9.1 (partially patched) installations
- **AutoUpdate.exe detection** &mdash; identifies the illegitimate binary planted by the attacker
- **Malware staging directories** &mdash; scans `%APPDATA%\ProShow`, `%APPDATA%\Bluetooth`, and checks `ProgramData\USOShared` and `%APPDATA%\Adobe\Scripts` for specific malicious artifacts without false-flagging legitimate Windows content
- **File hash verification** &mdash; 25 SHA-1 hashes (Kaspersky) + 16 SHA-256 hashes (Rapid7) checked against files in known staging paths
- **Persistence mechanisms** &mdash; registry Run/RunOnce keys, Windows services, and scheduled tasks matching known IOC patterns
- **Live process inspection** &mdash; malicious process names, GUP.exe C2 connections, fake `svchost.exe` from USOShared, and the Chrysalis mutex (`Global\Jdhfv_1.0.1`)
- **Network indicators** &mdash; active TCP connections to 8 known C2 IPs, DNS cache entries for 6 C2 domains, and hosts file tampering for `notepad-plus-plus.org`

### Remediation (GUI)

- **Process termination** &mdash; kills `BluetoothService`, `ProShow`, `ConsoleApplication2`, and fake `svchost.exe` instances
- **File removal** &mdash; deletes malware staging directories and individual artifacts; preserves legitimate Windows directories (`USOShared`, `Adobe\Scripts`) while removing only malicious files within them
- **Persistence cleanup** &mdash; scrubs registry Run keys, deletes the `BluetoothService` service, and removes compromised scheduled tasks
- **C2 IP blocking** &mdash; creates an outbound Windows Firewall rule blocking all known C2 addresses (requires elevation)
- **Confirmation dialog** &mdash; lists all planned actions before execution; logs every action to the results grid

---

## IOC Coverage

| Category | Count | Source |
|---|---|---|
| SHA-1 hashes | 25 | Kaspersky GReAT |
| SHA-256 hashes | 16 | Rapid7 Labs |
| C2 IP addresses | 8 | Kaspersky / Rapid7 |
| C2 domains | 6 | Kaspersky / Rapid7 |
| Malware files | 12 | Combined |
| Staging directories | 4 | Combined |
| Persistence patterns | 6 | Combined |

---

## Usage

### GUI Version

```powershell
.\Check-NotepadPlusPlusIOC-GUI.ps1
```

- Click **Run Scan** to begin &mdash; results populate in real time with color-coded status
- Select any row to view full details in the bottom pane
- If IOCs are detected, the **Remediate IOCs** button activates (red)
- **Export Report** saves a formatted `.txt` or `.csv` file
- **Copy Results** places the full report on the clipboard
- Source links in the title bar open the original research in your browser

### CLI Version

```powershell
# Standard scan
.\Check-NotepadPlusPlusIOC.ps1

# Export report to file
.\Check-NotepadPlusPlusIOC.ps1 -ExportPath "C:\Reports\npp-scan.txt"
```

---

## Requirements

- **PowerShell 5.1+** (ships with Windows 10/11)
- **Windows 10 / 11 / Server 2016+**
- **Run as Administrator** recommended for full coverage (network connections, services, scheduled tasks, firewall rules)
- No external dependencies &mdash; uses only built-in .NET assemblies (`PresentationFramework`, `PresentationCore`, `WindowsBase`)

---

## Attack Background

In mid-2025, Lotus Blossom compromised the hosting infrastructure serving Notepad++ updates. The WinGUp updater (pre-v8.8.9) lacked binary signature verification, allowing the attacker to serve trojanized `update.exe` payloads to selected targets via traffic redirection.

Three distinct infection chains were identified:

| Chain | Mechanism | Payload |
|---|---|---|
| **1** | NSIS installer &rarr; `%APPDATA%\ProShow` | Cobalt Strike beacon via renamed TCC (`svchost.exe` + `conf.c`) |
| **2** | NSIS installer &rarr; `%APPDATA%\ProShow` | Warbird code execution &rarr; Cobalt Strike |
| **3** | DLL sideloading via renamed Bitdefender binary | Chrysalis backdoor (`BluetoothService.exe` + `log.dll`) |

**Targets:** Organizations in Vietnam, Philippines, El Salvador, and Australia (telecom, financial services, government, IT services). The attack was highly selective; most Notepad++ users were not affected.

**Resolution:** Notepad++ v8.9.1+ includes XMLDSig signature validation for updates. All attacker access was terminated by December 2, 2025.

---

## False Positive Handling

The scanner avoids common false positives on legitimate system paths:

- **`C:\ProgramData\USOShared`** &mdash; legitimate Windows Update directory (Update Session Orchestrator). Only flagged if the specific malicious files (`svchost.exe`, `conf.c`, `libtcc.dll`) are found inside it. ETL trace logs and update data are ignored.
- **`%APPDATA%\Adobe\Scripts`** &mdash; legitimate Adobe directory. Only flagged if `alien.ini` (malware config) is present.
- **`%APPDATA%\ProShow`** and **`%APPDATA%\Bluetooth`** &mdash; not legitimate Windows paths. Their existence is always flagged.
- **Notepad++ plugins** &mdash; default bundled plugins (`mimeTools`, `NppConverter`, `NppExport`) generate a WARNING for manual review only, not a FOUND status.

---

## Sources

- **Kaspersky GReAT** &mdash; [Notepad++ Supply Chain Attack Analysis](https://securelist.com/notepad-supply-chain-attack/118708/)
- **Rapid7 Labs** &mdash; [TR: Chrysalis Backdoor &mdash; Dive into Lotus Blossom's Toolkit](https://www.rapid7.com/blog/post/tr-chrysalis-backdoor-dive-into-lotus-blossoms-toolkit/)
- **Notepad++ Official** &mdash; [Hijacked Incident Info Update](https://notepad-plus-plus.org/news/hijacked-incident-info-update/)

---

## Disclaimer

This tool is provided for **defensive security purposes only**. It is designed to help system administrators and security teams detect and remediate a specific, documented threat. Always preserve forensic evidence before running remediation in a confirmed incident. This tool does not replace a full incident response investigation.

---

## License

MIT
