# ============================================================================
# HelpDesk-PolicyCheck_v10.ps1
# ============================================================================

<#
.SYNOPSIS
    WPF GUI for common Help Desk troubleshooting commands.

.DESCRIPTION
    Provides a dark-themed WPF interface with one-click actions for everyday
    endpoint troubleshooting:
      - Group Policy update (standard and forced)
      - Domain trust relationship validation
      - MDM / Azure AD registration check
      - Applied Group Policy listing (gpresult)

    Runs on the local endpoint with no elevation required.

.NOTES
    Author : Brennon Hedman
    Version: 10
    Requires: Windows PowerShell 5.1+ or PowerShell 7+
    Platform: Windows (domain-joined or Azure AD-joined endpoints)

.EXAMPLE
    .\HelpDesk-PolicyCheck_v10.ps1

    Launches the Help Desk Policy Check GUI on the local machine.
#>

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
    Title="Help Desk Policy Check v10"
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
            <TextBlock Text="Help Desk Policy Check v10"
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
# MIIFlwYJKoZIhvcNAQcCoIIFiDCCBYQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHrHkltkT0a5fa4I/54J7zw6h
# T9ygggMkMIIDIDCCAgigAwIBAgIQHrfhJiTc0JlLezzxNwo/3TANBgkqhkiG9w0B
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
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUs0A/VxTB+p6RLiRR
# EpffMiuuIkYwDQYJKoZIhvcNAQEBBQAEggEAi3Yf/U39LQXouKRtX01y08sPQPCC
# dfBOivEJnTS7by5z0LUYiURfnQFqSEROZXgV3L+67RjTctlmSdwFO73IpXWeQYy+
# +25VbrTnDeChk3Z63VlxXrFjc9SxsvEsA1T7Gaz1M4iupuyuegF94WBkj51Sm1bU
# 5/ZKxvQf/M7Q8x6g3Ja6pnB6NWjMTiYi/rNeNBZiHULAhyIPDG8XoeO1Sa+i7uFH
# imoUwNDOZsYljGHTqvmNKYeBd4+0TEM/MSr34kjJhGzOcIKNFdrcGCo5GGjb239p
# 4ezslcy7bp3SMHvBpHvAX2gDhBhI1EPwzx6Tuqk+8R7RtwwxxC4Q/DiZ5g==
# SIG # End signature block
