# HelpDesk-PolicyCheck v10

One-click WPF GUI for common Help Desk endpoint troubleshooting: Group Policy updates, domain trust validation, MDM registration checks, and applied policy listing.

## Requirements

| Requirement       | Detail                                           |
|-------------------|--------------------------------------------------|
| OS                | Windows 10 / 11 (domain-joined or Azure AD-joined) |
| PowerShell        | 5.1+ or PowerShell 7+                           |
| .NET              | WPF assemblies (PresentationFramework, PresentationCore, WindowsBase) |
| Elevation         | Not required for standard operations             |
| Built-in commands | `gpupdate`, `gpresult`, `dsregcmd`, `Test-ComputerSecureChannel` |

## Quick Start

1. Open PowerShell on the target endpoint
2. Run the script:

```powershell
.\HelpDesk-PolicyCheck_v10.ps1
```

The GUI launches centered on screen. Select any action button to begin.

## Modes / Features Walkthrough

### Group Policy Update

1. Click **Group Policy Update**
2. The tool runs `gpupdate` and streams output line-by-line to the output pane
3. On completion, the **Show me the policies** button appears in the footer

### Force Group Policy Update

1. Click **Force Group Policy Update**
2. The tool runs `gpupdate /force`, reapplying all policies regardless of change status
3. Output streams to the pane; the **Show me the policies** button appears on completion

### Test Domain Trust

1. Click **Test Domain Trust**
2. The tool runs `Test-ComputerSecureChannel -Verbose`
3. Results display as either:
   - `HEALTHY` — trust relationship is intact
   - `BROKEN` — includes numbered remediation steps:
     1. Check network connection
     2. Remove computer from domain
     3. Reboot
     4. Delete computer object from AD
     5. Rejoin computer to domain
     6. Reboot
4. If the machine is not domain-joined, a warning suggests using **Check MDM Registration** instead

### Check MDM Registration

1. Click **Check MDM Registration**
2. The tool runs `dsregcmd /status` and parses key fields:
   - Device Name
   - Domain Joined (YES/NO)
   - Azure AD Joined (YES/NO)
   - Tenant Name
3. Device type is classified automatically:

| Domain Joined | Azure AD Joined | Classification              |
|---------------|------------------|-----------------------------|
| YES           | YES              | Hybrid Azure AD Joined      |
| NO            | YES              | Azure AD Joined (Cloud Only)|
| YES           | NO               | Domain Joined Only          |
| NO            | NO               | Workgroup (Not Joined)      |

### Show Me the Policies

1. Appears after any Group Policy update completes
2. Click **Show me the policies**
3. The tool runs `gpresult /R` and parses the output into:
   - **Computer Policies** — list of applied GPOs
   - **User Policies** — list of applied GPOs
   - **Total count** of applied policies

### Clear Output

Click **Clear Output** to reset the output pane.

## Reference Tables

### Output Prefixes

| Prefix    | Meaning                        |
|-----------|--------------------------------|
| `[INFO]`  | Informational message          |
| `[OK]`    | Successful operation           |
| `[WARN]`  | Warning or non-critical issue  |
| `[ERROR]` | Operation failed               |

### Button Layout

| Section                  | Button                     | Command                              |
|--------------------------|----------------------------|--------------------------------------|
| Group Policy             | Group Policy Update        | `gpupdate`                           |
| Group Policy             | Force Group Policy Update  | `gpupdate /force`                    |
| Domain and Device Status | Test Domain Trust          | `Test-ComputerSecureChannel -Verbose`|
| Domain and Device Status | Check MDM Registration     | `dsregcmd /status`                   |
| Footer                   | Clear Output               | Clears output pane                   |
| Footer                   | Show me the policies       | `gpresult /R`                        |

## Features

- Dark-themed WPF interface (production theme: `#1e1e1e` background)
- Timestamped output with severity prefixes (`[OK]`, `[ERROR]`, `[WARN]`, `[INFO]`)
- Green-on-black Consolas output pane for readability
- Buttons disable during operations to prevent overlapping commands
- Scrollable output with automatic scroll-to-end
- Computer name displayed in the header for quick identification
- Contextual **Show me the policies** button appears only after a GP update

## Integration

```
D:\4production\
+-- HelpDesk-PolicyCheck_v10.ps1        # This tool
+-- HelpDesk-PolicyCheck_v10_README.md   # This file
```

This is a standalone endpoint diagnostic tool. It wraps built-in Windows commands (`gpupdate`, `gpresult`, `dsregcmd`, `Test-ComputerSecureChannel`) into a single GUI for Help Desk technicians.

## Common Use Cases

### 1. User reports policy not applying

1. Launch the tool on the affected endpoint
2. Click **Force Group Policy Update**
3. Click **Show me the policies** to verify the expected GPO appears in the list
4. If the GPO is missing, escalate to the AD / GPO team

### 2. User cannot access domain resources

1. Launch the tool on the affected endpoint
2. Click **Test Domain Trust**
3. If BROKEN, follow the on-screen remediation steps
4. If HEALTHY, the issue is likely permissions or network-related

### 3. Verify device enrollment status

1. Launch the tool on the endpoint
2. Click **Check MDM Registration**
3. Confirm the device type matches expectations (Hybrid, Cloud-Only, Domain-Only, or Workgroup)
4. If the device shows as Workgroup when it should be joined, escalate for domain join or Azure AD registration

### 4. New machine setup verification

1. After imaging and domain join, launch the tool
2. Click **Group Policy Update** to pull initial policies
3. Click **Show me the policies** to verify baseline GPOs are applied
4. Click **Test Domain Trust** to confirm trust relationship
5. Click **Check MDM Registration** to confirm Azure AD / Intune enrollment

## Troubleshooting

| Issue                                  | Solution                                                        |
|----------------------------------------|-----------------------------------------------------------------|
| Script will not run (execution policy) | Re-sign the script or run `Set-ExecutionPolicy` as appropriate  |
| `gpupdate` hangs                       | May indicate network issues reaching a domain controller        |
| `Test-ComputerSecureChannel` throws error | Machine may not be domain-joined; use Check MDM Registration  |
| `gpresult /R` returns no policies      | Confirm the machine is domain-joined and can reach a DC         |
| `dsregcmd` not recognized              | Ensure running on Windows 10/11; command is not available on Server Core |
| Buttons stay disabled                  | Close and relaunch the tool; an unhandled error may have interrupted flow |

## Security Notes

- The script runs entirely on the local endpoint with no network calls beyond standard Windows domain communication
- No credentials are collected, stored, or transmitted
- No elevation is required; all commands run in the current user context
- The script is code-signed; re-sign after any modifications to maintain AllSigned execution policy compliance
- `gpresult /R` output may reveal GPO names and organizational structure; treat output with appropriate confidentiality
- Domain trust remediation steps involve AD operations that require elevated privileges and should be performed by authorized personnel
