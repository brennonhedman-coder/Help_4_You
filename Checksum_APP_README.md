# Checksum Verifier Ultimate

A PowerShell-based GUI tool for verifying file integrity using cryptographic hash checksums. Supports single file verification and batch processing from checksum files.

## Requirements

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or later
- .NET Framework 4.5+ (for WPF)

## Quick Start

1. Right-click `Checksum_APP.ps1` and select **Run with PowerShell**, or run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "Checksum_APP.ps1"
   ```
2. The GUI will open with Single File mode selected by default

## Verification Modes

### Single File Mode

Verify one file at a time by calculating its hash and optionally comparing it to an expected value.

**Steps:**
1. Click **Browse** or drag-and-drop a file into the file path field
2. Select the hash algorithm (SHA256 is recommended and selected by default)
3. Optionally paste the expected hash from the software publisher
4. Click **Verify**

**Results:**
- If no expected hash is provided, the tool calculates and displays the hash
- If an expected hash is provided, the tool compares them and shows PASS or FAIL

### Batch Mode

Verify multiple files at once using a checksum file (like SHA256SUMS).

**Steps:**
1. Select **Batch Verification** mode
2. Browse to or drag-and-drop the checksum file (e.g., `SHA256SUMS`, `checksums.txt`)
3. Select the folder containing the files to verify (auto-populated from checksum file location)
4. Ensure **Auto-detect hash algorithm** is checked (recommended)
5. Click **Verify**

**Supported Checksum File Formats:**
```
# Standard format (hash first, then filename)
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  filename.exe
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 *filename.exe

# Alternative format (filename first)
filename.exe e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

## Supported Hash Algorithms

| Algorithm | Hash Length | Use Case |
|-----------|-------------|----------|
| **SHA256** | 64 characters | Recommended - modern standard |
| SHA512 | 128 characters | Higher security, larger output |
| SHA1 | 40 characters | Legacy - being phased out |
| MD5 | 32 characters | Legacy - not recommended for security |

## What to Expect

When you run the tool, you'll see:

1. **Mode Selection** - Toggle between Single File and Batch modes
2. **Input Panel** - File/folder selection and algorithm options
3. **Results Grid** - Shows verification results with status, filename, algorithm, and hashes
4. **Action Bar** - Status message and action buttons

### Status Indicators

| Status | Meaning |
|--------|---------|
| `✓ PASS` | Hash matches the expected value - file is authentic |
| `✗ FAIL` | Hash does not match - file may be corrupted or tampered |
| `⚠ MISSING` | File listed in checksum file was not found in the folder |
| `Calculated` | Hash was computed (no expected value provided for comparison) |

### Detailed Results Dialog

After verification, a detailed results window shows:
- Full calculated hash (with copy button)
- Full expected hash (if provided)
- Clear pass/fail indication with explanation

Double-click any row in the results grid to view its detailed results.

## Features

### Drag-and-Drop
- Drag files directly onto the file path field
- Drag checksum files onto the checksum file field

### Auto-Detect Algorithm
In batch mode, the tool automatically determines the hash algorithm based on hash length:
- 32 characters = MD5
- 40 characters = SHA1
- 64 characters = SHA256
- 128 characters = SHA512

### Export Results
Click **Export Results** to save verification results to a CSV file for documentation or audit purposes.

## Integration with Software Trust Verifier

This tool is designed to work alongside `SoftwareTrustVerifier_v3.ps1`. The Software Trust Verifier includes a **Checksum Verifier** button that launches this tool automatically.

To enable this integration, place both scripts in the same folder:
```
D:\scripting\
├── SoftwareTrustVerifier_v3.ps1
├── Checksum_APP.ps1
└── TrustedSoftware.json
```

## Common Use Cases

### Verifying a Downloaded Installer
1. Download the installer and the publisher's checksum/hash
2. Open Checksum Verifier Ultimate
3. Browse to the downloaded file
4. Paste the expected hash
5. Click Verify
6. Confirm the result shows `✓ PASS`

### Verifying Linux ISO Downloads
Many Linux distributions provide SHA256SUMS files:
1. Download the ISO and SHA256SUMS file to the same folder
2. Open Checksum Verifier Ultimate
3. Select **Batch Verification** mode
4. Browse to the SHA256SUMS file
5. Click Verify
6. Confirm all files show `✓ PASS`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "File not found" error | Ensure the file path is correct and the file exists |
| Hash mismatch on valid file | Re-download the file - it may have been corrupted during transfer |
| Checksum file not parsing | Ensure the format matches one of the supported formats (hash + filename) |
| Batch mode missing files | Verify the folder path contains the files listed in the checksum file |
| Wrong algorithm detected | Uncheck "Auto-detect" and manually select the correct algorithm |

## Security Notes

- Always obtain expected hashes from the official software publisher's website
- Use HTTPS when downloading both files and checksums
- SHA256 is the recommended algorithm for security verification
- A matching hash confirms the file hasn't been modified, but doesn't guarantee the original source is trustworthy
- For complete verification, use this tool alongside digital signature checks (available in Software Trust Verifier)
