Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ============================================================================
# CHECKSUM VERIFIER v2 - Dark Theme Edition
# Verify file integrity via hash comparison
# v2: Dark theme, no emojis, PowerShell 5.1 compatible
# ============================================================================

# XAML Definition - Dark Theme matching SoftwareTrustVerifier_v4
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Checksum Verifier v2"
        Height="750"
        Width="950"
        WindowStartupLocation="CenterScreen"
        Background="#1a1a2e">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground" Value="White"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Background" Value="#0f0f1a"/>
            <Setter Property="Foreground" Value="#eaeaea"/>
            <Setter Property="BorderBrush" Value="#0f3460"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="CaretBrush" Value="#4da8da"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Foreground" Value="#a0a0a0"/>
            <Setter Property="Margin" Value="5,5,5,2"/>
        </Style>
        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="#eaeaea"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#eaeaea"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="10,12,5,5"/>
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

        <!-- Title Bar -->
        <Border Grid.Row="0"
                Background="#16213e"
                Padding="20,15"
                CornerRadius="10"
                Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="CHECKSUM VERIFIER"
                               FontSize="24"
                               FontWeight="Bold"
                               Foreground="#4da8da"/>
                    <TextBlock Text="Verify file integrity via hash comparison"
                               FontSize="12"
                               Foreground="#7f8c8d"
                               Margin="0,5,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Background="#2ECC71" CornerRadius="4" Padding="10,5" Margin="4,0">
                        <TextBlock Text="SHA256" Foreground="White" FontSize="10" FontWeight="Bold"/>
                    </Border>
                    <Border Background="#3498DB" CornerRadius="4" Padding="10,5" Margin="4,0">
                        <TextBlock Text="SHA512" Foreground="White" FontSize="10" FontWeight="Bold"/>
                    </Border>
                    <Border Background="#F39C12" CornerRadius="4" Padding="10,5" Margin="4,0">
                        <TextBlock Text="SHA1" Foreground="White" FontSize="10" FontWeight="Bold"/>
                    </Border>
                    <Border Background="#7F8C8D" CornerRadius="4" Padding="10,5" Margin="4,0">
                        <TextBlock Text="MD5" Foreground="White" FontSize="10" FontWeight="Bold"/>
                    </Border>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Mode Selection -->
        <Border Grid.Row="1"
                Background="#16213e"
                BorderBrush="#4da8da"
                BorderThickness="2"
                CornerRadius="10"
                Padding="18"
                Margin="0,0,0,12">
            <StackPanel>
                <TextBlock Text="Verification Mode" FontWeight="Bold" FontSize="14" Margin="0,0,0,10" Foreground="#eaeaea"/>
                <StackPanel Orientation="Horizontal">
                    <RadioButton Name="rbSingleFile"
                                Content="Single File Verification"
                                IsChecked="True"
                                FontWeight="SemiBold"/>
                    <RadioButton Name="rbBatchFile"
                                Content="Batch Verification (from checksum file)"
                                Margin="25,5,5,5"
                                FontWeight="SemiBold"/>
                </StackPanel>
            </StackPanel>
        </Border>

        <!-- Single File Mode Panel -->
        <Border Name="pnlSingleFile"
                Grid.Row="2"
                Background="#16213e"
                BorderBrush="#9b59b6"
                BorderThickness="2"
                CornerRadius="10"
                Padding="18"
                Margin="0,0,0,12">
            <StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                    <Border Background="#9b59b6" CornerRadius="15" Width="30" Height="30" Margin="0,0,12,0">
                        <TextBlock Text="1" Foreground="White" FontWeight="Bold" FontSize="14"
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Select file and algorithm"
                               FontSize="15" FontWeight="SemiBold" VerticalAlignment="Center" Foreground="#eaeaea"/>
                </StackPanel>

                <Label Content="File to verify:" FontSize="13"/>
                <Grid Margin="0,0,0,5">
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
                            Width="110"
                            Background="#9b59b6"/>
                </Grid>

                <Label Content="Hash Algorithm:" Margin="5,8,5,2" FontSize="13"/>
                <StackPanel Orientation="Horizontal" Margin="8,4,5,8">
                    <RadioButton Name="rbSHA256" Content="SHA256 (Recommended)"
                                IsChecked="True"
                                FontWeight="SemiBold"/>
                    <RadioButton Name="rbSHA1" Content="SHA1"
                                Margin="20,5,5,5"/>
                    <RadioButton Name="rbMD5" Content="MD5"
                                Margin="20,5,5,5"/>
                    <RadioButton Name="rbSHA512" Content="SHA512"
                                Margin="20,5,5,5"/>
                </StackPanel>

                <Label Content="Expected Hash (optional - leave blank to just calculate):" Margin="5,4,5,2" FontSize="13"/>
                <TextBox Name="txtExpectedHash"
                         TextWrapping="Wrap"
                         Height="55"
                         VerticalScrollBarVisibility="Auto"
                         FontFamily="Consolas"
                         FontSize="11"
                         ToolTip="Paste the expected hash here from the software publisher"/>
            </StackPanel>
        </Border>

        <!-- Batch File Mode Panel -->
        <Border Name="pnlBatchFile"
                Grid.Row="2"
                Background="#16213e"
                BorderBrush="#e94560"
                BorderThickness="2"
                CornerRadius="10"
                Padding="18"
                Margin="0,0,0,12"
                Visibility="Collapsed">
            <StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                    <Border Background="#e94560" CornerRadius="15" Width="30" Height="30" Margin="0,0,12,0">
                        <TextBlock Text="1" Foreground="White" FontWeight="Bold" FontSize="14"
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Select checksum file and target folder"
                               FontSize="15" FontWeight="SemiBold" VerticalAlignment="Center" Foreground="#eaeaea"/>
                </StackPanel>

                <Label Content="Checksum file (SHA256SUMS, checksums.txt, etc.):" FontSize="13"/>
                <Grid Margin="0,0,0,5">
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
                            Width="110"
                            Background="#e94560"/>
                </Grid>

                <Label Content="Folder containing files to verify:" Margin="5,8,5,2" FontSize="13"/>
                <Grid Margin="0,0,0,5">
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
                            Width="110"
                            Background="#e94560"/>
                </Grid>

                <CheckBox Name="chkAutoDetect"
                         Content="Auto-detect hash algorithm from checksum file"
                         IsChecked="True"
                         FontWeight="SemiBold"/>
            </StackPanel>
        </Border>

        <!-- Results Area -->
        <Border Grid.Row="3"
                Background="#16213e"
                BorderBrush="#0f3460"
                BorderThickness="2"
                CornerRadius="10"
                Padding="12"
                Margin="0,0,0,12">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Text="VERIFICATION RESULTS"
                           FontWeight="Bold" FontSize="14" Foreground="#4da8da" Margin="5,0,0,12"/>

                <DataGrid Name="dgResults"
                         Grid.Row="1"
                         AutoGenerateColumns="False"
                         IsReadOnly="True"
                         SelectionMode="Single"
                         GridLinesVisibility="Horizontal"
                         HeadersVisibility="Column"
                         RowHeight="32"
                         CanUserResizeRows="False"
                         BorderThickness="0"
                         Background="#0f0f1a"
                         Foreground="#eaeaea"
                         RowBackground="#0f0f1a"
                         AlternatingRowBackground="#16213e">
                    <DataGrid.Resources>
                        <Style TargetType="DataGridColumnHeader">
                            <Setter Property="Background" Value="#0f3460"/>
                            <Setter Property="Foreground" Value="White"/>
                            <Setter Property="FontWeight" Value="Bold"/>
                            <Setter Property="Padding" Value="8,6"/>
                            <Setter Property="BorderThickness" Value="0,0,1,0"/>
                            <Setter Property="BorderBrush" Value="#1a1a2e"/>
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
                                    <Setter Property="Foreground" Value="#a0a0a0"/>
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
                                            <Setter Property="Foreground" Value="#4da8da"/>
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
                                    <Setter Property="Foreground" Value="#eaeaea"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                        <DataGridTextColumn Header="Algorithm" Binding="{Binding Algorithm}" Width="90">
                            <DataGridTextColumn.ElementStyle>
                                <Style TargetType="TextBlock">
                                    <Setter Property="HorizontalAlignment" Value="Center"/>
                                    <Setter Property="VerticalAlignment" Value="Center"/>
                                    <Setter Property="FontWeight" Value="SemiBold"/>
                                    <Setter Property="Foreground" Value="#eaeaea"/>
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
                                    <Setter Property="Foreground" Value="#a0a0a0"/>
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
                                    <Setter Property="Foreground" Value="#a0a0a0"/>
                                </Style>
                            </DataGridTextColumn.ElementStyle>
                        </DataGridTextColumn>
                    </DataGrid.Columns>
                </DataGrid>
            </Grid>
        </Border>

        <!-- Status and Action Bar -->
        <Border Grid.Row="4"
                Background="#16213e"
                Padding="15"
                CornerRadius="10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <TextBlock Name="txtStatus"
                          Grid.Column="0"
                          Text="Ready to verify files"
                          VerticalAlignment="Center"
                          FontSize="14"
                          FontWeight="SemiBold"
                          Foreground="#a0a0a0"/>

                <StackPanel Grid.Column="1" Orientation="Horizontal">
                    <Button Name="btnVerify"
                            Content="VERIFY"
                            Width="130"
                            Height="42"
                            Background="#2ECC71"
                            FontSize="13"/>
                    <Button Name="btnViewDetails"
                            Content="VIEW DETAILS"
                            Width="130"
                            Height="42"
                            Background="#9b59b6"
                            FontSize="12"
                            IsEnabled="False"/>
                    <Button Name="btnExport"
                            Content="EXPORT RESULTS"
                            Width="140"
                            Height="42"
                            Background="#4da8da"
                            FontSize="12"
                            IsEnabled="False"/>
                    <Button Name="btnClear"
                            Content="CLEAR"
                            Width="90"
                            Height="42"
                            Background="#7F8C8D"
                            FontSize="12"/>
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
        Height="500"
        Width="650"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize"
        Background="#1a1a2e">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0"
                Background="#16213e"
                Padding="15,12"
                CornerRadius="10"
                Margin="0,0,0,15">
            <StackPanel>
                <TextBlock Name="txtResultTitle"
                           FontSize="20"
                           FontWeight="Bold"
                           HorizontalAlignment="Center"
                           Foreground="#4da8da"
                           Margin="0,0,0,8"/>
                <TextBlock Name="txtFileName"
                           FontSize="12"
                           TextWrapping="Wrap"
                           HorizontalAlignment="Center"
                           Foreground="#a0a0a0"/>
            </StackPanel>
        </Border>

        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel Margin="5">
                <Border Background="#16213e"
                        BorderBrush="#0f3460"
                        BorderThickness="1"
                        CornerRadius="8"
                        Padding="12"
                        Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="Algorithm:" FontWeight="Bold" FontSize="13" Margin="0,0,0,5" Foreground="#a0a0a0"/>
                        <TextBox Name="txtAlgorithm"
                                IsReadOnly="True"
                                Background="#0f0f1a"
                                Foreground="#eaeaea"
                                BorderThickness="0"
                                FontFamily="Consolas"
                                FontSize="13"/>
                    </StackPanel>
                </Border>

                <Border Background="#16213e"
                        BorderBrush="#0f3460"
                        BorderThickness="1"
                        CornerRadius="8"
                        Padding="12"
                        Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="Calculated Hash:" FontWeight="Bold" FontSize="13" Margin="0,0,0,5" Foreground="#a0a0a0"/>
                        <TextBox Name="txtActualHash"
                                 IsReadOnly="True"
                                 TextWrapping="Wrap"
                                 Background="#0f0f1a"
                                 Foreground="#eaeaea"
                                 BorderThickness="0"
                                 FontFamily="Consolas"
                                 FontSize="11"
                                 Height="70"
                                 VerticalScrollBarVisibility="Auto"/>
                    </StackPanel>
                </Border>

                <Border Name="pnlExpected" Visibility="Collapsed"
                        Background="#16213e"
                        BorderBrush="#0f3460"
                        BorderThickness="1"
                        CornerRadius="8"
                        Padding="12"
                        Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="Expected Hash:" FontWeight="Bold" FontSize="13" Margin="0,0,0,5" Foreground="#a0a0a0"/>
                        <TextBox Name="txtExpectedHashResult"
                                 IsReadOnly="True"
                                 TextWrapping="Wrap"
                                 Background="#0f0f1a"
                                 Foreground="#eaeaea"
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
                    <TextBlock Name="txtVerifyResult"
                               FontSize="15"
                               FontWeight="Bold"
                               TextWrapping="Wrap"
                               HorizontalAlignment="Center"
                               TextAlignment="Center"
                               LineHeight="22"/>
                </Border>
            </StackPanel>
        </ScrollViewer>

        <Border Grid.Row="2"
                Background="#16213e"
                Padding="10"
                CornerRadius="8"
                Margin="0,10,0,0">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                <Button Name="btnCopyHash"
                        Content="COPY HASH"
                        Width="140"
                        Height="36"
                        Margin="5"
                        Background="#4da8da"
                        Foreground="White"
                        FontWeight="SemiBold"
                        BorderThickness="0"
                        Cursor="Hand"/>
                <Button Name="btnClose"
                        Content="CLOSE"
                        Width="140"
                        Height="36"
                        Margin="5"
                        Background="#7F8C8D"
                        Foreground="White"
                        FontWeight="SemiBold"
                        BorderThickness="0"
                        Cursor="Hand"/>
            </StackPanel>
        </Border>
    </Grid>
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
        $txtResultTitle.Foreground = "#4da8da"
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
    $txtStatus.Foreground = "#a0a0a0"
})

$rbBatchFile.Add_Checked({
    $pnlSingleFile.Visibility = "Collapsed"
    $pnlBatchFile.Visibility = "Visible"
    Update-Status "Ready to verify batch files"
    $txtStatus.Foreground = "#a0a0a0"
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
    $txtStatus.Foreground = "#a0a0a0"
    $btnExport.IsEnabled = $false
    $btnViewDetails.IsEnabled = $false
    $rbSHA256.IsChecked = $true
})

# Show the window
$window.ShowDialog() | Out-Null

# SIG # Begin signature block
# MIIFvAYJKoZIhvcNAQcCoIIFrTCCBakCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD60YmXRfEYH1DS
# wpovMuv55QVcNjaLyCJg7gs9A1OCi6CCAyQwggMgMIICCKADAgECAhAet+EmJNzQ
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
# KoZIhvcNAQkEMSIEIBM4zmf4wfxiZdSw6I3U4ec3JssEuJPSNG/Qt+CerOadMA0G
# CSqGSIb3DQEBAQUABIIBAGxX0BVq6R7gfcOVhqqjbLZm5por8/a5L8Tgpmi/oh2n
# HdUdoFAJ4Y6vqzkiMIb5vCrGCMJW2m97I/L8lWXoDTaoAT9pvZYO6jjciO2Xdskh
# +0yVVd+ZD1wrxV3AUHxkX6cC+aX06fixw7N9V9YvPpPk4PRRt7kcRADeXeTHnr+e
# 1pWMIsCm4rGoXFiBq2WZgocswik/w4Hhf+rzctoryyNDqlj0XfF7VoIEX73tD0bh
# 6jLOFJWITy/EGGW/U7FgioYC++u3pXXZSCmlUGAwO+Vb4xBM+Cm4N8KIffFhC1L5
# /G7YLGbTOfQ019zILJxfml6lZtKW2PKopM6aQKuAeSw=
# SIG # End signature block
