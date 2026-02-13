# Checksum Tool v4

WPF GUI for verifying file integrity via hash comparison in single-file or batch mode.

## Requirements

- Windows 10/11
- PowerShell 5.1+ or PowerShell 7+
- .NET Framework (PresentationFramework, WinForms assemblies)

## Quick Start

1. Open PowerShell
2. Run the script:

```powershell
.\Checksum-Tool_v4.ps1
```

The GUI launches centered on screen, defaulting to Single File Verification mode.

## Modes / Features Walkthrough

### Single File Verification

1. Select **Single File Verification** (default)
2. Click **BROWSE** or drag and drop a file into the file path field
3. Choose a hash algorithm (SHA256 selected by default)
4. Optionally paste an expected hash from the software publisher
5. Click **VERIFY**
6. A detailed result dialog appears showing the calculated hash
7. If an expected hash was provided, the result shows PASS or FAIL with a clear visual indicator

### Batch Verification

1. Select **Batch Verification (from checksum file)**
2. Click **BROWSE** to select a checksum file (SHA256SUMS, checksums.txt, etc.)
3. The target folder auto-populates to the checksum file's directory — change it if needed
4. Leave **Auto-detect hash algorithm** checked (recommended) or select manually
5. Click **VERIFY**
6. All files listed in the checksum file are verified against the target folder
7. Results appear in the data grid with per-file PASS, FAIL, or MISSING status

### Viewing Details

1. Click a row in the results grid
2. Click **VIEW DETAILS** or double-click the row
3. A detail dialog shows the full calculated and expected hashes
4. Click **COPY HASH** to copy the calculated hash to clipboard

### Exporting Results

1. After verification, click **EXPORT RESULTS**
2. Choose a save location and filename
3. Results export as CSV with status, filename, algorithm, and full hashes

## Reference Tables

### Supported Algorithms

| Algorithm | Hash Length | Recommendation |
|-----------|-----------|----------------|
| SHA256    | 64 chars  | Recommended — industry standard |
| SHA512    | 128 chars | Strongest option |
| SHA1      | 40 chars  | Legacy — avoid for new verification |
| MD5       | 32 chars  | Weak — use only when no alternative |

### Auto-Detection Logic

The tool detects the algorithm from the hash length in the checksum file:

| Hash Length | Detected Algorithm |
|-------------|-------------------|
| 32 characters  | MD5 |
| 40 characters  | SHA1 |
| 64 characters  | SHA256 |
| 128 characters | SHA512 |

### Status Indicators

| Status     | Meaning |
|------------|---------|
| PASS       | Calculated hash matches expected hash |
| FAIL       | Hashes do not match — file may be corrupted or tampered |
| MISSING    | File listed in checksum file was not found in the target folder |
| Calculated | Hash computed successfully (no expected hash provided for comparison) |

### Checksum File Formats

The parser supports two common layouts:

```
# Format 1: hash-first (SHA256SUMS style)
e3b0c44298fc1c149afbf4c8996fb924  filename.iso
e3b0c44298fc1c149afbf4c8996fb924 *filename.iso

# Format 2: filename-first
filename.iso  e3b0c44298fc1c149afbf4c8996fb924
```

Lines starting with `#` and blank lines are ignored.

## Features

- Drag-and-drop file selection for both single file and checksum file inputs
- Auto-detection of hash algorithm from checksum file content
- Sortable results grid with color-coded status indicators
- Detailed drill-down dialog with full hash display and clipboard copy
- CSV export of verification results with timestamps
- Progressive workflow — browse, verify, review, export
- Auto-populates target folder from checksum file location
- Resizable window with scroll support

## Integration

```
D:\4production\
  Checksum-Tool_v4.ps1      <-- this tool
  Checksum-Tool_v4_README.md <-- this file
```

The tool uses the built-in `Get-FileHash` cmdlet for all hash calculations. No external dependencies or modules required. Checksum files can come from any software publisher (ISO downloads, package managers, release pages).

## Common Use Cases

### Verify a Downloaded ISO

1. Download the ISO and its SHA256SUMS file from the publisher
2. Launch Checksum Tool v4
3. Select **Single File Verification**
4. Browse to the ISO file
5. Paste the expected SHA256 hash from the publisher's site
6. Click **VERIFY** — confirm PASS before proceeding with installation

### Batch Verify a Software Release

1. Download all release files and the accompanying checksums file
2. Launch Checksum Tool v4
3. Select **Batch Verification**
4. Browse to the checksums file — the folder auto-populates
5. Click **VERIFY**
6. Review the grid — all files should show PASS
7. Export results to CSV for audit documentation

### Quick Hash Calculation

1. Launch Checksum Tool v4
2. Drag a file into the file path field
3. Leave the expected hash field blank
4. Click **VERIFY**
5. The calculated hash appears — click **COPY HASH** in the detail dialog to grab it

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Script won't run | Verify code signing — script must be signed under AllSigned execution policy |
| "No valid checksums found in file" | Checksum file format not recognized — verify it uses `hash filename` or `filename hash` format |
| All files show MISSING | Target folder path is wrong — browse to the folder containing the actual files |
| Hash shows FAIL for a known-good file | Confirm the algorithm matches what the publisher used — SHA256 vs SHA512 vs MD5 |
| Large file takes a long time | Expected behavior — hashing large ISOs (4+ GB) takes time. The UI will show a wait cursor |
| Drag and drop not working | Ensure the file is dropped directly onto the text field, not the button |

## Security Notes

- **Hash Algorithm Choice**: SHA256 is the recommended default. MD5 and SHA1 are cryptographically weak and should only be used when the publisher provides no stronger option.
- **FAIL Results**: A failed verification means the file does not match the publisher's hash. Do not install or use the file — it may be corrupted, incomplete, or tampered with.
- **Code Signing**: This script should be signed per AllSigned execution policy. Re-sign after any edits.
- **No Network Access**: The tool operates entirely offline. All hash calculations are performed locally using `Get-FileHash`.
- **No Data Persistence**: Nothing is saved to disk unless you explicitly export results via the EXPORT button.
