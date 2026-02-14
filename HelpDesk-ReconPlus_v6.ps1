# ============================================================================
# HelpDesk-ReconPlus_v6.ps1
# ============================================================================

<#
.SYNOPSIS
    WPF GUI for Active Directory computer and user lookups with remote
    command execution via "persistent" Invoke-Command input on target endpoint.

.DESCRIPTION
    Provides a dark-themed WPF interface with an embedded PowerShell
    terminal for AD troubleshooting:
      - Smart domain controller detection: accepts IPv4, FQDN, or partial
        hostname with fuzzy matching via Get-ADDomainController
      - One-click Auto-Detect to enumerate all DCs in the domain
      - Computer lookup via nslookup with DC-aware validation
      - Ping endpoint and one-click remote connection
      - Persistent PSSession: all terminal commands execute on the remote
        endpoint via Invoke-Command with full state persistence (variables,
        working directory, loaded modules survive between commands)
      - Local mode when no target is connected
      - User lookup showing account status, last logon, and password age
      - Find endpoints associated with a user in AD
      - Command history with Up/Down arrow navigation

    Requires the Active Directory module (RSAT) for AD lookups and
    DC detection.

.NOTES
    Author : Brennon Hedman
    Version: 6
    Requires: Windows PowerShell 5.1+ or PowerShell 7+
    Platform: Windows (domain-joined, RSAT required)

.EXAMPLE
    .\HelpDesk-ReconPlus_v6.ps1

    Launches the Help Desk Recon Plus GUI on the local machine.
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ============================================================================
# XAML UI DEFINITION
# ============================================================================

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="HelpDesk-ReconPlus v6"
    Width="750"
    Height="850"
    WindowStartupLocation="CenterScreen"
    ResizeMode="CanResizeWithGrip"
    Background="#1e1e1e">

    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#0078d4"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="15,10"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="4"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#106ebe"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Background" Value="#555555"/>
                    <Setter Property="Foreground" Value="#888888"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="TextBox" x:Key="InputBox">
            <Setter Property="Background" Value="#2d2d2d"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#444444"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="Help Desk ReconPlus v6"
                       FontSize="22"
                       FontWeight="Bold"
                       Foreground="White"/>
            <TextBlock Name="txtComputerName"
                       FontSize="12"
                       Foreground="#888888"/>
        </StackPanel>

        <!-- DC Configuration Section -->
        <GroupBox Grid.Row="1" Header="Domain Controller Detection" Foreground="#888888" Margin="0,0,0,10" BorderBrush="#444444">
            <Grid Margin="5">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox Name="txtDCInput" Grid.Row="0" Grid.Column="0"
                         Style="{StaticResource InputBox}"
                         Margin="0,0,10,0"
                         ToolTip="Enter DC IPv4, FQDN, or partial hostname (fuzzy search)"/>
                <Button Name="btnAddDC" Grid.Row="0" Grid.Column="1"
                        Content="Find DC" Width="100"/>
                <Button Name="btnAutoDetect" Grid.Row="0" Grid.Column="2"
                        Content="Auto-Detect" Width="120" Background="#107c10"/>
                <Button Name="btnClearDCs" Grid.Row="0" Grid.Column="3"
                        Content="Clear" Width="70" Background="#444444"/>
                <TextBlock Name="txtDCStatus" Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="4"
                           Foreground="#888888"
                           FontFamily="Consolas"
                           FontSize="12"
                           Margin="0,5,0,0"
                           TextWrapping="Wrap"
                           Text="No DCs configured - lookups will skip DC validation."/>
            </Grid>
        </GroupBox>

        <!-- Computer Lookup Section -->
        <GroupBox Grid.Row="2" Header="Target Computer" Foreground="#888888" Margin="0,0,0,10" BorderBrush="#444444">
            <Grid Margin="5">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox Name="txtComputerInput" Grid.Row="0" Grid.Column="0"
                         Style="{StaticResource InputBox}"
                         Margin="0,0,10,0"
                         Text=""
                         ToolTip="Enter computer hostname"/>
                <Button Name="btnLookupComputer" Grid.Row="0" Grid.Column="1"
                        Content="Lookup" Width="120"/>
                <StackPanel Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="2" Orientation="Horizontal" Margin="0,5,0,0">
                    <Button Name="btnPing" Content="Ping Endpoint" Width="175" Visibility="Collapsed"/>
                    <Button Name="btnConnect" Content="Connect" Width="175" Background="#107c10" Visibility="Collapsed"/>
                </StackPanel>
            </Grid>
        </GroupBox>

        <!-- User Lookup Section -->
        <GroupBox Grid.Row="3" Header="Target User" Foreground="#888888" Margin="0,0,0,10" BorderBrush="#444444">
            <Grid Margin="5">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox Name="txtUserInput" Grid.Row="0" Grid.Column="0"
                         Style="{StaticResource InputBox}"
                         Margin="0,0,10,0"
                         Text=""
                         ToolTip="Enter username (SAMAccountName)"/>
                <Button Name="btnLookupUser" Grid.Row="0" Grid.Column="1"
                        Content="Lookup" Width="120"/>
                <StackPanel Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="2" Orientation="Horizontal" Margin="0,5,0,0">
                    <Button Name="btnFindEndpoint" Content="Find User's Endpoint" Width="270" Visibility="Collapsed"/>
                </StackPanel>
            </Grid>
        </GroupBox>

        <!-- Terminal Section -->
        <GroupBox Grid.Row="4" Header="PowerShell Terminal" Foreground="#888888" BorderBrush="#444444" Margin="0,0,0,10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Terminal Output -->
                <TextBox Name="txtOutput" Grid.Row="0"
                         Background="#0c0c0c"
                         Foreground="#cccccc"
                         FontFamily="Consolas"
                         FontSize="13"
                         IsReadOnly="True"
                         TextWrapping="Wrap"
                         VerticalScrollBarVisibility="Auto"
                         BorderThickness="0"
                         Padding="10"
                         AcceptsReturn="True"/>

                <!-- Command Input -->
                <Grid Grid.Row="1" Background="#0c0c0c">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="txtPrompt" Grid.Column="0"
                               Text="PS> "
                               Foreground="#ffff00"
                               FontFamily="Consolas"
                               FontSize="13"
                               Padding="10,8,0,8"
                               VerticalAlignment="Center"/>
                    <TextBox Name="txtCommandInput" Grid.Column="1"
                             Background="#0c0c0c"
                             Foreground="#ffffff"
                             CaretBrush="#ffffff"
                             FontFamily="Consolas"
                             FontSize="13"
                             BorderThickness="0"
                             Padding="5,8,10,8"
                             VerticalContentAlignment="Center"/>
                </Grid>
            </Grid>
        </GroupBox>

        <!-- Footer -->
        <StackPanel Grid.Row="5" Orientation="Horizontal" Margin="5">
            <Button Name="btnClear" Content="Clear Terminal" Width="175" Background="#444444"/>
            <Button Name="btnDisconnect" Content="Disconnect" Width="175" Background="#d41a1a" Visibility="Collapsed"/>
        </StackPanel>
    </Grid>
</Window>
"@

# ============================================================================
# LOAD XAML
# ============================================================================

$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$txtComputerName  = $window.FindName("txtComputerName")
$txtDCInput       = $window.FindName("txtDCInput")
$txtDCStatus      = $window.FindName("txtDCStatus")
$txtComputerInput = $window.FindName("txtComputerInput")
$txtUserInput     = $window.FindName("txtUserInput")
$txtOutput        = $window.FindName("txtOutput")
$txtPrompt        = $window.FindName("txtPrompt")
$txtCommandInput  = $window.FindName("txtCommandInput")
$btnAddDC           = $window.FindName("btnAddDC")
$btnAutoDetect      = $window.FindName("btnAutoDetect")
$btnClearDCs        = $window.FindName("btnClearDCs")
$btnLookupComputer  = $window.FindName("btnLookupComputer")
$btnPing            = $window.FindName("btnPing")
$btnConnect         = $window.FindName("btnConnect")
$btnLookupUser      = $window.FindName("btnLookupUser")
$btnFindEndpoint    = $window.FindName("btnFindEndpoint")
$btnClear           = $window.FindName("btnClear")
$btnDisconnect      = $window.FindName("btnDisconnect")

# Set local computer name
$txtComputerName.Text = "Running from: $env:COMPUTERNAME"

# Script-level variables
$script:ResolvedIP          = $null
$script:TargetHostname      = $null
$script:TargetUser          = $null
$script:Runspace            = $null
$script:PowerShell          = $null
$script:RemoteSession       = $null
$script:CommandHistory      = [System.Collections.ArrayList]::new()
$script:HistoryIndex        = -1
$script:DomainControllerIPs = [System.Collections.ArrayList]::new()

# ============================================================================
# POWERSHELL RUNSPACE SETUP (LOCAL MODE)
# ============================================================================

function Initialize-Runspace {
    $script:Runspace = [runspacefactory]::CreateRunspace()
    $script:Runspace.ApartmentState = "STA"
    $script:Runspace.ThreadOptions = "ReuseThread"
    $script:Runspace.Open()
}

# ============================================================================
# TERMINAL OUTPUT FUNCTIONS
# ============================================================================

function Write-Terminal {
    param(
        [string]$Text,
        [string]$Color = "White"
    )

    $txtOutput.Dispatcher.Invoke([action]{
        $txtOutput.AppendText("$Text`r`n")
        $txtOutput.ScrollToEnd()
    })
}

function Write-TerminalNoNewline {
    param([string]$Text)

    $txtOutput.Dispatcher.Invoke([action]{
        $txtOutput.AppendText($Text)
        $txtOutput.ScrollToEnd()
    })
}

function Update-Prompt {
    param([string]$NewPrompt)

    $txtPrompt.Dispatcher.Invoke([action]{
        $txtPrompt.Text = $NewPrompt
    })
}

# ============================================================================
# REMOTE SESSION MANAGEMENT
# ============================================================================

function Connect-TargetEndpoint {
    param([string]$ComputerName)

    Write-Output-Box "Creating persistent session to $ComputerName..." "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        $session = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
        $script:RemoteSession = $session
        $script:TargetHostname = $ComputerName

        Update-Prompt "[$ComputerName]: PS> "
        $btnDisconnect.Dispatcher.Invoke([action]{ $btnDisconnect.Visibility = "Visible" })

        Write-Output-Box "Connected to $ComputerName." "Success"
        Write-Terminal "  Session ID: $($session.Id)"
        Write-Terminal "  State:      $($session.State)"
        Write-Terminal "  Transport:  $($session.Transport)"
        Write-Terminal ""
        Write-Terminal "All terminal commands now execute on $ComputerName."
        Write-Terminal "Type 'disconnect' or click Disconnect to return to local mode."
        Write-Terminal ""
    }
    catch {
        Write-Output-Box "Failed to connect: $_" "Error"
        Write-Output-Box "Check WinRM, firewall, and permissions on the target." "Warning"
    }
}

function Disconnect-TargetEndpoint {
    if ($script:RemoteSession) {
        $target = $script:TargetHostname
        try {
            Remove-PSSession -Session $script:RemoteSession -ErrorAction SilentlyContinue
        }
        catch {
            # Session may already be gone
        }
        $script:RemoteSession = $null
        Update-Prompt "PS> "
        $btnDisconnect.Dispatcher.Invoke([action]{ $btnDisconnect.Visibility = "Collapsed" })
        Write-Output-Box "Disconnected from $target. Terminal is now local." "Info"
    }
}

# ============================================================================
# COMMAND EXECUTION ENGINE
# ============================================================================

function Execute-Command {
    param([string]$Command)

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return
    }

    # Add to history
    [void]$script:CommandHistory.Add($Command)
    $script:HistoryIndex = $script:CommandHistory.Count

    # Display the command with current prompt
    $currentPrompt = $txtPrompt.Text
    Write-TerminalNoNewline "$currentPrompt$Command`r`n"

    # Clear input
    $txtCommandInput.Dispatcher.Invoke([action]{
        $txtCommandInput.Clear()
    })

    $trimmedCommand = $Command.Trim()

    # Handle disconnect command
    if ($trimmedCommand -match '^disconnect$|^exit$' -and $script:RemoteSession) {
        Disconnect-TargetEndpoint
        return
    }

    # Handle cls/clear
    if ($trimmedCommand -match '^cls$|^clear$|^clear-host$') {
        $txtOutput.Dispatcher.Invoke([action]{ $txtOutput.Clear() })
        return
    }

    # ── Remote mode: Invoke-Command over persistent session ──────────────
    if ($script:RemoteSession) {

        # Check session health
        if ($script:RemoteSession.State -ne 'Opened') {
            Write-Output-Box "Session is no longer open (State: $($script:RemoteSession.State))." "Error"
            Write-Output-Box "Cleaning up. Reconnect to continue." "Warning"
            Disconnect-TargetEndpoint
            return
        }

        try {
            $scriptBlock = [scriptblock]::Create($trimmedCommand)
            $output = Invoke-Command -Session $script:RemoteSession -ScriptBlock $scriptBlock -ErrorAction Stop -ErrorVariable remoteErrors 2>&1

            foreach ($item in $output) {
                if ($null -ne $item) {
                    $text = ($item | Out-String).TrimEnd()
                    if ($text) {
                        # Color error records differently
                        if ($item -is [System.Management.Automation.ErrorRecord]) {
                            $txtOutput.Dispatcher.Invoke([action]{
                                $txtOutput.AppendText("ERROR: $text`r`n")
                                $txtOutput.ScrollToEnd()
                            })
                        }
                        else {
                            Write-Terminal $text
                        }
                    }
                }
            }
        }
        catch {
            $txtOutput.Dispatcher.Invoke([action]{
                $txtOutput.AppendText("ERROR: $($_.Exception.Message)`r`n")
                $txtOutput.ScrollToEnd()
            })

            # If session died, clean up
            if ($script:RemoteSession.State -ne 'Opened') {
                Write-Output-Box "Session lost during command execution." "Error"
                Disconnect-TargetEndpoint
            }
        }
        return
    }

    # ── Local mode: execute in runspace ──────────────────────────────────
    try {
        $script:PowerShell = [powershell]::Create()
        $script:PowerShell.Runspace = $script:Runspace

        [void]$script:PowerShell.AddScript($trimmedCommand)

        $output = $script:PowerShell.Invoke()

        foreach ($item in $output) {
            if ($null -ne $item) {
                Write-Terminal ($item | Out-String).TrimEnd()
            }
        }

        if ($script:PowerShell.Streams.Error.Count -gt 0) {
            foreach ($err in $script:PowerShell.Streams.Error) {
                $txtOutput.Dispatcher.Invoke([action]{
                    $txtOutput.AppendText("ERROR: $($err.ToString())`r`n")
                    $txtOutput.ScrollToEnd()
                })
            }
        }

        if ($script:PowerShell.Streams.Warning.Count -gt 0) {
            foreach ($warn in $script:PowerShell.Streams.Warning) {
                $txtOutput.Dispatcher.Invoke([action]{
                    $txtOutput.AppendText("WARNING: $($warn.ToString())`r`n")
                    $txtOutput.ScrollToEnd()
                })
            }
        }

        $script:PowerShell.Dispose()
    }
    catch {
        Write-Terminal "Error: $_"
    }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Output-Box {
    param([string]$Message, [string]$Type = "Info")

    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Type) {
        "Success" { "[OK]" }
        "Error"   { "[ERROR]" }
        "Warning" { "[WARN]" }
        default   { "[INFO]" }
    }

    Write-Terminal "$timestamp $prefix $Message"
}

function Update-DCStatus {
    $count = $script:DomainControllerIPs.Count
    if ($count -eq 0) {
        $txtDCStatus.Text = "No DCs configured - lookups will skip DC validation."
    }
    else {
        $ipList = ($script:DomainControllerIPs | Sort-Object -Unique) -join ", "
        $txtDCStatus.Text = "$count DC(s): $ipList"
    }
}

function Test-IsDomainController {
    param([string]$IPAddress)

    if ($script:DomainControllerIPs.Count -eq 0) {
        return $false
    }
    return ($script:DomainControllerIPs -contains $IPAddress)
}

function Add-DCToList {
    param([string]$IP, [string]$Label)

    if ($script:DomainControllerIPs -contains $IP) {
        Write-Output-Box "  Already listed: $Label ($IP)" "Warning"
        return $false
    }
    [void]$script:DomainControllerIPs.Add($IP)
    Write-Output-Box "  Added DC: $Label ($IP)" "Success"
    return $true
}

function Resolve-ToIPv4 {
    param([string]$HostOrIP)

    if ($HostOrIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        return $HostOrIP
    }

    try {
        $resolved = [System.Net.Dns]::GetHostAddresses($HostOrIP) |
            Where-Object { $_.AddressFamily -eq "InterNetwork" } |
            Select-Object -First 1
        if ($resolved) {
            return $resolved.IPAddressToString
        }
    }
    catch {
        # Resolution failed
    }
    return $null
}

function Test-ADModuleAvailable {
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Output-Box "Active Directory module not installed." "Error"
        Write-Output-Box "Install RSAT or enter DCs as IPv4/FQDN instead." "Warning"
        return $false
    }
    Import-Module ActiveDirectory -ErrorAction Stop
    return $true
}

# ============================================================================
# DC SMART SEARCH
# ============================================================================

function Find-DomainController {
    param([string]$Input)

    $trimmed = $Input.Trim()

    # ── Path 1: IPv4 address ─────────────────────────────────────────────
    if ($trimmed -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        Write-Output-Box "Input looks like an IPv4 address." "Info"

        if (Test-ADModuleAvailable) {
            try {
                $allDCs = Get-ADDomainController -Filter * -ErrorAction Stop
                $match = $allDCs | Where-Object { $_.IPv4Address -eq $trimmed }

                if ($match) {
                    Add-DCToList -IP $trimmed -Label $match.HostName
                }
                else {
                    Write-Output-Box "  $trimmed is not a known DC in this domain." "Warning"
                    Write-Output-Box "  Adding anyway (may be cross-domain or unlisted)." "Info"
                    Add-DCToList -IP $trimmed -Label $trimmed
                }
            }
            catch {
                Write-Output-Box "  AD query failed, adding IP directly." "Warning"
                Add-DCToList -IP $trimmed -Label $trimmed
            }
        }
        else {
            Add-DCToList -IP $trimmed -Label $trimmed
        }

        Update-DCStatus
        return
    }

    # ── Path 2: FQDN (contains dots) ────────────────────────────────────
    if ($trimmed -match '\.') {
        Write-Output-Box "Input looks like an FQDN. Resolving..." "Info"
        $window.Dispatcher.Invoke([action]{}, "Render")

        $ip = Resolve-ToIPv4 -HostOrIP $trimmed
        if ($ip) {
            Write-Output-Box "  Resolved $trimmed to $ip" "Success"
            Add-DCToList -IP $ip -Label $trimmed
        }
        else {
            Write-Output-Box "  Could not resolve '$trimmed' to an IPv4 address." "Error"
            Write-Output-Box "  Check spelling or try the short hostname instead." "Info"
        }

        Update-DCStatus
        return
    }

    # ── Path 3: Partial name / fuzzy search ──────────────────────────────
    Write-Output-Box "Searching for DCs matching '$trimmed'..." "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    $dnsIP = Resolve-ToIPv4 -HostOrIP $trimmed
    $dnsResolved = $false

    if ($dnsIP) {
        Write-Output-Box "  DNS resolved '$trimmed' to $dnsIP" "Info"
        $dnsResolved = $true
    }

    if (Test-ADModuleAvailable) {
        try {
            $allDCs = Get-ADDomainController -Filter * -ErrorAction Stop
            $searchLower = $trimmed.ToLower()

            $matches = $allDCs | Where-Object {
                $_.Name.ToLower() -like "*$searchLower*" -or
                $_.HostName.ToLower() -like "*$searchLower*" -or
                $_.Site.ToLower() -like "*$searchLower*"
            }

            if ($matches) {
                $matchList = @($matches)
                Write-Output-Box "  Found $($matchList.Count) DC(s) matching '$trimmed':" "Success"
                Write-Terminal ""

                $addedCount = 0
                foreach ($dc in $matchList) {
                    $dcIP = $dc.IPv4Address
                    $dcName = $dc.HostName
                    $dcSite = $dc.Site

                    Write-Terminal "    Name: $($dc.Name)"
                    Write-Terminal "    FQDN: $dcName"
                    Write-Terminal "    IP:   $dcIP"
                    Write-Terminal "    Site: $dcSite"

                    if ($dcIP) {
                        $added = Add-DCToList -IP $dcIP -Label $dcName
                        if ($added) { $addedCount++ }
                    }
                    else {
                        Write-Output-Box "    No IPv4 address for $dcName, skipping." "Warning"
                    }
                    Write-Terminal ""
                }

                if ($addedCount -gt 0) {
                    Write-Output-Box "Added $addedCount DC(s) from fuzzy search." "Success"
                }
            }
            else {
                Write-Output-Box "  No DCs found matching '$trimmed' in AD." "Warning"

                if ($dnsResolved) {
                    Write-Output-Box "  DNS resolved to $dnsIP but it's not a known DC." "Warning"
                    Write-Output-Box "  Adding DNS result anyway." "Info"
                    Add-DCToList -IP $dnsIP -Label $trimmed
                }
                else {
                    Write-Output-Box "  Try a different spelling, the FQDN, or Auto-Detect." "Info"
                }
            }
        }
        catch {
            Write-Output-Box "  AD search failed: $_" "Error"

            if ($dnsResolved) {
                Write-Output-Box "  Using DNS result ($dnsIP) as fallback." "Info"
                Add-DCToList -IP $dnsIP -Label $trimmed
            }
        }
    }
    elseif ($dnsResolved) {
        Write-Output-Box "  No AD module - using DNS result ($dnsIP)." "Info"
        Add-DCToList -IP $dnsIP -Label $trimmed
    }

    Update-DCStatus
}

# ============================================================================
# DC CONFIGURATION EVENTS
# ============================================================================

$btnAddDC.Add_Click({
    $dcInput = $txtDCInput.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($dcInput)) {
        Write-Output-Box "Enter a DC IPv4, FQDN, or partial hostname." "Warning"
        return
    }

    Find-DomainController -Input $dcInput
    $txtDCInput.Clear()
})

$txtDCInput.Add_KeyDown({
    if ($_.Key -eq "Return") {
        $btnAddDC.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
    }
})

$btnAutoDetect.Add_Click({
    Write-Output-Box "Auto-detecting all domain controllers..." "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    if (-not (Test-ADModuleAvailable)) { return }

    try {
        $dcs = Get-ADDomainController -Filter * -ErrorAction Stop

        if (-not $dcs) {
            Write-Output-Box "No domain controllers found." "Warning"
            return
        }

        $addedCount = 0
        foreach ($dc in $dcs) {
            $ip = $dc.IPv4Address
            $name = $dc.HostName
            $site = $dc.Site
            if ($ip) {
                $added = Add-DCToList -IP $ip -Label "$name [$site]"
                if ($added) { $addedCount++ }
            }
        }

        if ($addedCount -eq 0) {
            Write-Output-Box "All detected DCs were already in the list." "Info"
        }
        else {
            Write-Output-Box "Added $addedCount domain controller(s)." "Success"
        }

        Update-DCStatus
    }
    catch {
        Write-Output-Box "Auto-detect failed: $_" "Error"
        Write-Output-Box "You can still add DCs manually using IPv4, FQDN, or hostname." "Info"
    }
})

$btnClearDCs.Add_Click({
    $script:DomainControllerIPs.Clear()
    Write-Output-Box "DC list cleared." "Info"
    Update-DCStatus
})

# ============================================================================
# BUTTON EVENTS
# ============================================================================

# Computer Lookup
$btnLookupComputer.Add_Click({
    $hostname = $txtComputerInput.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($hostname)) {
        Write-Output-Box "Please enter a computer hostname." "Warning"
        return
    }

    $btnPing.Visibility = "Collapsed"
    $btnConnect.Visibility = "Collapsed"
    $script:ResolvedIP = $null
    $script:TargetHostname = $hostname

    Write-Output-Box "Looking up hostname: $hostname" "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        $nslookupResult = & nslookup $hostname 2>&1
        $ipAddress = $null
        $inAnswer = $false

        foreach ($line in $nslookupResult) {
            $lineStr = $line.ToString().Trim()

            if ($lineStr -match "^Name:") {
                $inAnswer = $true
            }

            if ($inAnswer -and $lineStr -match 'Address:\s*([\d\.]+)') {
                $ipAddress = $matches[1]
                break
            }

            if ($inAnswer -and $lineStr -match 'Addresses:\s*([\d\.]+)') {
                $ipAddress = $matches[1]
                break
            }
        }

        if ($ipAddress) {
            Write-Output-Box "Resolved IP: $ipAddress" "Success"
            $script:ResolvedIP = $ipAddress

            if (Test-IsDomainController -IPAddress $ipAddress) {
                Write-Output-Box "IP matches a configured Domain Controller." "Error"
                Write-Output-Box "This hostname likely does not exist or DNS returned the DC." "Warning"
            }
            else {
                Write-Output-Box "IP is valid (does not match any configured DC)." "Success"
                $btnPing.Visibility = "Visible"
                Write-Output-Box "Click 'Ping Endpoint' to check if it's online." "Info"
            }
        }
        else {
            Write-Output-Box "Could not resolve IP address for $hostname" "Error"
        }
    }
    catch {
        Write-Output-Box "NSLookup failed: $_" "Error"
    }
})

# Ping Endpoint
$btnPing.Add_Click({
    if (-not $script:ResolvedIP) {
        Write-Output-Box "No IP address to ping. Run lookup first." "Warning"
        return
    }

    $btnConnect.Visibility = "Collapsed"

    Write-Output-Box "Pinging $script:ResolvedIP..." "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        $pingResult = Test-Connection -ComputerName $script:ResolvedIP -Count 2 -Quiet -ErrorAction SilentlyContinue

        if ($pingResult) {
            Write-Output-Box "Ping successful - endpoint is ONLINE" "Success"

            # If already connected to something else, warn
            if ($script:RemoteSession -and $script:RemoteSession.State -eq 'Opened') {
                Write-Output-Box "Already connected to $($script:RemoteSession.ComputerName). Disconnect first." "Warning"
            }
            else {
                Write-Output-Box "Ready to connect." "Info"
                $btnConnect.Visibility = "Visible"
            }
        }
        else {
            Write-Output-Box "Ping failed - endpoint appears to be OFFLINE" "Error"
            Write-Output-Box "The endpoint may be powered off, blocking ICMP, or unreachable." "Warning"
        }
    }
    catch {
        Write-Output-Box "Ping error: $_" "Error"
    }
})

# Connect to target (persistent session)
$btnConnect.Add_Click({
    if (-not $script:TargetHostname) {
        Write-Output-Box "No target hostname. Run lookup first." "Warning"
        return
    }

    # Disconnect existing session if any
    if ($script:RemoteSession) {
        Disconnect-TargetEndpoint
    }

    Connect-TargetEndpoint -ComputerName $script:TargetHostname
    $txtCommandInput.Focus()
})

# Disconnect button
$btnDisconnect.Add_Click({
    Disconnect-TargetEndpoint
})

# User Lookup
$btnLookupUser.Add_Click({
    $username = $txtUserInput.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($username)) {
        Write-Output-Box "Please enter a username." "Warning"
        return
    }

    $btnFindEndpoint.Visibility = "Collapsed"
    $script:TargetUser = $username

    Write-Output-Box "Looking up user: $username" "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        if (-not (Test-ADModuleAvailable)) { return }

        $user = Get-ADUser -Identity $username -Properties * -ErrorAction Stop

        Write-Terminal ""
        Write-Terminal "USER DETAILS"
        Write-Terminal ("=" * 45)
        Write-Terminal "Display Name:    $($user.DisplayName)"
        Write-Terminal "SAMAccountName:  $($user.SAMAccountName)"
        Write-Terminal "Email:           $($user.EmailAddress)"
        Write-Terminal "Title:           $($user.Title)"
        Write-Terminal "Department:      $($user.Department)"
        Write-Terminal ""

        $lastLogon = $null
        if ($user.LastLogonDate) {
            $lastLogon = $user.LastLogonDate
        }
        elseif ($user.LastLogon -and $user.LastLogon -ne 0) {
            $lastLogon = [DateTime]::FromFileTime($user.LastLogon)
        }

        if ($lastLogon) {
            $daysSinceLogon = (New-TimeSpan -Start $lastLogon -End (Get-Date)).Days
            Write-Output-Box "Last Logon:      $($lastLogon.ToString('yyyy-MM-dd HH:mm:ss')) ($daysSinceLogon days ago)" "Success"
        }
        else {
            Write-Output-Box "Last Logon:      Never or not recorded" "Warning"
        }

        if ($user.PasswordLastSet) {
            $daysSincePwChange = (New-TimeSpan -Start $user.PasswordLastSet -End (Get-Date)).Days
            Write-Output-Box "Password Changed: $($user.PasswordLastSet.ToString('yyyy-MM-dd HH:mm:ss')) ($daysSincePwChange days ago)" "Success"
        }
        else {
            Write-Output-Box "Password Changed: Never or must change at next logon" "Warning"
        }

        Write-Terminal ""
        if ($user.Enabled) {
            Write-Output-Box "Account Status:  ENABLED" "Success"
        }
        else {
            Write-Output-Box "Account Status:  DISABLED" "Error"
        }

        if ($user.LockedOut) {
            Write-Output-Box "Account Locked:  YES" "Error"
        }

        $btnFindEndpoint.Visibility = "Visible"
        $script:TargetUser = $username
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Output-Box "User '$username' not found in Active Directory." "Error"
    }
    catch {
        Write-Output-Box "Failed to lookup user: $_" "Error"
    }
})

# Find User's Endpoint
$btnFindEndpoint.Add_Click({
    if (-not $script:TargetUser) {
        Write-Output-Box "No user selected. Run user lookup first." "Warning"
        return
    }

    Write-Terminal ""
    Write-Output-Box "Searching for endpoint associated with $($script:TargetUser)..." "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        Import-Module ActiveDirectory -ErrorAction Stop

        $computers = @()

        $computersByName = Get-ADComputer -Filter "Name -like '*$($script:TargetUser)*'" -Properties Description, LastLogonDate -ErrorAction SilentlyContinue
        if ($computersByName) {
            $computers += $computersByName
        }

        $computersByDesc = Get-ADComputer -Filter "Description -like '*$($script:TargetUser)*'" -Properties Description, LastLogonDate -ErrorAction SilentlyContinue
        if ($computersByDesc) {
            $computers += $computersByDesc
        }

        $computers = $computers | Sort-Object -Property Name -Unique

        if ($computers.Count -gt 0) {
            Write-Output-Box "Found $($computers.Count) potential endpoint(s):" "Success"
            Write-Terminal ""
            foreach ($computer in $computers) {
                $lastLogon = if ($computer.LastLogonDate) { $computer.LastLogonDate.ToString('yyyy-MM-dd') } else { "Unknown" }
                Write-Terminal "  Computer: $($computer.Name)"
                Write-Terminal "  Last Logon: $lastLogon"
                if ($computer.Description) {
                    Write-Terminal "  Description: $($computer.Description)"
                }
                Write-Terminal ""
            }
            Write-Output-Box "Tip: Enter a computer name above to verify and connect." "Info"
        }
        else {
            Write-Output-Box "No endpoints found matching '$($script:TargetUser)'." "Warning"
        }
    }
    catch {
        Write-Output-Box "Failed to search for endpoint: $_" "Error"
    }
})

# Clear Terminal
$btnClear.Add_Click({
    $txtOutput.Clear()
    if ($script:RemoteSession -and $script:RemoteSession.State -eq 'Opened') {
        Write-Terminal "Terminal cleared. Connected to $($script:TargetHostname)."
    }
    else {
        Write-Terminal "Terminal cleared. Running in local mode."
    }
    Write-Terminal ""
})

# ============================================================================
# KEYBOARD EVENTS
# ============================================================================

$txtCommandInput.Add_KeyDown({
    param($sender, $e)

    switch ($e.Key) {
        "Return" {
            $command = $txtCommandInput.Text
            Execute-Command -Command $command
            $e.Handled = $true
        }
        "Up" {
            if ($script:CommandHistory.Count -gt 0 -and $script:HistoryIndex -gt 0) {
                $script:HistoryIndex--
                $txtCommandInput.Text = $script:CommandHistory[$script:HistoryIndex]
                $txtCommandInput.CaretIndex = $txtCommandInput.Text.Length
            }
            $e.Handled = $true
        }
        "Down" {
            if ($script:CommandHistory.Count -gt 0 -and $script:HistoryIndex -lt $script:CommandHistory.Count - 1) {
                $script:HistoryIndex++
                $txtCommandInput.Text = $script:CommandHistory[$script:HistoryIndex]
                $txtCommandInput.CaretIndex = $txtCommandInput.Text.Length
            }
            elseif ($script:HistoryIndex -ge $script:CommandHistory.Count - 1) {
                $script:HistoryIndex = $script:CommandHistory.Count
                $txtCommandInput.Text = ""
            }
            $e.Handled = $true
        }
        "Escape" {
            $txtCommandInput.Clear()
            $e.Handled = $true
        }
    }
})

$txtComputerInput.Add_KeyDown({
    if ($_.Key -eq "Return") {
        $btnLookupComputer.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
    }
})

$txtUserInput.Add_KeyDown({
    if ($_.Key -eq "Return") {
        $btnLookupUser.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
    }
})

# Cleanup on window close
$window.Add_Closed({
    if ($script:RemoteSession) {
        Remove-PSSession -Session $script:RemoteSession -ErrorAction SilentlyContinue
    }
    if ($script:Runspace) {
        $script:Runspace.Close()
        $script:Runspace.Dispose()
    }
})

# ============================================================================
# INITIALIZE AND SHOW WINDOW
# ============================================================================

Initialize-Runspace

Write-Terminal "HelpDesk ReconPlus v6 - Remote Command Terminal"
Write-Terminal ("=" * 50)
Write-Terminal ""
Write-Terminal "WORKFLOW:"
Write-Terminal "  1. Configure DCs (Find DC / Auto-Detect)"
Write-Terminal "  2. Look up a computer hostname"
Write-Terminal "  3. Ping to verify it's online"
Write-Terminal "  4. Click Connect to open a persistent session"
Write-Terminal "  5. Type commands - they execute on the remote endpoint"
Write-Terminal ""
Write-Terminal "LOCAL MODE: No target connected. Commands run on $env:COMPUTERNAME."
Write-Terminal "Type 'disconnect' or click Disconnect to return to local mode."
Write-Terminal ""
Write-Terminal "Keyboard: Up/Down = history, Enter = execute, Esc = clear"
Write-Terminal ""

$txtCommandInput.Focus()
$window.ShowDialog() | Out-Null

# SIG # Begin signature block
# MIIFlwYJKoZIhvcNAQcCoIIFiDCCBYQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbPzqzGp40IWx/CcmK3ttSAZg
# vCmgggMkMIIDIDCCAgigAwIBAgIQHrfhJiTc0JlLezzxNwo/3TANBgkqhkiG9w0B
# AQsFADAoMSYwJAYDVQQDDB1CcmVubiBQb3dlclNoZWxsIENvZGUgU2lnbmluZzAe
# Fw0yNjAyMDkxMTEyNDNaFw0zMTAyMDkxMTIyNDNaMCgxJjAkBgNVBAMMHUJyZW5u
# IFBvd2VyU2hlbGwgQ29kZSBTaWduaW5nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEA0Hr5Gi9ez22i9/vt++GmI+3bBMPMdGf3YINeRaYTWxXrIEZLD14q
# tx6iL/bhMg7qnU1PPgiL1fwF2fNUiSdqf+8cmMwnBmPJC3vesiFaanCh0AfZ3eCR
# NO8AJ+3fnwHqemqFbc1hzEbTWa7sJW/3SkeId+EBtWGxl4ENRGQEpDam8o4ZXVGT
# uX9vs2VHiTahMUiy8DNvRjrbA2NtouYYIJ8ayMetBCMF977+5fCQ7aFkGssi2ysX
# rFnMeEC4edK1fN+6m5hnv1TIokWhB3ZTZ92d1mTlmno7Bg16GnuH9qXKd9aYbhCp
# 5nTNTla5BAMUsVwIp0P6ekkbSfp1jWQJlQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMC
# B4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFDoP/cYOv0MFze1T5F7k
# Gq2tmQPUMA0GCSqGSIb3DQEBCwUAA4IBAQC784/q3mi/z/vTRpf4TwM6LBFrtSpR
# JJgXcWMvlR9nmJCT00i2S6zzTSCuk7247f9adh/3XWoyuHTz3nKCzED2IkUsa+7p
# IibMVtyc5/44NmQTCZEwRpNeVlKWvkwy0MPH2TXB4i7fV3rqFFUYfgGiDi3Emowe
# UxFRUN1pYgMZLhTOGVT06CRIaGxhqXMhyQiIorrpp37zXmo3uKhVb//HYlSY9/z9
# F4FJPU9UtB3ZF2xVuh/sIhZwk1gTCf0hvLheFcw1caKpjyRNubyISp+bspRmUlR6
# SPL3QHZtEF2rX3hQMoyQyqMJxDs3K060zgZmS68XxoaOGIEQggr8hqLTMYIB3TCC
# AdkCAQEwPDAoMSYwJAYDVQQDDB1CcmVubiBQb3dlclNoZWxsIENvZGUgU2lnbmlu
# ZwIQHrfhJiTc0JlLezzxNwo/3TAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEK
# MAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUAfUophNQy2c5Czua
# lQL24RIuGiwwDQYJKoZIhvcNAQEBBQAEggEAGK5A5lnc6pytJJ+OPFT7MFlUXHcT
# jholtf4+W6oV7J3GLX4YAfRtn+gapT9dsSoFMICvJH8S7n1FxXBsmfQCdOTTBHN9
# wsnk5ge8rWq7hKqCAT7lX8bgPEFcv2/rknRrM/wvknyAFcgrtu8BbuiXuud5Z6Yz
# sBf+etyHBBNwaUrhUR+wQgQQ8P5rOdZZDGv6jT6Q53xiFe6R9JmmEUyyXupFcUMg
# 9mqN1zKa7Cujforx7qXMpyJoMjCd4GWX6RM1YTMeiJ8tYtMDSEm2omKjGygJARkA
# Dvc9D24t8GgqSUcbNIFg6QffjcB32YN3mBLrgZ5STfLlrJcAjhjYEEa3uQ==
# SIG # End signature block
