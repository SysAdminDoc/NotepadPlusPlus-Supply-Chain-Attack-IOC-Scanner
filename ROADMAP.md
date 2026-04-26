# ROADMAP

Notepad++ Supply Chain IOC Scanner targets the Lotus Blossom / Chrysalis backdoor campaign via the WinGUp update mechanism. PowerShell CLI + WPF GUI with RMM-friendly exit codes.

## Planned Features

### Detection coverage
- Add YARA scanning for Chrysalis, Cobalt Strike, and Metasploit payloads via `yara-powershell` — hashes are brittle, bytecode isn't
- ETW consumer for short-lived processes so a malicious `gup.exe` that exits before scan starts is still caught (ring buffer, last 5 min)
- Sigma-rule ingestion for hunting queries against the local Event Log (4688 + PowerShell 4104)
- Memory scan of running processes for the `Global\Jdhfv_1.0.1` mutex string and Cobalt Strike beacon artifacts
- Amcache / Shimcache parsing for evidence of stale malicious `svchost.exe` execution

### Output and integration
- NDJSON output mode for direct SIEM ingest (Splunk, Elastic, Sentinel)
- Wazuh/OSSEC-compatible rule format export
- Direct Defender ASR + attack surface reduction rule recommendation (emit commands, don't apply)
- Sysmon config delta — emit the minimal Sysmon config needed to future-proof against this TTP set
- `-Since <date>` flag that scopes the scan to files modified after the known campaign start

### Remediation
- Pre-remediation snapshot (registry hive export + file copy to quarantine ZIP) before any destructive action
- Dry-run mode for the GUI that lists every action without executing
- Per-action rollback using the quarantine ZIP
- BITS/QMGR job inspection and purge — supply-chain campaigns often seed persistence via BITS

### Distribution
- Winget and Chocolatey packages
- Authenticode-signed release builds; RMM vendors refuse unsigned scripts
- Intune / SCCM detection-method snippets published with each release

## Competitive Research

- **CrowdStrike Falcon / Microsoft Defender for Endpoint** — The paid baseline; this tool fills the gap for orgs without EDR budgets. Keep it RMM-friendly
- **Kaspersky KVRT / ESET Online Scanner** — Single-exe one-off scanners; UX model for the GUI
- **Hayabusa** — Sigma-rule-based Windows event log hunter; direct inspiration for the Sigma ingest feature
- **Velociraptor / THOR Lite** — Enterprise IR tools; the artifact-collection pattern (snapshot before action) is worth copying

## Nice-to-Haves

- Portable mode — a single `.ps1` that emits a `.zip` of findings for air-gapped triage
- Scheduled-task installer that scans weekly and mails results via SMTP relay
- PowerShell module on PSGallery so `Install-Module NppScanner` works
- Multi-threat variant — the same chassis scanning for xz-utils backdoor, npm/PyPI token theft, 3CX compromise, etc.
- HTML report with collapsible sections suitable for attaching to a ticket

## Open-Source Research (Round 2)

### Related OSS Projects
- https://github.com/Neo23x0/Loki — Florian Roth's LOKI, the reference IOC + YARA scanner; now deprecated in favor of the Rust rewrite but still the canonical design
- https://github.com/Neo23x0/Loki-RS — LOKI RS, the active Rust port; informs where the industry is heading (native speed, smaller SBOM, easier signing)
- https://github.com/spyre-project/spyre — Go-based YARA-first host scanner, incident-responder-oriented, smaller surface than LOKI
- https://github.com/phantom0004/morpheus_IOC_scanner — Morpheus, auto-fetches new YARA rules from GitHub on each run; good reference for rule auto-update plumbing
- https://github.com/deepfence/YaraHunter — container-native YARA scanner; CI/CD-friendly SBOM approach
- https://github.com/rastrea2r/rastrea2r — RESTful client/server triage for hunting across thousands of endpoints
- https://github.com/afine-com/glassworm-hunter — supply-chain-specific detector (VS Code / npm / pip / git) with SARIF output and pipeline-gate exit codes
- https://github.com/InQuest/awesome-yara — curated YARA-rule + tooling index
- https://github.com/sroberts/awesome-iocs — curated IOC-source index

### Features to Borrow
- Auto-update YARA rule corpus from Git (Morpheus) — add `--update-rules` that pulls the latest Chrysalis / xz-backdoor / 3CX ruleset from our repo before scanning
- SARIF output for GitHub Code Scanning (GlassWorm Hunter) — organizations scanning dev machines can pipe findings into GitHub Security tab
- Structured exit codes 0 clean / 1 findings / 2 error (GlassWorm Hunter) — already on roadmap as "RMM-friendly exit codes"; codify exact semantics
- Client/server RESTful triage mode (Rastrea2r) — one analyst machine driving hundreds of endpoints; extends the PSGallery-module plan to fleet use
- Container/filesystem mode (YaraHunter) — scan VM images, golden images, and CI build artifacts, not just live hosts
- Memory scanning with YARA (LOKI, Spyre) — Chrysalis beaconing is easier to catch in-memory than on-disk; worth adding behind `--scan-memory`
- C2 connection enumeration (LOKI) — cross-reference active `netstat` endpoints against the known Cobalt Strike + Chrysalis C2 IOC list
- Awesome-list inclusion (InQuest/awesome-yara, sroberts/awesome-iocs) — submit upstream PRs once PSGallery module lands

### Patterns & Architectures Worth Studying
- Rule-pack-as-git-submodule (LOKI / Morpheus) — decouple scanner binary from rule corpus so IR teams can pin rule versions per engagement
- Rust rewrite trajectory (LOKI → LOKI RS) — once PSGallery module is shipped, evaluate a Rust core with a PowerShell wrapper for cross-platform reach and smaller attack surface
- Multi-layer detection (GlassWorm Hunter's "technique detection" + "known IOC matching") — pair behavioral heuristics (WinGUp update manifest mismatch) with hash-based IOCs for resilience against IOC rotation
- SBOM-aware container mode (YaraHunter) — scan a Notepad++ install directory as a pseudo-container, cross-reference every DLL against its upstream manifest to spot implants without needing a YARA hit
