#Requires -Version 5.1
<#
.SYNOPSIS
    GUI-based IOC scanner and remediator for the Notepad++ supply chain attack (June-December 2025).
.DESCRIPTION
    Professional WPF interface for detecting and remediating indicators of compromise from the Notepad++
    supply chain attack attributed to Chinese APT Lotus Blossom (Chrysalis backdoor).
    Sources: Kaspersky GReAT, Rapid7 Labs, Notepad++ official disclosure.
.NOTES
    Author  : SysAdminDoc
    Version : 2.3 GUI
    Date    : 2026-02-04
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Notepad++ IOC Scanner v2.3"
    Width="1160" Height="780" MinWidth="900" MinHeight="600"
    WindowStartupLocation="CenterScreen"
    Background="#1B1B2F" Foreground="#E8E8F0"
    FontFamily="Segoe UI">

    <Window.Resources>
        <SolidColorBrush x:Key="WindowBg" Color="#1B1B2F"/>
        <SolidColorBrush x:Key="PanelBg" Color="#22223A"/>
        <SolidColorBrush x:Key="SurfaceBg" Color="#1E1E36"/>
        <SolidColorBrush x:Key="ElevatedBg" Color="#2D2D4A"/>
        <SolidColorBrush x:Key="BorderClr" Color="#3A3A5C"/>

        <Style x:Key="PrimaryBtn" TargetType="Button">
            <Setter Property="Background" Value="#5B6ABF"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="18,8"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                CornerRadius="4" Padding="{TemplateBinding Padding}" SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#6D7DD1"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#4A5AAE"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bd" Property="Background" Value="#3A3A5C"/>
                                <Setter Property="Foreground" Value="#5A5A78"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SecondaryBtn" TargetType="Button">
            <Setter Property="Background" Value="#2A2A48"/>
            <Setter Property="Foreground" Value="#C0C0D8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="14,7"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#4A4A6A"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4" Padding="{TemplateBinding Padding}" SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#363658"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="#5B6ABF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#2E2E50"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bd" Property="Background" Value="#252540"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="#35354A"/>
                                <Setter Property="Foreground" Value="#4A4A60"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="DangerBtn" TargetType="Button">
            <Setter Property="Background" Value="#8B2020"/>
            <Setter Property="Foreground" Value="#FFCCCC"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="14,7"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#AA3333"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4" Padding="{TemplateBinding Padding}" SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#A52D2D"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="#DD4444"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#701818"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bd" Property="Background" Value="#352020"/>
                                <Setter TargetName="bd" Property="BorderBrush" Value="#452828"/>
                                <Setter Property="Foreground" Value="#5A4040"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SBThumb" TargetType="Thumb">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Thumb">
                        <Border x:Name="tb" Background="#4A4A6A" CornerRadius="3" Margin="1"/>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="tb" Property="Background" Value="#606082"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="SBRepeat" TargetType="RepeatButton">
            <Setter Property="OverridesDefaultStyle" Value="True"/>
            <Setter Property="IsTabStop" Value="False"/>
            <Setter Property="Focusable" Value="False"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RepeatButton"><Border Background="Transparent"/></ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <ControlTemplate x:Key="VScrollBar" TargetType="ScrollBar">
            <Grid Width="8" Background="Transparent">
                <Track x:Name="PART_Track" IsDirectionReversed="True">
                    <Track.DecreaseRepeatButton><RepeatButton Style="{StaticResource SBRepeat}" Command="ScrollBar.PageUpCommand"/></Track.DecreaseRepeatButton>
                    <Track.Thumb><Thumb Style="{StaticResource SBThumb}"/></Track.Thumb>
                    <Track.IncreaseRepeatButton><RepeatButton Style="{StaticResource SBRepeat}" Command="ScrollBar.PageDownCommand"/></Track.IncreaseRepeatButton>
                </Track>
            </Grid>
        </ControlTemplate>
        <ControlTemplate x:Key="HScrollBar" TargetType="ScrollBar">
            <Grid Height="8" Background="Transparent">
                <Track x:Name="PART_Track" IsDirectionReversed="False">
                    <Track.DecreaseRepeatButton><RepeatButton Style="{StaticResource SBRepeat}" Command="ScrollBar.PageLeftCommand"/></Track.DecreaseRepeatButton>
                    <Track.Thumb><Thumb Style="{StaticResource SBThumb}"/></Track.Thumb>
                    <Track.IncreaseRepeatButton><RepeatButton Style="{StaticResource SBRepeat}" Command="ScrollBar.PageRightCommand"/></Track.IncreaseRepeatButton>
                </Track>
            </Grid>
        </ControlTemplate>
        <Style TargetType="ScrollBar">
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="OverridesDefaultStyle" Value="True"/>
            <Style.Triggers>
                <Trigger Property="Orientation" Value="Vertical">
                    <Setter Property="Width" Value="8"/><Setter Property="Height" Value="Auto"/>
                    <Setter Property="Template" Value="{StaticResource VScrollBar}"/>
                </Trigger>
                <Trigger Property="Orientation" Value="Horizontal">
                    <Setter Property="Width" Value="Auto"/><Setter Property="Height" Value="8"/>
                    <Setter Property="Template" Value="{StaticResource HScrollBar}"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="#2D2D4A"/><Setter Property="Foreground" Value="#A0A0C0"/>
            <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="8,7"/><Setter Property="BorderBrush" Value="#3A3A5C"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
        </Style>
        <Style TargetType="DataGridRow">
            <Setter Property="Background" Value="#1F1F38"/><Setter Property="Foreground" Value="#E0E0F0"/>
            <Setter Property="BorderBrush" Value="#2A2A44"/><Setter Property="BorderThickness" Value="0,0,0,1"/>
            <Style.Triggers>
                <DataTrigger Binding="{Binding Status}" Value="CLEAN"><Setter Property="Background" Value="#1C2820"/></DataTrigger>
                <DataTrigger Binding="{Binding Status}" Value="FOUND"><Setter Property="Background" Value="#2E1C1C"/></DataTrigger>
                <DataTrigger Binding="{Binding Status}" Value="WARNING"><Setter Property="Background" Value="#2C2818"/></DataTrigger>
                <DataTrigger Binding="{Binding Status}" Value="ERROR"><Setter Property="Background" Value="#2C2218"/></DataTrigger>
                <DataTrigger Binding="{Binding Status}" Value="REMEDIATED"><Setter Property="Background" Value="#1C2838"/></DataTrigger>
                <Trigger Property="IsSelected" Value="True"><Setter Property="Background" Value="#33336A"/><Setter Property="Foreground" Value="#FFFFFF"/></Trigger>
                <Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#2A2A50"/></Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="DataGridCell">
            <Setter Property="BorderThickness" Value="0"/><Setter Property="FocusVisualStyle" Value="{x:Null}"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True"><Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="#FFFFFF"/></Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <DockPanel>
        <Border DockPanel.Dock="Top">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                    <GradientStop Color="#252548" Offset="0"/><GradientStop Color="#2E2E5A" Offset="0.5"/><GradientStop Color="#302A50" Offset="1"/>
                </LinearGradientBrush>
            </Border.Background>
            <Grid Margin="24,16,24,14">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <StackPanel Orientation="Horizontal">
                        <Viewbox Width="22" Height="22" Margin="0,0,10,0" VerticalAlignment="Center">
                            <Path Data="M12,1 L3,5 L3,12 C3,17.5 7,20.5 12,23 C17,20.5 21,17.5 21,12 L21,5 Z" Fill="#5B6ABF" Stroke="#7B8BDF" StrokeThickness="0.8"/>
                        </Viewbox>
                        <TextBlock Text="Notepad++ Supply Chain IOC Scanner" FontSize="20" FontWeight="Bold" Foreground="#E8E8F0" VerticalAlignment="Center"/>
                    </StackPanel>
                    <TextBlock Margin="32,4,0,0" FontSize="11.5" Foreground="#8888A8" Text="Lotus Blossom / Chrysalis Backdoor Detection + Remediation  --  v2.3"/>
                </StackPanel>
                <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock FontSize="10.5" Foreground="#7878A0" TextAlignment="Right">
                        <Hyperlink x:Name="linkKaspersky" Foreground="#7888CC" TextDecorations="{x:Null}">Kaspersky GReAT</Hyperlink>
                        <Run Text="  |  "/>
                        <Hyperlink x:Name="linkRapid7" Foreground="#7888CC" TextDecorations="{x:Null}">Rapid7 Labs</Hyperlink>
                        <Run Text="  |  "/>
                        <Hyperlink x:Name="linkOfficial" Foreground="#7888CC" TextDecorations="{x:Null}">Official Disclosure</Hyperlink>
                    </TextBlock>
                </StackPanel>
            </Grid>
        </Border>

        <Border DockPanel.Dock="Top" Background="#1E1E36" Padding="24,8" BorderBrush="#2A2A44" BorderThickness="0,0,0,1">
            <WrapPanel>
                <TextBlock x:Name="txtMachine" FontSize="11.5" Foreground="#9898B8" Margin="0,0,24,0"/>
                <TextBlock x:Name="txtUser" FontSize="11.5" Foreground="#9898B8" Margin="0,0,24,0"/>
                <TextBlock x:Name="txtOS" FontSize="11.5" Foreground="#9898B8" Margin="0,0,24,0"/>
                <TextBlock x:Name="txtElevated" FontSize="11.5" Margin="0,0,24,0"/>
                <TextBlock x:Name="txtScanDate" FontSize="11.5" Foreground="#9898B8"/>
            </WrapPanel>
        </Border>

        <Border DockPanel.Dock="Top" Background="#22223A" Padding="24,10" BorderBrush="#2A2A44" BorderThickness="0,0,0,1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Button x:Name="btnScan" Content="Run Scan" Style="{StaticResource PrimaryBtn}" Grid.Column="0"/>
                <Button x:Name="btnRemediate" Content="Remediate IOCs" Style="{StaticResource DangerBtn}" Grid.Column="1" Margin="10,0,0,0" IsEnabled="False"/>
                <Button x:Name="btnExport" Content="Export Report" Style="{StaticResource SecondaryBtn}" Grid.Column="2" Margin="10,0,0,0" IsEnabled="False"/>
                <Button x:Name="btnCopy" Content="Copy Results" Style="{StaticResource SecondaryBtn}" Grid.Column="3" Margin="10,0,0,0" IsEnabled="False"/>
                <StackPanel Grid.Column="4" Margin="24,0,10,0" VerticalAlignment="Center">
                    <TextBlock x:Name="txtProgress" Text="Ready to scan" FontSize="11" Foreground="#7878A0"/>
                    <Border Background="#2A2A44" CornerRadius="2" Height="4" Margin="0,5,0,0">
                        <Border x:Name="progressFill" Background="#5B6ABF" CornerRadius="2" HorizontalAlignment="Left" Width="0"/>
                    </Border>
                </StackPanel>
                <TextBlock x:Name="txtDuration" Grid.Column="5" FontSize="11" Foreground="#7878A0" VerticalAlignment="Center"/>
            </Grid>
        </Border>

        <Border x:Name="alertBanner" DockPanel.Dock="Top" Visibility="Collapsed" Padding="24,10" BorderBrush="#FF4444" BorderThickness="0,0,0,2">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                    <GradientStop Color="#3D1111" Offset="0"/><GradientStop Color="#4A1515" Offset="1"/>
                </LinearGradientBrush>
            </Border.Background>
            <StackPanel Orientation="Horizontal">
                <TextBlock Text="[!]" FontWeight="Bold" FontSize="15" Foreground="#FF6B6B" Margin="0,0,12,0" VerticalAlignment="Center"/>
                <TextBlock x:Name="txtAlert" Foreground="#FFB0B0" FontWeight="SemiBold" FontSize="12.5" TextWrapping="Wrap" VerticalAlignment="Center"/>
            </StackPanel>
        </Border>

        <Border DockPanel.Dock="Bottom" Background="#1A1A30" Padding="24,9" BorderBrush="#2A2A44" BorderThickness="0,1,0,0">
            <Grid>
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock x:Name="txtSummary" Grid.Column="0" FontSize="12" Foreground="#8888A8" VerticalAlignment="Center"/>
                <TextBlock x:Name="txtResult" Grid.Column="1" FontSize="12" FontWeight="Bold" Foreground="#8888A8" VerticalAlignment="Center"/>
            </Grid>
        </Border>

        <Border DockPanel.Dock="Bottom" Background="#1E1E36" Padding="24,10" MinHeight="68" BorderBrush="#2A2A44" BorderThickness="0,1,0,0">
            <StackPanel>
                <TextBlock Text="S E L E C T E D   C H E C K   D E T A I L S" FontSize="9.5" Foreground="#5A5A78" FontWeight="SemiBold" Margin="0,0,0,5"/>
                <TextBlock x:Name="txtDetails" TextWrapping="Wrap" Foreground="#B8B8D8" FontSize="12" Text="Select a row above to view full details"/>
            </StackPanel>
        </Border>

        <Grid Background="#1B1B2F">
            <DataGrid x:Name="dataGrid" AutoGenerateColumns="False" IsReadOnly="True"
                      SelectionMode="Single" SelectionUnit="FullRow" CanUserResizeRows="False"
                      CanUserReorderColumns="False" CanUserSortColumns="True" CanUserAddRows="False"
                      HeadersVisibility="Column" GridLinesVisibility="None" Background="#1B1B2F"
                      BorderThickness="0" RowHeaderWidth="0"
                      HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto">
                <DataGrid.Columns>
                    <DataGridTextColumn Header="Section" Binding="{Binding Section}" Width="115">
                        <DataGridTextColumn.ElementStyle>
                            <Style TargetType="TextBlock">
                                <Setter Property="Foreground" Value="#8888A8"/><Setter Property="Padding" Value="8,5"/>
                                <Setter Property="VerticalAlignment" Value="Center"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="FontSize" Value="11"/>
                            </Style>
                        </DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                    <DataGridTextColumn Header="Check" Binding="{Binding Check}" Width="260">
                        <DataGridTextColumn.ElementStyle>
                            <Style TargetType="TextBlock">
                                <Setter Property="Foreground" Value="#D0D0E8"/><Setter Property="Padding" Value="8,5"/>
                                <Setter Property="VerticalAlignment" Value="Center"/><Setter Property="FontSize" Value="12"/>
                            </Style>
                        </DataGridTextColumn.ElementStyle>
                    </DataGridTextColumn>
                    <DataGridTemplateColumn Header="Status" Width="100" SortMemberPath="Status">
                        <DataGridTemplateColumn.CellTemplate>
                            <DataTemplate>
                                <Border Padding="8,4">
                                    <TextBlock Text="{Binding Status}" FontWeight="Bold" FontSize="11.5" VerticalAlignment="Center">
                                        <TextBlock.Style>
                                            <Style TargetType="TextBlock">
                                                <Setter Property="Foreground" Value="#9898B8"/>
                                                <Style.Triggers>
                                                    <DataTrigger Binding="{Binding Status}" Value="CLEAN"><Setter Property="Foreground" Value="#4CAF50"/></DataTrigger>
                                                    <DataTrigger Binding="{Binding Status}" Value="FOUND"><Setter Property="Foreground" Value="#EF5350"/></DataTrigger>
                                                    <DataTrigger Binding="{Binding Status}" Value="WARNING"><Setter Property="Foreground" Value="#FFA726"/></DataTrigger>
                                                    <DataTrigger Binding="{Binding Status}" Value="ERROR"><Setter Property="Foreground" Value="#FF7043"/></DataTrigger>
                                                    <DataTrigger Binding="{Binding Status}" Value="REMEDIATED"><Setter Property="Foreground" Value="#42A5F5"/></DataTrigger>
                                                </Style.Triggers>
                                            </Style>
                                        </TextBlock.Style>
                                    </TextBlock>
                                </Border>
                            </DataTemplate>
                        </DataGridTemplateColumn.CellTemplate>
                    </DataGridTemplateColumn>
                    <DataGridTemplateColumn Header="Details" Width="*" SortMemberPath="Details">
                        <DataGridTemplateColumn.CellTemplate>
                            <DataTemplate>
                                <TextBlock Text="{Binding Details}" TextTrimming="CharacterEllipsis" TextWrapping="NoWrap"
                                           ToolTip="{Binding Details}" Foreground="#B0B0C8" Padding="8,5" FontSize="11.5" VerticalAlignment="Center"/>
                            </DataTemplate>
                        </DataGridTemplateColumn.CellTemplate>
                    </DataGridTemplateColumn>
                </DataGrid.Columns>
            </DataGrid>
            <TextBlock x:Name="txtPlaceholder" Text="Click 'Run Scan' to begin IOC detection"
                       HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#4A4A6A" FontSize="15" IsHitTestVisible="False"/>
        </Grid>
    </DockPanel>
</Window>
"@

$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# codex-branding:start
                try {
                    $brandingIconPath = Join-Path $PSScriptRoot 'icon.ico'
                    if (Test-Path $brandingIconPath) {
                        $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create((New-Object System.Uri($brandingIconPath)))
                    }
                } catch {
                }
                # codex-branding:end
$btnScan        = $window.FindName('btnScan')
$btnRemediate   = $window.FindName('btnRemediate')
$btnExport      = $window.FindName('btnExport')
$btnCopy        = $window.FindName('btnCopy')
$dataGrid       = $window.FindName('dataGrid')
$txtMachine     = $window.FindName('txtMachine')
$txtUser        = $window.FindName('txtUser')
$txtOS          = $window.FindName('txtOS')
$txtElevated    = $window.FindName('txtElevated')
$txtScanDate    = $window.FindName('txtScanDate')
$txtProgress    = $window.FindName('txtProgress')
$progressFill   = $window.FindName('progressFill')
$txtDuration    = $window.FindName('txtDuration')
$txtDetails     = $window.FindName('txtDetails')
$txtSummary     = $window.FindName('txtSummary')
$txtResult      = $window.FindName('txtResult')
$txtPlaceholder = $window.FindName('txtPlaceholder')
$alertBanner    = $window.FindName('alertBanner')
$txtAlert       = $window.FindName('txtAlert')
$linkKaspersky  = $window.FindName('linkKaspersky')
$linkRapid7     = $window.FindName('linkRapid7')
$linkOfficial   = $window.FindName('linkOfficial')

$txtMachine.Text = "Machine: $env:COMPUTERNAME"
$txtUser.Text    = "User: $env:USERDOMAIN\$env:USERNAME"
try { $txtOS.Text = "OS: $((Get-CimInstance Win32_OperatingSystem -EA Stop).Caption)" } catch { $txtOS.Text = 'OS: Windows' }
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$txtElevated.Text = "Elevated: $isAdmin"
$txtElevated.Foreground = if ($isAdmin) {
    [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(76,175,80))
} else {
    [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(255,167,38))
}
$txtScanDate.Text = "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

$script:resultsCollection = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new()
$dataGrid.ItemsSource = $script:resultsCollection

$script:syncHash = [hashtable]::Synchronized(@{})
$script:syncHash.ResultQueue   = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
$script:syncHash.ProgressValue = 0
$script:syncHash.ProgressText  = ''
$script:syncHash.Duration      = ''
$script:syncHash.ScanComplete  = $false
$script:syncHash.ScanRunning   = $false

$script:iocConfig = @{
    C2Ips = @('45.76.155.202';'45.32.144.255';'95.179.213.0';'45.77.31.210';'59.110.7.32';'124.222.137.114';'61.4.102.97';'51.91.79.17')
    C2Domains = @('skycloudcenter.com';'wiresguard.com';'cdncheck.it.com';'safe-dns.it.com';'self-dns.it.com';'temp.sh')
    Sha1Hashes = @('8e6e505438c21f3d281e1cc257abdbf7223b7f5a';'90e677d7ff5844407b9c073e3b7e896e078e11cd';'573549869e84544e3ef253bdba79851dcde4963a';'13179c8f19fbf3d8473c49983a199e6cb4f318f0';'4c9aac447bf732acc97992290aa7a187b967ee2c';'821c0cafb2aab0f063ef7e313f64313fc81d46cd';'d7ffd7b588880cf61b603346a3557e7cce648c93';'06a6a5a39193075734a32e0235bde0e979c27228';'9c3ba38890ed984a25abb6a094b5dbf052f22fa7';'ca4b6fe0c69472cd3d63b212eb805b7f65710d33';'0d0f315fd8cf408a483f8e2dd1e69422629ed9fd';'2a476cfb85fbf012fdbe63a37642c11afa5cf020';'21a942273c14e4b9d3faa58e4de1fd4d5014a1ed';'7e0790226ea461bcc9ecd4be3c315ace41e1c122';'f7910d943a013eede24ac89d6388c1b98f8b3717';'94dffa9de5b665dc51bc36e2693b8a3a0a4cc6b8';'73d9d0139eaf89b7df34ceeb60e5f8c7cd2463bf';'bd4915b3597942d88f319740a9b803cc51585c4a';'c68d09dd50e357fd3de17a70b7724f8949441d77';'813ace987a61af909c053607635489ee984534f4';'9fbf2195dee991b1e5a727fd51391dcc2d7a4b16';'07d2a01e1dc94d59d5ca3bdf0c7848553ae91a51';'3090ecf034337857f786084fb14e63354e271c5d';'d0662eadbe5ba92acbd3485d8187112543bcfbf5';'9c0eff4deeb626730ad6a05c85eb138df48372ce')
    Sha256Hashes = @('a511be5164dc1122fb5a7daa3eef9467e43d8458425b15a640235796006590c9';'8ea8b83645fba6e23d48075a0d3fc73ad2ba515b4536710cda4f1f232718f53e';'2da00de67720f5f13b17e9d985fe70f10f153da60c9ab1086fe58f069a156924';'77bfea78def679aa1117f569a35e8fd1542df21f7e00e27f192c907e61d63a2e';'3bdc4c0637591533f1d4198a72a33426c01f69bd2e15ceee547866f65e26b7ad';'9276594e73cda1c69b7d265b3f08dc8fa84bf2d6599086b9acc0bb3745146600';'f4d829739f2d6ba7e3ede83dad428a0ced1a703ec582fc73a4eee3df3704629a';'4a52570eeaf9d27722377865df312e295a7a23c3b6eb991944c2ecd707cc9906';'831e1ea13a1bd405f5bda2b9d8f2265f7b1db6c668dd2165ccc8a9c4c15ea7dd';'0a9b8df968df41920b6ff07785cbfebe8bda29e6b512c94a3b2a83d10014d2fd';'4c2ea8193f4a5db63b897a2d3ce127cc5d89687f380b97a1d91e0c8db542e4f8';'e7cd605568c38bd6e0aba31045e1633205d0598c607a855e2e1bca4cca1c6eda';'078a9e5c6c787e5532a7e728720cbafee9021bfec4a30e3c2be110748d7c43c5';'b4169a831292e245ebdffedd5820584d73b129411546e7d3eccf4663d5fc5be3';'fcc2765305bcd213b7558025b2039df2265c3e0b6401e4833123c461df2de51a';'7add554a98d3a99b319f2127688356c1283ed073a084805f14e33b4f6a6126fd')
    # Directories safe to delete entirely (these are NOT legitimate Windows paths)
    MalwareDirs = @("$env:APPDATA\ProShow";"$env:APPDATA\Bluetooth")
    # Specific malware files for targeted remediation (includes files inside legitimate dirs)
    MalwareFiles = @(
        "$env:APPDATA\Adobe\Scripts\alien.ini"
        "$env:ProgramData\USOShared\svchost.exe"
        "$env:ProgramData\USOShared\conf.c"
        "$env:ProgramData\USOShared\libtcc.dll"
        "$env:LOCALAPPDATA\Temp\ns.tmp"
        "$env:LOCALAPPDATA\Temp\1.txt"
        "$env:LOCALAPPDATA\Temp\a.txt"
        "$env:LOCALAPPDATA\Temp\u.bat"
    )
    MalwareProcesses = @('BluetoothService','ProShow','ConsoleApplication2')
    PersistencePatterns = @('BluetoothService','ProShow','USOShared','svchost.*-nostdlib','svchost.*conf\.c','log\.dll')
}

# === Scan ScriptBlock ===
$scanScript = {
    param($sync, $ioc)
    $c2Ips=$ioc.C2Ips; $c2Domains=$ioc.C2Domains; $knownSha1=$ioc.Sha1Hashes; $knownSha256=$ioc.Sha256Hashes
    function Enq { param([string]$S,[string]$C,[string]$St,[string]$D); $sync.ResultQueue.Enqueue([PSCustomObject]@{Section=$S;Check=$C;Status=$St;Details=$D}) }
    function Prog { param([int]$V,[string]$T); $sync.ProgressValue=$V; $sync.ProgressText=$T }
    $t0 = Get-Date
    try {
        Prog 5 'Checking Notepad++ installation...'
        $npp=[System.Collections.Generic.List[string]]::new()
        foreach($rk in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')){
            try{Get-ItemProperty $rk -EA SilentlyContinue|Where-Object{$_.DisplayName-like'*Notepad++*'}|ForEach-Object{if($_.InstallLocation-and(Test-Path $_.InstallLocation)){$p=$_.InstallLocation.TrimEnd('\');if(-not $npp.Contains($p)){$npp.Add($p)}}}}catch{}}
        @("$env:ProgramFiles\Notepad++","${env:ProgramFiles(x86)}\Notepad++")|ForEach-Object{if((Test-Path $_)-and -not $npp.Contains($_)){$npp.Add($_)}}
        if($npp.Count-eq 0){Enq 'Install' 'Notepad++ installed' 'CLEAN' 'Not found on this system'}
        else{foreach($nd in $npp){$exe=Join-Path $nd 'notepad++.exe';if(Test-Path $exe){try{$vi=(Get-Item $exe -EA Stop).VersionInfo;$v=[version]$vi.ProductVersion
            if($v-lt[version]'8.8.9'){Enq 'Install' "Version ($nd)" 'FOUND' "v$($vi.ProductVersion) - VULNERABLE. Upgrade to v8.9.1+ immediately."}
            elseif($v-lt[version]'8.9.1'){Enq 'Install' "Version ($nd)" 'WARNING' "v$($vi.ProductVersion) - Partially patched. Upgrade to v8.9.1+."}
            else{Enq 'Install' "Version ($nd)" 'CLEAN' "v$($vi.ProductVersion) - Fully patched."}}catch{Enq 'Install' "Version ($nd)" 'WARNING' "Cannot read version"}}
            $au=Join-Path $nd 'AutoUpdate.exe';if(Test-Path $au){$ai=Get-Item $au -Force -EA SilentlyContinue;Enq 'Install' 'AutoUpdate.exe' 'FOUND' "NOT legitimate Notepad++ file. Size: $($ai.Length) bytes"}}}
        $plugDirs=@("$env:APPDATA\Notepad++\plugins");foreach($nd in $npp){$ip=Join-Path $nd 'plugins';if(Test-Path $ip){$plugDirs+=$ip}}
        foreach($pd in $plugDirs){if(Test-Path $pd){$nd2=Get-ChildItem $pd -Directory -Force -EA SilentlyContinue|Where-Object{$_.Name-notin@('Config','config','doc','disabled')}
            if($nd2){Enq 'Install' "Plugins ($pd)" 'WARNING' "Review: $(($nd2.Name)-join', ')"}else{Enq 'Install' "Plugins ($pd)" 'CLEAN' 'Default only'}}}
        Prog 15 'Installation done'

        Prog 18 'Scanning files...'
        # Directories that should NOT exist at all (always malicious)
        foreach($d in @(@{N='%APPDATA%\ProShow';P="$env:APPDATA\ProShow";D='Payload staging (Chain 1+2)'},@{N='%APPDATA%\Bluetooth';P="$env:APPDATA\Bluetooth";D='Chrysalis backdoor staging'})){
            if(Test-Path $d.P){$items=Get-ChildItem $d.P -Recurse -Force -EA SilentlyContinue;Enq 'Files' "$($d.N) directory" 'FOUND' "$($d.D) -- $($items.Count) items: $(($items.Name)-join', ')"}
            else{Enq 'Files' "$($d.N) directory" 'CLEAN' 'Not found'}}
        # Hidden attribute check - Chrysalis NSIS installer sets Hidden on %AppData%\Bluetooth
        $btDir="$env:APPDATA\Bluetooth";if(Test-Path $btDir){$btItem=Get-Item $btDir -Force -EA SilentlyContinue
            if($btItem-and($btItem.Attributes-band[IO.FileAttributes]::Hidden)){Enq 'Files' 'Bluetooth dir (Hidden)' 'FOUND' 'Directory has Hidden attribute set -- matches Chrysalis NSIS installer behavior'}
            elseif($btItem){Enq 'Files' 'Bluetooth dir (Hidden)' 'FOUND' 'Directory exists but is NOT hidden (atypical for Chrysalis)'}}
        # Legitimate directories that may contain malicious files - check for SPECIFIC artifacts only
        # USOShared is a legitimate Windows Update directory (USO = Update Session Orchestrator)
        $usoPath="$env:ProgramData\USOShared"; $usoMalware=@('svchost.exe','conf.c','libtcc.dll')
        if(Test-Path $usoPath){$usoHits=$usoMalware|Where-Object{Test-Path(Join-Path $usoPath $_)}
            if($usoHits){Enq 'Files' 'ProgramData\USOShared' 'FOUND' "Malicious artifacts in legitimate Windows Update directory: $($usoHits-join', ')"}
            else{Enq 'Files' 'ProgramData\USOShared' 'CLEAN' "Legitimate Windows Update directory (no malicious artifacts)"}}
        else{Enq 'Files' 'ProgramData\USOShared' 'CLEAN' 'Directory not present'}
        # Adobe\Scripts may be legitimate - only flag if alien.ini exists
        $adobePath="$env:APPDATA\Adobe\Scripts"
        if(Test-Path $adobePath){if(Test-Path "$adobePath\alien.ini"){Enq 'Files' '%APPDATA%\Adobe\Scripts' 'FOUND' "Contains alien.ini malware config"}
            else{Enq 'Files' '%APPDATA%\Adobe\Scripts' 'CLEAN' "Legitimate Adobe directory (no malicious artifacts)"}}
        else{Enq 'Files' '%APPDATA%\Adobe\Scripts' 'CLEAN' 'Not found'}
        foreach($f in @(@{N='Payload (load)';P="$env:APPDATA\ProShow\load";D='Chain 1+2'},@{N='Config (alien.ini)';P="$env:APPDATA\Adobe\Scripts\alien.ini";D='Malware config'},@{N='BluetoothService.exe';P="$env:APPDATA\Bluetooth\BluetoothService.exe";D='Renamed Bitdefender'},@{N='BluetoothService (shellcode)';P="$env:APPDATA\Bluetooth\BluetoothService";D='Chrysalis shellcode'},@{N='log.dll';P="$env:APPDATA\Bluetooth\log.dll";D='Sideload DLL'},@{N='USOShared svchost.exe';P="$env:ProgramData\USOShared\svchost.exe";D='Renamed TCC'},@{N='USOShared conf.c';P="$env:ProgramData\USOShared\conf.c";D='Metasploit loader'},@{N='USOShared libtcc.dll';P="$env:ProgramData\USOShared\libtcc.dll";D='TCC library'},@{N='NSIS temp (ns.tmp)';P="$env:LOCALAPPDATA\Temp\ns.tmp";D='NSIS artifact'},@{N='Recon (1.txt)';P="$env:LOCALAPPDATA\Temp\1.txt";D='Recon output'},@{N='Recon (a.txt)';P="$env:LOCALAPPDATA\Temp\a.txt";D='Recon output'},@{N='Self-removal (u.bat)';P="$env:LOCALAPPDATA\Temp\u.bat";D='Chrysalis cleanup'})){
            if(Test-Path $f.P){$fi=Get-Item $f.P -Force -EA SilentlyContinue;Enq 'Files' $f.N 'FOUND' "$($f.D) -- Size: $($fi.Length)B, Modified: $($fi.LastWriteTime)"}
            else{Enq 'Files' $f.N 'CLEAN' 'Not found'}}
        Prog 30 'Files done'

        Prog 33 'Verifying hashes...'
        $sha1H=[System.Collections.Generic.List[string]]::new();$sha256H=[System.Collections.Generic.List[string]]::new();$sc=0
        foreach($hp in @("$env:APPDATA\ProShow";"$env:APPDATA\Adobe\Scripts";"$env:APPDATA\Bluetooth";"$env:ProgramData\USOShared")){
            if(Test-Path $hp){Get-ChildItem $hp -File -Recurse -Force -EA SilentlyContinue|ForEach-Object{$sc++
                try{$h1=(Get-FileHash $_.FullName -Algorithm SHA1 -EA Stop).Hash.ToLower();if($knownSha1-contains $h1){$sha1H.Add("$($_.Name) [$h1]")}}catch{}
                try{$h2=(Get-FileHash $_.FullName -Algorithm SHA256 -EA Stop).Hash.ToLower();if($knownSha256-contains $h2){$sha256H.Add("$($_.Name) [$h2]")}}catch{}}}}
        if($sha1H.Count-gt 0){Enq 'Hashes' 'SHA-1 (Kaspersky)' 'FOUND' ($sha1H-join'; ')}else{Enq 'Hashes' 'SHA-1 (Kaspersky)' 'CLEAN' "No matches ($sc files)"}
        if($sha256H.Count-gt 0){Enq 'Hashes' 'SHA-256 (Rapid7)' 'FOUND' ($sha256H-join'; ')}else{Enq 'Hashes' 'SHA-256 (Rapid7)' 'CLEAN' "No matches ($sc files)"}
        Prog 50 'Hashes done'

        Prog 53 'Checking persistence...'
        $rH=[System.Collections.Generic.List[string]]::new()
        foreach($rk in @('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run')){
            try{if(Test-Path $rk){(Get-ItemProperty $rk -EA SilentlyContinue).PSObject.Properties|Where-Object{$_.Name-notmatch'^PS'}|ForEach-Object{$val=[string]$_.Value
                foreach($pat in @('BluetoothService','ProShow','USOShared','svchost.*-nostdlib','svchost.*conf\.c','log\.dll')){if($val-match $pat){$rH.Add("$rk -- $($_.Name)");break}}}}}catch{}}
        if($rH.Count-gt 0){Enq 'Persist' 'Registry Run keys' 'FOUND' ($rH-join'; ')}else{Enq 'Persist' 'Registry Run keys' 'CLEAN' 'No suspicious entries'}
        $sH=[System.Collections.Generic.List[string]]::new()
        try{$sv=Get-Service -Name 'BluetoothService' -EA SilentlyContinue;if($sv){$sH.Add("BluetoothService exists ($($sv.Status))")}
            Get-CimInstance Win32_Service -EA SilentlyContinue|ForEach-Object{$pn=[string]$_.PathName;foreach($p in @('Bluetooth','ProShow','USOShared')){if($pn-match[regex]::Escape($p)){$e="$($_.Name): $pn";if(-not $sH.Contains($e)){$sH.Add($e)}}}}}catch{}
        if($sH.Count-gt 0){Enq 'Persist' 'Services' 'FOUND' ($sH-join'; ')}else{Enq 'Persist' 'Services' 'CLEAN' 'No suspicious services'}
        $tH=[System.Collections.Generic.List[string]]::new()
        try{Get-ScheduledTask -EA SilentlyContinue|ForEach-Object{$all="$($_.TaskName) "+(($_.Actions|ForEach-Object{"$($_.Execute) $($_.Arguments)"})-join' ')
            foreach($tp in @('BluetoothService','ProShow','USOShared')){if($all-match $tp){$tH.Add($_.TaskName);break}}}}catch{}
        if($tH.Count-gt 0){Enq 'Persist' 'Scheduled tasks' 'FOUND' ($tH-join'; ')}else{Enq 'Persist' 'Scheduled tasks' 'CLEAN' 'No suspicious tasks'}
        Prog 65 'Persistence done'

        Prog 68 'Checking processes...'
        $rp=Get-Process -EA SilentlyContinue|Where-Object{$_.ProcessName-match'BluetoothService|ProShow|ConsoleApplication2'}
        if($rp){Enq 'Process' 'Malicious processes' 'FOUND' "Running: $(($rp|ForEach-Object{"$($_.ProcessName) PID:$($_.Id)"})-join'; ')"}else{Enq 'Process' 'Malicious processes' 'CLEAN' 'None'}
        try{$gp=Get-Process -Name 'GUP' -EA SilentlyContinue;if($gp){$gc=Get-NetTCPConnection -EA SilentlyContinue|Where-Object{($gp.Id)-contains $_.OwningProcess-and $_.RemoteAddress-notin@('0.0.0.0','::','127.0.0.1','::1')}
            if($gc){$c2c=$gc|Where-Object{$c2Ips-contains $_.RemoteAddress};if($c2c){Enq 'Process' 'GUP.exe C2' 'FOUND' "C2: $(($c2c.RemoteAddress|Select-Object -Unique)-join', ')"}else{Enq 'Process' 'GUP.exe connections' 'WARNING' "Active: $(($gc.RemoteAddress|Select-Object -Unique)-join', ')"}}
            else{Enq 'Process' 'GUP.exe' 'CLEAN' 'No remote connections'}}else{Enq 'Process' 'GUP.exe' 'CLEAN' 'Not running'}}catch{Enq 'Process' 'GUP.exe' 'ERROR' "$($_.Exception.Message)"}
        try{$fs=Get-Process -Name 'svchost' -EA SilentlyContinue|Where-Object{try{$_.Path-and $_.Path-match'USOShared'}catch{$false}}
            if($fs){Enq 'Process' 'Fake svchost (TCC)' 'FOUND' "PID: $(($fs.Id)-join', ')"}else{Enq 'Process' 'Fake svchost (TCC)' 'CLEAN' 'None'}}catch{}
        $mf=$false;try{$mx=[System.Threading.Mutex]::OpenExisting('Global\Jdhfv_1.0.1');$mf=$true;$mx.Dispose()}catch [System.Threading.WaitHandleCannotBeOpenedException]{}catch{if($_.Exception.InnerException-is[System.UnauthorizedAccessException]){$mf=$true}}
        if($mf){Enq 'Process' 'Chrysalis mutex' 'FOUND' 'Global\Jdhfv_1.0.1 exists - backdoor active'}else{Enq 'Process' 'Chrysalis mutex' 'CLEAN' 'Not found'}
        Prog 80 'Processes done'

        Prog 83 'Scanning network...'
        try{$cn=Get-NetTCPConnection -EA SilentlyContinue;$ih=$cn|Where-Object{$c2Ips-contains $_.RemoteAddress}|Select-Object RemoteAddress,RemotePort,OwningProcess,State -Unique
            if($ih){$dt=$ih|ForEach-Object{$pn=try{(Get-Process -Id $_.OwningProcess -EA Stop).ProcessName}catch{'?'};"$($_.RemoteAddress):$($_.RemotePort) ($pn)"};Enq 'Network' 'C2 IP connections' 'FOUND' ($dt-join'; ')}
            else{Enq 'Network' 'C2 IP connections' 'CLEAN' 'None'}}catch{Enq 'Network' 'C2 IP connections' 'ERROR' "Elevation needed"}
        try{$dns=Get-DnsClientCache -EA SilentlyContinue;$dh=@();if($dns){$dh=$dns|Where-Object{$e=$_.Entry;foreach($d in $c2Domains){if($e-like"*$d*"){return $true}};return $false}}
            if($dh){$fd=($dh.Entry|Select-Object -Unique)-join', ';$fp=if($fd-match'temp\.sh'){' (temp.sh may be false positive)'}else{''};Enq 'Network' 'DNS cache: C2' 'FOUND' "Resolved: $fd$fp"}else{Enq 'Network' 'DNS cache: C2' 'CLEAN' 'No C2 domains'}}catch{Enq 'Network' 'DNS cache' 'ERROR' "$($_.Exception.Message)"}
        try{$hf="$env:SystemRoot\System32\drivers\etc\hosts";if(Test-Path $hf){$nh=Get-Content $hf -EA Stop|Where-Object{$_-match'notepad'-and $_-notmatch'^\s*#'}
            if($nh){Enq 'Network' 'Hosts file' 'FOUND' "Entries: $($nh-join'; ')"}else{Enq 'Network' 'Hosts file' 'CLEAN' 'No redirections'}}}catch{Enq 'Network' 'Hosts file' 'ERROR' "$($_.Exception.Message)"}
        Prog 100 'Scan complete'
    }catch{Enq 'Error' 'Unhandled' 'ERROR' $_.Exception.Message}
    finally{$sync.Duration=((Get-Date)-$t0).TotalSeconds.ToString('0.00')+'s';$sync.ScanComplete=$true}
}

# === Report builder (shared by Export + Copy -- uses string interpolation, NOT -f operator) ===
function Build-ReportText {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('=' * 80)
    [void]$sb.AppendLine('  Notepad++ Supply Chain IOC Scanner v2.3 - Report')
    [void]$sb.AppendLine('=' * 80)
    [void]$sb.AppendLine("  Machine  : $env:COMPUTERNAME")
    [void]$sb.AppendLine("  User     : $env:USERDOMAIN\$env:USERNAME")
    [void]$sb.AppendLine("  Elevated : $isAdmin")
    [void]$sb.AppendLine("  Scanned  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("  Duration : $($txtDuration.Text)")
    [void]$sb.AppendLine('=' * 80)
    [void]$sb.AppendLine('')
    $curSec = ''
    foreach ($r in $script:resultsCollection) {
        $rSec = [string]$r.Section
        $rChk = [string]$r.Check
        $rSta = [string]$r.Status
        $rDet = [string]$r.Details
        if ($rSec -ne $curSec) { $curSec = $rSec; [void]$sb.AppendLine("--- $curSec ".PadRight(80, '-')) }
        [void]$sb.AppendLine("  $($rChk.PadRight(38)) [$($rSta.PadRight(10))] $rDet")
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('=' * 80)
    [void]$sb.AppendLine("  $($txtSummary.Text)")
    [void]$sb.AppendLine("  $($txtResult.Text)")
    [void]$sb.AppendLine('=' * 80)
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Sources:')
    [void]$sb.AppendLine('  https://securelist.com/notepad-supply-chain-attack/118708/')
    [void]$sb.AppendLine('  https://www.rapid7.com/blog/post/tr-chrysalis-backdoor-dive-into-lotus-blossoms-toolkit/')
    [void]$sb.AppendLine('  https://notepad-plus-plus.org/news/hijacked-incident-info-update/')
    return $sb.ToString()
}

# === Timer ===
$script:timer = New-Object System.Windows.Threading.DispatcherTimer
$script:timer.Interval = [TimeSpan]::FromMilliseconds(80)
$script:timer.Add_Tick({
    $item=$null; while($script:syncHash.ResultQueue.TryDequeue([ref]$item)){$script:resultsCollection.Add($item);$txtPlaceholder.Visibility='Collapsed'}
    $txtProgress.Text=$script:syncHash.ProgressText
    $tw=$progressFill.Parent.ActualWidth; if($tw-gt 0){$progressFill.Width=[Math]::Max(0,($tw*$script:syncHash.ProgressValue/100))}
    if($script:syncHash.ScanComplete-and -not $script:syncHash.ScanRunning){return}
    if($script:syncHash.ScanComplete){
        $script:syncHash.ScanRunning=$false; $script:timer.Stop()
        $btnScan.IsEnabled=$true; $btnExport.IsEnabled=$true; $btnCopy.IsEnabled=$true
        $txtDuration.Text=$script:syncHash.Duration
        $total=$script:resultsCollection.Count
        $found=($script:resultsCollection|Where-Object{$_.Status-eq'FOUND'}).Count
        $warn=($script:resultsCollection|Where-Object{$_.Status-eq'WARNING'}).Count
        $clean=($script:resultsCollection|Where-Object{$_.Status-eq'CLEAN'}).Count
        $errs=($script:resultsCollection|Where-Object{$_.Status-eq'ERROR'}).Count
        $txtSummary.Text="Checks: $total  |  FOUND: $found  |  WARNING: $warn  |  CLEAN: $clean  |  Errors: $errs"
        if($found-gt 0){
            $txtResult.Text="COMPROMISE DETECTED: $found IOC(s)"; $txtResult.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(239,83,80))
            $alertBanner.Visibility='Visible'; $txtAlert.Text="ALERT: $found indicator(s) of compromise. Use 'Remediate IOCs' to clean, or export report first for forensic evidence."
            $btnRemediate.IsEnabled=$true
        }elseif($warn-gt 0){$txtResult.Text="NO IOCs - $warn warning(s)"; $txtResult.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(255,167,38)); $btnRemediate.IsEnabled=$false}
        else{$txtResult.Text='CLEAN: No IOCs detected'; $txtResult.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(76,175,80)); $btnRemediate.IsEnabled=$false}
        $txtScanDate.Text="Scanned: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }
})

# === Run Scan ===
$btnScan.Add_Click({
    $script:resultsCollection.Clear(); $alertBanner.Visibility='Collapsed'
    $txtDetails.Text='Scan running...'; $txtSummary.Text=''; $txtResult.Text=''
    $txtResult.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(136,136,168))
    $txtDuration.Text=''; $progressFill.Width=0; $txtPlaceholder.Visibility='Visible'; $txtPlaceholder.Text='Scanning...'
    $btnScan.IsEnabled=$false; $btnRemediate.IsEnabled=$false; $btnExport.IsEnabled=$false; $btnCopy.IsEnabled=$false
    $script:syncHash.ProgressValue=0; $script:syncHash.ProgressText='Starting...'; $script:syncHash.Duration=''
    $script:syncHash.ScanComplete=$false; $script:syncHash.ScanRunning=$true
    $lo=$null; while($script:syncHash.ResultQueue.TryDequeue([ref]$lo)){}
    $rs=[runspacefactory]::CreateRunspace(); $rs.ApartmentState='STA'; $rs.Open()
    $ps=[powershell]::Create(); $ps.Runspace=$rs
    [void]$ps.AddScript($scanScript); [void]$ps.AddArgument($script:syncHash); [void]$ps.AddArgument($script:iocConfig)
    $ps.BeginInvoke()|Out-Null; $script:scanPS=$ps; $script:scanRS=$rs; $script:timer.Start()
})

# === Remediate ===
$btnRemediate.Add_Click({
    $ioc = $script:iocConfig
    $foundCount = ($script:resultsCollection | Where-Object { $_.Status -eq 'FOUND' }).Count
    $msg = "$foundCount IOC(s) detected. Remediation will:`n`n"
    $msg += "  [KILL]    Terminate malicious processes`n"
    $msg += "  [DELETE]  Remove malware directories (ProShow, Bluetooth) and specific malicious files`n"
    $msg += "            (USOShared directory preserved - only malicious files within it removed)`n"
    $msg += "  [CLEAN]   Remove persistence (registry, services, tasks)`n"
    if ($isAdmin) { $msg += "  [BLOCK]   Create firewall rule blocking $($ioc.C2Ips.Count) C2 IPs`n" }
    else { $msg += "  [SKIP]    Firewall blocking requires elevation`n" }
    $msg += "`nExport the report BEFORE remediating to preserve evidence.`nProceed?"

    $ans = [System.Windows.MessageBox]::Show($msg, 'Confirm Remediation', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($ans -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $log = [System.Collections.Generic.List[string]]::new()

    # Kill processes
    foreach ($pn in $ioc.MalwareProcesses) {
        try { $pp = Get-Process -Name $pn -EA SilentlyContinue
            if ($pp) { $pp | Stop-Process -Force -EA Stop; $log.Add("Killed $pn (PIDs: $(($pp.Id)-join', '))") }
        } catch { $log.Add("Failed to kill $pn - $($_.Exception.Message)") } }
    try { Get-Process -Name 'svchost' -EA SilentlyContinue |
        Where-Object { try{$_.Path-and $_.Path-match'USOShared'}catch{$false} } |
        ForEach-Object { Stop-Process -Id $_.Id -Force -EA Stop; $log.Add("Killed fake svchost PID:$($_.Id)") }
    } catch { $log.Add("Failed killing fake svchost: $($_.Exception.Message)") }

    # Remove directories
    foreach ($d in $ioc.MalwareDirs) {
        if (Test-Path $d) { try { Remove-Item $d -Recurse -Force -EA Stop; $log.Add("Removed directory: $d") } catch { $log.Add("Failed removing $d - $($_.Exception.Message)") } } }

    # Remove individual files
    foreach ($f in $ioc.MalwareFiles) {
        if (Test-Path $f) { try { Remove-Item $f -Force -EA Stop; $log.Add("Removed file: $f") } catch { $log.Add("Failed removing $f - $($_.Exception.Message)") } } }

    # Clean registry
    foreach ($rk in @('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run')) {
        try { if (Test-Path $rk) { (Get-ItemProperty $rk -EA SilentlyContinue).PSObject.Properties |
            Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object { $val = [string]$_.Value
                foreach ($pat in $ioc.PersistencePatterns) { if ($val -match $pat) {
                    Remove-ItemProperty -Path $rk -Name $_.Name -Force -EA Stop
                    $log.Add("Removed registry: $rk\$($_.Name)"); break } } } } } catch { $log.Add("Failed cleaning $rk - $($_.Exception.Message)") } }

    # Remove service
    try { $svc = Get-Service -Name 'BluetoothService' -EA SilentlyContinue
        if ($svc) { if ($svc.Status -eq 'Running') { Stop-Service 'BluetoothService' -Force -EA Stop }
            & sc.exe delete 'BluetoothService' 2>&1 | Out-Null; $log.Add('Removed service: BluetoothService') }
    } catch { $log.Add("Failed removing service: $($_.Exception.Message)") }

    # Remove scheduled tasks
    try { Get-ScheduledTask -EA SilentlyContinue | ForEach-Object {
        $all = "$($_.TaskName) " + (($_.Actions|ForEach-Object{"$($_.Execute) $($_.Arguments)"})-join' ')
        foreach ($tp in @('BluetoothService','ProShow','USOShared')) {
            if ($all -match $tp) { Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -EA Stop
                $log.Add("Removed task: $($_.TaskName)"); break } } }
    } catch { $log.Add("Failed cleaning tasks: $($_.Exception.Message)") }

    # Firewall block
    if ($isAdmin) {
        $ruleName = 'Block NPP Supply Chain C2'
        try { Get-NetFirewallRule -DisplayName $ruleName -EA SilentlyContinue | Remove-NetFirewallRule -EA SilentlyContinue
            New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Action Block `
                -RemoteAddress ($ioc.C2Ips-join',') -Protocol TCP -Enabled True `
                -Description 'Blocks known C2 IPs from NPP supply chain attack' -EA Stop | Out-Null
            $log.Add("Firewall rule created blocking $($ioc.C2Ips.Count) C2 IPs")
        } catch { $log.Add("Failed creating firewall rule: $($_.Exception.Message)") }
    } else { $log.Add('SKIPPED: Firewall block requires elevation') }

    # Add results to grid
    $script:resultsCollection.Add([PSCustomObject]@{Section='Remediate';Check='Summary';Status='REMEDIATED';Details="$($log.Count) action(s) performed"})
    foreach ($entry in $log) {
        $st = if ($entry -match '^(Failed|SKIPPED)') { 'WARNING' } else { 'REMEDIATED' }
        $chk = if ($entry.Length -gt 50) { $entry.Substring(0,50) } else { $entry }
        $script:resultsCollection.Add([PSCustomObject]@{Section='Remediate';Check=$chk;Status=$st;Details=$entry})
    }
    $script:resultsCollection.Add([PSCustomObject]@{Section='Remediate';Check='Next Steps';Status='WARNING';Details='Update Notepad++ to v8.9.1+ from GitHub. Block gup.exe internet access. Re-scan this machine. Rotate credentials. Engage IR team if confirmed incident.'})

    $btnRemediate.IsEnabled = $false
    $txtProgress.Text = 'Remediation complete - re-scan recommended'
    $remed = ($script:resultsCollection | Where-Object { $_.Status -eq 'REMEDIATED' }).Count
    $txtSummary.Text = "$($txtSummary.Text)  |  REMEDIATED: $remed"

    [System.Windows.MessageBox]::Show(
        "Remediation complete.`n`n$($log.Count) actions performed.`n`nRe-scan to verify IOCs are cleared.`n`nAdditional steps:`n  1. Update Notepad++ to v8.9.1+ (GitHub)`n  2. Block gup.exe internet access`n  3. Rotate credentials on this machine`n  4. Check other machines with Notepad++`n  5. Review logs for lateral movement",
        'Remediation Complete', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
})

# === Selection ===
$dataGrid.Add_SelectionChanged({ $sel=$dataGrid.SelectedItem; if($sel){$txtDetails.Text="[$([string]$sel.Section)] $([string]$sel.Check) -- $([string]$sel.Status)`n$([string]$sel.Details)"} })

# === Export ===
$btnExport.Add_Click({
    $dlg=New-Object Microsoft.Win32.SaveFileDialog; $dlg.Filter='Text (*.txt)|*.txt|CSV (*.csv)|*.csv|All (*.*)|*.*'; $dlg.DefaultExt='.txt'
    $dlg.FileName="NPP-IOC_$($env:COMPUTERNAME)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    if($dlg.ShowDialog()-eq $true){try{
        if($dlg.FileName-like'*.csv'){$script:resultsCollection|Export-Csv $dlg.FileName -NoTypeInformation -Encoding UTF8}
        else{(Build-ReportText)|Out-File $dlg.FileName -Encoding UTF8 -Force}
        [System.Windows.MessageBox]::Show("Saved to:`n$($dlg.FileName)",'Export Complete',[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information)|Out-Null
    }catch{[System.Windows.MessageBox]::Show("Export failed: $($_.Exception.Message)",'Export Error',[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error)|Out-Null}}
})

# === Copy ===
$btnCopy.Add_Click({ try{[System.Windows.Clipboard]::SetText((Build-ReportText));$txtProgress.Text='Copied to clipboard'}catch{$txtProgress.Text="Copy failed: $($_.Exception.Message)"} })

# === Links ===
$linkKaspersky.Add_Click({Start-Process 'https://securelist.com/notepad-supply-chain-attack/118708/'})
$linkRapid7.Add_Click({Start-Process 'https://www.rapid7.com/blog/post/tr-chrysalis-backdoor-dive-into-lotus-blossoms-toolkit/'})
$linkOfficial.Add_Click({Start-Process 'https://notepad-plus-plus.org/news/hijacked-incident-info-update/'})

# === Cleanup ===
$window.Add_Closed({if($script:timer){$script:timer.Stop()};try{if($script:scanPS){$script:scanPS.Stop();$script:scanPS.Dispose()};if($script:scanRS){$script:scanRS.Close();$script:scanRS.Dispose()}}catch{}})

$window.ShowDialog() | Out-Null
