#Requires -RunAsAdministrator
Add-Type -AssemblyName PresentationFramework, System.Windows.Forms

# XAML GUI Definition
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="DISM &amp; SFC Repair Tool v3" Height="500" Width="700"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <TextBlock Grid.Row="0" Text="Windows System Repair Tool"
                   FontSize="20" FontWeight="Bold" Foreground="#ffffff"
                   Margin="0,0,0,10"/>

        <!-- Buttons -->
        <WrapPanel Grid.Row="1" Margin="0,0,0,10">
            <Button Name="btnCheckHealth" Content="DISM CheckHealth"
                    Width="130" Height="35" Margin="0,0,10,5" Background="#0078D4"
                    Foreground="White" BorderThickness="0"/>
            <Button Name="btnScanHealth" Content="DISM ScanHealth"
                    Width="130" Height="35" Margin="0,0,10,5" Background="#0078D4"
                    Foreground="White" BorderThickness="0"/>
            <Button Name="btnRestoreHealth" Content="DISM RestoreHealth"
                    Width="140" Height="35" Margin="0,0,10,5" Background="#0078D4"
                    Foreground="White" BorderThickness="0"/>
            <Button Name="btnSFC" Content="SFC /scannow"
                    Width="110" Height="35" Margin="0,0,10,5" Background="#0078D4"
                    Foreground="White" BorderThickness="0"/>
            <Button Name="btnRunAll" Content="Run All (Smart)"
                    Width="140" Height="35" Margin="0,0,10,5" Background="#107C10"
                    Foreground="White" BorderThickness="0" FontWeight="Bold"/>
        </WrapPanel>

        <!-- Output Box -->
        <TextBox Name="txtOutput" Grid.Row="2"
                 Background="#0C0C0C" Foreground="#33FF33"
                 FontFamily="Consolas" FontSize="12"
                 IsReadOnly="True" TextWrapping="Wrap"
                 VerticalScrollBarVisibility="Auto"
                 AcceptsReturn="True" Padding="5"/>

        <!-- Status Bar -->
        <Grid Grid.Row="3" Margin="0,10,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Name="txtStatus" Grid.Column="0" Foreground="#888888"
                       VerticalAlignment="Center" Text="Ready"/>
            <Button Name="btnClear" Grid.Column="1" Content="Clear Output"
                    Width="100" Height="30" Background="#333333"
                    Foreground="White" BorderThickness="0" Margin="0,0,10,0"/>
            <Button Name="btnClose" Grid.Column="2" Content="Close"
                    Width="80" Height="30" Background="#D41A1A"
                    Foreground="White" BorderThickness="0" IsEnabled="False"/>
        </Grid>
    </Grid>
</Window>
"@

# Load XAML
$Reader = (New-Object System.Xml.XmlNodeReader $XAML)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Get Controls
$btnCheckHealth = $Window.FindName("btnCheckHealth")
$btnScanHealth = $Window.FindName("btnScanHealth")
$btnRestoreHealth = $Window.FindName("btnRestoreHealth")
$btnSFC = $Window.FindName("btnSFC")
$btnRunAll = $Window.FindName("btnRunAll")
$btnClear = $Window.FindName("btnClear")
$btnClose = $Window.FindName("btnClose")
$txtOutput = $Window.FindName("txtOutput")
$txtStatus = $Window.FindName("txtStatus")

# Helper function to append output
function Write-Output-Box {
    param([string]$Text)
    $txtOutput.Dispatcher.Invoke([action]{
        $txtOutput.AppendText("$Text`r`n")
        $txtOutput.ScrollToEnd()
    })
}

function Set-Status {
    param([string]$Text)
    $txtStatus.Dispatcher.Invoke([action]{
        $txtStatus.Text = $Text
    })
}

function Set-ButtonsEnabled {
    param([bool]$Enabled)
    $Window.Dispatcher.Invoke([action]{
        $btnCheckHealth.IsEnabled = $Enabled
        $btnScanHealth.IsEnabled = $Enabled
        $btnRestoreHealth.IsEnabled = $Enabled
        $btnSFC.IsEnabled = $Enabled
        $btnRunAll.IsEnabled = $Enabled
        # Enable Close button only when operations complete (Enabled = $true)
        if ($Enabled) {
            $btnClose.IsEnabled = $true
        } else {
            $btnClose.IsEnabled = $false
        }
    })
}

# Function to run a command and capture output
# Returns a hashtable with ExitCode and Output
function Run-Command {
    param(
        [string]$DisplayName,
        [string]$Command,
        [string]$Arguments,
        [switch]$CaptureOutput
    )

    Write-Output-Box "=============================================="
    Write-Output-Box "Starting: $DisplayName"
    Write-Output-Box "Command: $Command $Arguments"
    Write-Output-Box "=============================================="
    Write-Output-Box ""

    Set-Status "Running: $DisplayName..."

    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $Command
    $ProcessInfo.Arguments = $Arguments
    $ProcessInfo.RedirectStandardOutput = $true
    $ProcessInfo.RedirectStandardError = $true
    $ProcessInfo.UseShellExecute = $false
    $ProcessInfo.CreateNoWindow = $true

    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $ProcessInfo
    $Process.Start() | Out-Null

    # Collect output if requested
    $OutputLines = @()

    # Read output line by line
    while (-not $Process.StandardOutput.EndOfStream) {
        $Line = $Process.StandardOutput.ReadLine()
        if ($Line) {
            Write-Output-Box $Line
            if ($CaptureOutput) {
                $OutputLines += $Line
            }
        }
        [System.Windows.Forms.Application]::DoEvents()
    }

    # Capture any errors
    $ErrorOutput = $Process.StandardError.ReadToEnd()
    if ($ErrorOutput) {
        Write-Output-Box "ERRORS: $ErrorOutput"
    }

    $Process.WaitForExit()
    $ExitCode = $Process.ExitCode

    Write-Output-Box ""
    Write-Output-Box "$DisplayName completed with exit code: $ExitCode"
    Write-Output-Box ""

    # Return result object
    return @{
        ExitCode = $ExitCode
        Output = ($OutputLines -join "`n")
    }
}

# Button Click Handlers
$btnCheckHealth.Add_Click({
    Set-ButtonsEnabled $false
    Run-Command -DisplayName "DISM CheckHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /CheckHealth"
    Set-Status "Ready"
    Set-ButtonsEnabled $true
})

$btnScanHealth.Add_Click({
    Set-ButtonsEnabled $false
    Run-Command -DisplayName "DISM ScanHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /ScanHealth"
    Set-Status "Ready"
    Set-ButtonsEnabled $true
})

$btnRestoreHealth.Add_Click({
    Set-ButtonsEnabled $false
    Run-Command -DisplayName "DISM RestoreHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /RestoreHealth"
    Set-Status "Ready"
    Set-ButtonsEnabled $true
})

$btnSFC.Add_Click({
    Set-ButtonsEnabled $false
    Run-Command -DisplayName "SFC Scannow" -Command "sfc.exe" -Arguments "/scannow"
    Set-Status "Ready"
    Set-ButtonsEnabled $true
})

$btnRunAll.Add_Click({
    Set-ButtonsEnabled $false

    Write-Output-Box "######################################################"
    Write-Output-Box "#       STARTING SMART REPAIR SEQUENCE               #"
    Write-Output-Box "######################################################"
    Write-Output-Box ""
    Write-Output-Box "NOTE: This sequence will intelligently skip RestoreHealth"
    Write-Output-Box "if ScanHealth detects no component store corruption."
    Write-Output-Box ""

    # Step 1: CheckHealth (quick)
    $Result = Run-Command -DisplayName "DISM CheckHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /CheckHealth"

    # Step 2: ScanHealth (takes longer, more thorough) - capture output for analysis
    $ScanResult = Run-Command -DisplayName "DISM ScanHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /ScanHealth" -CaptureOutput

    # Analyze ScanHealth output to determine if RestoreHealth is needed
    $NeedsRepair = $false
    $ScanOutput = $ScanResult.Output

    # Check for indicators that repair is needed
    if ($ScanOutput -match "component store corruption" -and $ScanOutput -notmatch "No component store corruption") {
        $NeedsRepair = $true
    }
    if ($ScanOutput -match "repairable") {
        $NeedsRepair = $true
    }
    if ($ScanOutput -match "component store repair") {
        $NeedsRepair = $true
    }

    # Step 3: RestoreHealth - only if corruption was detected
    if ($NeedsRepair) {
        Write-Output-Box "----------------------------------------------"
        Write-Output-Box "ANALYSIS: Component store issues detected."
        Write-Output-Box "Proceeding with RestoreHealth to repair..."
        Write-Output-Box "----------------------------------------------"
        Write-Output-Box ""
        $Result = Run-Command -DisplayName "DISM RestoreHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /RestoreHealth"
    } else {
        Write-Output-Box "----------------------------------------------"
        Write-Output-Box "ANALYSIS: No component store corruption detected."
        Write-Output-Box "SKIPPING RestoreHealth - not needed."
        Write-Output-Box "Proceeding directly to SFC..."
        Write-Output-Box "----------------------------------------------"
        Write-Output-Box ""
    }

    # Step 4: SFC (checks and repairs system files)
    $Result = Run-Command -DisplayName "SFC Scannow" -Command "sfc.exe" -Arguments "/scannow"

    Write-Output-Box "######################################################"
    Write-Output-Box "#       SMART REPAIR SEQUENCE COMPLETE               #"
    Write-Output-Box "######################################################"
    Write-Output-Box ""
    if (-not $NeedsRepair) {
        Write-Output-Box "RestoreHealth was skipped (no corruption found)."
    }
    Write-Output-Box "Review the output above for any issues."
    Write-Output-Box "A system restart may be required for changes to take effect."

    Set-Status "Complete - Smart sequence finished"
    Set-ButtonsEnabled $true
})

$btnClear.Add_Click({
    $txtOutput.Clear()
    Set-Status "Ready"
})

$btnClose.Add_Click({
    $Window.Close()
})

# Show startup message
$txtOutput.Text = @"
=======================================================================
  DISM & SFC Repair Tool v3
=======================================================================

NOTE: DISM and SFC operations can take a significant amount of time
to complete. It is normal behavior for this window to periodically
go into a "Not Responding" state during these operations.

Please be patient and allow the process to finish.

The "Run All (Smart)" button will automatically skip the RestoreHealth
step if ScanHealth finds no corruption, saving you time when your
component store is healthy.

The CLOSE button will become available after any operation completes.

=======================================================================

"@

# Show Window
$Window.ShowDialog() | Out-Null

