HelpDesk-QuickActions_v8.ps1
=============================

PURPOSE
-------
A simple GUI tool for Help Desk technicians to run common troubleshooting
commands on endpoints without needing to open a command prompt or remember
syntax. No elevation required.

REQUIREMENTS
------------
- Windows 10 / Windows 11
- PowerShell 5.1 or later
- No admin rights needed

HOW TO RUN
----------
1. Right-click the script and select "Run with PowerShell"
   -or-
2. Open PowerShell and run: .\HelpDesk-QuickActions_v8.ps1

BUTTONS
-------

GROUP POLICY UPDATE
  Runs: gpupdate
  Use when: User reports policy changes aren't applying, drive mappings
  missing, or after making AD group membership changes.

FORCE GROUP POLICY UPDATE
  Runs: gpupdate /force
  Use when: Standard GP update didn't resolve the issue. Forces reapplication
  of all policies, not just changed ones.

TEST DOMAIN TRUST
  Runs: Test-ComputerSecureChannel
  Use when: User can't authenticate, "trust relationship failed" errors,
  or machine seems disconnected from the domain.

  If broken, displays remediation steps:
    1. Remove computer from domain (use local admin)
    2. Reboot
    3. Delete computer object from AD
    4. Rejoin computer to domain
    5. Reboot

CHECK MDM REGISTRATION
  Runs: dsregcmd /status (parsed for key info)
  Use when: Need to verify how a device is joined/managed, troubleshooting
  Intune enrollment, or confirming hybrid Azure AD join status.

  Displays:
    - Device Name
    - Domain Joined (YES/NO)
    - Azure AD Joined (YES/NO)
    - Tenant Name
    - Device Type classification
    - MDM/Intune enrollment status

SHOW ME THE POLICIES
  Runs gpresult and displays the applied GPO names in the WPF terminal-style output box

DEVICE TYPES EXPLAINED
----------------------
HYBRID AZURE AD JOINED
  - Machine is joined to on-premises AD
  - Also registered with Azure AD
  - Can receive policies from both AD and Intune

AZURE AD JOINED (Cloud Only)
  - Not joined to on-premises AD
  - Managed entirely through Azure AD / Intune
  - Common for remote or BYOD scenarios

DOMAIN JOINED ONLY
  - Traditional on-premises AD join
  - Not registered with Azure AD
  - May need hybrid join configured

WORKGROUP (Not Joined)
  - Not connected to any domain
  - Not registered with Azure AD
  - May need to be joined to domain or enrolled in Intune

OUTPUT WINDOW
-------------
- Green text on black background (terminal style)
- Timestamped entries with status prefixes:
    [OK]    - Success
    [ERROR] - Failure
    [WARN]  - Warning or attention needed
    [INFO]  - Informational
- Use "Clear Output" button to reset

NOTES
-----
- All actions run in the current user context (no elevation)
- Results are displayed in the tool only (not logged to file)
- Safe to run multiple times
