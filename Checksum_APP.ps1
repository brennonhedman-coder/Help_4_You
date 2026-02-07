Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# XAML Definition
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Checksum Verifier Ultimate" 
        Height="750" 
        Width="950"
        WindowStartupLocation="CenterScreen"
        Background="#F0F0F0">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontSize" Value="11"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Margin" Value="5,5,5,0"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Title -->
        <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,10">
            <TextBlock Text="🔐 " FontSize="24" VerticalAlignment="Center" Margin="0,0,5,0"/>
            <TextBlock Text="Checksum Verifier Ultimate" 
                       FontSize="24" 
                       FontWeight="Bold" 
                       Foreground="#2C3E50"
                       VerticalAlignment="Center"/>
        </StackPanel>

        <!-- Mode Selection -->
        <Border Grid.Row="1" 
                BorderBrush="#3498DB" 
                BorderThickness="2" 
                CornerRadius="8" 
                Padding="12" 
                Margin="5"
                Background="White">
            <StackPanel>
                <TextBlock Text="Verification Mode:" FontWeight="Bold" FontSize="14" Margin="0,0,0,8" Foreground="#2C3E50"/>
                <StackPanel Orientation="Horizontal">
                    <RadioButton Name="rbSingleFile" 
                                Content="📄 Single File Verification" 
                                IsChecked="True" 
                                Margin="5" 
                                FontSize="13"
                                VerticalAlignment="Center"/>
                    <RadioButton Name="rbBatchFile" 
                                Content="📦 Batch Verification (from checksum file)" 
                                Margin="25,5,5,5" 
                                FontSize="13"
                                VerticalAlignment="Center"/>
                </StackPanel>
            </StackPanel>
        </Border>

        <!-- Single File Mode Panel -->
        <Border Name="pnlSingleFile" 
                Grid.Row="2" 
                BorderBrush="#BDC3C7" 
                BorderThickness="1" 
                CornerRadius="8" 
                Padding="12" 
                Margin="5"
                Background="White">
            <StackPanel>
                <Label Content="📁 Select File to Verify:" FontSize="13"/>
                <Grid Margin="5,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtFilePath" 
                             Grid.Column="0" 
                             IsReadOnly="True"
                             AllowDrop="True"
                             Background="#F8F9FA"
                             BorderBrush="#BDC3C7"
                             ToolTip="Drag and drop a file here or click Browse"/>
                    <Button Name="btnBrowseFile" 
                            Grid.Column="1" 
                            Content="Browse..." 
                            Width="110"
                            Background="#3498DB"
                            Foreground="White"
                            FontWeight="SemiBold"/>
                </Grid>

                <Label Content="🔢 Hash Algorithm:" Margin="5,12,5,0" FontSize="13"/>
                <StackPanel Orientation="Horizontal" Margin="8,4,5,4">
                    <RadioButton Name="rbSHA256" Content="SHA256 (Recommended)" 
                                IsChecked="True" 
                                Margin="5" 
                                FontSize="12"
                                FontWeight="SemiBold"/>
                    <RadioButton Name="rbSHA1" Content="SHA1" 
                                Margin="20,5,5,5" 
                                FontSize="12"/>
                    <RadioButton Name="rbMD5" Content="MD5" 
                                Margin="20,5,5,5" 
                                FontSize="12"/>
                    <RadioButton Name="rbSHA512" Content="SHA512" 
                                Margin="20,5,5,5" 
                                FontSize="12"/>
                </StackPanel>

                <Label Content="🎯 Expected Hash (optional - leave blank to just calculate):" Margin="5,8,5,0" FontSize="13"/>
                <TextBox Name="txtExpectedHash" 
                         TextWrapping="Wrap"
                         Height="60"
                         Background="#F8F9FA"
                         BorderBrush="#BDC3C7"
                         VerticalScrollBarVisibility="Auto"
                         FontFamily="Consolas"
                         FontSize="11"
                         ToolTip="Paste the expected hash here from the software publisher"/>
            </StackPanel>
        </Border>

        <!-- Batch File Mode Panel -->
        <Border Name="pnlBatchFile" 
                Grid.Row="2" 
                BorderBrush="#BDC3C7" 
                BorderThickness="1" 
                CornerRadius="8" 
                Padding="12" 
                Margin="5"
                Background="White"
                Visibility="Collapsed">
            <StackPanel>
                <Label Content="📋 Checksum File (SHA256SUMS, checksums.txt, etc.):" FontSize="13"/>
                <Grid Margin="5,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtChecksumFile" 
                             Grid.Column="0" 
                             IsReadOnly="True"
                             AllowDrop="True"
                             Background="#F8F9FA"
                             BorderBrush="#BDC3C7"
                             ToolTip="Select or drag the checksum file (e.g., SHA256SUMS)"/>
                    <Button Name="btnBrowseChecksumFile" 
                            Grid.Column="1" 
                            Content="Browse..." 
                            Width="110"
                            Background="#3498DB"
                            Foreground="White"
                            FontWeight="SemiBold"/>
                </Grid>

                <Label Content="📂 Folder Containing Files to Verify:" Margin="5,12,5,0" FontSize="13"/>
                <Grid Margin="5,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtBatchFolder" 
                             Grid.Column="0" 
                             IsReadOnly="True"
                             Background="#F8F9FA"
                             BorderBrush="#BDC3C7"
                             ToolTip="Folder where the downloaded files are located"/>
                    <Button Name="btnBrowseFolder" 
                            Grid.Column="1" 
                            Content="Browse..." 
                            Width="110"
                            Background="#3498DB"
                            Foreground="White"
                            FontWeight="SemiBold"/>
                </Grid>

                <CheckBox Name="chkAutoDetect" 
                         Content="✨ Auto-detect hash algorithm from checksum file" 
                         IsChecked="True"
                         Margin="10,12,5,5"
                         FontSize="12"
                         FontWeight="SemiBold"/>
            </StackPanel>
        </Border>

        <!-- Results Area -->
        <Border Grid.Row="3" 
                BorderBrush="#BDC3C7" 
                BorderThickness="1" 
                CornerRadius="8" 
                Padding="8" 
                Margin="5,10,5,5"
                Background="White">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                
                <Border Grid.Row="0" 
                        Background="#ECF0F1" 
                        Padding="8,5" 
                        CornerRadius="4"
                        Margin="0,0,0,8">
                    <TextBlock Text="📊 Verification Results" 
                              FontWeight="Bold" 
                              FontSize="14" 
                              Foreground="#2C3E50"/>
                </Border>
                
                <DataGrid Name="dgResults" 
                         Grid.Row="1"
                         AutoGenerateColumns="False"
                         IsReadOnly="True"
                         SelectionMode="Single"
                         AlternatingRowBackground="#F8F9FA"
                         GridLinesVisibility="Horizontal"
                         HeadersVisibility="Column"
                         RowHeight="32"
                         CanUserResizeRows="False"
                         BorderThickness="0">
                    <DataGrid.Resources>
                        <Style TargetType="DataGridColumnHeader">
                            <Setter Property="Background" Value="#34495E"/>
                            <Setter Property="Foreground" Value="White"/>
                            <Setter Property="FontWeight" Value="Bold"/>
                            <Setter Property="Padding" Value="8,6"/>
                            <Setter Property="BorderThickness" Value="0,0,1,0"/>
                            <Setter Property="BorderBrush" Value="#2C3E50"/>
                        </Style>
                    </DataGrid.Resources>
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="90">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="FontWeight" Value="Bold"/>
                                    <Setter Property="FontSize" Value="12"/>
                                    <Setter Property="HorizontalAlignment" Value="Center"/>
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Style.Triggers>
                                        <DataTrigger Binding="{Binding Status}" Value="✓ PASS">
                                            <Setter Property="Foreground" Value="#27AE60"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding Status}" Value="✗ FAIL">
                                            <Setter Property="Foreground" Value="#E74C3C"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding Status}" Value="⚠ MISSING">
                                            <Setter Property="Foreground" Value="#F39C12"/>
                                        </DataTrigger>
                                        <DataTrigger Binding="{Binding Status}" Value="Calculated">
                                            <Setter Property="Foreground" Value="#3498DB"/>
                                        </DataTrigger>
                                    </Style.Triggers>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="File Name" Binding="{Binding FileName}" Width="*">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="Padding" Value="5,0"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="Algorithm" Binding="{Binding Algorithm}" Width="90">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="HorizontalAlignment" Value="Center"/>
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="FontWeight" Value="SemiBold"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="Expected Hash" Binding="{Binding ExpectedHash}" Width="220">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="FontFamily" Value="Consolas"/>
                                    <Setter Property="FontSize" Value="10"/>
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="Padding" Value="5,0"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="Actual Hash" Binding="{Binding ActualHash}" Width="220">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="FontFamily" Value="Consolas"/>
                                    <Setter Property="FontSize" Value="10"/>
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="Padding" Value="5,0"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                    </DataGrid.Columns>
                </DataGrid>
            </Grid>
        </Border>

        <!-- Status and Action Bar -->
        <Border Grid.Row="4" 
                Background="#ECF0F1" 
                Padding="10" 
                Margin="5,5,5,0"
                CornerRadius="6">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <!-- Status text -->
                <StackPanel Grid.Column="0" VerticalAlignment="Center" Orientation="Horizontal">
                    <TextBlock Name="txtStatusIcon" 
                              Text="ℹ️ " 
                              FontSize="14"
                              Margin="5,0"
                              VerticalAlignment="Center"/>
                    <TextBlock Name="txtStatus" 
                              Text="Ready to verify files"
                              VerticalAlignment="Center"
                              FontSize="12"
                              Foreground="#34495E"
                              FontWeight="SemiBold"/>
                </StackPanel>
                
                <!-- Buttons -->
                <StackPanel Grid.Column="1" Orientation="Horizontal">
                    <Button Name="btnVerify" 
                            Content="🔍 Verify" 
                            Width="130"
                            Height="36"
                            Background="#27AE60"
                            Foreground="White"
                            FontWeight="Bold"
                            FontSize="14"/>
                    <Button Name="btnViewDetails" 
                            Content="👁️ View Details" 
                            Width="130"
                            Height="36"
                            Background="#9B59B6"
                            Foreground="White"
                            FontWeight="SemiBold"
                            IsEnabled="False"/>
                    <Button Name="btnExport" 
                            Content="💾 Export Results" 
                            Width="140"
                            Height="36"
                            Background="#3498DB"
                            Foreground="White"
                            FontWeight="SemiBold"
                            IsEnabled="False"/>
                    <Button Name="btnClear" 
                            Content="🗑️ Clear" 
                            Width="100"
                            Height="36"
                            Background="#95A5A6"
                            Foreground="White"
                            FontWeight="SemiBold"/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
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
$txtStatusIcon = $window.FindName("txtStatusIcon")
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

function Show-MessageBox {
    param(
        [string]$Message,
        [string]$Title,
        [string]$Type = "Information"
    )
    
    $icon = switch ($Type) {
        "Information" { [System.Windows.MessageBoxImage]::Information }
        "Warning" { [System.Windows.MessageBoxImage]::Warning }
        "Error" { [System.Windows.MessageBoxImage]::Error }
        default { [System.Windows.MessageBoxImage]::Information }
    }
    
    [System.Windows.MessageBox]::Show($Message, $Title, [System.Windows.MessageBoxButton]::OK, $icon)
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
    
    # Create result window
    [xml]$resultXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Detailed Results" 
        Height="500" 
        Width="650"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize"
        Background="#F0F0F0">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" 
                Background="#34495E" 
                Padding="15,12" 
                CornerRadius="6"
                Margin="0,0,0,15">
            <StackPanel>
                <TextBlock Name="txtResultTitle" 
                           FontSize="20" 
                           FontWeight="Bold" 
                           HorizontalAlignment="Center"
                           Foreground="White"
                           Margin="0,0,0,8"/>
                <TextBlock Name="txtFileName" 
                           FontSize="12" 
                           TextWrapping="Wrap"
                           HorizontalAlignment="Center"
                           Foreground="#ECF0F1"/>
            </StackPanel>
        </Border>

        <!-- Content -->
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Margin="5">
                <Border Background="White" 
                        BorderBrush="#BDC3C7" 
                        BorderThickness="1" 
                        CornerRadius="6" 
                        Padding="12"
                        Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="Algorithm:" FontWeight="Bold" FontSize="13" Margin="0,0,0,5" Foreground="#2C3E50"/>
                        <TextBox Name="txtAlgorithm" 
                                IsReadOnly="True" 
                                Background="#ECF0F1" 
                                BorderThickness="0"
                                FontFamily="Consolas"
                                FontSize="13"/>
                    </StackPanel>
                </Border>
                
                <Border Background="White" 
                        BorderBrush="#BDC3C7" 
                        BorderThickness="1" 
                        CornerRadius="6" 
                        Padding="12"
                        Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="Calculated Hash:" FontWeight="Bold" FontSize="13" Margin="0,0,0,5" Foreground="#2C3E50"/>
                        <TextBox Name="txtActualHash" 
                                 IsReadOnly="True" 
                                 TextWrapping="Wrap" 
                                 Background="#E8F8F5" 
                                 BorderThickness="0"
                                 FontFamily="Consolas"
                                 FontSize="11"
                                 Height="70"
                                 VerticalScrollBarVisibility="Auto"/>
                    </StackPanel>
                </Border>
                
                <Border Name="pnlExpected" Visibility="Collapsed"
                        Background="White" 
                        BorderBrush="#BDC3C7" 
                        BorderThickness="1" 
                        CornerRadius="6" 
                        Padding="12"
                        Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="Expected Hash:" FontWeight="Bold" FontSize="13" Margin="0,0,0,5" Foreground="#2C3E50"/>
                        <TextBox Name="txtExpectedHashResult" 
                                 IsReadOnly="True" 
                                 TextWrapping="Wrap" 
                                 Background="#FEF5E7" 
                                 BorderThickness="0"
                                 FontFamily="Consolas"
                                 FontSize="11"
                                 Height="70"
                                 VerticalScrollBarVisibility="Auto"/>
                    </StackPanel>
                </Border>
                
                <Border Name="borderResult" 
                        BorderThickness="3" 
                        CornerRadius="8" 
                        Padding="15"
                        Margin="0,5,0,0"
                        Visibility="Collapsed">
                    <StackPanel>
                        <TextBlock Name="txtVerifyResult" 
                                   FontSize="15" 
                                   FontWeight="Bold"
                                   TextWrapping="Wrap"
                                   HorizontalAlignment="Center"
                                   TextAlignment="Center"
                                   LineHeight="22"/>
                    </StackPanel>
                </Border>
            </StackPanel>
        </ScrollViewer>

        <!-- Buttons -->
        <Border Grid.Row="2" 
                Background="#ECF0F1" 
                Padding="10" 
                CornerRadius="6"
                Margin="0,10,0,0">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <Button Name="btnCopyHash" 
                        Content="📋 Copy Hash" 
                        Width="140" 
                        Height="36"
                        Margin="5"
                        Background="#3498DB"
                        Foreground="White"
                        FontWeight="SemiBold"/>
                <Button Name="btnClose" 
                        Content="✖️ Close" 
                        Width="140" 
                        Height="36"
                        Margin="5"
                        Background="#95A5A6"
                        Foreground="White"
                        FontWeight="SemiBold"/>
            </StackPanel>
        </Border>
    </Grid>
</Window>
"@
    
    $resultReader = New-Object System.Xml.XmlNodeReader $resultXaml
    $resultWindow = [Windows.Markup.XamlReader]::Load($resultReader)
    
    # Get controls
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
    
    # Set values
    $txtFileName.Text = "📄 $([System.IO.Path]::GetFileName($FilePath))"
    $txtAlgorithm.Text = $Algorithm
    $txtActualHash.Text = $ActualHash
    
    if ($VerifyMode -and $ExpectedHash) {
        $pnlExpected.Visibility = "Visible"
        $txtExpectedHashResult.Text = $ExpectedHash
        $borderResult.Visibility = "Visible"
        
        if ($IsMatch) {
            $txtResultTitle.Text = "✓ VERIFICATION PASSED"
            $borderResult.BorderBrush = "#27AE60"
            $borderResult.Background = "#D5F4E6"
            $txtVerifyResult.Text = "✓ SUCCESS!`n`nThe file is authentic and has not been tampered with.`nThe calculated hash matches the expected hash perfectly."
            $txtVerifyResult.Foreground = "#27AE60"
        } else {
            $txtResultTitle.Text = "✗ VERIFICATION FAILED"
            $borderResult.BorderBrush = "#E74C3C"
            $borderResult.Background = "#FADBD8"
            $txtVerifyResult.Text = "✗ WARNING! HASHES DO NOT MATCH!`n`nDo NOT install or use this file.`nIt may be corrupted, incomplete, or malicious."
            $txtVerifyResult.Foreground = "#E74C3C"
        }
    } else {
        $txtResultTitle.Text = "✓ HASH CALCULATED"
        $borderResult.Visibility = "Collapsed"
    }
    
    # Button events
    $btnCopyHash.Add_Click({
        [System.Windows.Clipboard]::SetText($ActualHash)
        Show-MessageBox -Message "Hash copied to clipboard!" -Title "Copied" -Type "Information"
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
        
        # Skip empty lines and comments
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
            continue
        }
        
        # Try to parse different formats
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

function Detect-HashAlgorithm {
    param([string]$Hash)
    
    $cleanHash = $Hash.Replace(" ", "").Replace("-", "").Replace(":", "")
    $length = $cleanHash.Length
    
    switch ($length) {
        32 { return "MD5" }
        40 { return "SHA1" }
        64 { return "SHA256" }
        128 { return "SHA512" }
        default { return "SHA256" }
    }
}

function Update-Status {
    param(
        [string]$Message,
        [string]$Icon = "ℹ️"
    )
    $txtStatusIcon.Text = "$Icon "
    $txtStatus.Text = $Message
}

function Verify-SingleFile {
    $script:results.Clear()
    Update-Status "⏳ Calculating hash..." "⏳"
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    $btnVerify.IsEnabled = $false
    
    try {
        $filePath = $txtFilePath.Text
        $algorithm = Get-SelectedAlgorithm
        $expectedHash = $txtExpectedHash.Text.Trim().ToUpper().Replace(" ", "").Replace("-", "").Replace(":", "")
        
        if (-not (Test-Path $filePath)) {
            throw "File not found: $filePath"
        }
        
        # Calculate hash
        $actualHash = (Get-FileHash -Path $filePath -Algorithm $algorithm).Hash
        
        # Determine status
        $isMatch = $false
        $status = "Calculated"
        $verifyMode = $false
        
        if (-not [string]::IsNullOrWhiteSpace($expectedHash)) {
            $verifyMode = $true
            if ($actualHash -eq $expectedHash) {
                $status = "✓ PASS"
                $isMatch = $true
            } else {
                $status = "✗ FAIL"
            }
        }
        
        # Add result
        $displayExpected = if ([string]::IsNullOrWhiteSpace($expectedHash)) { "N/A" } else { $expectedHash.Substring(0, [Math]::Min(20, $expectedHash.Length)) + "..." }
        
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
                Update-Status "✓ Verification complete - Hash matches!" "✓"
            } else {
                Update-Status "✗ Verification complete - Hash MISMATCH!" "✗"
            }
        } else {
            Update-Status "✓ Hash calculated successfully" "✓"
        }
        
        $btnExport.IsEnabled = $true
        $btnViewDetails.IsEnabled = $true
        
        # Auto-show detailed results for single file
        Show-DetailedResultDialog -FilePath $filePath -Algorithm $algorithm -ActualHash $actualHash -ExpectedHash $txtExpectedHash.Text.Trim() -IsMatch $isMatch -VerifyMode $verifyMode
    }
    catch {
        Show-MessageBox -Message "Error: $($_.Exception.Message)" -Title "Error" -Type "Error"
        Update-Status "❌ Error occurred" "❌"
    }
    finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        $btnVerify.IsEnabled = $true
    }
}

function Verify-BatchFiles {
    $script:results.Clear()
    Update-Status "⏳ Parsing checksum file..." "⏳"
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
        
        # Parse checksum file
        $checksums = Parse-ChecksumFile -FilePath $checksumFile
        
        if ($checksums.Count -eq 0) {
            throw "No valid checksums found in file"
        }
        
        Update-Status "⏳ Verifying $($checksums.Count) files..." "⏳"
        
        # Verify each file
        $completed = 0
        $passed = 0
        $failed = 0
        $missing = 0
        
        foreach ($item in $checksums) {
            $fileName = $item.FileName
            $expectedHash = $item.Hash.ToUpper()
            
            # Detect algorithm
            $algorithm = if ($chkAutoDetect.IsChecked) {
                Detect-HashAlgorithm -Hash $expectedHash
            } else {
                Get-SelectedAlgorithm
            }
            
            # Find file
            $filePath = Join-Path $folder $fileName
            
            if (-not (Test-Path $filePath)) {
                # Add missing file result
                $script:results.Add([PSCustomObject]@{
                    Status = "⚠ MISSING"
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
            
            # Calculate hash
            try {
                $actualHash = (Get-FileHash -Path $filePath -Algorithm $algorithm).Hash
                
                # Compare
                if ($actualHash -eq $expectedHash) {
                    $status = "✓ PASS"
                    $passed++
                } else {
                    $status = "✗ FAIL"
                    $failed++
                }
                
                # Add result
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
                    Status = "✗ FAIL"
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
            Update-Status "⏳ Verified $completed of $($checksums.Count) files..." "⏳"
        }
        
        # Summary
        $icon = if ($failed -eq 0 -and $missing -eq 0) { "✓" } elseif ($passed -gt 0) { "⚠" } else { "✗" }
        Update-Status "Complete: $passed passed, $failed failed, $missing missing" $icon
        $btnExport.IsEnabled = $true
        $btnViewDetails.IsEnabled = $true
    }
    catch {
        Show-MessageBox -Message "Error: $($_.Exception.Message)" -Title "Error" -Type "Error"
        Update-Status "❌ Error occurred" "❌"
    }
    finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        $btnVerify.IsEnabled = $true
    }
}

# Mode switching
$rbSingleFile.Add_Checked({
    $pnlSingleFile.Visibility = "Visible"
    $pnlBatchFile.Visibility = "Collapsed"
    Update-Status "Ready to verify single file" "ℹ️"
})

$rbBatchFile.Add_Checked({
    $pnlSingleFile.Visibility = "Collapsed"
    $pnlBatchFile.Visibility = "Visible"
    Update-Status "Ready to verify batch files" "ℹ️"
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
        
        # Auto-populate folder
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
            Show-MessageBox -Message "Please select a file to verify." -Title "No File Selected" -Type "Warning"
            return
        }
        Verify-SingleFile
    } else {
        if ([string]::IsNullOrWhiteSpace($txtChecksumFile.Text)) {
            Show-MessageBox -Message "Please select a checksum file." -Title "No Checksum File" -Type "Warning"
            return
        }
        if ([string]::IsNullOrWhiteSpace($txtBatchFolder.Text)) {
            Show-MessageBox -Message "Please select the folder containing files to verify." -Title "No Folder Selected" -Type "Warning"
            return
        }
        Verify-BatchFiles
    }
})

# View Details button
$btnViewDetails.Add_Click({
    $selected = $dgResults.SelectedItem
    if ($selected -eq $null -and $script:results.Count -gt 0) {
        $selected = $script:results[0]
    }
    
    if ($selected -ne $null) {
        $verifyMode = ($selected.FullExpectedHash -ne "" -and $selected.FullExpectedHash -ne "N/A")
        $isMatch = ($selected.Status -eq "✓ PASS")
        
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
    if ($selected -ne $null) {
        $verifyMode = ($selected.FullExpectedHash -ne "" -and $selected.FullExpectedHash -ne "N/A")
        $isMatch = ($selected.Status -eq "✓ PASS")
        
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
            Show-MessageBox -Message "Results exported successfully to:`n$($saveDialog.FileName)" -Title "Export Complete" -Type "Information"
            Update-Status "✓ Results exported successfully" "✓"
        }
        catch {
            Show-MessageBox -Message "Error exporting results: $($_.Exception.Message)" -Title "Export Error" -Type "Error"
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
    Update-Status "Ready to verify files" "ℹ️"
    $btnExport.IsEnabled = $false
    $btnViewDetails.IsEnabled = $false
    $rbSHA256.IsChecked = $true
})

# Show the window
$window.ShowDialog() | Out-Null