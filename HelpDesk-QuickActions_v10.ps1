# HelpDesk-QuickActions.ps1
# WPF GUI for common Help Desk troubleshooting commands
# Runs on local endpoint - no elevation required

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ============================================================================
# XAML UI DEFINITION
# ============================================================================

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Help Desk Quick Actions v10"
    Width="625"
    Height="635"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
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
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="Help Desk Quick Actions v10"
                       FontSize="22"
                       FontWeight="Bold"
                       Foreground="White"/>
            <TextBlock Text="{Binding ComputerName}"
                       FontSize="12"
                       Foreground="#888888"
                       Name="txtComputerName"/>
        </StackPanel>

        <!-- Group Policy Section -->
        <GroupBox Grid.Row="1" Header="Group Policy" Foreground="#888888" Margin="0,0,0,10" BorderBrush="#444444">
            <StackPanel Orientation="Horizontal" Margin="5">
                <Button Name="btnGpUpdate" Content="Group Policy Update" Width="270"/>
                <Button Name="btnGpForce" Content="Force Group Policy Update" Width="270"/>
            </StackPanel>
        </GroupBox>

        <!-- Domain / Device Section -->
        <GroupBox Grid.Row="2" Header="Domain and Device Status" Foreground="#888888" Margin="0,0,0,10" BorderBrush="#444444">
            <StackPanel Orientation="Horizontal" Margin="5">
                <Button Name="btnTestTrust" Content="Test Domain Trust" Width="270"/>
                <Button Name="btnDeviceReg" Content="Check MDM Registration" Width="270"/>
            </StackPanel>
        </GroupBox>

        <!-- Output Section -->
        <GroupBox Grid.Row="3" Header="Output" Foreground="#888888" BorderBrush="#444444" Margin="0,0,0,10">
            <TextBox Name="txtOutput"
                     Background="#0d0d0d"
                     Foreground="#00ff00"
                     FontFamily="Consolas"
                     FontSize="12"
                     IsReadOnly="True"
                     TextWrapping="Wrap"
                     VerticalScrollBarVisibility="Auto"
                     BorderThickness="0"
                     Padding="10"
                     MinHeight="200"/>
        </GroupBox>

        <!-- Footer -->
        <StackPanel Grid.Row="4" Orientation="Horizontal" Margin="5">
            <Button Name="btnClear" Content="Clear Output" Width="270" Background="#444444"/>
            <Button Name="btnShowPolicies" Content="Show me the policies" Width="270" Background="#107c10" Visibility="Collapsed"/>
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
$txtComputerName = $window.FindName("txtComputerName")
$txtOutput = $window.FindName("txtOutput")
$btnGpUpdate = $window.FindName("btnGpUpdate")
$btnGpForce = $window.FindName("btnGpForce")
$btnTestTrust = $window.FindName("btnTestTrust")
$btnDeviceReg = $window.FindName("btnDeviceReg")
$btnShowPolicies = $window.FindName("btnShowPolicies")
$btnClear = $window.FindName("btnClear")

# Set computer name
$txtComputerName.Text = "Computer: $env:COMPUTERNAME"

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

    $txtOutput.AppendText("$timestamp $prefix $Message`r`n")
    $txtOutput.ScrollToEnd()
}

function Set-ButtonsEnabled {
    param([bool]$Enabled)
    $btnGpUpdate.IsEnabled = $Enabled
    $btnGpForce.IsEnabled = $Enabled
    $btnTestTrust.IsEnabled = $Enabled
    $btnDeviceReg.IsEnabled = $Enabled
    $btnShowPolicies.IsEnabled = $Enabled
}

# ============================================================================
# BUTTON EVENTS
# ============================================================================

# Group Policy Update
$btnGpUpdate.Add_Click({
    Set-ButtonsEnabled $false
    Write-Output-Box "Running Group Policy Update..." "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        Write-Output-Box "Looking for Group Policy updates..." "Info"
        $window.Dispatcher.Invoke([action]{}, "Render")
        $result = & gpupdate 2>&1
        foreach ($line in $result) {
            if ($line -and $line.ToString().Trim()) {
                Write-Output-Box $line.ToString().Trim()
            }
        }
        Write-Output-Box "Group Policy Update completed." "Success"
    }
    catch {
        Write-Output-Box "Failed: $_" "Error"
    }

    # Show the policies button after gpupdate completes
    $btnShowPolicies.Visibility = "Visible"
    Set-ButtonsEnabled $true
})

# Force Group Policy Update
$btnGpForce.Add_Click({
    Set-ButtonsEnabled $false
    Write-Output-Box "Running Force Group Policy Update..." "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        Write-Output-Box "Looking for Group Policy updates..." "Info"
        $window.Dispatcher.Invoke([action]{}, "Render")
        $result = & gpupdate /force 2>&1
        foreach ($line in $result) {
            if ($line -and $line.ToString().Trim()) {
                Write-Output-Box $line.ToString().Trim()
            }
        }
        Write-Output-Box "Force Group Policy Update completed." "Success"
    }
    catch {
        Write-Output-Box "Failed: $_" "Error"
    }

    # Show the policies button after gpupdate completes
    $btnShowPolicies.Visibility = "Visible"
    Set-ButtonsEnabled $true
})

# Test Domain Trust
$btnTestTrust.Add_Click({
    Set-ButtonsEnabled $false
    Write-Output-Box "Testing Domain Trust relationship..." "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        $result = Test-ComputerSecureChannel -Verbose 4>&1
        $trustHealthy = $false

        foreach ($line in $result) {
            if ($line -and $line.ToString().Trim()) {
                $lineText = $line.ToString().Trim()
                Write-Output-Box $lineText
                if ($lineText -match "True") {
                    $trustHealthy = $true
                }
            }
        }

        if ($trustHealthy) {
            Write-Output-Box "Domain trust relationship is healthy." "Success"
        }
        else {
            Write-Output-Box "Domain trust relationship is BROKEN." "Error"
            Write-Output-Box "" "Info"
            Write-Output-Box "REMEDIATION STEPS:" "Warning"
            Write-Output-Box "  1. Check what network you're on" "Info"
            Write-Output-Box "  2. Remove computer from domain" "Info"
            Write-Output-Box "  3. Reboot" "Info"
            Write-Output-Box "  4. Delete computer object from AD" "Info"
            Write-Output-Box "  5. Rejoin computer to domain" "Info"
            Write-Output-Box "  6. Reboot" "Info"
        }
    }
    catch {
        Write-Output-Box "Failed to test domain trust: $_" "Error"
        Write-Output-Box "This machine may not be domain-joined." "Warning"
        Write-Output-Box "Use 'Check MDM Registration' to verify join status." "Info"
    }

    Set-ButtonsEnabled $true
})

# Check MDM Registration (dsregcmd /status)
$btnDeviceReg.Add_Click({
    Set-ButtonsEnabled $false
    Write-Output-Box "Checking MDM Registration status..." "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        $result = & dsregcmd /status 2>&1
        $fullOutput = $result -join "`n"

        # Parse key values
        $azureAdJoined = if ($fullOutput -match "AzureAdJoined\s*:\s*(\w+)") { $matches[1] } else { "Unknown" }
        $domainJoined = if ($fullOutput -match "DomainJoined\s*:\s*(\w+)") { $matches[1] } else { "Unknown" }
        $deviceName = if ($fullOutput -match "DeviceName\s*:\s*(.+)") { $matches[1].Trim() } else { $env:COMPUTERNAME }
        $tenantName = if ($fullOutput -match "TenantName\s*:\s*(.+)") { $matches[1].Trim() } else { "N/A" }
        $mdmUrl = if ($fullOutput -match "MdmUrl\s*:\s*(.+)") { $matches[1].Trim() } else { $null }

        Write-Output-Box "" "Info"
        Write-Output-Box "MDM REGISTRATION STATUS" "Info"
        Write-Output-Box ("=" * 40) "Info"
        Write-Output-Box "Device Name:     $deviceName" "Info"
        Write-Output-Box "Domain Joined:   $domainJoined" "Info"
        Write-Output-Box "Azure AD Joined: $azureAdJoined" "Info"
        Write-Output-Box "Tenant:          $tenantName" "Info"

        # Determine device type
        Write-Output-Box "" "Info"
        if ($domainJoined -eq "YES" -and $azureAdJoined -eq "YES") {
            Write-Output-Box "Device Type: HYBRID AZURE AD JOINED" "Success"
            Write-Output-Box "  - Connected to on-premises AD" "Info"
            Write-Output-Box "  - Registered with Azure AD" "Info"
        }
        elseif ($domainJoined -eq "NO" -and $azureAdJoined -eq "YES") {
            Write-Output-Box "Device Type: AZURE AD JOINED (Cloud Only)" "Success"
            Write-Output-Box "  - Not joined to on-premises AD" "Info"
            Write-Output-Box "  - Managed through Azure AD / Intune" "Info"
        }
        elseif ($domainJoined -eq "YES" -and $azureAdJoined -eq "NO") {
            Write-Output-Box "Device Type: DOMAIN JOINED ONLY" "Warning"
            Write-Output-Box "  - Connected to on-premises AD" "Info"
            Write-Output-Box "  - NOT registered with Azure AD" "Info"
        }
        else {
            Write-Output-Box "Device Type: WORKGROUP (Not Joined)" "Warning"
            Write-Output-Box "  - Not joined to any domain" "Info"
            Write-Output-Box "  - Not registered with Azure AD" "Info"
        }

        # MDM Status
        if ($mdmUrl) {
            Write-Output-Box "" "Info"
            Write-Output-Box "MDM Enrollment: No" "Info"
        }
    }
    catch {
        Write-Output-Box "Failed to check MDM registration: $_" "Error"
    }

    Set-ButtonsEnabled $true
})

# Show Policies (GPRESULT /R - faster text output)
$btnShowPolicies.Add_Click({
    Set-ButtonsEnabled $false
    Write-Output-Box "Retrieving applied Group Policies..." "Info"
    $window.Dispatcher.Invoke([action]{}, "Render")

    try {
        $result = & gpresult /R 2>&1
        $fullOutput = $result -join "`n"

        # Split into Computer and User sections
        $computerSection = ""
        $userSection = ""

        if ($fullOutput -match "(?s)COMPUTER SETTINGS\s*-+(.+?)(?=USER SETTINGS|$)") {
            $computerSection = $matches[1]
        }
        if ($fullOutput -match "(?s)USER SETTINGS\s*-+(.+)$") {
            $userSection = $matches[1]
        }

        # Function to extract GPO names from a section
        function Get-AppliedGPOs {
            param([string]$Section)
            $gpos = @()
            if ($Section -match "(?s)Applied Group Policy Objects\s*-+(.+?)(?=The following GPOs|$)") {
                $gpoBlock = $matches[1]
                $lines = $gpoBlock -split "`n"
                foreach ($line in $lines) {
                    $trimmed = $line.Trim()
                    # Skip empty lines and section headers
                    if ($trimmed -and $trimmed -notmatch "^-+$" -and $trimmed -notmatch "^N/A$") {
                        $gpos += $trimmed
                    }
                }
            }
            return $gpos
        }

        Write-Output-Box "" "Info"
        Write-Output-Box "APPLIED GROUP POLICIES" "Info"
        Write-Output-Box ("=" * 40) "Info"

        # Computer GPOs
        Write-Output-Box "" "Info"
        Write-Output-Box "COMPUTER POLICIES:" "Info"
        $computerGPOs = Get-AppliedGPOs -Section $computerSection
        if ($computerGPOs.Count -gt 0) {
            foreach ($gpo in $computerGPOs) {
                Write-Output-Box "  - $gpo" "Success"
            }
        }
        else {
            Write-Output-Box "  (None found)" "Warning"
        }

        # User GPOs
        Write-Output-Box "" "Info"
        Write-Output-Box "USER POLICIES:" "Info"
        $userGPOs = Get-AppliedGPOs -Section $userSection
        if ($userGPOs.Count -gt 0) {
            foreach ($gpo in $userGPOs) {
                Write-Output-Box "  - $gpo" "Success"
            }
        }
        else {
            Write-Output-Box "  (None found)" "Warning"
        }

        $totalCount = $computerGPOs.Count + $userGPOs.Count
        Write-Output-Box "" "Info"
        Write-Output-Box "Total: $totalCount applied policies" "Info"
    }
    catch {
        Write-Output-Box "Failed to retrieve policies: $_" "Error"
    }

    Set-ButtonsEnabled $true
})

# Clear Output
$btnClear.Add_Click({
    $txtOutput.Clear()
    Write-Output-Box "Ready. Select an action above." "Info"
})

# ============================================================================
# SHOW WINDOW
# ============================================================================

Write-Output-Box "Ready. Select an action above." "Info"
$window.ShowDialog() | Out-Null

# SIG # Begin signature block
# MIIFvAYJKoZIhvcNAQcCoIIFrTCCBakCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDEFwlD7eCzn4Ts
# fKU2UlbyFOQas2M6Dw468LZyBOXvr6CCAyQwggMgMIICCKADAgECAhAet+EmJNzQ
# mUt7PPE3Cj/dMA0GCSqGSIb3DQEBCwUAMCgxJjAkBgNVBAMMHUJyZW5uIFBvd2Vy
# U2hlbGwgQ29kZSBTaWduaW5nMB4XDTI2MDIwOTExMTI0M1oXDTMxMDIwOTExMjI0
# M1owKDEmMCQGA1UEAwwdQnJlbm4gUG93ZXJTaGVsbCBDb2RlIFNpZ25pbmcwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDQevkaL17PbaL3++374aYj7dsE
# w8x0Z/dgg15FphNbFesgRksPXiq3HqIv9uEyDuqdTU8+CIvV/AXZ81SJJ2p/7xyY
# zCcGY8kLe96yIVpqcKHQB9nd4JE07wAn7d+fAep6aoVtzWHMRtNZruwlb/dKR4h3
# 4QG1YbGXgQ1EZASkNqbyjhldUZO5f2+zZUeJNqExSLLwM29GOtsDY22i5hggnxrI
# x60EIwX3vv7l8JDtoWQayyLbKxesWcx4QLh50rV837qbmGe/VMiiRaEHdlNn3Z3W
# ZOWaejsGDXoae4f2pcp31phuEKnmdM1OVrkEAxSxXAinQ/p6SRtJ+nWNZAmVAgMB
# AAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNV
# HQ4EFgQUOg/9xg6/QwXN7VPkXuQara2ZA9QwDQYJKoZIhvcNAQELBQADggEBALvz
# j+reaL/P+9NGl/hPAzosEWu1KlEkmBdxYy+VH2eYkJPTSLZLrPNNIK6Tvbjt/1p2
# H/ddajK4dPPecoLMQPYiRSxr7ukiJsxW3Jzn/jg2ZBMJkTBGk15WUpa+TDLQw8fZ
# NcHiLt9XeuoUVRh+AaIOLcSajB5TEVFQ3WliAxkuFM4ZVPToJEhobGGpcyHJCIii
# uumnfvNeaje4qFVv/8diVJj3/P0XgUk9T1S0HdkXbFW6H+wiFnCTWBMJ/SG8uF4V
# zDVxoqmPJE25vIhKn5uylGZSVHpI8vdAdm0QXatfeFAyjJDKownEOzcrTrTOBmZL
# rxfGho4YgRCCCvyGotMxggHuMIIB6gIBATA8MCgxJjAkBgNVBAMMHUJyZW5uIFBv
# d2VyU2hlbGwgQ29kZSBTaWduaW5nAhAet+EmJNzQmUt7PPE3Cj/dMA0GCWCGSAFl
# AwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJ
# KoZIhvcNAQkEMSIEIPSptRTj3TiSiRmMg5Si49d0nPupEo6yZCqM2/hudFuEMA0G
# CSqGSIb3DQEBAQUABIIBAJrm2GTf2D/L/I5hPbrUxb1NymkH4C3vAKKSXlk4Qv7Y
# AAzJumSeoPtym9s5/llBZEcJ/WRrWNFs8fzUwSn7s+lx6B4j+6sNd+38bi7es64X
# OMqsM/E0n/wtVUVa3KVbdphMQwbI3RPnpz7XcAT8R2w/ewE9pyZcUZGs/FklACtp
# isQdd3UWL6LmQDVf4WW+dlMLWblfLjhRIQg8MLgq+RroMPvASu65pnQDRSKCqgeg
# NXu4qXVl2OfSNvnisMREXAIULTr8qINUv8TswVRa0PwDIFIbby2F2+i+o8sKmGoj
# Jn4VU+lUYihq8gjMWr2P0QMlOxZMhORJ3KUPWj82n1c=
# SIG # End signature block
