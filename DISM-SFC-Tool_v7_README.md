# DISM-SFC-Tool v7

WPF GUI for one-click DISM and SFC system image repair with a smart mode that skips unnecessary steps.

## Requirements

| Requirement   | Detail                                                        |
|---------------|---------------------------------------------------------------|
| OS            | Windows 10 / 11                                               |
| PowerShell    | 5.1+ or PowerShell 7+                                        |
| .NET          | WPF assemblies (PresentationFramework, PresentationCore, WindowsBase) |
| Elevation     | Required — must Run as Administrator                          |
| Assemblies    | System.Windows.Forms (for DoEvents during long operations)    |

## Quick Start

1. Right-click PowerShell and select **Run as Administrator**
2. Run the script:

```powershell
.\DISM-SFC-Tool_v7.ps1
```

The GUI launches centered on screen. Select any action button to begin.

## Modes / Features Walkthrough

### DISM Operations

#### CheckHealth

1. Click **CheckHealth**
2. Runs `DISM.exe /Online /Cleanup-Image /CheckHealth`
3. Quick pass/fail check — reads the corruption flag without scanning files
4. Completes in seconds

#### ScanHealth

1. Click **ScanHealth**
2. Runs `DISM.exe /Online /Cleanup-Image /ScanHealth`
3. Thorough scan of the component store for corruption
4. Can take several minutes depending on the endpoint

#### RestoreHealth

1. Click **RestoreHealth**
2. Runs `DISM.exe /Online /Cleanup-Image /RestoreHealth`
3. Repairs component store corruption using Windows Update as a source
4. Requires internet connectivity to download replacement files

### System File Checker

#### SFC /scannow

1. Click **SFC /scannow**
2. Runs `sfc.exe /scannow`
3. Scans all protected system files and replaces corrupted files from the component store
4. Best results when run after DISM RestoreHealth

#### Run All (Smart)

1. Click **Run All (Smart)** (green button)
2. The tool executes the full repair pipeline automatically:

| Step | Command        | Logic                                                          |
|------|----------------|----------------------------------------------------------------|
| 1    | CheckHealth    | Always runs — quick corruption flag check                      |
| 2    | ScanHealth     | Always runs — thorough scan with output capture                |
| 3    | RestoreHealth  | Conditional — only runs if ScanHealth detects corruption       |
| 4    | SFC /scannow   | Always runs — final system file verification                   |

3. ScanHealth output is analyzed for corruption indicators:
   - `component store corruption` (excluding "No component store corruption")
   - `repairable`
   - `component store repair`
4. If none are found, RestoreHealth is skipped and the tool proceeds directly to SFC
5. A restart advisory is displayed on completion

### Footer Buttons

- **Clear Output** — resets the output pane
- **Close** — appears after any operation completes; closes the window

## Reference Tables

### Output Prefixes

| Prefix    | Meaning                        |
|-----------|--------------------------------|
| `[INFO]`  | Informational / progress       |
| `[OK]`    | Successful operation           |
| `[WARN]`  | Warning or non-zero exit code  |
| `[ERROR]` | Operation failed               |

### DISM Exit Codes

| Exit Code | Meaning                                         |
|-----------|-------------------------------------------------|
| 0         | Operation completed successfully                |
| 87        | Invalid argument — check command syntax         |
| 112       | Insufficient disk space                         |
| 1726      | RPC server unavailable                          |
| 1910      | Source for RestoreHealth not found               |

### Button Map

| Section              | Button             | Command                                              |
|----------------------|--------------------|------------------------------------------------------|
| DISM Operations      | CheckHealth        | `DISM.exe /Online /Cleanup-Image /CheckHealth`       |
| DISM Operations      | ScanHealth         | `DISM.exe /Online /Cleanup-Image /ScanHealth`        |
| DISM Operations      | RestoreHealth      | `DISM.exe /Online /Cleanup-Image /RestoreHealth`     |
| System File Checker  | SFC /scannow       | `sfc.exe /scannow`                                   |
| System File Checker  | Run All (Smart)    | Sequential pipeline (CheckHealth > ScanHealth > conditional RestoreHealth > SFC) |
| Footer               | Clear Output       | Clears output pane                                   |
| Footer               | Close              | Closes the window                                    |

## Features

- Dark-themed WPF interface (production theme: `#1e1e1e` background)
- Timestamped output with severity prefixes (`[OK]`, `[ERROR]`, `[WARN]`, `[INFO]`)
- Green-on-black Consolas output pane for readability
- Real-time streaming — command output appears line-by-line as it runs
- Buttons disable during operations to prevent overlapping commands
- Smart mode analyzes ScanHealth output to skip unnecessary RestoreHealth
- Close button appears only after an operation completes
- Computer name displayed in the header for quick identification

## Integration

```
D:\4production\
+-- DISM-SFC-Tool_v7.ps1        # This tool
+-- DISM-SFC-Tool_v7_README.md   # This file
```

This is a standalone endpoint repair tool. It wraps built-in Windows commands (`DISM.exe`, `sfc.exe`) into a single GUI for Help Desk technicians and system administrators. No external modules or dependencies required.

## Common Use Cases

### 1. Routine system health check

1. Launch the tool elevated on the endpoint
2. Click **CheckHealth** for a quick pass/fail
3. If corruption is flagged, click **ScanHealth** for details
4. If repair is needed, click **RestoreHealth** then **SFC /scannow**

### 2. Full automated repair (recommended)

1. Launch the tool elevated
2. Click **Run All (Smart)**
3. Walk away — the tool runs the full pipeline and skips RestoreHealth if not needed
4. Review the output when complete; restart if advised

### 3. Post-update troubleshooting

1. After a failed Windows Update, launch the tool elevated
2. Click **Run All (Smart)** to repair any corruption left behind
3. Retry Windows Update after restart

### 4. Pre-imaging baseline verification

1. Before capturing an image, launch the tool on the reference machine
2. Click **Run All (Smart)** to ensure no corruption exists
3. Confirm all steps report `[OK]` before proceeding with image capture

## Troubleshooting

| Issue                                      | Solution                                                             |
|--------------------------------------------|----------------------------------------------------------------------|
| Script fails with "requires administrator" | Right-click PowerShell > Run as Administrator                        |
| Script will not run (execution policy)     | Re-sign the script or verify AllSigned policy is satisfied           |
| DISM hangs or takes very long              | ScanHealth and RestoreHealth can take 15-30 min; let them complete   |
| RestoreHealth fails (exit code 1910)       | Source files not found — check internet or specify a local source    |
| SFC reports "could not perform repair"     | Run RestoreHealth first to fix the component store, then retry SFC   |
| GUI freezes momentarily                    | Normal during output streaming; DoEvents keeps the UI responsive     |
| Exit code non-zero but no visible error    | Check `C:\Windows\Logs\DISM\dism.log` or `C:\Windows\Logs\CBS\CBS.log` |

## Security Notes

- Requires elevation — the script enforces `#Requires -RunAsAdministrator`
- All commands run locally on the current endpoint with no network calls beyond Windows Update for RestoreHealth
- No credentials are collected, stored, or transmitted
- DISM and SFC output may reveal system configuration details; treat output with appropriate confidentiality
- The script is code-signed; re-sign after any modifications to maintain AllSigned execution policy compliance
- RestoreHealth downloads files from Microsoft Windows Update servers; ensure this traffic is permitted by network policy
