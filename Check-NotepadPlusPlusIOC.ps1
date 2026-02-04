#Requires -Version 5.1
<#
.SYNOPSIS
    Checks for indicators of compromise related to the Notepad++ supply chain attack (June-December 2025).
.DESCRIPTION
    Comprehensive IOC scanner for the Notepad++ supply chain compromise attributed to the Chinese APT group
    Lotus Blossom (aka Billbug, Raspberry Typhoon, Spring Dragon). The attack hijacked the WinGUp update
    mechanism via hosting provider compromise to deliver the Chrysalis backdoor, Cobalt Strike beacons,
    and Metasploit payloads to targeted organizations.

    This script checks:
      - Notepad++ installation version (pre-8.8.9 = vulnerable, pre-8.9.1 = partially patched)
      - Malware staging directories and specific malicious files
      - SHA-1 hashes (Kaspersky) and SHA-256 hashes (Rapid7) of known malicious files
      - Cobalt Strike artifacts in ProgramData\USOShared
      - Persistence mechanisms (registry Run keys, services, scheduled tasks)
      - Running processes associated with the attack
      - Active network connections to known C2 infrastructure
      - DNS cache entries for C2 domains
      - GUP.exe network connections to non-legitimate update sources
      - Hosts file tampering for notepad-plus-plus.org
      - Chrysalis backdoor mutex

    Sources:
      Kaspersky GReAT  : https://securelist.com/notepad-supply-chain-attack/118708/
      Rapid7 Labs      : https://www.rapid7.com/blog/post/tr-chrysalis-backdoor-dive-into-lotus-blossoms-toolkit/
      Notepad++ Disclosure: https://notepad-plus-plus.org/news/hijacked-incident-info-update/

.PARAMETER ExportPath
    Optional. File path to export results as a text report. If omitted, results display in console only.

.EXAMPLE
    .\Check-NotepadPlusPlusIOC.ps1
    Runs all checks and displays results in the console.

.EXAMPLE
    .\Check-NotepadPlusPlusIOC.ps1 -ExportPath "C:\Reports\npp-ioc-scan.txt"
    Runs all checks and exports results to the specified text file.

.NOTES
    Author  : SysAdminDoc
    Version : 2.2
    Date    : 2026-02-04
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

# ============================================================================
#  Results Collection
# ============================================================================

$results = [System.Collections.Generic.List[PSCustomObject]]::new()
$scanStart = Get-Date

function Add-Result {
    param(
        [string]$Section,
        [string]$Check,
        [ValidateSet('CLEAN','FOUND','WARNING','ERROR')]
        [string]$Status,
        [string]$Details
    )
    $results.Add([PSCustomObject]@{
        Section = $Section
        Check   = $Check
        Status  = $Status
        Details = $Details
    })
}

# ============================================================================
#  IOC Definitions
# ============================================================================

# --- C2 IP addresses (Kaspersky + Rapid7) ---
$c2Ips = @(
    '45.76.155.202'          # Malicious update host (Chain 1 - Jul 2025)
    '45.32.144.255'          # Malicious update host (Chain 2 - Sep 2025)
    '95.179.213.0'           # Malicious update host (observed by Rapid7)
    '45.77.31.210'           # C2 (Kaspersky Chain 1 - Cobalt Strike)
    '59.110.7.32'            # C2 (Cobalt Strike beacon - Loader 1)
    '124.222.137.114'        # C2 (Cobalt Strike beacon - Loader 2)
    '61.4.102.97'            # api.skycloudcenter.com resolution (Chrysalis C2)
    '51.91.79.17'            # temp.sh anonymous file-sharing (exfil)
)

# --- C2 Domains (Kaspersky + Rapid7) ---
$c2Domains = @(
    'skycloudcenter.com'     # Chrysalis backdoor C2
    'wiresguard.com'         # Cobalt Strike beacon C2
    'cdncheck.it.com'        # C2 (Kaspersky)
    'safe-dns.it.com'        # C2 (Kaspersky)
    'self-dns.it.com'        # C2 (Kaspersky)
    'temp.sh'                # Anonymous file-sharing (exfiltration)
)

# --- Known malicious SHA-1 hashes (Kaspersky GReAT) ---
$knownSha1 = @(
    '8e6e505438c21f3d281e1cc257abdbf7223b7f5a'
    '90e677d7ff5844407b9c073e3b7e896e078e11cd'
    '573549869e84544e3ef253bdba79851dcde4963a'
    '13179c8f19fbf3d8473c49983a199e6cb4f318f0'
    '4c9aac447bf732acc97992290aa7a187b967ee2c'
    '821c0cafb2aab0f063ef7e313f64313fc81d46cd'
    'd7ffd7b588880cf61b603346a3557e7cce648c93'
    '06a6a5a39193075734a32e0235bde0e979c27228'
    '9c3ba38890ed984a25abb6a094b5dbf052f22fa7'
    'ca4b6fe0c69472cd3d63b212eb805b7f65710d33'
    '0d0f315fd8cf408a483f8e2dd1e69422629ed9fd'
    '2a476cfb85fbf012fdbe63a37642c11afa5cf020'
    '21a942273c14e4b9d3faa58e4de1fd4d5014a1ed'
    '7e0790226ea461bcc9ecd4be3c315ace41e1c122'
    'f7910d943a013eede24ac89d6388c1b98f8b3717'
    '94dffa9de5b665dc51bc36e2693b8a3a0a4cc6b8'
    '73d9d0139eaf89b7df34ceeb60e5f8c7cd2463bf'
    'bd4915b3597942d88f319740a9b803cc51585c4a'
    'c68d09dd50e357fd3de17a70b7724f8949441d77'
    '813ace987a61af909c053607635489ee984534f4'
    '9fbf2195dee991b1e5a727fd51391dcc2d7a4b16'
    '07d2a01e1dc94d59d5ca3bdf0c7848553ae91a51'
    '3090ecf034337857f786084fb14e63354e271c5d'
    'd0662eadbe5ba92acbd3485d8187112543bcfbf5'
    '9c0eff4deeb626730ad6a05c85eb138df48372ce'
)

# --- Known malicious SHA-256 hashes (Rapid7 Labs) ---
$knownSha256 = @(
    'a511be5164dc1122fb5a7daa3eef9467e43d8458425b15a640235796006590c9'  # update.exe (NSIS installer)
    '8ea8b83645fba6e23d48075a0d3fc73ad2ba515b4536710cda4f1f232718f53e'  # NSIS script
    '2da00de67720f5f13b17e9d985fe70f10f153da60c9ab1086fe58f069a156924'  # BluetoothService.exe (renamed Bitdefender)
    '77bfea78def679aa1117f569a35e8fd1542df21f7e00e27f192c907e61d63a2e'  # BluetoothService (encrypted shellcode)
    '3bdc4c0637591533f1d4198a72a33426c01f69bd2e15ceee547866f65e26b7ad'  # log.dll (malicious sideload DLL)
    '9276594e73cda1c69b7d265b3f08dc8fa84bf2d6599086b9acc0bb3745146600'  # u.bat (self-removal script)
    'f4d829739f2d6ba7e3ede83dad428a0ced1a703ec582fc73a4eee3df3704629a'  # conf.c (Metasploit shellcode loader)
    '4a52570eeaf9d27722377865df312e295a7a23c3b6eb991944c2ecd707cc9906'  # libtcc.dll (Tiny C Compiler library)
    '831e1ea13a1bd405f5bda2b9d8f2265f7b1db6c668dd2165ccc8a9c4c15ea7dd'  # admin (CS beacon payload)
    '0a9b8df968df41920b6ff07785cbfebe8bda29e6b512c94a3b2a83d10014d2fd'  # Loader 1
    '4c2ea8193f4a5db63b897a2d3ce127cc5d89687f380b97a1d91e0c8db542e4f8'  # uffhxpSy (CS beacon shellcode)
    'e7cd605568c38bd6e0aba31045e1633205d0598c607a855e2e1bca4cca1c6eda'  # Loader 2
    '078a9e5c6c787e5532a7e728720cbafee9021bfec4a30e3c2be110748d7c43c5'  # 3yzr31vk (CS beacon shellcode)
    'b4169a831292e245ebdffedd5820584d73b129411546e7d3eccf4663d5fc5be3'  # ConsoleApplication2.exe (Warbird loader)
    'fcc2765305bcd213b7558025b2039df2265c3e0b6401e4833123c461df2de51a'  # Loader 4
    '7add554a98d3a99b319f2127688356c1283ed073a084805f14e33b4f6a6126fd'  # CS beacon shellcode (Loaders 3+4)
)

# ============================================================================
#  Section 1: Notepad++ Installation & Version
# ============================================================================

$sectionName = 'Installation'

# Locate all Notepad++ installs via registry + common paths
$nppPaths = [System.Collections.Generic.List[string]]::new()

# Check registry uninstall keys
$uninstallKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach ($key in $uninstallKeys) {
    try {
        Get-ItemProperty -Path $key -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like '*Notepad++*' } |
            ForEach-Object {
                if ($_.InstallLocation -and (Test-Path $_.InstallLocation)) {
                    if (-not $nppPaths.Contains($_.InstallLocation.TrimEnd('\'))) {
                        $nppPaths.Add($_.InstallLocation.TrimEnd('\'))
                    }
                }
            }
    } catch { }
}

# Also check common default paths
$defaultPaths = @(
    "$env:ProgramFiles\Notepad++"
    "${env:ProgramFiles(x86)}\Notepad++"
)
foreach ($dp in $defaultPaths) {
    if ((Test-Path $dp) -and -not $nppPaths.Contains($dp)) {
        $nppPaths.Add($dp)
    }
}

if ($nppPaths.Count -eq 0) {
    Add-Result -Section $sectionName -Check 'Notepad++ installed' -Status 'CLEAN' `
               -Details 'Notepad++ not found on this system'
} else {
    foreach ($nppDir in $nppPaths) {
        $nppExe = Join-Path $nppDir 'notepad++.exe'
        if (Test-Path $nppExe) {
            try {
                $verInfo = (Get-Item $nppExe -ErrorAction Stop).VersionInfo
                $version = [version]$verInfo.ProductVersion
                $verString = $verInfo.ProductVersion

                if ($version -lt [version]'8.8.9') {
                    Add-Result -Section $sectionName -Check "Version ($nppDir)" -Status 'FOUND' `
                               -Details "v$verString - VULNERABLE. Update infrastructure was compromised Jun-Dec 2025. Updater lacks integrity verification. Upgrade to v8.9.1+ immediately."
                } elseif ($version -lt [version]'8.9.1') {
                    Add-Result -Section $sectionName -Check "Version ($nppDir)" -Status 'WARNING' `
                               -Details "v$verString - Partially patched. Upgrade to v8.9.1+ for full XMLDSig update validation."
                } else {
                    Add-Result -Section $sectionName -Check "Version ($nppDir)" -Status 'CLEAN' `
                               -Details "v$verString - Fully patched with update signature validation."
                }
            } catch {
                Add-Result -Section $sectionName -Check "Version ($nppDir)" -Status 'WARNING' `
                           -Details "Could not determine version: $($_.Exception.Message)"
            }
        }

        # Check for AutoUpdate.exe (not a legitimate Notepad++ file - per Kevin Beaumont)
        $autoUpdate = Join-Path $nppDir 'AutoUpdate.exe'
        if (Test-Path $autoUpdate) {
            $auInfo = Get-Item $autoUpdate -Force -ErrorAction SilentlyContinue
            Add-Result -Section $sectionName -Check 'AutoUpdate.exe present' -Status 'FOUND' `
                       -Details "SUSPICIOUS: $autoUpdate is NOT a legitimate Notepad++ file. Size: $($auInfo.Length) bytes, Modified: $($auInfo.LastWriteTime)"
        }

        # Check for GUP.exe connecting to unexpected destinations
        $gupExe = Join-Path $nppDir 'updater\GUP.exe'
        if (-not (Test-Path $gupExe)) {
            $gupExe = Join-Path $nppDir 'updater\gup.exe'
        }
        if (Test-Path $gupExe) {
            Add-Result -Section $sectionName -Check 'GUP.exe present' -Status 'CLEAN' `
                       -Details "Updater found at $gupExe"
        }
    }
}

# Notepad++ plugins directory (user-level)
$nppPluginPaths = @(
    "$env:APPDATA\Notepad++\plugins"
)
# Also check install-level plugin dirs
foreach ($nppDir in $nppPaths) {
    $installPlugins = Join-Path $nppDir 'plugins'
    if ($installPlugins -and (Test-Path $installPlugins)) {
        $nppPluginPaths += $installPlugins
    }
}
foreach ($pluginPath in $nppPluginPaths) {
    if (Test-Path -Path $pluginPath) {
        $pluginDirs = Get-ChildItem -Path $pluginPath -Directory -Force -ErrorAction SilentlyContinue |
                      Select-Object -ExpandProperty Name
        $nonDefault = $pluginDirs | Where-Object { $_ -ne 'Config' -and $_ -ne 'config' -and $_ -ne 'doc' -and $_ -ne 'disabled' }
        if ($nonDefault) {
            Add-Result -Section $sectionName -Check "Plugins ($pluginPath)" -Status 'WARNING' `
                       -Details "Review manually: $($nonDefault -join ', ')"
        } else {
            Add-Result -Section $sectionName -Check "Plugins ($pluginPath)" -Status 'CLEAN' `
                       -Details 'Only default plugin content found'
        }
    }
}

# ============================================================================
#  Section 2: File System IOCs
# ============================================================================

$sectionName = 'File System'

# --- Malware staging directories (NOT legitimate Windows paths - safe to flag) ---
$malwareDirs = @(
    @{ Name = '%APPDATA%\ProShow';          Path = "$env:APPDATA\ProShow";         Note = 'Payload staging (Chain 1 + 2)' }
    @{ Name = '%APPDATA%\Bluetooth';        Path = "$env:APPDATA\Bluetooth";       Note = 'Chrysalis backdoor staging (Chain 3)' }
)

foreach ($dir in $malwareDirs) {
    if (Test-Path -Path $dir.Path) {
        $files = Get-ChildItem -Path $dir.Path -Recurse -Force -ErrorAction SilentlyContinue
        $fileList = ($files | Select-Object -ExpandProperty Name) -join ', '
        Add-Result -Section $sectionName -Check "$($dir.Name) directory" -Status 'FOUND' `
                   -Details "$($dir.Note) -- Contains $($files.Count) item(s): $fileList"
    } else {
        Add-Result -Section $sectionName -Check "$($dir.Name) directory" -Status 'CLEAN' `
                   -Details 'Not found'
    }
}

# --- Legitimate directories - only flag if specific malicious artifacts are present ---
# USOShared is a legitimate Windows Update directory (Update Session Orchestrator)
$usoPath = "$env:ProgramData\USOShared"
$usoMalwareFiles = @('svchost.exe', 'conf.c', 'libtcc.dll')
if (Test-Path $usoPath) {
    $usoHits = $usoMalwareFiles | Where-Object { Test-Path (Join-Path $usoPath $_) }
    if ($usoHits) {
        Add-Result -Section $sectionName -Check 'ProgramData\USOShared' -Status 'FOUND' `
                   -Details "Malicious artifacts found in legitimate Windows Update directory: $($usoHits -join ', ')"
    } else {
        Add-Result -Section $sectionName -Check 'ProgramData\USOShared' -Status 'CLEAN' `
                   -Details 'Legitimate Windows Update directory (no malicious artifacts)'
    }
} else {
    Add-Result -Section $sectionName -Check 'ProgramData\USOShared' -Status 'CLEAN' `
               -Details 'Directory not present'
}

# Adobe\Scripts may be a legitimate Adobe directory
$adobeScriptsPath = "$env:APPDATA\Adobe\Scripts"
if (Test-Path $adobeScriptsPath) {
    if (Test-Path "$adobeScriptsPath\alien.ini") {
        Add-Result -Section $sectionName -Check '%APPDATA%\Adobe\Scripts' -Status 'FOUND' `
                   -Details 'Contains alien.ini malware configuration file'
    } else {
        Add-Result -Section $sectionName -Check '%APPDATA%\Adobe\Scripts' -Status 'CLEAN' `
                   -Details 'Legitimate Adobe directory (no malicious artifacts)'
    }
} else {
    Add-Result -Section $sectionName -Check '%APPDATA%\Adobe\Scripts' -Status 'CLEAN' `
               -Details 'Not found'
}

# --- Specific malicious files ---
$malwareFiles = @(
    # Chain 1 + 2: ProShow staging
    @{ Name = 'Payload loader (load)';              Path = "$env:APPDATA\ProShow\load";                    Note = 'Kaspersky Chain 1+2 payload' }
    # Config
    @{ Name = 'Config (alien.ini)';                  Path = "$env:APPDATA\Adobe\Scripts\alien.ini";         Note = 'Malware configuration file' }
    # Chain 3: Chrysalis backdoor components
    @{ Name = 'BluetoothService.exe';                Path = "$env:APPDATA\Bluetooth\BluetoothService.exe";  Note = 'Renamed Bitdefender Submission Wizard (DLL sideloading)' }
    @{ Name = 'BluetoothService (shellcode)';        Path = "$env:APPDATA\Bluetooth\BluetoothService";      Note = 'Encrypted Chrysalis backdoor shellcode' }
    @{ Name = 'log.dll (sideload DLL)';              Path = "$env:APPDATA\Bluetooth\log.dll";                Note = 'Malicious DLL - decrypts and executes Chrysalis' }
    # Cobalt Strike artifacts
    @{ Name = 'USOShared svchost.exe';               Path = "$env:ProgramData\USOShared\svchost.exe";       Note = 'Renamed Tiny C Compiler (loads conf.c shellcode)' }
    @{ Name = 'USOShared conf.c';                    Path = "$env:ProgramData\USOShared\conf.c";            Note = 'Metasploit block_api shellcode loader for CS beacon' }
    @{ Name = 'USOShared libtcc.dll';                Path = "$env:ProgramData\USOShared\libtcc.dll";        Note = 'Tiny C Compiler library (used with renamed svchost)' }
    # NSIS temp artifacts
    @{ Name = 'NSIS temp (ns.tmp)';                  Path = "$env:LOCALAPPDATA\Temp\ns.tmp";                Note = 'NSIS installer temp file' }
    # Recon output
    @{ Name = 'Recon output (1.txt)';                Path = "$env:LOCALAPPDATA\Temp\1.txt";                 Note = 'Reconnaissance output' }
    @{ Name = 'Recon output (a.txt)';                Path = "$env:LOCALAPPDATA\Temp\a.txt";                 Note = 'Reconnaissance output' }
    # Self-removal batch
    @{ Name = 'Self-removal (u.bat)';                Path = "$env:LOCALAPPDATA\Temp\u.bat";                 Note = 'Chrysalis self-removal batch script' }
)

foreach ($file in $malwareFiles) {
    if (Test-Path -Path $file.Path) {
        $info = Get-Item -Path $file.Path -Force -ErrorAction SilentlyContinue
        Add-Result -Section $sectionName -Check $file.Name -Status 'FOUND' `
                   -Details "$($file.Note) -- Size: $($info.Length) bytes, Modified: $($info.LastWriteTime), Path: $($file.Path)"
    } else {
        Add-Result -Section $sectionName -Check $file.Name -Status 'CLEAN' -Details 'Not found'
    }
}

# ============================================================================
#  Section 3: Hash Verification
# ============================================================================

$sectionName = 'Hash Verification'

$hashScanPaths = @(
    "$env:APPDATA\ProShow"
    "$env:APPDATA\Adobe\Scripts"
    "$env:APPDATA\Bluetooth"
    "$env:ProgramData\USOShared"
)

$sha1Matches  = [System.Collections.Generic.List[string]]::new()
$sha256Matches = [System.Collections.Generic.List[string]]::new()
$filesScanned = 0

foreach ($dir in $hashScanPaths) {
    if (Test-Path -Path $dir) {
        $filesToScan = Get-ChildItem -Path $dir -File -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($f in $filesToScan) {
            $filesScanned++
            try {
                $sha1Hash = (Get-FileHash -Path $f.FullName -Algorithm SHA1 -ErrorAction Stop).Hash.ToLower()
                if ($knownSha1 -contains $sha1Hash) {
                    $sha1Matches.Add("$($f.FullName) [SHA1: $sha1Hash]")
                }
            } catch { }
            try {
                $sha256Hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash.ToLower()
                if ($knownSha256 -contains $sha256Hash) {
                    $sha256Matches.Add("$($f.FullName) [SHA256: $sha256Hash]")
                }
            } catch { }
        }
    }
}

if ($sha1Matches.Count -gt 0) {
    Add-Result -Section $sectionName -Check 'SHA-1 matches (Kaspersky)' -Status 'FOUND' `
               -Details ($sha1Matches -join '; ')
} else {
    Add-Result -Section $sectionName -Check 'SHA-1 matches (Kaspersky)' -Status 'CLEAN' `
               -Details "No matches in $filesScanned files scanned"
}

if ($sha256Matches.Count -gt 0) {
    Add-Result -Section $sectionName -Check 'SHA-256 matches (Rapid7)' -Status 'FOUND' `
               -Details ($sha256Matches -join '; ')
} else {
    Add-Result -Section $sectionName -Check 'SHA-256 matches (Rapid7)' -Status 'CLEAN' `
               -Details "No matches in $filesScanned files scanned"
}

# ============================================================================
#  Section 4: Persistence Checks
# ============================================================================

$sectionName = 'Persistence'

# Registry Run keys - Chrysalis falls back to HKCU Run key if service creation fails
$runKeyPaths = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
)

$suspiciousRunEntries = [System.Collections.Generic.List[string]]::new()
$suspiciousValuePatterns = @('BluetoothService', 'ProShow', 'USOShared', 'svchost.*-nostdlib', 'svchost.*conf\.c', 'log\.dll')

foreach ($rkPath in $runKeyPaths) {
    try {
        if (Test-Path $rkPath) {
            $props = Get-ItemProperty -Path $rkPath -ErrorAction SilentlyContinue
            if ($props) {
                $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                    $val = [string]$_.Value
                    foreach ($pattern in $suspiciousValuePatterns) {
                        if ($val -match $pattern) {
                            $suspiciousRunEntries.Add("$rkPath\$($_.Name) = $val")
                        }
                    }
                }
            }
        }
    } catch { }
}

if ($suspiciousRunEntries.Count -gt 0) {
    Add-Result -Section $sectionName -Check 'Registry Run keys' -Status 'FOUND' `
               -Details ($suspiciousRunEntries -join '; ')
} else {
    Add-Result -Section $sectionName -Check 'Registry Run keys' -Status 'CLEAN' `
               -Details 'No suspicious Run key entries found'
}

# Windows services - Chrysalis attempts to create a BluetoothService service
$suspiciousServiceNames = @('BluetoothService')
$suspiciousServicePaths = @('Bluetooth', 'ProShow', 'USOShared')
$foundServices = [System.Collections.Generic.List[string]]::new()

try {
    # Check by exact service name first
    foreach ($svcName in $suspiciousServiceNames) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            $wmiSvc = Get-CimInstance -ClassName Win32_Service -Filter "Name='$svcName'" -ErrorAction SilentlyContinue
            $binPath = if ($wmiSvc) { $wmiSvc.PathName } else { '(unknown)' }
            $foundServices.Add("Service '$svcName' exists - Status: $($svc.Status), Path: $binPath")
        }
    }
    # Also scan all service binary paths for suspicious directories
    Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue | ForEach-Object {
        $pathStr = [string]$_.PathName
        foreach ($pattern in $suspiciousServicePaths) {
            if ($pathStr -match [regex]::Escape($pattern)) {
                $entry = "Service '$($_.Name)' binary in suspicious path: $pathStr"
                if (-not $foundServices.Contains($entry)) {
                    $foundServices.Add($entry)
                }
            }
        }
    }
} catch { }

if ($foundServices.Count -gt 0) {
    Add-Result -Section $sectionName -Check 'Windows services' -Status 'FOUND' `
               -Details ($foundServices -join '; ')
} else {
    Add-Result -Section $sectionName -Check 'Windows services' -Status 'CLEAN' `
               -Details 'No suspicious services found'
}

# Scheduled tasks
$suspiciousTaskPatterns = @('BluetoothService', 'ProShow', 'USOShared')
$foundTasks = [System.Collections.Generic.List[string]]::new()

try {
    Get-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object {
        $taskName = $_.TaskName
        $actions  = $_.Actions | ForEach-Object { $_.Execute + ' ' + $_.Arguments }
        $allText  = "$taskName $($actions -join ' ')"
        foreach ($pattern in $suspiciousTaskPatterns) {
            if ($allText -match $pattern) {
                $foundTasks.Add("Task: $taskName, Action: $($actions -join ' | ')")
                break
            }
        }
    }
} catch { }

if ($foundTasks.Count -gt 0) {
    Add-Result -Section $sectionName -Check 'Scheduled tasks' -Status 'FOUND' `
               -Details ($foundTasks -join '; ')
} else {
    Add-Result -Section $sectionName -Check 'Scheduled tasks' -Status 'CLEAN' `
               -Details 'No suspicious scheduled tasks found'
}

# ============================================================================
#  Section 5: Process Checks
# ============================================================================

$sectionName = 'Processes'

# Suspicious process names
$suspiciousProcesses = @('BluetoothService', 'ProShow', 'ConsoleApplication2')
$runningProcs = Get-Process -ErrorAction SilentlyContinue |
                Where-Object { $_.ProcessName -match ($suspiciousProcesses -join '|') }

if ($runningProcs) {
    $procDetails = $runningProcs | ForEach-Object {
        "$($_.ProcessName) (PID: $($_.Id), Path: $(try { $_.Path } catch { 'N/A' }))"
    }
    Add-Result -Section $sectionName -Check 'Malicious processes' -Status 'FOUND' `
               -Details "Running: $($procDetails -join '; ')"
} else {
    Add-Result -Section $sectionName -Check 'Malicious processes' -Status 'CLEAN' `
               -Details 'None running'
}

# Check for GUP.exe with active network connections to non-legitimate targets
try {
    $gupProcs = Get-Process -Name 'GUP' -ErrorAction SilentlyContinue
    if ($gupProcs) {
        $gupPids = $gupProcs | Select-Object -ExpandProperty Id
        $gupConnections = Get-NetTCPConnection -ErrorAction SilentlyContinue |
                          Where-Object { $gupPids -contains $_.OwningProcess -and $_.RemoteAddress -ne '0.0.0.0' -and $_.RemoteAddress -ne '::' }
        if ($gupConnections) {
            $suspiciousGup = $gupConnections | Where-Object { $c2Ips -contains $_.RemoteAddress }
            if ($suspiciousGup) {
                $ips = ($suspiciousGup | Select-Object -ExpandProperty RemoteAddress -Unique) -join ', '
                Add-Result -Section $sectionName -Check 'GUP.exe C2 connections' -Status 'FOUND' `
                           -Details "GUP.exe connected to known C2 IPs: $ips"
            } else {
                $ips = ($gupConnections | Select-Object -ExpandProperty RemoteAddress -Unique) -join ', '
                Add-Result -Section $sectionName -Check 'GUP.exe connections' -Status 'WARNING' `
                           -Details "GUP.exe has active connections to: $ips -- Verify these are legitimate"
            }
        } else {
            Add-Result -Section $sectionName -Check 'GUP.exe connections' -Status 'CLEAN' `
                       -Details 'GUP.exe running but no active remote connections'
        }
    } else {
        Add-Result -Section $sectionName -Check 'GUP.exe connections' -Status 'CLEAN' `
                   -Details 'GUP.exe not currently running'
    }
} catch {
    Add-Result -Section $sectionName -Check 'GUP.exe connections' -Status 'WARNING' `
               -Details "Could not check: $($_.Exception.Message)"
}

# Check for svchost.exe running from USOShared (renamed Tiny C Compiler)
try {
    $svchostProcs = Get-Process -Name 'svchost' -ErrorAction SilentlyContinue
    $fakeSvchost = $svchostProcs | Where-Object {
        try { $_.Path -and $_.Path -match 'USOShared' } catch { $false }
    }
    if ($fakeSvchost) {
        $details = $fakeSvchost | ForEach-Object { "PID: $($_.Id), Path: $($_.Path)" }
        Add-Result -Section $sectionName -Check 'Fake svchost.exe (TCC)' -Status 'FOUND' `
                   -Details "Renamed Tiny C Compiler running from USOShared: $($details -join '; ')"
    } else {
        Add-Result -Section $sectionName -Check 'Fake svchost.exe (TCC)' -Status 'CLEAN' `
                   -Details 'No svchost.exe running from ProgramData\USOShared'
    }
} catch { }

# Chrysalis mutex check
$mutexName = 'Global\Jdhfv_1.0.1'
$mutexFound = $false
try {
    $mutex = [System.Threading.Mutex]::OpenExisting($mutexName)
    $mutexFound = $true
    $mutex.Dispose()
} catch [System.Threading.WaitHandleCannotBeOpenedException] {
    # Mutex does not exist -- this is the expected clean state
} catch {
    # Access denied could mean it exists but we can't open it
    if ($_.Exception.InnerException -is [System.UnauthorizedAccessException]) {
        $mutexFound = $true
    }
}

if ($mutexFound) {
    Add-Result -Section $sectionName -Check 'Chrysalis mutex' -Status 'FOUND' `
               -Details "Mutex '$mutexName' exists - Chrysalis backdoor is likely active"
} else {
    Add-Result -Section $sectionName -Check 'Chrysalis mutex' -Status 'CLEAN' `
               -Details "Mutex '$mutexName' not found"
}

# ============================================================================
#  Section 6: Network IOCs
# ============================================================================

$sectionName = 'Network'

# Active connections to C2 IPs
try {
    $connections = Get-NetTCPConnection -ErrorAction SilentlyContinue
    $matchedIps = $connections |
                  Where-Object { $c2Ips -contains $_.RemoteAddress } |
                  Select-Object RemoteAddress, RemotePort, OwningProcess, State -Unique

    if ($matchedIps) {
        $details = $matchedIps | ForEach-Object {
            $procName = try { (Get-Process -Id $_.OwningProcess -ErrorAction Stop).ProcessName } catch { 'unknown' }
            "$($_.RemoteAddress):$($_.RemotePort) ($procName, PID $($_.OwningProcess), $($_.State))"
        }
        Add-Result -Section $sectionName -Check 'Connections to C2 IPs' -Status 'FOUND' `
                   -Details "Active: $($details -join '; ')"
    } else {
        Add-Result -Section $sectionName -Check 'Connections to C2 IPs' -Status 'CLEAN' `
                   -Details 'No connections to known C2 IPs detected'
    }
} catch {
    Add-Result -Section $sectionName -Check 'Connections to C2 IPs' -Status 'ERROR' `
               -Details "Could not query network connections (may require elevation): $($_.Exception.Message)"
}

# DNS cache check for C2 domains
try {
    $dnsCache = Get-DnsClientCache -ErrorAction SilentlyContinue
    $matchedDns = @()
    if ($dnsCache) {
        $matchedDns = $dnsCache | Where-Object {
            $entry = $_.Entry
            foreach ($d in $c2Domains) {
                if ($entry -like "*$d*") { return $true }
            }
            return $false
        }
    }

    if ($matchedDns) {
        $found = ($matchedDns | Select-Object -ExpandProperty Entry -Unique) -join ', '
        Add-Result -Section $sectionName -Check 'DNS cache: C2 domains' -Status 'FOUND' `
                   -Details "Resolved: $found"
    } else {
        Add-Result -Section $sectionName -Check 'DNS cache: C2 domains' -Status 'CLEAN' `
                   -Details 'No C2 domains found in DNS cache'
    }
} catch {
    Add-Result -Section $sectionName -Check 'DNS cache: C2 domains' -Status 'ERROR' `
               -Details "Could not query DNS cache: $($_.Exception.Message)"
}

# Hosts file check for notepad-plus-plus.org redirection
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
try {
    if (Test-Path $hostsPath) {
        $hostsContent = Get-Content -Path $hostsPath -ErrorAction Stop
        $nppHostsEntries = $hostsContent | Where-Object {
            $_ -match 'notepad' -and $_ -notmatch '^\s*#'
        }
        if ($nppHostsEntries) {
            Add-Result -Section $sectionName -Check 'Hosts file tampering' -Status 'FOUND' `
                       -Details "Notepad-related entries in hosts file: $($nppHostsEntries -join '; ')"
        } else {
            Add-Result -Section $sectionName -Check 'Hosts file tampering' -Status 'CLEAN' `
                       -Details 'No notepad-related redirections in hosts file'
        }
    }
} catch {
    Add-Result -Section $sectionName -Check 'Hosts file tampering' -Status 'ERROR' `
               -Details "Could not read hosts file: $($_.Exception.Message)"
}

# ============================================================================
#  Output
# ============================================================================

$scanEnd = Get-Date
$duration = $scanEnd - $scanStart

# Build header
$header = @"

================================================================================
  Notepad++ Supply Chain Attack IOC Scanner v2.2
  Lotus Blossom / Chrysalis Backdoor (Jun-Dec 2025)
================================================================================
  Machine  : $env:COMPUTERNAME
  User     : $env:USERDOMAIN\$env:USERNAME
  Elevated : $([bool](New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
  Scanned  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  Duration : $($duration.TotalSeconds.ToString('0.00'))s
================================================================================
  Sources:
    Kaspersky : https://securelist.com/notepad-supply-chain-attack/118708/
    Rapid7    : https://www.rapid7.com/blog/post/tr-chrysalis-backdoor-dive-into-lotus-blossoms-toolkit/
    Official  : https://notepad-plus-plus.org/news/hijacked-incident-info-update/
================================================================================

"@

Write-Host $header -ForegroundColor Cyan

# Group results by section
$sections = $results | Select-Object -ExpandProperty Section -Unique

$reportBody = [System.Text.StringBuilder]::new()

foreach ($section in $sections) {
    $sectionHeader = "--- $section "
    $sectionHeader = $sectionHeader.PadRight(80, '-')
    Write-Host $sectionHeader -ForegroundColor White
    [void]$reportBody.AppendLine($sectionHeader)

    $sectionResults = $results | Where-Object { $_.Section -eq $section }
    foreach ($r in $sectionResults) {
        $color = switch ($r.Status) {
            'CLEAN'   { 'Green' }
            'FOUND'   { 'Red' }
            'WARNING' { 'Yellow' }
            'ERROR'   { 'DarkYellow' }
        }
        $statusTag = "[$($r.Status)]"
        $line = "  {0,-40} {1,-10} {2}" -f $r.Check, $statusTag, $r.Details
        Write-Host $line -ForegroundColor $color
        [void]$reportBody.AppendLine($line)
    }
    Write-Host ''
    [void]$reportBody.AppendLine('')
}

# Summary
$foundCount   = ($results | Where-Object { $_.Status -eq 'FOUND' }).Count
$warningCount = ($results | Where-Object { $_.Status -eq 'WARNING' }).Count
$cleanCount   = ($results | Where-Object { $_.Status -eq 'CLEAN' }).Count
$errorCount   = ($results | Where-Object { $_.Status -eq 'ERROR' }).Count

Write-Host ('=' * 80) -ForegroundColor Cyan
$summaryLines = @(
    "  Total Checks : $($results.Count)"
    "  FOUND (IOC)  : $foundCount"
    "  WARNING      : $warningCount"
    "  CLEAN        : $cleanCount"
    "  ERROR        : $errorCount"
)
foreach ($sl in $summaryLines) {
    Write-Host $sl -ForegroundColor White
}

Write-Host ''
if ($foundCount -gt 0) {
    $resultMsg = "RESULT: $foundCount indicator(s) of compromise detected. Investigate immediately."
    Write-Host $resultMsg -ForegroundColor Red
    Write-Host ''
    Write-Host '  Recommended immediate actions:' -ForegroundColor Red
    Write-Host '    1. Isolate this machine from the network' -ForegroundColor Yellow
    Write-Host '    2. Preserve forensic evidence (memory dump, disk image)' -ForegroundColor Yellow
    Write-Host '    3. Engage your incident response team' -ForegroundColor Yellow
    Write-Host '    4. Review Rapid7 report for full Chrysalis analysis' -ForegroundColor Yellow
    Write-Host '    5. Update Notepad++ to v8.9.1+ via manual download from GitHub' -ForegroundColor Yellow
} elseif ($warningCount -gt 0) {
    $resultMsg = "RESULT: No confirmed IOCs, but $warningCount warning(s) require review."
    Write-Host $resultMsg -ForegroundColor Yellow
    Write-Host '  - Ensure Notepad++ is updated to v8.9.1+ (full signature validation)' -ForegroundColor Yellow
    Write-Host '  - Block GUP.exe internet access or route updates through internal repo' -ForegroundColor Yellow
} else {
    $resultMsg = 'RESULT: No indicators of compromise detected.'
    Write-Host $resultMsg -ForegroundColor Green
}
Write-Host ''

# Export if requested
if ($ExportPath) {
    try {
        $exportDir = Split-Path -Path $ExportPath -Parent
        if ($exportDir -and -not (Test-Path $exportDir)) {
            New-Item -Path $exportDir -ItemType Directory -Force | Out-Null
        }
        $fullReport = $header + $reportBody.ToString() + ('=' * 80) + "`n" +
                      ($summaryLines -join "`n") + "`n`n" + $resultMsg + "`n"
        $fullReport | Out-File -FilePath $ExportPath -Encoding UTF8 -Force
        Write-Host "Report exported to: $ExportPath" -ForegroundColor Cyan
    } catch {
        Write-Host "ERROR: Could not export report - $($_.Exception.Message)" -ForegroundColor Red
    }
}
