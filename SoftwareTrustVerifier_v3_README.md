# Software Trust Verifier - Help Desk Edition v3

A PowerShell-based GUI tool for verifying software authenticity before installation. Designed for IT help desk staff to quickly validate that software downloads are legitimate and from official sources.

## Requirements

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or later
- .NET Framework 4.5+ (for WPF)
- `TrustedSoftware.json` database file in the same folder as the script

### Optional
- `Checksum_APP.ps1` for hash verification (launched via the Checksum Verifier button)

## Quick Start

1. Place `SoftwareTrustVerifier_v3.ps1` and `TrustedSoftware.json` in the same folder
2. Right-click the script and select **Run with PowerShell**, or run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "SoftwareTrustVerifier_v3.ps1"
   ```
3. The dark-themed GUI will open

## How It Works

The tool uses a 3-step verification process:

### Step 1: Software Identification

Enter the name of the software the user wants to install. The tool searches a local database of known software with **typo-tolerant fuzzy matching**.

- Type a software name (e.g., "chrome", "vlc", "7zip")
- Select from matching results, or
- Click **Proceed Anyway** for unknown software (with warnings)

### Step 2: URL Verification

Paste the download URL to verify it's from an official source.

- The tool extracts the domain and checks it against known official domains
- Green = matches official source
- Red = does not match (potential risk)
- For unknown software, the domain is displayed but cannot be verified

### Step 3: Digital Signature Check

Browse to or drag-and-drop the downloaded installer file.

- Checks if the file has a valid Authenticode digital signature
- Verifies the signer matches the expected publisher
- Works with `.exe` and `.msi` files

## Trust Tiers

Software publishers are categorized into trust tiers:

| Tier | Color | Description |
|------|-------|-------------|
| **Trusted** | Green | Major vendors with strong security track records (Microsoft, Adobe, etc.) |
| **Verified** | Blue | Well-known publishers with verified signing practices |
| **Community** | Orange | Open-source or community projects |
| **Caution** | Red | Publishers requiring extra scrutiny |
| **Unknown** | Gray | Software not in the database |

## What to Expect

When you run the tool, you'll see:

1. **Header bar** with trust tier legend
2. **Three verification sections** (numbered 1-3) with input fields and action buttons
3. **Verification Summary** showing status icons for each check:
   - `O` = Not checked
   - `+` = Passed
   - `!` = Warning/Failed
   - `?` = Unknown/Needs attention
   - `X` = Failed
4. **Action buttons** at the bottom:
   - **Checksum Verifier** - Opens the hash verification tool
   - **Save Report** - Exports results to a text file
   - **Reset** - Clears all fields and starts over

## Verification Summary Panel

The summary shows four status indicators:

| Check | What It Shows |
|-------|---------------|
| **Publisher** | Trust tier of the software publisher |
| **URL** | Whether the download URL is from an official domain |
| **Signature** | Digital signature validity and signer match |
| **Checksum** | Reserved for hash verification (via external tool) |

## Overall Status Messages

At the bottom of the window, you'll see one of these status messages:

- **"All checks passed - software appears legitimate"** (green) - Safe to proceed
- **"Signature valid - but software is unknown, proceed with caution"** (orange) - Use judgment
- **"WARNING: [issues listed]"** (red) - One or more checks failed

## Saving Reports

Click **Save Report** to generate a text file containing:
- Software identification details
- URL verification results
- Digital signature check results
- Overall assessment
- Timestamp and verifier information

Useful for audit trails and documentation.

## Database Format

The `TrustedSoftware.json` file should contain:

```json
{
  "publishers": {
    "publisher_id": {
      "name": "Publisher Name",
      "tier": "trusted",
      "signingNames": ["Expected Signer Name"]
    }
  },
  "software": [
    {
      "names": ["Software Name", "alternate name", "abbreviation"],
      "publisher": "publisher_id",
      "officialDomains": ["example.com", "download.example.com"],
      "downloadPage": "https://example.com/download",
      "notes": "Optional notes"
    }
  ]
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Database not found" error | Ensure `TrustedSoftware.json` is in the same folder as the script |
| Script won't run | Run PowerShell as Administrator or adjust execution policy |
| Signature check fails on valid file | File may have been modified after download, or certificate expired |
| Drag-and-drop not working | Run PowerShell with same elevation as the source (both as admin or both as user) |

## Security Notes

- This tool helps verify software but is not a guarantee of safety
- Always use multiple verification methods for critical systems
- Keep the `TrustedSoftware.json` database updated
- Unknown software should be researched before installation
- A valid signature only means the file hasn't been tampered with since signing
