# ============================================================================
# DISM-SFC-Tool_v7.ps1
# ============================================================================

#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WPF GUI for DISM and SFC system image repair operations.

.DESCRIPTION
    Provides a dark-themed WPF interface with one-click actions for Windows
    component store and system file repair:
      - DISM CheckHealth (quick corruption flag check)
      - DISM ScanHealth (thorough component store scan)
      - DISM RestoreHealth (repair from Windows Update)
      - SFC /scannow (system file integrity verification)
      - Run All (Smart) — sequential pipeline that skips RestoreHealth
        when ScanHealth reports no corruption

    Requires elevation (Run as Administrator). All commands run locally on
    the current endpoint.

.NOTES
    Author : Brennon Hedman
    Version: 7
    Requires: Windows PowerShell 5.1+ or PowerShell 7+, Administrator
    Platform: Windows 10 / 11

.EXAMPLE
    .\DISM-SFC-Tool_v7.ps1

    Launches the DISM & SFC Repair Tool GUI (must be run elevated).
#>

Add-Type -AssemblyName PresentationFramework, System.Windows.Forms

# ============================================================================
# XAML UI DEFINITION
# ============================================================================

[xml]$XAML = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="DISM &amp; SFC Repair Tool v7"
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
            <TextBlock Text="DISM &amp; SFC Repair Tool"
                       FontSize="22"
                       FontWeight="Bold"
                       Foreground="White"/>
            <TextBlock Name="txtComputerName"
                       FontSize="12"
                       Foreground="#888888"/>
        </StackPanel>

        <!-- DISM Section -->
        <GroupBox Grid.Row="1" Header="DISM Operations" Foreground="#888888" Margin="0,0,0,10" BorderBrush="#444444">
            <StackPanel Orientation="Horizontal" Margin="5">
                <Button Name="btnCheckHealth" Content="CheckHealth" Width="175"/>
                <Button Name="btnScanHealth" Content="ScanHealth" Width="175"/>
                <Button Name="btnRestoreHealth" Content="RestoreHealth" Width="175"/>
            </StackPanel>
        </GroupBox>

        <!-- SFC and Run All Section -->
        <GroupBox Grid.Row="2" Header="System File Checker" Foreground="#888888" Margin="0,0,0,10" BorderBrush="#444444">
            <StackPanel Orientation="Horizontal" Margin="5">
                <Button Name="btnSFC" Content="SFC /scannow" Width="270"/>
                <Button Name="btnRunAll" Content="Run All (Smart)" Width="270" Background="#107c10"/>
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
                     AcceptsReturn="True"
                     BorderThickness="0"
                     Padding="10"/>
        </GroupBox>

        <!-- Footer -->
        <StackPanel Grid.Row="4" Orientation="Horizontal" Margin="5">
            <Button Name="btnClear" Content="Clear Output" Width="270" Background="#444444"/>
            <Button Name="btnClose" Content="Close" Width="270" Background="#d41a1a" Visibility="Collapsed"/>
        </StackPanel>
    </Grid>
</Window>
"@

# ============================================================================
# LOAD XAML
# ============================================================================

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
$txtComputerName = $Window.FindName("txtComputerName")

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

    $txtOutput.Dispatcher.Invoke([action]{
        $txtOutput.AppendText("$timestamp $prefix $Message`r`n")
        $txtOutput.ScrollToEnd()
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
        if ($Enabled) {
            $btnClose.Visibility = "Visible"
        } else {
            $btnClose.Visibility = "Collapsed"
        }
    })
}

# Function to run a command and capture output
function Run-Command {
    param(
        [string]$DisplayName,
        [string]$Command,
        [string]$Arguments,
        [switch]$CaptureOutput
    )

    Write-Output-Box "Starting: $DisplayName" "Info"
    Write-Output-Box "Command: $Command $Arguments" "Info"

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

    $OutputLines = @()

    while (-not $Process.StandardOutput.EndOfStream) {
        $Line = $Process.StandardOutput.ReadLine()
        if ($Line) {
            Write-Output-Box $Line "Info"
            if ($CaptureOutput) {
                $OutputLines += $Line
            }
        }
        [System.Windows.Forms.Application]::DoEvents()
    }

    $ErrorOutput = $Process.StandardError.ReadToEnd()
    if ($ErrorOutput) {
        Write-Output-Box "ERRORS: $ErrorOutput" "Error"
    }

    $Process.WaitForExit()
    $ExitCode = $Process.ExitCode

    if ($ExitCode -eq 0) {
        Write-Output-Box "$DisplayName completed successfully (exit code: $ExitCode)" "Success"
    } else {
        Write-Output-Box "$DisplayName completed with exit code: $ExitCode" "Warning"
    }

    return @{
        ExitCode = $ExitCode
        Output = ($OutputLines -join "`n")
    }
}

# ============================================================================
# BUTTON EVENTS
# ============================================================================

$btnCheckHealth.Add_Click({
    Set-ButtonsEnabled $false
    Run-Command -DisplayName "DISM CheckHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /CheckHealth"
    Set-ButtonsEnabled $true
})

$btnScanHealth.Add_Click({
    Set-ButtonsEnabled $false
    Run-Command -DisplayName "DISM ScanHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /ScanHealth"
    Set-ButtonsEnabled $true
})

$btnRestoreHealth.Add_Click({
    Set-ButtonsEnabled $false
    Run-Command -DisplayName "DISM RestoreHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /RestoreHealth"
    Set-ButtonsEnabled $true
})

$btnSFC.Add_Click({
    Set-ButtonsEnabled $false
    Run-Command -DisplayName "SFC Scannow" -Command "sfc.exe" -Arguments "/scannow"
    Set-ButtonsEnabled $true
})

$btnRunAll.Add_Click({
    Set-ButtonsEnabled $false

    Write-Output-Box "STARTING SMART REPAIR SEQUENCE" "Info"
    Write-Output-Box "This sequence will skip RestoreHealth if no corruption is found." "Info"

    # Step 1: CheckHealth
    $Result = Run-Command -DisplayName "DISM CheckHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /CheckHealth"

    # Step 2: ScanHealth
    $ScanResult = Run-Command -DisplayName "DISM ScanHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /ScanHealth" -CaptureOutput

    # Analyze ScanHealth output
    $NeedsRepair = $false
    $ScanOutput = $ScanResult.Output

    if ($ScanOutput -match "component store corruption" -and $ScanOutput -notmatch "No component store corruption") {
        $NeedsRepair = $true
    }
    if ($ScanOutput -match "repairable") {
        $NeedsRepair = $true
    }
    if ($ScanOutput -match "component store repair") {
        $NeedsRepair = $true
    }

    # Step 3: RestoreHealth (only if needed)
    if ($NeedsRepair) {
        Write-Output-Box "Component store issues detected." "Warning"
        Write-Output-Box "Proceeding with RestoreHealth to repair..." "Info"
        $Result = Run-Command -DisplayName "DISM RestoreHealth" -Command "DISM.exe" -Arguments "/Online /Cleanup-Image /RestoreHealth"
    } else {
        Write-Output-Box "No component store corruption detected." "Success"
        Write-Output-Box "Skipping RestoreHealth - not needed." "Info"
        Write-Output-Box "Proceeding directly to SFC..." "Info"
    }

    # Step 4: SFC
    $Result = Run-Command -DisplayName "SFC Scannow" -Command "sfc.exe" -Arguments "/scannow"

    Write-Output-Box "SMART REPAIR SEQUENCE COMPLETE" "Success"
    if (-not $NeedsRepair) {
        Write-Output-Box "RestoreHealth was skipped (no corruption found)." "Info"
    }
    Write-Output-Box "A system restart may be required for changes to take effect." "Warning"

    Set-ButtonsEnabled $true
})

$btnClear.Add_Click({
    $txtOutput.Clear()
    Write-Output-Box "Ready. Select an action above." "Info"
})

$btnClose.Add_Click({
    $Window.Close()
})

# ============================================================================
# SHOW WINDOW
# ============================================================================

Write-Output-Box "Ready. Select an action above." "Info"

$Window.ShowDialog() | Out-Null
# SIG # Begin signature block
# MIIFlwYJKoZIhvcNAQcCoIIFiDCCBYQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbB6eHe1/uxQwfCz+3lKmqNcE
# u+KgggMkMIIDIDCCAgigAwIBAgIQHrfhJiTc0JlLezzxNwo/3TANBgkqhkiG9w0B
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
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUJWADmKvufS5L9ekd
# WWzvZHiCZTQwDQYJKoZIhvcNAQEBBQAEggEAwYN0cg5yvKWQiqDH2aGBrepQH/NA
# VS1Skm+qOjHgo7e6L5H0001WfaSpAG10Sz8BGxSc7Tmn+DMbA4b1hCfa9zH/gXvW
# mZ81NBPONOE0ttFvFw4kDzxwM2MyUc0dibGvvwlhOtPXjGoS6991Se3aaC5VF0ca
# ko0SG49KDF2vFLb+4L6JJCdoEf13rMzIky4Oa2Atw0cL1SQgQ8OFN/y2zDRXwKFS
# JAk/o2QL6nEviKVMVc4iQM4djR+A8/ObTRPMLibjcl4zdkfKkevoP4k4LhZD6Nv1
# 7FsTmcullLmjancQ1y6uc3v/s1kHlPcg+JtPf/g8t0nL20tLp14THhvERg==
# SIG # End signature block
