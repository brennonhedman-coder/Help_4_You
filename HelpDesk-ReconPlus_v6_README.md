# Help Desk ReconPlus v6

WPF GUI for Active Directory computer and user lookups with an embedded PowerShell terminal.

## Requirements

- Windows 10/11 (domain-joined)
- PowerShell 5.1+ or PowerShell 7+
- .NET Framework (PresentationFramework, WinForms assemblies)
- RSAT Active Directory module for AD lookups
- WinRM enabled on target endpoints for Invoke-Command connectivity

## Quick Start

1. Open PowerShell on a domain-joined workstation
2. Run the script:

```powershell
.\HelpDesk-ReconPlus_v6.ps1
```

The GUI launches centered on screen with computer lookup, user lookup, and an embedded terminal ready to use.

## Modes / Features Walkthrough

### Domain Controller Lookup

1. Manually enter your Domain Controller or use built-in search

### Computer Lookup

1. Enter a hostname in the **Target Computer** field
2. Click **Lookup** (or press Enter)
3. The tool runs `nslookup` and resolves the IP address
4. If the IP address is not resolved, a warning is displayed — the hostname likely does not exist
5. If the IP is valid, the **Ping Endpoint** button appears
6. Click **Ping Endpoint** to verify the machine is online (sends 2 ICMP packets)
7. If ping succeeds, the "Persistant" **Invoke-Command** session input is available

### User Lookup

1. Enter a SAMAccountName in the **Target User** field
2. Click **Lookup** (or press Enter)
3. The tool queries AD and displays:
   - Display name, email, title, department
   - Last logon date with days-ago calculation
   - Password last set with days-ago calculation
   - Account enabled/disabled status
   - Account lockout status
4. The **Find User's Endpoint** button appears after a successful lookup

### Find User's Endpoint 

1. After a user lookup, click **Find User's Endpoint**
2. The tool searches for AD bound computers matching the username in:
   - Computer name (contains username)
   - Computer description (contains username)
3. Results display computer name, last logon date, and description

### Embedded PowerShell Terminal

1. Type any PowerShell command in the input field at the bottom
2. Press **Enter** to execute
3. Use **Up/Down** arrows to navigate command history
4. Press **Escape** to clear the input field
5. Commands entered into the embedded terminal with a target computer selected are executed remotely on the target using **Invoke-Command**
6. Commands entered into the embedded terminal without a target computer selected are executed locally
7. Click **Clear Terminal** to reset the output pane

## Reference Tables

### Domain Controller Detection

Smart search with "Fuzzy" error handling using Get-ADDomainController

### Terminal Log Prefixes

| Prefix    | Meaning                     |
|-----------|-----------------------------|
| `[OK]`    | Successful operation        |
| `[ERROR]` | Operation failed            |
| `[WARN]`  | Caution or missing data     |
| `[INFO]`  | Informational status update |

### Button Visibility States

| Button             | Appears When                            |
|--------------------|-----------------------------------------|
| Ping Endpoint      | Computer lookup resolves Endpoint IP    |
| Find User's Endpoint | User lookup succeeds                  |

## Features

- Dark-themed production UI (`#1e1e1e` background, `#0078d4` accent buttons)
- Progressive disclosure — buttons appear only when the prerequisite step succeeds
- Command history with Up/Down arrow navigation
- Enter key triggers lookup in both input fields
- Embedded runspace executes commands without spawning external windows
- Error and warning streams captured and displayed inline
- Window is resizable with grip

## Integration

```
D:\4production\
  HelpDesk-ReconPlus_v6.ps1     <-- this tool
  LHelpDesk-ReconPlus_README.md <-- this file
```

The tool queries Active Directory directly using the RSAT `ActiveDirectory` module. It uses `nslookup` for DNS resolution and `Test-Connection` for ICMP ping. Remote sessions are established via WinRM (`Invoke-Command`).

## Common Use Cases

### Helpdesk: User Can't Log In

1. Enter the username in **Target User** and click **Lookup**
2. Check if the account is DISABLED or locked out
3. Review password age — if expired, that's your answer
4. Check last logon — if "Never," the account may not be provisioned correctly

### Helpdesk: Find Which Computer a User Is On

1. Look up the user first to confirm the account exists
2. Click **Find User's Endpoint**
3. Review the list of computers matching that username
4. Enter the computer name in the **Target Computer** field to connect

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Active Directory module not installed" | Install RSAT: `Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools` |
| nslookup returns DC IP for a valid hostname | DNS may be stale — try `ipconfig /flushdns` then re-lookup |
| Ping succeeds but 'Invoke-Command' fails | WinRM may not be enabled on the target - Get eyes on the endpoint to troubleshoot in-person |
| Script won't run | Verify code signing — script must be signed under AllSigned execution policy |
| GUI freezes during lookup | Long-running AD queries block the UI thread — wait for completion |
| "User not found" for a valid account | Confirm you're using the SAMAccountName, not display name or email |

## Security Notes

- **Invoke-Command**: `Invoke-Command` uses WinRM and will generate security event logs on the target endpoint. Enterprise EDR solutions may flag lateral movement — notify your security team that this tool is in use.
- **AD Queries**: `Get-ADUser -Properties *` retrieves all attributes. In large environments, consider scoping to only the properties you need for performance.
- **Code Signing**: This script should be signed per AllSigned execution policy. Re-sign after any edits.
- **No Credentials Stored**: The tool uses the current user's domain credentials — no passwords are hardcoded or cached.
- **Runspace Execution**: Commands run in a separate PowerShell runspace. Script Block Logging (if enabled) will capture all commands executed through the embedded terminal.
