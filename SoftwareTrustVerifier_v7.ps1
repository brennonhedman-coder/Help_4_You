Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ============================================================================
# SOFTWARE TRUST VERIFIER - Help Desk Edition v7
# v5: Compact layout for laptop screens + ScrollViewer fallback
# v6: refers to newer checksum app but headers still read: v5
# ============================================================================

# Configuration
$script:DatabasePath = Join-Path $PSScriptRoot "TrustedSoftware.json"
$script:Database = $null
$script:CurrentSoftware = $null
$script:SignatureResult = $null
$script:IsUnknownSoftware = $false
$script:UnknownSoftwareName = ""

# Load the trusted software database
function Load-Database {
    if (-not (Test-Path $script:DatabasePath)) {
        throw "Trusted software database not found at: $script:DatabasePath"
    }
    $script:Database = Get-Content $script:DatabasePath -Raw | ConvertFrom-Json
}

# Calculate Levenshtein distance for typo tolerance
function Get-LevenshteinDistance {
    param(
        [string]$Source,
        [string]$Target
    )

    $n = $Source.Length
    $m = $Target.Length

    if ($n -eq 0) { return $m }
    if ($m -eq 0) { return $n }

    # Use jagged array instead of 2D array for PowerShell compatibility
    $d = @()
    for ($i = 0; $i -le $n; $i++) {
        $d += ,(@(0) * ($m + 1))
    }

    for ($i = 0; $i -le $n; $i++) { $d[$i][0] = $i }
    for ($j = 0; $j -le $m; $j++) { $d[0][$j] = $j }

    for ($i = 1; $i -le $n; $i++) {
        for ($j = 1; $j -le $m; $j++) {
            if ($Source[$i - 1] -eq $Target[$j - 1]) {
                $cost = 0
            } else {
                $cost = 1
            }

            $deletion = $d[$i - 1][$j] + 1
            $insertion = $d[$i][$j - 1] + 1
            $substitution = $d[$i - 1][$j - 1] + $cost

            $d[$i][$j] = [Math]::Min([Math]::Min($deletion, $insertion), $substitution)
        }
    }

    return $d[$n][$m]
}

# Calculate similarity ratio (0-100)
function Get-SimilarityScore {
    param(
        [string]$Source,
        [string]$Target
    )

    $source = $Source.ToLower().Trim()
    $target = $Target.ToLower().Trim()

    if ($source -eq $target) { return 100 }

    $maxLen = [Math]::Max($source.Length, $target.Length)
    if ($maxLen -eq 0) { return 0 }

    $distance = Get-LevenshteinDistance -Source $source -Target $target
    $similarity = [Math]::Round((1 - ($distance / $maxLen)) * 100)

    return [Math]::Max(0, $similarity)
}

# Improved fuzzy match software name against database
function Find-Software {
    param([string]$SearchTerm)

    $searchLower = $SearchTerm.ToLower().Trim()
    $results = @()

    foreach ($software in $script:Database.software) {
        $bestScore = 0
        $matchedName = ""

        foreach ($name in $software.names) {
            $nameLower = $name.ToLower()
            $score = 0

            # Exact match
            if ($nameLower -eq $searchLower) {
                $score = 100
            }
            # Search term starts with name or vice versa (for abbreviations)
            elseif ($searchLower.StartsWith($nameLower) -or $nameLower.StartsWith($searchLower)) {
                if ($searchLower.Length -lt $nameLower.Length) {
                    $shorter = $searchLower
                } else {
                    $shorter = $nameLower
                }
                if ($shorter.Length -ge 3) {
                    $score = 85
                }
            }
            # Use Levenshtein for typo tolerance
            else {
                $similarity = Get-SimilarityScore -Source $searchLower -Target $nameLower

                # Require at least 70% similarity for short terms, 60% for longer terms
                if ($searchLower.Length -le 5) {
                    $threshold = 70
                } else {
                    $threshold = 60
                }

                if ($similarity -ge $threshold) {
                    $score = $similarity
                }
            }

            if ($score -gt $bestScore) {
                $bestScore = $score
                $matchedName = $name
            }
        }

        # Only include results with score >= 50
        if ($bestScore -ge 50) {
            $publisher = $script:Database.publishers.($software.publisher)
            $results += [PSCustomObject]@{
                Score = $bestScore
                Software = $software
                MatchedName = $matchedName
                Publisher = $publisher
            }
        }
    }

    return $results | Sort-Object -Property Score -Descending | Select-Object -First 5
}

# Extract domain from URL
function Get-UrlDomain {
    param([string]$Url)

    try {
        $uri = [System.Uri]::new($Url)
        $domain = $uri.Host.ToLower()
        if ($domain.StartsWith("www.")) {
            $domain = $domain.Substring(4)
        }
        return $domain
    }
    catch {
        return $null
    }
}

# Validate URL against known official domains
function Test-OfficialUrl {
    param(
        [string]$Url,
        [object]$Software
    )

    try {
        $uri = [System.Uri]::new($Url)
        $domain = $uri.Host.ToLower()

        if ($domain.StartsWith("www.")) {
            $domain = $domain.Substring(4)
        }

        foreach ($officialDomain in $Software.officialDomains) {
            $official = $officialDomain.ToLower()
            if ($official.StartsWith("www.")) {
                $official = $official.Substring(4)
            }

            if ($domain -eq $official -or $domain.EndsWith(".$official")) {
                return @{
                    IsOfficial = $true
                    Message = "URL matches official domain: $officialDomain"
                    MatchedDomain = $officialDomain
                    Domain = $domain
                }
            }
        }

        return @{
            IsOfficial = $false
            Message = "URL domain '$domain' does not match any official sources"
            ExpectedDomains = $Software.officialDomains -join ", "
            Domain = $domain
        }
    }
    catch {
        return @{
            IsOfficial = $false
            Message = "Invalid URL format: $($_.Exception.Message)"
            ExpectedDomains = ""
            Domain = ""
        }
    }
}

# Check digital signature of a file
function Get-FileSignature {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        return @{
            IsSigned = $false
            IsValid = $false
            Status = "FileNotFound"
            Message = "File not found"
            Signer = ""
            Issuer = ""
        }
    }

    try {
        $sig = Get-AuthenticodeSignature -FilePath $FilePath

        $result = @{
            IsSigned = $sig.Status -ne "NotSigned"
            IsValid = $sig.Status -eq "Valid"
            Status = $sig.Status.ToString()
            StatusMessage = $sig.StatusMessage
            Signer = ""
            Issuer = ""
            Thumbprint = ""
            TimeStamped = $false
        }

        if ($sig.SignerCertificate) {
            $result.Signer = $sig.SignerCertificate.Subject
            $result.Issuer = $sig.SignerCertificate.Issuer
            $result.Thumbprint = $sig.SignerCertificate.Thumbprint

            if ($sig.SignerCertificate.Subject -match 'CN=([^,]+)') {
                $result.SignerName = $matches[1].Trim('"')
            }
        }

        if ($sig.TimeStamperCertificate) {
            $result.TimeStamped = $true
        }

        return $result
    }
    catch {
        return @{
            IsSigned = $false
            IsValid = $false
            Status = "Error"
            Message = $_.Exception.Message
            Signer = ""
            Issuer = ""
        }
    }
}

# Verify signer matches expected publisher
function Test-SignerMatch {
    param(
        [object]$SignatureResult,
        [object]$Publisher
    )

    if (-not $SignatureResult.IsSigned) {
        return @{
            Matches = $false
            Message = "File is not signed"
        }
    }

    $signerName = $SignatureResult.SignerName
    if (-not $signerName) { $signerName = $SignatureResult.Signer }

    foreach ($expectedName in $Publisher.signingNames) {
        if ($signerName -like "*$expectedName*") {
            return @{
                Matches = $true
                Message = "Signer '$signerName' matches expected publisher"
                ExpectedName = $expectedName
            }
        }
    }

    return @{
        Matches = $false
        Message = "Signer '$signerName' does not match expected publisher"
        ExpectedNames = $Publisher.signingNames -join ", "
    }
}

# Get tier color (dark theme)
function Get-TierColor {
    param([string]$Tier)

    switch ($Tier) {
        "trusted" { return "#2ECC71" }
        "verified" { return "#3498DB" }
        "community" { return "#F39C12" }
        "caution" { return "#E74C3C" }
        "unknown" { return "#7F8C8D" }
        default { return "#7F8C8D" }
    }
}

# Get tier icon
function Get-TierIcon {
    param([string]$Tier)

    switch ($Tier) {
        "trusted" { return "[TRUSTED]" }
        "verified" { return "[VERIFIED]" }
        "community" { return "[COMMUNITY]" }
        "caution" { return "[CAUTION]" }
        "unknown" { return "[UNKNOWN]" }
        default { return "[UNKNOWN]" }
    }
}

# ============================================================================
# XAML UI DEFINITION - DARK THEME (COMPACT FOR LAPTOPS)
# ============================================================================

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Software Trust Verifier v7"
        Height="700"
        MinHeight="500"
        Width="1020"
        MinWidth="800"
        WindowStartupLocation="CenterScreen"
        Background="#1a1a2e">
    <Window.Resources>
        <SolidColorBrush x:Key="DarkBgBrush" Color="#1a1a2e"/>
        <SolidColorBrush x:Key="CardBgBrush" Color="#16213e"/>
        <SolidColorBrush x:Key="CardBorderBrush" Color="#0f3460"/>
        <SolidColorBrush x:Key="InputBgBrush" Color="#0f0f1a"/>
        <SolidColorBrush x:Key="TextPrimaryBrush" Color="#eaeaea"/>
        <SolidColorBrush x:Key="TextSecondaryBrush" Color="#a0a0a0"/>

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
            <Setter Property="Background" Value="#0f0f1a"/>
            <Setter Property="Foreground" Value="#eaeaea"/>
            <Setter Property="BorderBrush" Value="#0f3460"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="CaretBrush" Value="#4da8da"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Foreground" Value="#a0a0a0"/>
            <Setter Property="Margin" Value="4,4,4,1"/>
        </Style>
    </Window.Resources>

    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Title Bar -->
        <Border Grid.Row="0"
                Background="#16213e"
                Padding="15,10"
                CornerRadius="8"
                Margin="0,0,0,8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="SOFTWARE TRUST VERIFIER"
                               FontSize="20"
                               FontWeight="Bold"
                               Foreground="#4da8da"/>
                    <TextBlock Text="Verify software authenticity before installation"
                               FontSize="11"
                               Foreground="#7f8c8d"
                               Margin="0,3,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Background="#2ECC71" CornerRadius="4" Padding="8,4" Margin="3,0">
                        <TextBlock Text="TRUSTED" Foreground="White" FontSize="9" FontWeight="Bold"/>
                    </Border>
                    <Border Background="#3498DB" CornerRadius="4" Padding="8,4" Margin="3,0">
                        <TextBlock Text="VERIFIED" Foreground="White" FontSize="9" FontWeight="Bold"/>
                    </Border>
                    <Border Background="#F39C12" CornerRadius="4" Padding="8,4" Margin="3,0">
                        <TextBlock Text="COMMUNITY" Foreground="White" FontSize="9" FontWeight="Bold"/>
                    </Border>
                    <Border Background="#E74C3C" CornerRadius="4" Padding="8,4" Margin="3,0">
                        <TextBlock Text="CAUTION" Foreground="White" FontSize="9" FontWeight="Bold"/>
                    </Border>
                    <Border Background="#7F8C8D" CornerRadius="4" Padding="8,4" Margin="3,0">
                        <TextBlock Text="UNKNOWN" Foreground="White" FontSize="9" FontWeight="Bold"/>
                    </Border>
                </StackPanel>
            </Grid>
        </Border>

        <!-- STEP 1: Software Search -->
        <Border Grid.Row="1"
                Background="#16213e"
                BorderBrush="#4da8da"
                BorderThickness="2"
                CornerRadius="8"
                Padding="12"
                Margin="0,0,0,8">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,8">
                    <Border Background="#4da8da" CornerRadius="13" Width="26" Height="26" Margin="0,0,10,0">
                        <TextBlock Text="1" Foreground="White" FontWeight="Bold" FontSize="13"
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="What software does the customer want to install?"
                               FontSize="14" FontWeight="SemiBold" VerticalAlignment="Center" Foreground="#eaeaea"/>
                </StackPanel>

                <Grid Grid.Row="1">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtSoftwareSearch"
                             Grid.Column="0"
                             FontSize="13"
                             ToolTip="Type the software name (e.g., 'chrome', 'vlc', '7zip')"/>
                    <Button Name="btnSearch"
                            Grid.Column="1"
                            Content="SEARCH"
                            Width="100"
                            Background="#4da8da"
                            FontSize="12"/>
                </Grid>

                <!-- Search Results -->
                <Border Name="pnlSearchResults" Grid.Row="2" Visibility="Collapsed"
                        Background="#0f0f1a" CornerRadius="6" Padding="10" Margin="0,8,0,0">
                    <StackPanel>
                        <TextBlock Text="Select the matching software:" FontWeight="SemiBold" Margin="0,0,0,8" Foreground="#a0a0a0"/>
                        <ListBox Name="lstSearchResults"
                                 BorderThickness="0"
                                 Background="Transparent"
                                 MaxHeight="120">
                            <ListBox.ItemTemplate>
                                <DataTemplate>
                                    <Border Padding="10,8" Margin="2" Background="#16213e" CornerRadius="5"
                                            BorderBrush="#0f3460" BorderThickness="1" Cursor="Hand">
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <StackPanel Grid.Column="0">
                                                <TextBlock Text="{Binding DisplayName}" FontWeight="SemiBold" FontSize="13" Foreground="#eaeaea"/>
                                                <TextBlock Text="{Binding PublisherName}" Foreground="#7f8c8d" FontSize="10" Margin="0,2,0,0"/>
                                            </StackPanel>
                                            <Border Grid.Column="1" CornerRadius="4" Padding="8,3" VerticalAlignment="Center"
                                                    Background="{Binding TierColor}">
                                                <TextBlock Text="{Binding TierLabel}" Foreground="White" FontSize="9" FontWeight="Bold"/>
                                            </Border>
                                        </Grid>
                                    </Border>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>

                        <!-- No Results -->
                        <Border Name="pnlNoResults" Visibility="Collapsed"
                                Background="#2c1810" CornerRadius="6" Padding="12" Margin="0,8,0,0"
                                BorderBrush="#E74C3C" BorderThickness="2">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0">
                                    <TextBlock Text="SOFTWARE NOT FOUND IN DATABASE" FontWeight="Bold" FontSize="12" Foreground="#E74C3C"/>
                                    <TextBlock Name="txtUnknownSoftwareName" FontSize="11" Foreground="#a0a0a0" Margin="0,4,0,0"/>
                                    <TextBlock Text="You can still verify the URL and signature. Proceed with caution."
                                               FontSize="10" Foreground="#7f8c8d" Margin="0,4,0,0" TextWrapping="Wrap"/>
                                </StackPanel>
                                <Button Name="btnProceedUnknown"
                                        Grid.Column="1"
                                        Content="PROCEED ANYWAY"
                                        Background="#E74C3C"
                                        VerticalAlignment="Center"
                                        Width="130"/>
                            </Grid>
                        </Border>
                    </StackPanel>
                </Border>

                <!-- Selected Software (Known) -->
                <Border Name="pnlSelectedSoftware" Grid.Row="2" Visibility="Collapsed"
                        Background="#0a2a1a" CornerRadius="6" Padding="12" Margin="0,8,0,0"
                        BorderBrush="#2ECC71" BorderThickness="2">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0">
                            <StackPanel Orientation="Horizontal">
                                <TextBlock Name="txtSelectedName" FontSize="15" FontWeight="Bold" Foreground="#eaeaea"/>
                                <Border Name="bdrSelectedTier" CornerRadius="4" Padding="8,3" Margin="10,0,0,0" VerticalAlignment="Center">
                                    <TextBlock Name="txtSelectedTier" Foreground="White" FontSize="9" FontWeight="Bold"/>
                                </Border>
                            </StackPanel>
                            <TextBlock Name="txtSelectedPublisher" Foreground="#7f8c8d" FontSize="11" Margin="0,4,0,0"/>
                            <StackPanel Name="pnlOfficialDomains" Orientation="Horizontal" Margin="0,4,0,0">
                                <TextBlock Text="Official domains: " FontWeight="SemiBold" FontSize="10" Foreground="#a0a0a0"/>
                                <TextBlock Name="txtSelectedDomains" FontSize="10" Foreground="#4da8da"/>
                            </StackPanel>
                            <TextBlock Name="txtSelectedNotes" FontSize="10" Foreground="#F39C12" FontStyle="Italic"
                                       Margin="0,4,0,0" TextWrapping="Wrap" Visibility="Collapsed"/>
                        </StackPanel>
                        <Button Name="btnClearSelection" Grid.Column="1" Content="X" Width="30" Height="30"
                                Background="#E74C3C" FontWeight="Bold" VerticalAlignment="Top" FontSize="12"/>
                    </Grid>
                </Border>

                <!-- Selected Software (Unknown) -->
                <Border Name="pnlSelectedUnknown" Grid.Row="2" Visibility="Collapsed"
                        Background="#2c1810" CornerRadius="6" Padding="12" Margin="0,8,0,0"
                        BorderBrush="#F39C12" BorderThickness="2">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0">
                            <StackPanel Orientation="Horizontal">
                                <TextBlock Name="txtSelectedUnknownName" FontSize="15" FontWeight="Bold" Foreground="#eaeaea"/>
                                <Border Background="#7F8C8D" CornerRadius="4" Padding="8,3" Margin="10,0,0,0" VerticalAlignment="Center">
                                    <TextBlock Text="UNKNOWN" Foreground="White" FontSize="9" FontWeight="Bold"/>
                                </Border>
                            </StackPanel>
                            <TextBlock Text="This software is NOT in our trusted database" Foreground="#E74C3C" FontSize="11" FontWeight="SemiBold" Margin="0,4,0,0"/>
                            <TextBlock Text="URL verification will show the domain but cannot confirm if official. Signature check is still available."
                                       FontSize="10" Foreground="#7f8c8d" Margin="0,4,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                        <Button Name="btnClearUnknown" Grid.Column="1" Content="X" Width="30" Height="30"
                                Background="#E74C3C" FontWeight="Bold" VerticalAlignment="Top" FontSize="12"/>
                    </Grid>
                </Border>
            </Grid>
        </Border>

        <!-- STEP 2: URL Verification -->
        <Border Grid.Row="2"
                Background="#16213e"
                BorderBrush="#9b59b6"
                BorderThickness="2"
                CornerRadius="8"
                Padding="12"
                Margin="0,0,0,8">
            <StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                    <Border Background="#9b59b6" CornerRadius="13" Width="26" Height="26" Margin="0,0,10,0">
                        <TextBlock Text="2" Foreground="White" FontWeight="Bold" FontSize="13"
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="What URL is the customer downloading from?"
                               FontSize="14" FontWeight="SemiBold" VerticalAlignment="Center" Foreground="#eaeaea"/>
                </StackPanel>

                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtDownloadUrl"
                             Grid.Column="0"
                             FontSize="12"
                             ToolTip="Paste the download URL here"/>
                    <Button Name="btnVerifyUrl"
                            Grid.Column="1"
                            Content="VERIFY URL"
                            Width="110"
                            Background="#9b59b6"
                            FontSize="12"/>
                </Grid>

                <!-- URL Result -->
                <Border Name="pnlUrlResult" Visibility="Collapsed"
                        CornerRadius="6" Padding="12" Margin="0,8,0,0">
                    <StackPanel>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Name="txtUrlIcon" FontSize="16" Margin="0,0,8,0" FontWeight="Bold"/>
                            <TextBlock Name="txtUrlResult" FontWeight="SemiBold" FontSize="13" TextWrapping="Wrap" VerticalAlignment="Center"/>
                        </StackPanel>
                        <TextBlock Name="txtUrlDetails" FontSize="10" Foreground="#7f8c8d" Margin="24,4,0,0" TextWrapping="Wrap"/>
                        <Button Name="btnOpenOfficial" Content="OPEN OFFICIAL DOWNLOAD PAGE"
                                Background="#4da8da" FontSize="10"
                                HorizontalAlignment="Left" Margin="0,8,0,0" Visibility="Collapsed"/>
                    </StackPanel>
                </Border>
            </StackPanel>
        </Border>

        <!-- STEP 3: File Signature Check -->
        <Border Grid.Row="3"
                Background="#16213e"
                BorderBrush="#e94560"
                BorderThickness="2"
                CornerRadius="8"
                Padding="12"
                Margin="0,0,0,8">
            <StackPanel>
                <StackPanel Orientation="Horizontal" Margin="0,0,0,8">
                    <Border Background="#e94560" CornerRadius="13" Width="26" Height="26" Margin="0,0,10,0">
                        <TextBlock Text="3" Foreground="White" FontWeight="Bold" FontSize="13"
                                   HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Check the downloaded file's digital signature"
                               FontSize="14" FontWeight="SemiBold" VerticalAlignment="Center" Foreground="#eaeaea"/>
                </StackPanel>

                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtFilePath"
                             Grid.Column="0"
                             IsReadOnly="True"
                             AllowDrop="True"
                             FontSize="12"
                             ToolTip="Browse or drag and drop the downloaded file"/>
                    <Button Name="btnBrowseFile"
                            Grid.Column="1"
                            Content="BROWSE"
                            Width="90"
                            Background="#e94560"
                            FontSize="12"/>
                    <Button Name="btnCheckSignature"
                            Grid.Column="2"
                            Content="CHECK SIGNATURE"
                            Width="140"
                            Background="#2ECC71"
                            FontSize="12"/>
                </Grid>

                <!-- Signature Result -->
                <Border Name="pnlSignatureResult" Visibility="Collapsed"
                        CornerRadius="6" Padding="12" Margin="0,8,0,0">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0">
                            <StackPanel Orientation="Horizontal">
                                <TextBlock Name="txtSigIcon" FontSize="16" Margin="0,0,8,0" FontWeight="Bold"/>
                                <TextBlock Name="txtSigStatus" FontWeight="Bold" FontSize="13"/>
                            </StackPanel>
                            <TextBlock Name="txtSigSigner" FontSize="10" Margin="24,4,0,0" TextWrapping="Wrap" Foreground="#a0a0a0"/>
                        </StackPanel>
                        <StackPanel Grid.Column="1">
                            <TextBlock Name="txtSigMatch" FontWeight="SemiBold" FontSize="11" TextWrapping="Wrap"/>
                            <TextBlock Name="txtSigMatchDetails" FontSize="10" Foreground="#7f8c8d" Margin="0,4,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Grid>
                </Border>
            </StackPanel>
        </Border>

        <!-- Results Summary -->
        <Border Grid.Row="4"
                Background="#16213e"
                BorderBrush="#0f3460"
                BorderThickness="2"
                CornerRadius="8"
                Padding="12"
                Margin="0,0,0,8">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Text="VERIFICATION SUMMARY"
                           FontSize="14" FontWeight="Bold" Foreground="#4da8da" Margin="0,0,0,10"/>

                <Grid Grid.Row="1">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <Border Grid.Column="0" Margin="4" Padding="12" CornerRadius="8" Name="bdrSummaryPublisher" Background="#0f0f1a">
                        <StackPanel HorizontalAlignment="Center">
                            <TextBlock Name="txtSummaryPublisherIcon" Text="O" FontSize="26" HorizontalAlignment="Center" Foreground="#7F8C8D" FontWeight="Bold"/>
                            <TextBlock Text="PUBLISHER" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,6,0,0" Foreground="#a0a0a0" FontSize="10"/>
                            <TextBlock Name="txtSummaryPublisher" Text="Not checked" FontSize="9" HorizontalAlignment="Center"
                                       Foreground="#7f8c8d" TextAlignment="Center" Margin="0,4,0,0"/>
                        </StackPanel>
                    </Border>

                    <Border Grid.Column="1" Margin="4" Padding="12" CornerRadius="8" Name="bdrSummaryUrl" Background="#0f0f1a">
                        <StackPanel HorizontalAlignment="Center">
                            <TextBlock Name="txtSummaryUrlIcon" Text="O" FontSize="26" HorizontalAlignment="Center" Foreground="#7F8C8D" FontWeight="Bold"/>
                            <TextBlock Text="URL" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,6,0,0" Foreground="#a0a0a0" FontSize="10"/>
                            <TextBlock Name="txtSummaryUrl" Text="Not checked" FontSize="9" HorizontalAlignment="Center"
                                       Foreground="#7f8c8d" TextAlignment="Center" Margin="0,4,0,0"/>
                        </StackPanel>
                    </Border>

                    <Border Grid.Column="2" Margin="4" Padding="12" CornerRadius="8" Name="bdrSummarySignature" Background="#0f0f1a">
                        <StackPanel HorizontalAlignment="Center">
                            <TextBlock Name="txtSummarySignatureIcon" Text="O" FontSize="26" HorizontalAlignment="Center" Foreground="#7F8C8D" FontWeight="Bold"/>
                            <TextBlock Text="SIGNATURE" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,6,0,0" Foreground="#a0a0a0" FontSize="10"/>
                            <TextBlock Name="txtSummarySignature" Text="Not checked" FontSize="9" HorizontalAlignment="Center"
                                       Foreground="#7f8c8d" TextAlignment="Center" Margin="0,4,0,0"/>
                        </StackPanel>
                    </Border>

                    <Border Grid.Column="3" Margin="4" Padding="12" CornerRadius="8" Name="bdrSummaryChecksum" Background="#0f0f1a">
                        <StackPanel HorizontalAlignment="Center">
                            <TextBlock Name="txtSummaryChecksumIcon" Text="O" FontSize="26" HorizontalAlignment="Center" Foreground="#7F8C8D" FontWeight="Bold"/>
                            <TextBlock Text="CHECKSUM" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,6,0,0" Foreground="#a0a0a0" FontSize="10"/>
                            <TextBlock Name="txtSummaryChecksum" Text="Not checked" FontSize="9" HorizontalAlignment="Center"
                                       Foreground="#7f8c8d" TextAlignment="Center" Margin="0,4,0,0"/>
                        </StackPanel>
                    </Border>
                </Grid>
            </Grid>
        </Border>

        <!-- Action Buttons -->
        <Border Grid.Row="5"
                Background="#16213e"
                Padding="12"
                CornerRadius="8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Name="txtOverallStatus"
                               Text="Complete the verification steps above"
                               FontSize="13"
                               FontWeight="SemiBold"
                               Foreground="#a0a0a0"
                               VerticalAlignment="Center"/>
                </StackPanel>

                <StackPanel Grid.Column="1" Orientation="Horizontal">
                    <Button Name="btnChecksumTool"
                            Content="CHECKSUM VERIFIER"
                            Width="160"
                            Height="36"
                            Background="#2ECC71"
                            FontSize="11"/>
                    <Button Name="btnSaveReport"
                            Content="SAVE REPORT"
                            Width="120"
                            Height="36"
                            Background="#4da8da"
                            FontSize="11"/>
                    <Button Name="btnReset"
                            Content="RESET"
                            Width="80"
                            Height="36"
                            Background="#7F8C8D"
                            FontSize="11"/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
    </ScrollViewer>
</Window>
"@

# Load XAML
try {
    Load-Database
}
catch {
    [System.Windows.MessageBox]::Show(
        "Failed to load trusted software database:`n$($_.Exception.Message)`n`nPlease ensure TrustedSoftware.json exists in the same folder as this script.",
        "Database Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    )
    exit
}

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$txtSoftwareSearch = $window.FindName("txtSoftwareSearch")
$btnSearch = $window.FindName("btnSearch")
$pnlSearchResults = $window.FindName("pnlSearchResults")
$lstSearchResults = $window.FindName("lstSearchResults")
$pnlNoResults = $window.FindName("pnlNoResults")
$txtUnknownSoftwareName = $window.FindName("txtUnknownSoftwareName")
$btnProceedUnknown = $window.FindName("btnProceedUnknown")
$pnlSelectedSoftware = $window.FindName("pnlSelectedSoftware")
$txtSelectedName = $window.FindName("txtSelectedName")
$txtSelectedPublisher = $window.FindName("txtSelectedPublisher")
$txtSelectedDomains = $window.FindName("txtSelectedDomains")
$pnlOfficialDomains = $window.FindName("pnlOfficialDomains")
$txtSelectedNotes = $window.FindName("txtSelectedNotes")
$bdrSelectedTier = $window.FindName("bdrSelectedTier")
$txtSelectedTier = $window.FindName("txtSelectedTier")
$btnClearSelection = $window.FindName("btnClearSelection")
$pnlSelectedUnknown = $window.FindName("pnlSelectedUnknown")
$txtSelectedUnknownName = $window.FindName("txtSelectedUnknownName")
$btnClearUnknown = $window.FindName("btnClearUnknown")

$txtDownloadUrl = $window.FindName("txtDownloadUrl")
$btnVerifyUrl = $window.FindName("btnVerifyUrl")
$pnlUrlResult = $window.FindName("pnlUrlResult")
$txtUrlIcon = $window.FindName("txtUrlIcon")
$txtUrlResult = $window.FindName("txtUrlResult")
$txtUrlDetails = $window.FindName("txtUrlDetails")
$btnOpenOfficial = $window.FindName("btnOpenOfficial")

$txtFilePath = $window.FindName("txtFilePath")
$btnBrowseFile = $window.FindName("btnBrowseFile")
$btnCheckSignature = $window.FindName("btnCheckSignature")
$pnlSignatureResult = $window.FindName("pnlSignatureResult")
$txtSigIcon = $window.FindName("txtSigIcon")
$txtSigStatus = $window.FindName("txtSigStatus")
$txtSigSigner = $window.FindName("txtSigSigner")
$txtSigMatch = $window.FindName("txtSigMatch")
$txtSigMatchDetails = $window.FindName("txtSigMatchDetails")

$bdrSummaryPublisher = $window.FindName("bdrSummaryPublisher")
$txtSummaryPublisherIcon = $window.FindName("txtSummaryPublisherIcon")
$txtSummaryPublisher = $window.FindName("txtSummaryPublisher")
$bdrSummaryUrl = $window.FindName("bdrSummaryUrl")
$txtSummaryUrlIcon = $window.FindName("txtSummaryUrlIcon")
$txtSummaryUrl = $window.FindName("txtSummaryUrl")
$bdrSummarySignature = $window.FindName("bdrSummarySignature")
$txtSummarySignatureIcon = $window.FindName("txtSummarySignatureIcon")
$txtSummarySignature = $window.FindName("txtSummarySignature")
$bdrSummaryChecksum = $window.FindName("bdrSummaryChecksum")
$txtSummaryChecksumIcon = $window.FindName("txtSummaryChecksumIcon")
$txtSummaryChecksum = $window.FindName("txtSummaryChecksum")

$txtOverallStatus = $window.FindName("txtOverallStatus")
$btnChecksumTool = $window.FindName("btnChecksumTool")
$btnSaveReport = $window.FindName("btnSaveReport")
$btnReset = $window.FindName("btnReset")

# State
$script:UrlCheckResult = $null
$script:SignatureCheckResult = $null
$script:SignerMatchResult = $null

# Helper to update summary
function Update-Summary {
    if ($script:CurrentSoftware) {
        $tier = $script:CurrentSoftware.Publisher.tier
        $txtSummaryPublisherIcon.Text = "+"
        $txtSummaryPublisherIcon.Foreground = (Get-TierColor $tier)
        $txtSummaryPublisher.Text = "$($script:CurrentSoftware.Publisher.name)`n$(Get-TierIcon $tier)"
    } elseif ($script:IsUnknownSoftware) {
        $txtSummaryPublisherIcon.Text = "?"
        $txtSummaryPublisherIcon.Foreground = "#7F8C8D"
        $txtSummaryPublisher.Text = "Unknown software`n[NOT IN DATABASE]"
    }

    if ($script:UrlCheckResult) {
        if ($script:UrlCheckResult.IsOfficial -eq $true) {
            $txtSummaryUrlIcon.Text = "+"
            $txtSummaryUrlIcon.Foreground = "#2ECC71"
            $txtSummaryUrl.Text = "Official source"
        } elseif ($script:UrlCheckResult.IsOfficial -eq $false -and $script:CurrentSoftware) {
            $txtSummaryUrlIcon.Text = "!"
            $txtSummaryUrlIcon.Foreground = "#E74C3C"
            $txtSummaryUrl.Text = "Non-official URL"
        } elseif ($script:IsUnknownSoftware) {
            $txtSummaryUrlIcon.Text = "?"
            $txtSummaryUrlIcon.Foreground = "#F39C12"
            $txtSummaryUrl.Text = "Domain: $($script:UrlCheckResult.Domain)"
        }
    }

    if ($script:SignatureCheckResult) {
        if ($script:SignatureCheckResult.IsValid) {
            if ($script:CurrentSoftware -and $script:SignerMatchResult -and $script:SignerMatchResult.Matches) {
                $txtSummarySignatureIcon.Text = "+"
                $txtSummarySignatureIcon.Foreground = "#2ECC71"
                $txtSummarySignature.Text = "Valid & matches"
            } elseif ($script:CurrentSoftware -and $script:SignerMatchResult -and -not $script:SignerMatchResult.Matches) {
                $txtSummarySignatureIcon.Text = "?"
                $txtSummarySignatureIcon.Foreground = "#F39C12"
                $txtSummarySignature.Text = "Valid but different signer"
            } else {
                $txtSummarySignatureIcon.Text = "+"
                $txtSummarySignatureIcon.Foreground = "#2ECC71"
                $txtSummarySignature.Text = "Valid signature"
            }
        } elseif ($script:SignatureCheckResult.IsSigned) {
            $txtSummarySignatureIcon.Text = "!"
            $txtSummarySignatureIcon.Foreground = "#E74C3C"
            $txtSummarySignature.Text = "Invalid signature"
        } else {
            $txtSummarySignatureIcon.Text = "X"
            $txtSummarySignatureIcon.Foreground = "#E74C3C"
            $txtSummarySignature.Text = "Not signed"
        }
    }

    $warnings = @()

    if ($script:IsUnknownSoftware) {
        $warnings += "unknown software"
    } elseif ($script:CurrentSoftware -and $script:CurrentSoftware.Publisher.tier -eq "caution") {
        $warnings += "caution-tier publisher"
    }

    if ($script:UrlCheckResult -and $script:CurrentSoftware -and -not $script:UrlCheckResult.IsOfficial) {
        $warnings += "non-official URL"
    }

    if ($script:SignatureCheckResult) {
        if (-not $script:SignatureCheckResult.IsSigned) {
            $warnings += "not signed"
        } elseif (-not $script:SignatureCheckResult.IsValid) {
            $warnings += "invalid signature"
        } elseif ($script:CurrentSoftware -and $script:SignerMatchResult -and -not $script:SignerMatchResult.Matches) {
            $warnings += "signer mismatch"
        }
    }

    $hasSelection = $script:CurrentSoftware -or $script:IsUnknownSoftware

    if ($warnings.Count -eq 0 -and $hasSelection -and $script:UrlCheckResult -and $script:SignatureCheckResult) {
        if ($script:IsUnknownSoftware) {
            $txtOverallStatus.Text = "Signature valid - but software is unknown, proceed with caution"
            $txtOverallStatus.Foreground = "#F39C12"
        } else {
            $txtOverallStatus.Text = "All checks passed - software appears legitimate"
            $txtOverallStatus.Foreground = "#2ECC71"
        }
    } elseif ($warnings.Count -gt 0) {
        $txtOverallStatus.Text = "WARNING: " + ($warnings -join ", ").ToUpper()
        $txtOverallStatus.Foreground = "#E74C3C"
    } else {
        $txtOverallStatus.Text = "Complete the verification steps above"
        $txtOverallStatus.Foreground = "#a0a0a0"
    }
}

# Search button click
$btnSearch.Add_Click({
    $searchTerm = $txtSoftwareSearch.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($searchTerm)) {
        return
    }

    $script:UnknownSoftwareName = $searchTerm
    $results = Find-Software -SearchTerm $searchTerm

    $pnlSearchResults.Visibility = "Visible"
    $pnlSelectedSoftware.Visibility = "Collapsed"
    $pnlSelectedUnknown.Visibility = "Collapsed"
    $lstSearchResults.Items.Clear()

    if ($results.Count -eq 0) {
        $pnlNoResults.Visibility = "Visible"
        $lstSearchResults.Visibility = "Collapsed"
        $txtUnknownSoftwareName.Text = "Searched for: `"$searchTerm`""
    } else {
        $pnlNoResults.Visibility = "Collapsed"
        $lstSearchResults.Visibility = "Visible"

        foreach ($result in $results) {
            $item = [PSCustomObject]@{
                DisplayName = $result.Software.names[0]
                PublisherName = $result.Publisher.name
                TierLabel = $result.Publisher.tier.ToUpper()
                TierColor = Get-TierColor $result.Publisher.tier
                Software = $result.Software
                Publisher = $result.Publisher
            }
            $lstSearchResults.Items.Add($item)
        }
    }
})

# Enter key in search box
$txtSoftwareSearch.Add_KeyDown({
    param($sender, $e)
    if ($e.Key -eq "Return") {
        $btnSearch.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
    }
})

# Proceed with unknown software
$btnProceedUnknown.Add_Click({
    $script:IsUnknownSoftware = $true
    $script:CurrentSoftware = $null

    $txtSelectedUnknownName.Text = $script:UnknownSoftwareName

    $pnlSearchResults.Visibility = "Collapsed"
    $pnlSelectedSoftware.Visibility = "Collapsed"
    $pnlSelectedUnknown.Visibility = "Visible"

    Update-Summary
})

# Select software from list
$lstSearchResults.Add_SelectionChanged({
    $selected = $lstSearchResults.SelectedItem
    if ($null -eq $selected) { return }

    $script:IsUnknownSoftware = $false
    $script:CurrentSoftware = @{
        Software = $selected.Software
        Publisher = $selected.Publisher
    }

    $txtSelectedName.Text = $selected.DisplayName
    $txtSelectedPublisher.Text = "Publisher: " + $selected.PublisherName
    $txtSelectedDomains.Text = ($selected.Software.officialDomains -join ", ")
    $bdrSelectedTier.Background = $selected.TierColor
    $txtSelectedTier.Text = $selected.TierLabel

    if ($selected.Software.notes) {
        $txtSelectedNotes.Text = "Note: " + $selected.Software.notes
        $txtSelectedNotes.Visibility = "Visible"
    } else {
        $txtSelectedNotes.Visibility = "Collapsed"
    }

    $pnlSearchResults.Visibility = "Collapsed"
    $pnlSelectedSoftware.Visibility = "Visible"
    $pnlSelectedUnknown.Visibility = "Collapsed"

    Update-Summary
})

# Clear selection (known software)
$btnClearSelection.Add_Click({
    $script:CurrentSoftware = $null
    $script:IsUnknownSoftware = $false
    $pnlSelectedSoftware.Visibility = "Collapsed"
    $txtSoftwareSearch.Text = ""
    $txtSummaryPublisherIcon.Text = "O"
    $txtSummaryPublisherIcon.Foreground = "#7F8C8D"
    $txtSummaryPublisher.Text = "Not checked"
    Update-Summary
})

# Clear selection (unknown software)
$btnClearUnknown.Add_Click({
    $script:CurrentSoftware = $null
    $script:IsUnknownSoftware = $false
    $pnlSelectedUnknown.Visibility = "Collapsed"
    $txtSoftwareSearch.Text = ""
    $txtSummaryPublisherIcon.Text = "O"
    $txtSummaryPublisherIcon.Foreground = "#7F8C8D"
    $txtSummaryPublisher.Text = "Not checked"
    Update-Summary
})

# Verify URL
$btnVerifyUrl.Add_Click({
    $url = $txtDownloadUrl.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($url)) {
        return
    }

    $pnlUrlResult.Visibility = "Visible"

    if ($script:IsUnknownSoftware) {
        $domain = Get-UrlDomain -Url $url
        if ($domain) {
            $script:UrlCheckResult = @{
                IsOfficial = $null
                Domain = $domain
                Message = "Domain extracted from URL"
            }
            $txtUrlIcon.Text = "?"
            $pnlUrlResult.Background = "#2c2010"
            $txtUrlResult.Text = "URL domain: $domain"
            $txtUrlResult.Foreground = "#F39C12"
            $txtUrlDetails.Text = "Cannot verify if official - software not in database. Research this domain before proceeding."
            $btnOpenOfficial.Visibility = "Collapsed"
        } else {
            $script:UrlCheckResult = @{
                IsOfficial = $false
                Domain = ""
                Message = "Invalid URL"
            }
            $txtUrlIcon.Text = "!"
            $pnlUrlResult.Background = "#2c1010"
            $txtUrlResult.Text = "Invalid URL format"
            $txtUrlResult.Foreground = "#E74C3C"
            $txtUrlDetails.Text = ""
            $btnOpenOfficial.Visibility = "Collapsed"
        }
        Update-Summary
        return
    }

    if (-not $script:CurrentSoftware) {
        $txtUrlIcon.Text = "?"
        $pnlUrlResult.Background = "#2c2010"
        $txtUrlResult.Text = "Search for software first (Step 1)"
        $txtUrlResult.Foreground = "#F39C12"
        $txtUrlDetails.Text = "Select a known software or click 'Proceed Anyway' for unknown software"
        $btnOpenOfficial.Visibility = "Collapsed"
        return
    }

    $result = Test-OfficialUrl -Url $url -Software $script:CurrentSoftware.Software
    $script:UrlCheckResult = $result

    if ($result.IsOfficial) {
        $txtUrlIcon.Text = "+"
        $pnlUrlResult.Background = "#0a2a1a"
        $txtUrlResult.Text = "URL matches official source"
        $txtUrlResult.Foreground = "#2ECC71"
        $txtUrlDetails.Text = $result.Message
        $btnOpenOfficial.Visibility = "Collapsed"
    } else {
        $txtUrlIcon.Text = "!"
        $pnlUrlResult.Background = "#2c1010"
        $txtUrlResult.Text = "WARNING: URL does not match official sources!"
        $txtUrlResult.Foreground = "#E74C3C"
        $txtUrlDetails.Text = "Expected domains: " + $result.ExpectedDomains

        if ($script:CurrentSoftware.Software.downloadPage) {
            $btnOpenOfficial.Visibility = "Visible"
        }
    }

    Update-Summary
})

# Open official download page
$btnOpenOfficial.Add_Click({
    if ($script:CurrentSoftware -and $script:CurrentSoftware.Software.downloadPage) {
        Start-Process $script:CurrentSoftware.Software.downloadPage
    }
})

# Browse file
$btnBrowseFile.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Executable Files (*.exe;*.msi)|*.exe;*.msi|All Files (*.*)|*.*"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtFilePath.Text = $openFileDialog.FileName
    }
})

# Drag and drop for file
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

# Check signature
$btnCheckSignature.Add_Click({
    $filePath = $txtFilePath.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($filePath)) {
        return
    }

    $pnlSignatureResult.Visibility = "Visible"

    $result = Get-FileSignature -FilePath $filePath
    $script:SignatureCheckResult = $result

    if ($result.IsValid) {
        $txtSigIcon.Text = "+"
        $pnlSignatureResult.Background = "#0a2a1a"
        $txtSigStatus.Text = "Valid Digital Signature"
        $txtSigStatus.Foreground = "#2ECC71"
        $txtSigSigner.Text = "Signed by: " + $result.SignerName

        if ($script:CurrentSoftware) {
            $matchResult = Test-SignerMatch -SignatureResult $result -Publisher $script:CurrentSoftware.Publisher
            $script:SignerMatchResult = $matchResult

            if ($matchResult.Matches) {
                $txtSigMatch.Text = "+ Signer matches expected publisher"
                $txtSigMatch.Foreground = "#2ECC71"
                $txtSigMatchDetails.Text = ""
            } else {
                $txtSigMatch.Text = "! Signer does NOT match expected publisher"
                $txtSigMatch.Foreground = "#E74C3C"
                $txtSigMatchDetails.Text = "Expected: " + $matchResult.ExpectedNames
            }
        } elseif ($script:IsUnknownSoftware) {
            $txtSigMatch.Text = "Unknown software - verify signer manually"
            $txtSigMatch.Foreground = "#F39C12"
            $txtSigMatchDetails.Text = "Research if '$($result.SignerName)' is the legitimate publisher"
        } else {
            $txtSigMatch.Text = "Search for software to verify signer"
            $txtSigMatch.Foreground = "#7f8c8d"
            $txtSigMatchDetails.Text = ""
        }
    } elseif ($result.IsSigned) {
        $txtSigIcon.Text = "!"
        $pnlSignatureResult.Background = "#2c1010"
        $txtSigStatus.Text = "Signature Invalid: " + $result.Status
        $txtSigStatus.Foreground = "#E74C3C"
        $txtSigSigner.Text = $result.StatusMessage
        $txtSigMatch.Text = ""
        $txtSigMatchDetails.Text = ""
    } else {
        $txtSigIcon.Text = "X"
        $pnlSignatureResult.Background = "#2c1010"
        $txtSigStatus.Text = "File is NOT digitally signed"
        $txtSigStatus.Foreground = "#E74C3C"
        $txtSigSigner.Text = "This file has no digital signature - proceed with caution"
        $txtSigMatch.Text = ""
        $txtSigMatchDetails.Text = ""
    }

    Update-Summary
})

# Open checksum tool
$btnChecksumTool.Add_Click({
    $checksumScript = Join-Path $PSScriptRoot "Checksum_APP_v3.ps1"
    if (-not (Test-Path $checksumScript)) {
        $checksumScript = Join-Path $PSScriptRoot "Checksum_APP_v2.ps1"
    }
    if (Test-Path $checksumScript) {
        Start-Process powershell -ArgumentList "-NoProfile -File `"$checksumScript`""
    } else {
        [System.Windows.MessageBox]::Show(
            "Checksum verifier script not found.`n`nPlease ensure Checksum_APP_v2.ps1 or Checksum_APP.ps1 exists in the same folder.",
            "File Not Found",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Warning
        )
    }
})

# Save report
$btnSaveReport.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
    $saveDialog.FileName = "SoftwareVerification_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $report = @"
SOFTWARE TRUST VERIFICATION REPORT
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
============================================================

STEP 1: SOFTWARE IDENTIFICATION
"@

        if ($script:CurrentSoftware) {
            $report += @"

Software: $($script:CurrentSoftware.Software.names[0])
Publisher: $($script:CurrentSoftware.Publisher.name)
Trust Tier: $($script:CurrentSoftware.Publisher.tier.ToUpper())
Official Domains: $($script:CurrentSoftware.Software.officialDomains -join ", ")
"@
        } elseif ($script:IsUnknownSoftware) {
            $report += @"

Software: $($script:UnknownSoftwareName)
Publisher: UNKNOWN - NOT IN DATABASE
Trust Tier: UNKNOWN
Official Domains: N/A

*** WARNING: This software is not in the trusted database ***
*** Extra verification is recommended ***
"@
        } else {
            $report += "`nNo software selected"
        }

        $report += @"


STEP 2: URL VERIFICATION
"@
        $report += "`nProvided URL: $($txtDownloadUrl.Text)"
        if ($script:UrlCheckResult) {
            if ($script:IsUnknownSoftware) {
                $report += "`nResult: DOMAIN EXTRACTED (cannot verify - unknown software)"
                $report += "`nDomain: $($script:UrlCheckResult.Domain)"
            } elseif ($script:UrlCheckResult.IsOfficial) {
                $report += "`nResult: MATCHES OFFICIAL SOURCE"
                $report += "`nDetails: $($script:UrlCheckResult.Message)"
            } else {
                $report += "`nResult: DOES NOT MATCH OFFICIAL SOURCES"
                $report += "`nDetails: $($script:UrlCheckResult.Message)"
            }
        } else {
            $report += "`nResult: Not verified"
        }

        $report += @"


STEP 3: DIGITAL SIGNATURE
"@
        $report += "`nFile: $($txtFilePath.Text)"
        if ($script:SignatureCheckResult) {
            if ($script:SignatureCheckResult.IsSigned) { $signedText = 'Yes' } else { $signedText = 'No' }
            if ($script:SignatureCheckResult.IsValid) { $validText = 'Yes' } else { $validText = 'No' }
            $report += "`nSigned: $signedText"
            $report += "`nValid: $validText"
            if ($script:SignatureCheckResult.SignerName) {
                $report += "`nSigner: $($script:SignatureCheckResult.SignerName)"
            }
            if ($script:CurrentSoftware -and $script:SignerMatchResult) {
                if ($script:SignerMatchResult.Matches) { $matchText = 'Yes' } else { $matchText = 'No' }
                $report += "`nMatches Expected Publisher: $matchText"
            } elseif ($script:IsUnknownSoftware) {
                $report += "`nMatches Expected Publisher: N/A (unknown software)"
            }
        } else {
            $report += "`nResult: Not checked"
        }

        $report += @"


============================================================
OVERALL ASSESSMENT: $($txtOverallStatus.Text)
============================================================

Verified by: $env:USERNAME
Workstation: $env:COMPUTERNAME
"@

        try {
            $report | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
            [System.Windows.MessageBox]::Show(
                "Report saved to:`n$($saveDialog.FileName)",
                "Report Saved",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            )
        }
        catch {
            [System.Windows.MessageBox]::Show(
                "Error saving report: $($_.Exception.Message)",
                "Error",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            )
        }
    }
})

# Reset
$btnReset.Add_Click({
    $script:CurrentSoftware = $null
    $script:IsUnknownSoftware = $false
    $script:UnknownSoftwareName = ""
    $script:UrlCheckResult = $null
    $script:SignatureCheckResult = $null
    $script:SignerMatchResult = $null

    $txtSoftwareSearch.Text = ""
    $pnlSearchResults.Visibility = "Collapsed"
    $pnlSelectedSoftware.Visibility = "Collapsed"
    $pnlSelectedUnknown.Visibility = "Collapsed"

    $txtDownloadUrl.Text = ""
    $pnlUrlResult.Visibility = "Collapsed"

    $txtFilePath.Text = ""
    $pnlSignatureResult.Visibility = "Collapsed"

    $txtSummaryPublisherIcon.Text = "O"
    $txtSummaryPublisherIcon.Foreground = "#7F8C8D"
    $txtSummaryPublisher.Text = "Not checked"

    $txtSummaryUrlIcon.Text = "O"
    $txtSummaryUrlIcon.Foreground = "#7F8C8D"
    $txtSummaryUrl.Text = "Not checked"

    $txtSummarySignatureIcon.Text = "O"
    $txtSummarySignatureIcon.Foreground = "#7F8C8D"
    $txtSummarySignature.Text = "Not checked"

    $txtSummaryChecksumIcon.Text = "O"
    $txtSummaryChecksumIcon.Foreground = "#7F8C8D"
    $txtSummaryChecksum.Text = "Not checked"

    $txtOverallStatus.Text = "Complete the verification steps above"
    $txtOverallStatus.Foreground = "#a0a0a0"
})

# Show the window
$window.ShowDialog() | Out-Null
# SIG # Begin signature block
# MIIFvAYJKoZIhvcNAQcCoIIFrTCCBakCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDtMj5oRJf1KUYl
# qyiuS8e6bnyBIih0IVbV69q5aFoWXKCCAyQwggMgMIICCKADAgECAhAet+EmJNzQ
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
# KoZIhvcNAQkEMSIEINCzeENk6p3IYhlGpUIRtVBnDizmLfOD+F6zbtsNGgCXMA0G
# CSqGSIb3DQEBAQUABIIBAH4eYo1RtwoTWeG6AXu3BFhmuLb/19jC75TiKt2IlO0Y
# T4+7ARD/iE3napLvt+OMHCUXQ2EuGIU3QmPPSw0Fu5sT9w0NwSJWIgaJyQzsjfVO
# WmX0CcOHUCLYaqYavZp5OM43BFJI/T4W47nqGs6ND10cs9nF6KfNgv7dtA7BBWff
# f+YJR7c3GooNM2Ff5/MzygZ9w5U1wN/dO5u199OcY8m5AHQDbwpEa97Cr0gMvSLO
# BtB9Huug/vjMd6XNKSjBg3G3VzJCYKE0kCK96eI5UCLz0VEgdjbnfykze66fUPzf
# wplDYhFJnoTq2YFbj+s28dh5U+wy08BavrQWBgIcPWs=
# SIG # End signature block
