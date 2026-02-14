# ============================================================================
# Lookup-Tool_PSSESSION-DEMO.ps1
# ============================================================================

<#
.SYNOPSIS
    Demo-themed WPF GUI for Active Directory computer and user lookups.

.DESCRIPTION
    Prototype/demo version of the Lookup Tool with a navy/midnight blue
    visual theme. Provides an embedded PowerShell terminal for AD
    troubleshooting:
      - Domain controller detection via manual FQDN/IPv4 entry or
        automatic discovery with Get-ADDomainController
      - Computer lookup via nslookup with DC-aware validation
      - Ping endpoint and Enter-PSSession from the GUI
      - User lookup showing account status, last logon, and password age
      - Find endpoints associated with a user in AD
      - Full interactive PowerShell terminal with command history

    Requires the Active Directory module (RSAT) for AD lookups and
    DC auto-detection.

.NOTES
    Author : Brennon Hedman
    Version: 4 (Demo)
    Requires: Windows PowerShell 5.1+ or PowerShell 7+
    Platform: Windows (domain-joined, RSAT required)

.EXAMPLE
    .\Lookup-Tool_PSSESSION-DEMO.ps1

    Launches the Lookup Tool demo GUI on the local machine.
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
    Title="Lookup Tool - PSSession Demo"
    Width="750"
    Height="850"
    WindowStartupLocation="CenterScreen"
    ResizeMode="CanResizeWithGrip"
    Background="#1a1a2e">

    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#4da8da"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="12"/>
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
                    <Setter Property="Background" Value="#3a8fc2"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Background" Value="#2a2a4a"/>
                    <Setter Property="Foreground" Value="#7f8c8d"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="TextBox" x:Key="InputBox">
            <Setter Property="Background" Value="#0f0f1a"/>
            <Setter Property="Foreground" Value="#eaeaea"/>
            <Setter Property="BorderBrush" Value="#0f3460"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="FontSize" Value="13"/>
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
            <TextBlock Text="Lookup Tool - PSSession Demo"
                       FontSize="20"
                       FontWeight="Bold"
                       Foreground="#eaeaea"/>
            <TextBlock Name="txtComputerName"
                       FontSize="11"
                       Foreground="#a0a0a0"/>
        </StackPanel>

        <!-- DC Configuration Section -->
        <GroupBox Grid.Row="1" Header="Domain Controller Detection" Foreground="#a0a0a0" Margin="0,0,0,10" BorderBrush="#0f3460" Background="#16213e">
            <Grid Margin="5">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox Name="txtDCInput" Grid.Row="0" Grid.Column="0"
                         Style="{StaticResource InputBox}"
                         Margin="0,0,10,0"
                         ToolTip="Enter DC hostname (FQDN) or IPv4 address"/>
                <Button Name="btnAddDC" Grid.Row="0" Grid.Column="1"
                        Content="Add DC" Width="100"/>
                <Button Name="btnAutoDetect" Grid.Row="0" Grid.Column="2"
                        Content="Auto-Detect" Width="120" Background="#2ECC71"/>
                <TextBlock Name="txtDCStatus" Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="3"
                           Foreground="#a0a0a0"
                           FontFamily="Consolas"
                           FontSize="11"
                           Margin="0,5,0,0"
                           TextWrapping="Wrap"
                           Text="No DCs configured - lookups will skip DC validation."/>
            </Grid>
        </GroupBox>

        <!-- Computer Lookup Section -->
        <GroupBox Grid.Row="2" Header="Target Computer" Foreground="#a0a0a0" Margin="0,0,0,10" BorderBrush="#0f3460" Background="#16213e">
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
                    <Button Name="btnPing" Content="Ping Endpoint" Width="175" Background="#9b59b6" Visibility="Collapsed"/>
                    <Button Name="btnConnect" Content="Enter-PSSession" Width="175" Background="#2ECC71" Visibility="Collapsed"/>
                </StackPanel>
            </Grid>
        </GroupBox>

        <!-- User Lookup Section -->
        <GroupBox Grid.Row="3" Header="Target User" Foreground="#a0a0a0" Margin="0,0,0,10" BorderBrush="#0f3460" Background="#16213e">
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
                    <Button Name="btnFindEndpoint" Content="Find User's Endpoint" Width="270" Background="#9b59b6" Visibility="Collapsed"/>
                </StackPanel>
            </Grid>
        </GroupBox>

        <!-- Terminal Section -->
        <GroupBox Grid.Row="4" Header="PowerShell Terminal" Foreground="#a0a0a0" BorderBrush="#0f3460" Background="#16213e" Margin="0,0,0,10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <!-- Terminal Output -->
                <TextBox Name="txtOutput" Grid.Row="0"
                         Background="#0f0f1a"
                         Foreground="#eaeaea"
                         FontFamily="Consolas"
                         FontSize="13"
                         IsReadOnly="True"
                         TextWrapping="Wrap"
                         VerticalScrollBarVisibility="Auto"
                         BorderThickness="0"
                         Padding="10"
                         AcceptsReturn="True"/>

                <!-- Command Input -->
                <Grid Grid.Row="1" Background="#0f0f1a">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="txtPrompt" Grid.Column="0"
                               Text="PS> "
                               Foreground="#4da8da"
                               FontFamily="Consolas"
                               FontSize="13"
                               Padding="10,8,0,8"
                               VerticalAlignment="Center"/>
                    <TextBox Name="txtCommandInput" Grid.Column="1"
                             Background="#0f0f1a"
                             Foreground="#eaeaea"
                             CaretBrush="#eaeaea"
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
            <Button Name="btnClear" Content="Clear Terminal" Width="175" Background="#7F8C8D"/>
            <Button Name="btnExitSession" Content="Exit-PSSession" Width="175" Background="#e94560" Visibility="Collapsed"/>
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
$btnLookupComputer  = $window.FindName("btnLookupComputer")
$btnPing            = $window.FindName("btnPing")
$btnConnect         = $window.FindName("btnConnect")
$btnLookupUser      = $window.FindName("btnLookupUser")
$btnFindEndpoint    = $window.FindName("btnFindEndpoint")
$btnClear           = $window.FindName("btnClear")
$btnExitSession     = $window.FindName("btnExitSession")

# Set local computer name
$txtComputerName.Text = "Running from: $env:COMPUTERNAME"

# Script-level variables
$script:ResolvedIP          = $null
$script:TargetHostname      = $null
$script:TargetUser          = $null
$script:Runspace            = $null
$script:PowerShell          = $null
$script:IsInRemoteSession   = $false
$script:CommandHistory      = [System.Collections.ArrayList]::new()
$script:HistoryIndex        = -1
$script:DomainControllerIPs = [System.Collections.ArrayList]::new()

# ============================================================================
# POWERSHELL RUNSPACE SETUP
# ============================================================================

function Initialize-Runspace {
    $script:Runspace = [runspacefactory]::CreateRunspace()
    $script:Runspace.ApartmentState = "STA"
    $script:Runspace.ThreadOptions = "ReuseThread"
    $script:Runspace.Open()

    $script:Runspace.SessionStateProxy.SetVariable("SyncHash", @{
        Window       = $window
        Output       = $txtOutput
        Prompt       = $txtPrompt
        CommandInput = $txtCommandInput
        ExitSessionBtn = $btnExitSession
    })
}

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

function Execute-Command {
    param([string]$Command)

    if ([string]::IsNullOrWhiteSpace($Command)) {
        return
    }

    # Add to history
    [void]$script:CommandHistory.Add($Command)
    $script:HistoryIndex = $script:CommandHistory.Count

    # Display the command
    $currentPrompt = $txtPrompt.Text
    Write-TerminalNoNewline "$currentPrompt$Command`r`n"

    # Clear input
    $txtCommandInput.Dispatcher.Invoke([action]{
        $txtCommandInput.Clear()
    })

    # Handle special commands
    $trimmedCommand = $Command.Trim()

    # Handle Exit-PSSession
    if ($trimmedCommand -match "^exit-pssession$|^exit$" -and $script:IsInRemoteSession) {
        try {
            $script:PowerShell = [powershell]::Create()
            $script:PowerShell.Runspace = $script:Runspace
            [void]$script:PowerShell.AddScript("Exit-PSSession")
            $script:PowerShell.Invoke()
            $script:PowerShell.Dispose()

            $script:IsInRemoteSession = $false
            Update-Prompt "PS> "
            $btnExitSession.Dispatcher.Invoke([action]{ $btnExitSession.Visibility = "Collapsed" })
            Write-Terminal "Disconnected from remote session."
        }
        catch {
            Write-Terminal "Error exiting session: $_"
        }
        return
    }

    # Handle Enter-PSSession
    if ($trimmedCommand -match "^enter-pssession\s+(.+)$") {
        $targetComputer = $matches[1].Trim() -replace "^-ComputerName\s+", ""
        Enter-RemoteSession -ComputerName $targetComputer
        return
    }

    # Handle cls/clear
    if ($trimmedCommand -match "^cls$|^clear$|^clear-host$") {
        $txtOutput.Dispatcher.Invoke([action]{ $txtOutput.Clear() })
        return
    }

    # Execute command in runspace
    try {
        $script:PowerShell = [powershell]::Create()
        $script:PowerShell.Runspace = $script:Runspace

        [void]$script:PowerShell.AddScript($Command)

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

function Enter-RemoteSession {
    param([string]$ComputerName)

    Write-Terminal "Connecting to $ComputerName..."
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        $script:PowerShell = [powershell]::Create()
        $script:PowerShell.Runspace = $script:Runspace
        [void]$script:PowerShell.AddScript("Enter-PSSession -ComputerName $ComputerName")

        $output = $script:PowerShell.Invoke()

        if ($script:PowerShell.Streams.Error.Count -gt 0) {
            foreach ($err in $script:PowerShell.Streams.Error) {
                Write-Terminal "ERROR: $($err.ToString())"
            }
            $script:PowerShell.Dispose()
            return
        }

        $script:IsInRemoteSession = $true
        $script:TargetHostname = $ComputerName
        Update-Prompt "[$ComputerName]: PS> "

        $btnExitSession.Dispatcher.Invoke([action]{ $btnExitSession.Visibility = "Visible" })
        Write-Terminal "Connected to $ComputerName. Type 'exit' or click 'Exit-PSSession' to disconnect."

        $script:PowerShell.Dispose()
    }
    catch {
        Write-Terminal "Failed to connect: $_"
    }
}

# ============================================================================
# HELPER FUNCTIONS FOR LOOKUPS
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
        $txtDCStatus.Text = "$count DC(s) configured: $ipList"
    }
}

function Test-IsDomainController {
    param([string]$IPAddress)

    if ($script:DomainControllerIPs.Count -eq 0) {
        return $false
    }
    return ($script:DomainControllerIPs -contains $IPAddress)
}

function Resolve-ToIPv4 {
    param([string]$HostOrIP)

    if ($HostOrIP -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") {
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

# ============================================================================
# DC CONFIGURATION EVENTS
# ============================================================================

# Add DC manually (FQDN or IPv4)
$btnAddDC.Add_Click({
    $dcInput = $txtDCInput.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($dcInput)) {
        Write-Output-Box "Enter a DC hostname (FQDN) or IPv4 address." "Warning"
        return
    }

    Write-Output-Box "Resolving DC: $dcInput" "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    $ip = Resolve-ToIPv4 -HostOrIP $dcInput
    if ($ip) {
        if ($script:DomainControllerIPs -contains $ip) {
            Write-Output-Box "DC $ip is already in the list." "Warning"
        }
        else {
            [void]$script:DomainControllerIPs.Add($ip)
            Write-Output-Box "Added DC: $dcInput ($ip)" "Success"
        }
    }
    else {
        Write-Output-Box "Could not resolve '$dcInput' to an IPv4 address." "Error"
    }

    $txtDCInput.Clear()
    Update-DCStatus
})

# Enter key in DC input field
$txtDCInput.Add_KeyDown({
    if ($_.Key -eq "Return") {
        $btnAddDC.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
    }
})

# Auto-Detect DCs via Get-ADDomainController
$btnAutoDetect.Add_Click({
    Write-Output-Box "Auto-detecting domain controllers..." "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Output-Box "Active Directory module not installed." "Error"
            Write-Output-Box "Install RSAT or add DCs manually using FQDN/IPv4." "Warning"
            return
        }

        Import-Module ActiveDirectory -ErrorAction Stop

        $dcs = Get-ADDomainController -Filter * -ErrorAction Stop

        if (-not $dcs) {
            Write-Output-Box "No domain controllers found." "Warning"
            return
        }

        $addedCount = 0
        foreach ($dc in $dcs) {
            $ip = $dc.IPv4Address
            $name = $dc.HostName
            if ($ip -and ($script:DomainControllerIPs -notcontains $ip)) {
                [void]$script:DomainControllerIPs.Add($ip)
                Write-Output-Box "  Found DC: $name ($ip)" "Success"
                $addedCount++
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
        Write-Output-Box "You can still add DCs manually using FQDN or IPv4." "Info"
    }
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

            if ($inAnswer -and $lineStr -match "Address:\s*([\d\.]+)") {
                $ipAddress = $matches[1]
                break
            }

            if ($inAnswer -and $lineStr -match "Addresses:\s*([\d\.]+)") {
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
            Write-Output-Box "Ready to connect via PSSession." "Info"
            $btnConnect.Visibility = "Visible"
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

# Connect via PSSession
$btnConnect.Add_Click({
    if (-not $script:TargetHostname) {
        Write-Output-Box "No target hostname. Run lookup first." "Warning"
        return
    }

    Enter-RemoteSession -ComputerName $script:TargetHostname
    $txtCommandInput.Focus()
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
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Output-Box "Active Directory module not installed." "Error"
            Write-Output-Box "Install RSAT or run from a domain controller." "Warning"
            return
        }

        Import-Module ActiveDirectory -ErrorAction Stop

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

# Exit PSSession button
$btnExitSession.Add_Click({
    if ($script:IsInRemoteSession) {
        Execute-Command "exit"
    }
})

# Clear Terminal
$btnClear.Add_Click({
    $txtOutput.Clear()
    Write-Terminal "Terminal cleared. Type commands below or use the lookup buttons above."
    Write-Terminal ""
})

# ============================================================================
# KEYBOARD EVENTS
# ============================================================================

# Command Input - Handle Enter key and history
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

# Allow Enter key in lookup fields
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
    if ($script:Runspace) {
        $script:Runspace.Close()
        $script:Runspace.Dispose()
    }
})

# ============================================================================
# INITIALIZE AND SHOW WINDOW
# ============================================================================

Initialize-Runspace

Write-Terminal "Lookup Tool - PSSession Demo"
Write-Terminal ("=" * 50)
Write-Terminal ""
Write-Terminal "DC DETECTION: Configure domain controllers above using"
Write-Terminal "  FQDN, IPv4, or Auto-Detect before running lookups."
Write-Terminal ""
Write-Terminal "Use the lookup buttons above for quick actions, or type"
Write-Terminal "PowerShell commands directly in the input field below."
Write-Terminal ""
Write-Terminal "Features:"
Write-Terminal "  - Up/Down arrows for command history"
Write-Terminal "  - Enter-PSSession works in this terminal"
Write-Terminal "  - Type 'exit' or click button to leave remote session"
Write-Terminal ""

$txtCommandInput.Focus()
$window.ShowDialog() | Out-Null

# SIG # Begin signature block
# MIIFlwYJKoZIhvcNAQcCoIIFiDCCBYQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwkRsV+/ToJYJ2SSlobSCJ+Lw
# 1yigggMkMIIDIDCCAgigAwIBAgIQHrfhJiTc0JlLezzxNwo/3TANBgkqhkiG9w0B
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
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUh1cZU3TN2ea873ZW
# hrQaNEVxdDYwDQYJKoZIhvcNAQEBBQAEggEAXHCYrdzepPKvcOFw9FZG0tlrR+o1
# FHHR1eYDtvSDG3bVswwVVczGOihNxvNIppgxcBjU/+keYSiv+JWKvLubaLzc6Aqi
# nQvaohuPBo72OZrTNkNHhPlI4WuILBllVkGgszqEcRovd4qIvtKCOP28GhNzqm2s
# yjErKGFjRYhJwWfVlUahbM+rItzRcMd4v5s3ix1yZgW13RxCeth2h71RA9BRgNaH
# O9hJs3HyxCpA8MXxHbJDn5T/sXVVljI8D1pwNHnwHtp8Q1JOJIGlRxudjwEKJDPn
# k1003EgIeYy0zvyAeCxc+ZcdBjbUR7oHf5s3PAyL/OM4ls7U6DjYrnXs/A==
# SIG # End signature block
