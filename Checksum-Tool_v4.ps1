# ============================================================================
# Checksum-Tool_v4.ps1
# ============================================================================

<#
.SYNOPSIS
    WPF GUI for verifying file integrity via hash comparison.

.DESCRIPTION
    Provides a dark-themed WPF interface for checksum verification with
    two operating modes:
      - Single File: Calculate and optionally compare a file hash
        (SHA256, SHA512, SHA1, or MD5)
      - Batch Mode: Parse a checksum file (SHA256SUMS, etc.) and verify
        all listed files in a target folder

    Displays results in a sortable grid with detailed drill-down and
    CSV export capability.

.NOTES
    Author : Brennon Hedman
    Version: 4
    Requires: Windows PowerShell 5.1+ or PowerShell 7+
    Platform: Windows

.EXAMPLE
    .\Checksum-Tool_v4.ps1

    Launches the Checksum Verifier GUI.
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# XAML Definition - Production Dark Theme (black/gray/blue)
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Checksum Verifier v4"
        Height="716"
        MinHeight="500"
        Width="950"
        MinWidth="800"
        WindowStartupLocation="CenterScreen"
        Background="#1e1e1e">
    <Window.Resources>
        <SolidColorBrush x:Key="DarkBgBrush" Color="#1e1e1e"/>
        <SolidColorBrush x:Key="CardBgBrush" Color="#2d2d2d"/>
        <SolidColorBrush x:Key="CardBorderBrush" Color="#444444"/>
        <SolidColorBrush x:Key="InputBgBrush" Color="#0d0d0d"/>
        <SolidColorBrush x:Key="TextPrimaryBrush" Color="White"/>
        <SolidColorBrush x:Key="TextSecondaryBrush" Color="#888888"/>

        <Style TargetType="Button">
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground" Value="White"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Background" Value="#0d0d0d"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#444444"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="CaretBrush" Value="#0078d4"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Foreground" Value="#888888"/>
            <Setter Property="Margin" Value="4,4,4,1"/>
        </Style>
        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="8,8,4,4"/>
        </Style>
    </Window.Resources>

    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Title Bar -->
        <Border Grid.Row="0"
                Background="#2d2d2d"
                Padding="15,12"
                CornerRadius="8"
                Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="CHECKSUM VERIFIER"
                               FontSize="20"
                               FontWeight="Bold"
                               Foreground="White"/>
                    <TextBlock Text="Verify file integrity via hash comparison"
                               FontSize="11"
                               Foreground="#888888"
                               Margin="0,3,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Background="#2ECC71" CornerRadius="4" Padding="8,4" Margin="3,0">
                        <TextBlock Text="SHA256" Foreground="White" FontSize="9" FontWeight="Bold"/>
                    </Border>
                    <Border Background="#3498DB" CornerRadius="4" Padding="8,4" Margin="3,0">
                        <TextBlock Text="SHA512" Foreground="White" FontSize="9" FontWeight="Bold"/>
                    </Border>
                    <Border Background="#F39C12" CornerRadius="4" Padding="8,4" Margin="3,0">
                        <TextBlock Text="SHA1" Foreground="White" FontSize="9" FontWeight="Bold"/>
                    </Border>
                    <Border Background="#555555" CornerRadius="4" Padding="8,4" Margin="3,0">
                        <TextBlock Text="MD5" Foreground="White" FontSize="9" FontWeight="Bold"/>
                    </Border>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Mode Selection -->
        <Border Grid.Row="1"
                Background="#2d2d2d"
                BorderBrush="#0078d4"
                BorderThickness="2"
                CornerRadius="8"
                Padding="14"
                Margin="0,0,0,12">
            <StackPanel>
                <TextBlock Text="Verification Mode" FontWeight="Bold" FontSize="13" Margin="0,0,0,8" Foreground="White"/>
                <StackPanel Orientation="Horizontal">
                    <RadioButton Name="rbSingleFile"
                                Content="Single File Verification"
                                IsChecked="True"
                                FontWeight="SemiBold"/>
                    <RadioButton Name="rbBatchFile"
                                Content="Batch Verification (from checksum file)"
                                Margin="20,4,4,4"
                                FontWeight="SemiBold"/>
                </StackPanel>
            </StackPanel>
        </Border>

        <!-- Single File Mode Panel -->
        <Border Name="pnlSingleFile"
                Grid.Row="2"
                Background="#2d2d2d"
                BorderBrush="#0078d4"
                BorderThickness="2"
                CornerRadius="8"
                Padding="14"
                Margin="0,0,0,12">
            <StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                    <Border Background="#0078d4" CornerRadius="13" Width="26" Height="26" Margin="0,0,10,0">
                        <TextBlock Text="1" Foreground="White" FontWeight="Bold" FontSize="13"
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Select file and algorithm"
                               FontSize="14" FontWeight="SemiBold" VerticalAlignment="Center" Foreground="White"/>
                </StackPanel>

                <Label Content="File to verify:" FontSize="12"/>
                <Grid Margin="0,0,0,4">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtFilePath"
                             Grid.Column="0"
                             IsReadOnly="True"
                             AllowDrop="True"
                             ToolTip="Drag and drop a file here or click Browse"/>
                    <Button Name="btnBrowseFile"
                            Grid.Column="1"
                            Content="BROWSE"
                            Width="100"
                            Background="#0078d4"/>
                </Grid>

                <Label Content="Hash Algorithm:" Margin="4,6,4,1" FontSize="12"/>
                <StackPanel Orientation="Horizontal" Margin="6,3,4,6">
                    <RadioButton Name="rbSHA256" Content="SHA256 (Recommended)"
                                IsChecked="True"
                                FontWeight="SemiBold"/>
                    <RadioButton Name="rbSHA1" Content="SHA1"
                                Margin="16,4,4,4"/>
                    <RadioButton Name="rbMD5" Content="MD5"
                                Margin="16,4,4,4"/>
                    <RadioButton Name="rbSHA512" Content="SHA512"
                                Margin="16,4,4,4"/>
                </StackPanel>

                <Label Content="Expected Hash (optional - leave blank to just calculate):" Margin="4,3,4,1" FontSize="12"/>
                <TextBox Name="txtExpectedHash"
                         TextWrapping="Wrap"
                         Height="50"
                         VerticalScrollBarVisibility="Auto"
                         FontFamily="Consolas"
                         FontSize="11"
                         ToolTip="Paste the expected hash here from the software publisher"/>
            </StackPanel>
        </Border>

        <!-- Batch File Mode Panel -->
        <Border Name="pnlBatchFile"
                Grid.Row="2"
                Background="#2d2d2d"
                BorderBrush="#d41a1a"
                BorderThickness="2"
                CornerRadius="8"
                Padding="14"
                Margin="0,0,0,12"
                Visibility="Collapsed">
            <StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                    <Border Background="#d41a1a" CornerRadius="13" Width="26" Height="26" Margin="0,0,10,0">
                        <TextBlock Text="1" Foreground="White" FontWeight="Bold" FontSize="13"
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Select checksum file and target folder"
                               FontSize="14" FontWeight="SemiBold" VerticalAlignment="Center" Foreground="White"/>
                </StackPanel>

                <Label Content="Checksum file (SHA256SUMS, checksums.txt, etc.):" FontSize="12"/>
                <Grid Margin="0,0,0,4">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtChecksumFile"
                             Grid.Column="0"
                             IsReadOnly="True"
                             AllowDrop="True"
                             ToolTip="Select or drag the checksum file"/>
                    <Button Name="btnBrowseChecksumFile"
                            Grid.Column="1"
                            Content="BROWSE"
                            Width="100"
                            Background="#d41a1a"/>
                </Grid>

                <Label Content="Folder containing files to verify:" Margin="4,6,4,1" FontSize="12"/>
                <Grid Margin="0,0,0,4">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtBatchFolder"
                             Grid.Column="0"
                             IsReadOnly="True"
                             ToolTip="Folder where the downloaded files are located"/>
                    <Button Name="btnBrowseFolder"
                            Grid.Column="1"
                            Content="BROWSE"
                            Width="100"
                            Background="#d41a1a"/>
                </Grid>

                <CheckBox Name="chkAutoDetect"
                         Content="Auto-detect hash algorithm from checksum file"
                         IsChecked="True"
                         FontWeight="SemiBold"/>
            </StackPanel>
        </Border>

        <!-- Results Area -->
        <Border Grid.Row="3"
                Background="#2d2d2d"
                BorderBrush="#444444"
                BorderThickness="2"
                CornerRadius="8"
                Padding="14"
                Margin="0,0,0,12">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Text="VERIFICATION RESULTS"
                           FontWeight="Bold" FontSize="13" Foreground="#0078d4" Margin="4,0,0,8"/>

                <DataGrid Name="dgResults"
                         Grid.Row="1"
                         AutoGenerateColumns="False"
                         IsReadOnly="True"
                         SelectionMode="Single"
                         GridLinesVisibility="Horizontal"
                         HeadersVisibility="Column"
                         RowHeight="30"
                         MaxHeight="200"
                         CanUserResizeRows="False"
                         BorderThickness="0"
                         Background="#0d0d0d"
                         Foreground="White"
                         RowBackground="#0d0d0d"
                         AlternatingRowBackground="#2d2d2d">
                    <DataGrid.Resources>
                        <Style TargetType="DataGridColumnHeader">
                            <Setter Property="Background" Value="#444444"/>
                            <Setter Property="Foreground" Value="White"/>
                            <Setter Property="FontWeight" Value="Bold"/>
                            <Setter Property="Padding" Value="6,5"/>
                            <Setter Property="BorderThickness" Value="0,0,1,0"/>
                            <Setter Property="BorderBrush" Value="#1e1e1e"/>
                        </Style>
                    </DataGrid.Resources>
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="80">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="FontWeight" Value="Bold"/>
                                    <Setter Property="FontSize" Value="11"/>
                                    <Setter Property="HorizontalAlignment" Value="Center"/>
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="Foreground" Value="#888888"/>
                                    <Style.Triggers>
                                        <DataTrigger Binding="{Binding Status}" Value="PASS">
                                            <Setter Property="Foreground" Value="#2ECC71"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding Status}" Value="FAIL">
                                            <Setter Property="Foreground" Value="#E74C3C"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding Status}" Value="MISSING">
                                            <Setter Property="Foreground" Value="#F39C12"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding Status}" Value="Calculated">
                                            <Setter Property="Foreground" Value="#0078d4"/>
                                        </DataTrigger>
                                    </Style.Triggers>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="File Name" Binding="{Binding FileName}" Width="*">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="Padding" Value="4,0"/>
                                    <Setter Property="Foreground" Value="White"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="Algorithm" Binding="{Binding Algorithm}" Width="80">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="HorizontalAlignment" Value="Center"/>
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="FontWeight" Value="SemiBold"/>
                                    <Setter Property="Foreground" Value="White"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="Expected Hash" Binding="{Binding ExpectedHash}" Width="200">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="FontFamily" Value="Consolas"/>
                                    <Setter Property="FontSize" Value="10"/>
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="Padding" Value="4,0"/>
                                    <Setter Property="Foreground" Value="#888888"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="Actual Hash" Binding="{Binding ActualHash}" Width="200">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="FontFamily" Value="Consolas"/>
                                    <Setter Property="FontSize" Value="10"/>
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="Padding" Value="4,0"/>
                                    <Setter Property="Foreground" Value="#888888"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                    </DataGrid.Columns>
                </DataGrid>
            </Grid>
        </Border>

        <!-- Status and Action Bar -->
        <Border Grid.Row="4"
                Background="#2d2d2d"
                Padding="14"
                CornerRadius="8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <TextBlock Name="txtStatus"
                          Grid.Column="0"
                          Text="Ready to verify files"
                          VerticalAlignment="Center"
                          FontSize="13"
                          FontWeight="SemiBold"
                          Foreground="#888888"/>

                <StackPanel Grid.Column="1" Orientation="Horizontal">
                    <Button Name="btnVerify"
                            Content="VERIFY"
                            Width="120"
                            Height="36"
                            Background="#107c10"
                            FontSize="12"/>
                    <Button Name="btnViewDetails"
                            Content="VIEW DETAILS"
                            Width="120"
                            Height="36"
                            Background="#0078d4"
                            FontSize="11"
                            IsEnabled="False"/>
                    <Button Name="btnExport"
                            Content="EXPORT RESULTS"
                            Width="130"
                            Height="36"
                            Background="#0078d4"
                            FontSize="11"
                            IsEnabled="False"/>
                    <Button Name="btnClear"
                            Content="CLEAR"
                            Width="80"
                            Height="36"
                            Background="#555555"
                            FontSize="11"/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
    </ScrollViewer>
</Window>
"@

# Load XAML
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$rbSingleFile = $window.FindName("rbSingleFile")
$rbBatchFile = $window.FindName("rbBatchFile")
$pnlSingleFile = $window.FindName("pnlSingleFile")
$pnlBatchFile = $window.FindName("pnlBatchFile")
$txtFilePath = $window.FindName("txtFilePath")
$btnBrowseFile = $window.FindName("btnBrowseFile")
$rbSHA256 = $window.FindName("rbSHA256")
$rbSHA1 = $window.FindName("rbSHA1")
$rbMD5 = $window.FindName("rbMD5")
$rbSHA512 = $window.FindName("rbSHA512")
$txtExpectedHash = $window.FindName("txtExpectedHash")
$txtChecksumFile = $window.FindName("txtChecksumFile")
$btnBrowseChecksumFile = $window.FindName("btnBrowseChecksumFile")
$txtBatchFolder = $window.FindName("txtBatchFolder")
$btnBrowseFolder = $window.FindName("btnBrowseFolder")
$chkAutoDetect = $window.FindName("chkAutoDetect")
$dgResults = $window.FindName("dgResults")
$txtStatus = $window.FindName("txtStatus")
$btnVerify = $window.FindName("btnVerify")
$btnViewDetails = $window.FindName("btnViewDetails")
$btnExport = $window.FindName("btnExport")
$btnClear = $window.FindName("btnClear")

# Results collection
$script:results = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$dgResults.ItemsSource = $script:results

# Helper functions
function Get-SelectedAlgorithm {
    if ($rbSHA256.IsChecked) { return "SHA256" }
    if ($rbSHA1.IsChecked) { return "SHA1" }
    if ($rbMD5.IsChecked) { return "MD5" }
    if ($rbSHA512.IsChecked) { return "SHA512" }
    return "SHA256"
}

function Detect-HashAlgorithm {
    param([string]$Hash)

    $cleanHash = $Hash.Replace(" ", "").Replace("-", "").Replace(":", "")
    switch ($cleanHash.Length) {
        32 { return "MD5" }
        40 { return "SHA1" }
        64 { return "SHA256" }
        128 { return "SHA512" }
        default { return "SHA256" }
    }
}

function Update-Status {
    param([string]$Message)
    $txtStatus.Text = $Message
}

function Show-DetailedResultDialog {
    param(
        [string]$FilePath,
        [string]$Algorithm,
        [string]$ActualHash,
        [string]$ExpectedHash = "",
        [bool]$IsMatch = $false,
        [bool]$VerifyMode = $false
    )

    [xml]$resultXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Detailed Results"
        Height="450"
        MinHeight="350"
        Width="600"
        MinWidth="450"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize"
        Background="#1e1e1e">
    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0"
                Background="#2d2d2d"
                Padding="12,10"
                CornerRadius="8"
                Margin="0,0,0,10">
            <StackPanel>
                <TextBlock Name="txtResultTitle"
                           FontSize="18"
                           FontWeight="Bold"
                           HorizontalAlignment="Center"
                           Foreground="#0078d4"
                           Margin="0,0,0,6"/>
                <TextBlock Name="txtFileName"
                           FontSize="11"
                           TextWrapping="Wrap"
                           HorizontalAlignment="Center"
                           Foreground="#888888"/>
            </StackPanel>
        </Border>

        <StackPanel Grid.Row="1" Margin="4">
            <Border Background="#2d2d2d"
                    BorderBrush="#444444"
                    BorderThickness="1"
                    CornerRadius="6"
                    Padding="10"
                    Margin="0,0,0,8">
                <StackPanel>
                    <TextBlock Text="Algorithm:" FontWeight="Bold" FontSize="12" Margin="0,0,0,4" Foreground="#888888"/>
                    <TextBox Name="txtAlgorithm"
                            IsReadOnly="True"
                            Background="#0d0d0d"
                            Foreground="White"
                            BorderThickness="0"
                            FontFamily="Consolas"
                            FontSize="13"/>
                </StackPanel>
            </Border>

            <Border Background="#2d2d2d"
                    BorderBrush="#444444"
                    BorderThickness="1"
                    CornerRadius="6"
                    Padding="10"
                    Margin="0,0,0,8">
                <StackPanel>
                    <TextBlock Text="Calculated Hash:" FontWeight="Bold" FontSize="12" Margin="0,0,0,4" Foreground="#888888"/>
                    <TextBox Name="txtActualHash"
                             IsReadOnly="True"
                             TextWrapping="Wrap"
                             Background="#0d0d0d"
                             Foreground="White"
                             BorderThickness="0"
                             FontFamily="Consolas"
                             FontSize="11"
                             Height="60"
                             VerticalScrollBarVisibility="Auto"/>
                </StackPanel>
            </Border>

            <Border Name="pnlExpected" Visibility="Collapsed"
                    Background="#2d2d2d"
                    BorderBrush="#444444"
                    BorderThickness="1"
                    CornerRadius="6"
                    Padding="10"
                    Margin="0,0,0,8">
                <StackPanel>
                    <TextBlock Text="Expected Hash:" FontWeight="Bold" FontSize="12" Margin="0,0,0,4" Foreground="#888888"/>
                    <TextBox Name="txtExpectedHashResult"
                             IsReadOnly="True"
                             TextWrapping="Wrap"
                             Background="#0d0d0d"
                             Foreground="White"
                             BorderThickness="0"
                             FontFamily="Consolas"
                             FontSize="11"
                             Height="60"
                             VerticalScrollBarVisibility="Auto"/>
                </StackPanel>
            </Border>

            <Border Name="borderResult"
                    BorderThickness="3"
                    CornerRadius="6"
                    Padding="12"
                    Margin="0,4,0,0"
                    Visibility="Collapsed">
                <TextBlock Name="txtVerifyResult"
                           FontSize="14"
                           FontWeight="Bold"
                           TextWrapping="Wrap"
                           HorizontalAlignment="Center"
                           TextAlignment="Center"
                           LineHeight="20"/>
            </Border>
        </StackPanel>

        <Border Grid.Row="2"
                Background="#2d2d2d"
                Padding="8"
                CornerRadius="6"
                Margin="0,8,0,0">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <Button Name="btnCopyHash"
                        Content="COPY HASH"
                        Width="130"
                        Height="34"
                        Margin="4"
                        Background="#0078d4"
                        Foreground="White"
                        FontWeight="SemiBold"
                        BorderThickness="0"
                        Cursor="Hand"/>
                <Button Name="btnClose"
                        Content="CLOSE"
                        Width="130"
                        Height="34"
                        Margin="4"
                        Background="#555555"
                        Foreground="White"
                        FontWeight="SemiBold"
                        BorderThickness="0"
                        Cursor="Hand"/>
            </StackPanel>
        </Border>
    </Grid>
    </ScrollViewer>
</Window>
"@

    $resultReader = New-Object System.Xml.XmlNodeReader $resultXaml
    $resultWindow = [Windows.Markup.XamlReader]::Load($resultReader)

    $txtResultTitle = $resultWindow.FindName("txtResultTitle")
    $txtFileName = $resultWindow.FindName("txtFileName")
    $txtAlgorithm = $resultWindow.FindName("txtAlgorithm")
    $txtActualHash = $resultWindow.FindName("txtActualHash")
    $pnlExpected = $resultWindow.FindName("pnlExpected")
    $txtExpectedHashResult = $resultWindow.FindName("txtExpectedHashResult")
    $borderResult = $resultWindow.FindName("borderResult")
    $txtVerifyResult = $resultWindow.FindName("txtVerifyResult")
    $btnCopyHash = $resultWindow.FindName("btnCopyHash")
    $btnClose = $resultWindow.FindName("btnClose")

    $txtFileName.Text = [System.IO.Path]::GetFileName($FilePath)
    $txtAlgorithm.Text = $Algorithm
    $txtActualHash.Text = $ActualHash

    if ($VerifyMode -and $ExpectedHash) {
        $pnlExpected.Visibility = "Visible"
        $txtExpectedHashResult.Text = $ExpectedHash
        $borderResult.Visibility = "Visible"

        if ($IsMatch) {
            $txtResultTitle.Text = "[PASS] VERIFICATION PASSED"
            $txtResultTitle.Foreground = "#2ECC71"
            $borderResult.BorderBrush = "#2ECC71"
            $borderResult.Background = "#0a2a1a"
            $txtVerifyResult.Text = "The file is authentic and has not been tampered with.`nThe calculated hash matches the expected hash."
            $txtVerifyResult.Foreground = "#2ECC71"
        } else {
            $txtResultTitle.Text = "[FAIL] VERIFICATION FAILED"
            $txtResultTitle.Foreground = "#E74C3C"
            $borderResult.BorderBrush = "#E74C3C"
            $borderResult.Background = "#2c1010"
            $txtVerifyResult.Text = "WARNING: HASHES DO NOT MATCH`n`nDo NOT install or use this file.`nIt may be corrupted, incomplete, or malicious."
            $txtVerifyResult.Foreground = "#E74C3C"
        }
    } else {
        $txtResultTitle.Text = "HASH CALCULATED"
        $txtResultTitle.Foreground = "#0078d4"
        $borderResult.Visibility = "Collapsed"
    }

    $btnCopyHash.Add_Click({
        [System.Windows.Clipboard]::SetText($ActualHash)
        [System.Windows.MessageBox]::Show(
            "Hash copied to clipboard.",
            "Copied",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        )
    })

    $btnClose.Add_Click({
        $resultWindow.Close()
    })

    $resultWindow.ShowDialog() | Out-Null
}

function Parse-ChecksumFile {
    param([string]$FilePath)

    $checksums = @()
    $content = Get-Content $FilePath -ErrorAction Stop

    foreach ($line in $content) {
        $line = $line.Trim()

        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
            continue
        }

        if ($line -match '^([a-fA-F0-9]+)\s+\*?(.+)$') {
            $checksums += @{
                Hash = $matches[1].Trim()
                FileName = $matches[2].Trim().TrimStart('*')
            }
        }
        elseif ($line -match '^(.+?)\s+([a-fA-F0-9]{32,})$') {
            $checksums += @{
                Hash = $matches[2].Trim()
                FileName = $matches[1].Trim()
            }
        }
    }

    return $checksums
}

function Verify-SingleFile {
    $script:results.Clear()
    Update-Status "Calculating hash..."
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    $btnVerify.IsEnabled = $false

    try {
        $filePath = $txtFilePath.Text
        $algorithm = Get-SelectedAlgorithm
        $expectedHash = $txtExpectedHash.Text.Trim().ToUpper().Replace(" ", "").Replace("-", "").Replace(":", "")

        if (-not (Test-Path $filePath)) {
            throw "File not found: $filePath"
        }

        $actualHash = (Get-FileHash -Path $filePath -Algorithm $algorithm).Hash

        $isMatch = $false
        $status = "Calculated"
        $verifyMode = $false

        if (-not [string]::IsNullOrWhiteSpace($expectedHash)) {
            $verifyMode = $true
            if ($actualHash -eq $expectedHash) {
                $status = "PASS"
                $isMatch = $true
            } else {
                $status = "FAIL"
            }
        }

        if ([string]::IsNullOrWhiteSpace($expectedHash)) {
            $displayExpected = "N/A"
        } else {
            $displayExpected = $expectedHash.Substring(0, [Math]::Min(20, $expectedHash.Length)) + "..."
        }

        $script:results.Add([PSCustomObject]@{
            Status = $status
            FileName = [System.IO.Path]::GetFileName($filePath)
            Algorithm = $algorithm
            ExpectedHash = $displayExpected
            ActualHash = $actualHash.Substring(0, [Math]::Min(20, $actualHash.Length)) + "..."
            FullExpectedHash = $expectedHash
            FullActualHash = $actualHash
            FullFilePath = $filePath
        })

        if ($verifyMode) {
            if ($isMatch) {
                Update-Status "[PASS] Hash matches - file is authentic"
                $txtStatus.Foreground = "#2ECC71"
            } else {
                Update-Status "[FAIL] Hash MISMATCH - do not trust this file"
                $txtStatus.Foreground = "#E74C3C"
            }
        } else {
            Update-Status "Hash calculated successfully"
            $txtStatus.Foreground = "#2ECC71"
        }

        $btnExport.IsEnabled = $true
        $btnViewDetails.IsEnabled = $true

        Show-DetailedResultDialog -FilePath $filePath -Algorithm $algorithm -ActualHash $actualHash -ExpectedHash $txtExpectedHash.Text.Trim() -IsMatch $isMatch -VerifyMode $verifyMode
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Error: $($_.Exception.Message)",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
        Update-Status "Error occurred"
        $txtStatus.Foreground = "#E74C3C"
    }
    finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        $btnVerify.IsEnabled = $true
    }
}

function Verify-BatchFiles {
    $script:results.Clear()
    Update-Status "Parsing checksum file..."
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    $btnVerify.IsEnabled = $false

    try {
        $checksumFile = $txtChecksumFile.Text
        $folder = $txtBatchFolder.Text

        if (-not (Test-Path $checksumFile)) {
            throw "Checksum file not found: $checksumFile"
        }

        if (-not (Test-Path $folder)) {
            throw "Folder not found: $folder"
        }

        $checksums = Parse-ChecksumFile -FilePath $checksumFile

        if ($checksums.Count -eq 0) {
            throw "No valid checksums found in file"
        }

        Update-Status "Verifying $($checksums.Count) files..."

        $completed = 0
        $passed = 0
        $failed = 0
        $missing = 0

        foreach ($item in $checksums) {
            $fileName = $item.FileName
            $expectedHash = $item.Hash.ToUpper()

            if ($chkAutoDetect.IsChecked) {
                $algorithm = Detect-HashAlgorithm -Hash $expectedHash
            } else {
                $algorithm = Get-SelectedAlgorithm
            }

            $filePath = Join-Path $folder $fileName

            if (-not (Test-Path $filePath)) {
                $script:results.Add([PSCustomObject]@{
                    Status = "MISSING"
                    FileName = $fileName
                    Algorithm = $algorithm
                    ExpectedHash = $expectedHash.Substring(0, [Math]::Min(20, $expectedHash.Length)) + "..."
                    ActualHash = "File not found"
                    FullExpectedHash = $expectedHash
                    FullActualHash = ""
                    FullFilePath = $filePath
                })
                $missing++
                $completed++
                continue
            }

            try {
                $actualHash = (Get-FileHash -Path $filePath -Algorithm $algorithm).Hash

                if ($actualHash -eq $expectedHash) {
                    $status = "PASS"
                    $passed++
                } else {
                    $status = "FAIL"
                    $failed++
                }

                $script:results.Add([PSCustomObject]@{
                    Status = $status
                    FileName = $fileName
                    Algorithm = $algorithm
                    ExpectedHash = $expectedHash.Substring(0, [Math]::Min(20, $expectedHash.Length)) + "..."
                    ActualHash = $actualHash.Substring(0, [Math]::Min(20, $actualHash.Length)) + "..."
                    FullExpectedHash = $expectedHash
                    FullActualHash = $actualHash
                    FullFilePath = $filePath
                })
            }
            catch {
                $script:results.Add([PSCustomObject]@{
                    Status = "FAIL"
                    FileName = $fileName
                    Algorithm = $algorithm
                    ExpectedHash = $expectedHash.Substring(0, [Math]::Min(20, $expectedHash.Length)) + "..."
                    ActualHash = "Error: $($_.Exception.Message)"
                    FullExpectedHash = $expectedHash
                    FullActualHash = ""
                    FullFilePath = $filePath
                })
                $failed++
            }

            $completed++
            Update-Status "Verified $completed of $($checksums.Count) files..."
        }

        $summaryText = "Complete: $passed passed, $failed failed, $missing missing"
        Update-Status $summaryText

        if ($failed -eq 0 -and $missing -eq 0) {
            $txtStatus.Foreground = "#2ECC71"
        } elseif ($passed -gt 0) {
            $txtStatus.Foreground = "#F39C12"
        } else {
            $txtStatus.Foreground = "#E74C3C"
        }

        $btnExport.IsEnabled = $true
        $btnViewDetails.IsEnabled = $true
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Error: $($_.Exception.Message)",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
        Update-Status "Error occurred"
        $txtStatus.Foreground = "#E74C3C"
    }
    finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        $btnVerify.IsEnabled = $true
    }
}

# === EVENT HANDLERS ===

# Mode switching
$rbSingleFile.Add_Checked({
    $pnlSingleFile.Visibility = "Visible"
    $pnlBatchFile.Visibility = "Collapsed"
    Update-Status "Ready to verify single file"
    $txtStatus.Foreground = "#888888"
})

$rbBatchFile.Add_Checked({
    $pnlSingleFile.Visibility = "Collapsed"
    $pnlBatchFile.Visibility = "Visible"
    Update-Status "Ready to verify batch files"
    $txtStatus.Foreground = "#888888"
})

# Browse buttons
$btnBrowseFile.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "All Files (*.*)|*.*"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtFilePath.Text = $openFileDialog.FileName
    }
})

$btnBrowseChecksumFile.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Checksum Files (*.txt;*SUMS;*.sha*;*.md5)|*.txt;*SUMS;*.sha*;*.md5|All Files (*.*)|*.*"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtChecksumFile.Text = $openFileDialog.FileName

        $folder = [System.IO.Path]::GetDirectoryName($openFileDialog.FileName)
        if ([string]::IsNullOrWhiteSpace($txtBatchFolder.Text)) {
            $txtBatchFolder.Text = $folder
        }
    }
})

$btnBrowseFolder.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select folder containing files to verify"
    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtBatchFolder.Text = $folderDialog.SelectedPath
    }
})

# Drag and drop
$txtFilePath.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effects = [Windows.DragDropEffects]::Copy
    }
})

$txtFilePath.Add_Drop({
    param($sender, $e)
    $files = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if ($files.Count -gt 0) {
        $txtFilePath.Text = $files[0]
    }
})

$txtChecksumFile.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effects = [Windows.DragDropEffects]::Copy
    }
})

$txtChecksumFile.Add_Drop({
    param($sender, $e)
    $files = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if ($files.Count -gt 0) {
        $txtChecksumFile.Text = $files[0]
        $folder = [System.IO.Path]::GetDirectoryName($files[0])
        if ([string]::IsNullOrWhiteSpace($txtBatchFolder.Text)) {
            $txtBatchFolder.Text = $folder
        }
    }
})

# Verify button
$btnVerify.Add_Click({
    if ($rbSingleFile.IsChecked) {
        if ([string]::IsNullOrWhiteSpace($txtFilePath.Text)) {
            [System.Windows.MessageBox]::Show(
                "Please select a file to verify.",
                "No File Selected",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            )
            return
        }
        Verify-SingleFile
    } else {
        if ([string]::IsNullOrWhiteSpace($txtChecksumFile.Text)) {
            [System.Windows.MessageBox]::Show(
                "Please select a checksum file.",
                "No Checksum File",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            )
            return
        }
        if ([string]::IsNullOrWhiteSpace($txtBatchFolder.Text)) {
            [System.Windows.MessageBox]::Show(
                "Please select the folder containing files to verify.",
                "No Folder Selected",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            )
            return
        }
        Verify-BatchFiles
    }
})

# View Details button
$btnViewDetails.Add_Click({
    $selected = $dgResults.SelectedItem
    if ($null -eq $selected -and $script:results.Count -gt 0) {
        $selected = $script:results[0]
    }

    if ($null -ne $selected) {
        $verifyMode = ($selected.FullExpectedHash -ne "" -and $selected.FullExpectedHash -ne "N/A")
        $isMatch = ($selected.Status -eq "PASS")

        Show-DetailedResultDialog -FilePath $selected.FullFilePath `
                                   -Algorithm $selected.Algorithm `
                                   -ActualHash $selected.FullActualHash `
                                   -ExpectedHash $selected.FullExpectedHash `
                                   -IsMatch $isMatch `
                                   -VerifyMode $verifyMode
    }
})

# Double-click on grid to view details
$dgResults.Add_MouseDoubleClick({
    $selected = $dgResults.SelectedItem
    if ($null -ne $selected) {
        $verifyMode = ($selected.FullExpectedHash -ne "" -and $selected.FullExpectedHash -ne "N/A")
        $isMatch = ($selected.Status -eq "PASS")

        Show-DetailedResultDialog -FilePath $selected.FullFilePath `
                                   -Algorithm $selected.Algorithm `
                                   -ActualHash $selected.FullActualHash `
                                   -ExpectedHash $selected.FullExpectedHash `
                                   -IsMatch $isMatch `
                                   -VerifyMode $verifyMode
    }
})

# Export button
$btnExport.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "CSV Files (*.csv)|*.csv|Text Files (*.txt)|*.txt"
    $saveDialog.FileName = "ChecksumResults_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $exportData = $script:results | Select-Object Status, FileName, Algorithm, FullExpectedHash, FullActualHash
            $exportData | Export-Csv -Path $saveDialog.FileName -NoTypeInformation
            [System.Windows.MessageBox]::Show(
                "Results exported to:`n$($saveDialog.FileName)",
                "Export Complete",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            )
            Update-Status "Results exported successfully"
            $txtStatus.Foreground = "#2ECC71"
        }
        catch {
            [System.Windows.MessageBox]::Show(
                "Error exporting results: $($_.Exception.Message)",
                "Export Error",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            )
        }
    }
})

# Clear button
$btnClear.Add_Click({
    $txtFilePath.Text = ""
    $txtExpectedHash.Text = ""
    $txtChecksumFile.Text = ""
    $txtBatchFolder.Text = ""
    $script:results.Clear()
    Update-Status "Ready to verify files"
    $txtStatus.Foreground = "#888888"
    $btnExport.IsEnabled = $false
    $btnViewDetails.IsEnabled = $false
    $rbSHA256.IsChecked = $true
})

# Show the window
$window.ShowDialog() | Out-Null

# SIG # Begin signature block
# MIIFlwYJKoZIhvcNAQcCoIIFiDCCBYQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUN4khNV40ykbzWEZUC2oAmRSR
# j7WgggMkMIIDIDCCAgigAwIBAgIQHrfhJiTc0JlLezzxNwo/3TANBgkqhkiG9w0B
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
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUlpxK8bfPcy6ZD15i
# JfMyv6UgBZQwDQYJKoZIhvcNAQEBBQAEggEAv9dYU8WKUToRCWEu717VkAvUsA+5
# t/MuwqbPbFkTbZEvQcOVN+IZjcEFcaHPsRCyBuooeBADK3sT2t6d5fsOXAcobdM5
# MlKUuKaeWArFifGrJ0If/pzIkXBurVlz4cmMn7ovVN/PBHrT+jbP3j6hFOMY/H3x
# TXPAlfM1uW0bYo+hmW+cOLU5FB8rd/1qzLaGcZ5w+GC00/jaTxzmXPllAzsZP/Xp
# OkRPxuvlCbiTWLLCJHI6431HeU2mxFfmfftKVaVTdbMyuJLViu3HpND9fNZmIqou
# sCk7aolmXYbsdV1/X2nnDkpZitzKmq9/2RCsszYJS/fTiS9DlGVnsCRAJg==
# SIG # End signature block
