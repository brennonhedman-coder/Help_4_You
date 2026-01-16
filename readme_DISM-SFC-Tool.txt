DISM & SFC REPAIR TOOL
======================

Scripts: DISM-SFC-Tool.txt (v1), DISM-SFC-Tool-v2.ps1 (v2), DISM-SFC-Tool-v3.ps1 (v3)

DESCRIPTION
-----------
A GUI-based Windows system repair tool that wraps DISM and SFC commands in a
user-friendly interface. Allows running individual repair operations or a
complete repair sequence with real-time output display.

VERSION HISTORY
---------------
v1: Original implementation with basic GUI and manual operation buttons

v2: Added smart sequence logic
    - Skips RestoreHealth if ScanHealth finds no corruption
    - Saves time when the component store is healthy

v3: Added Close button with smart enable/disable behavior
    - Close button starts disabled when tool launches
    - Becomes enabled only after any operation completes
    - Disables again while operations are running
    - Provides clean exit option without using window X button

REQUIREMENTS
------------
- Windows PowerShell 5.1 or later
- Administrative privileges required
- No internet connection required (uses local Windows component store)

WHAT TO EXPECT
--------------
1. A dark-themed GUI window will open with the following buttons:
   - DISM CheckHealth: Quick component store validation
   - DISM ScanHealth: Thorough component store scan
   - DISM RestoreHealth: Repairs component store issues
   - SFC /scannow: Scans and repairs system files
   - Run All (Smart): Executes full sequence with smart skip logic

2. Bottom status bar includes:
   - Status text (shows current operation or "Ready")
   - Clear Output button: Clears the output display
   - Close button: Exits the tool (enabled after operations complete)

3. Output displays in a console-style box (green text on black background)

4. IMPORTANT: These operations can take significant time to complete.
   It is normal for the window to periodically show "Not Responding"
   during long operations. Please be patient and let it finish.

5. Buttons are disabled during operations to prevent concurrent runs

SMART SEQUENCE LOGIC
--------------------
When using "Run All (Smart)", the tool will:
1. Run CheckHealth
2. Run ScanHealth and analyze the output
3. IF corruption detected: Run RestoreHealth
   IF no corruption: Skip RestoreHealth and proceed to SFC
4. Run SFC /scannow

The output box will clearly indicate whether RestoreHealth was run or skipped.

TYPICAL RUN TIMES
-----------------
- CheckHealth: ~10 seconds
- ScanHealth: 5-15 minutes
- RestoreHealth: 10-30 minutes (if needed)
- SFC /scannow: 10-20 minutes

Total time varies based on system state and disk speed.

LAUNCHING THE TOOL
------------------
Option 1: Right-click the .ps1 file > Run with PowerShell
Option 2: Create a shortcut with target:
          powershell.exe -ExecutionPolicy Bypass -File "path\to\DISM-SFC-Tool-v3.ps1"
