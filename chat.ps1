# LAN Chat v5 - two-way chat between Windows PCs on the same network.
# Ports 9999 / 9998 / 9997 (all listened at once). No admin needed to run.

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$ErrorActionPreference = 'Stop'
$ports   = @(9999, 9998, 9997)
$cfgDir  = Join-Path $env:APPDATA 'LANChat'
$cfgFile = Join-Path $cfgDir 'settings.txt'
$maxMsg  = 1MB

try {

# ---------- settings (peer IP + name remembered) ----------
function Load-Settings {
    $s = @{ peer = ''; name = $env:USERNAME }
    if (Test-Path $cfgFile) {
        foreach ($line in Get-Content $cfgFile) {
            $kv = $line -split '=', 2
            if ($kv.Count -eq 2 -and $s.ContainsKey($kv[0])) { $s[$kv[0]] = $kv[1].Trim() }
        }
    }
    return $s
}
function Save-Settings($peer, $name) {
    try {
        if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir | Out-Null }
        Set-Content -Path $cfgFile -Value @("peer=$peer", "name=$name")
    } catch {}
}

# ---------- this PC's LAN addresses ----------
function Get-LocalIPs {
    $list = @()
    foreach ($nic in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
        if ($nic.OperationalStatus -ne 'Up') { continue }
        if ($nic.NetworkInterfaceType -eq 'Loopback') { continue }
        foreach ($ua in $nic.GetIPProperties().UnicastAddresses) {
            if ($ua.Address.AddressFamily -eq 'InterNetwork') {
                $ip = $ua.Address.ToString()
                if (-not $ip.StartsWith('169.254.')) { $list += $ip }
            }
        }
    }
    return $list
}

# ---------- framing: 4-byte length (big-endian) + UTF-8 payload ----------
function Read-Exact($stream, [int]$count) {
    $buf = New-Object byte[] $count
    $got = 0
    while ($got -lt $count) {
        $n = $stream.Read($buf, $got, $count - $got)
        if ($n -le 0) { throw 'connection closed early' }
        $got += $n
    }
    return ,$buf
}
function Write-Frame($stream, [string]$text) {
    $payload = [System.Text.Encoding]::UTF8.GetBytes($text)
    $len = $payload.Length
    $hdr = New-Object byte[] 4
    $hdr[0] = [byte](($len -shr 24) -band 255)
    $hdr[1] = [byte](($len -shr 16) -band 255)
    $hdr[2] = [byte](($len -shr 8) -band 255)
    $hdr[3] = [byte]($len -band 255)
    $stream.Write($hdr, 0, 4)
    $stream.Write($payload, 0, $payload.Length)
    $stream.Flush()
}
function Read-Frame($stream) {
    $h = Read-Exact $stream 4
    $len = ([int]$h[0] -shl 24) -bor ([int]$h[1] -shl 16) -bor ([int]$h[2] -shl 8) -bor [int]$h[3]
    if ($len -lt 0 -or $len -gt $maxMsg) { throw 'bad frame size' }
    $p = Read-Exact $stream $len
    return [System.Text.Encoding]::UTF8.GetString($p)
}

# ---------- window ----------
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="LAN Chat v5.1" Width="520" Height="560" MinWidth="380" MinHeight="400"
        WindowStartupLocation="CenterScreen">
  <Grid Margin="10">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="Auto"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <TextBlock Grid.Row="0" Grid.Column="0" Text="Your IP:" Margin="0,0,8,6" VerticalAlignment="Center"/>
    <TextBox   Grid.Row="0" Grid.Column="1" Name="txtMyIP" IsReadOnly="True" FontSize="14" FontWeight="Bold" Margin="0,0,0,6" Padding="3"/>

    <TextBlock Grid.Row="1" Grid.Column="0" Text="Peer IP:" Margin="0,0,8,6" VerticalAlignment="Center"/>
    <TextBox   Grid.Row="1" Grid.Column="1" Name="txtPeer" FontSize="14" Margin="0,0,0,6" Padding="3"/>

    <TextBlock Grid.Row="2" Grid.Column="0" Text="Your name:" Margin="0,0,8,6" VerticalAlignment="Center"/>
    <TextBox   Grid.Row="2" Grid.Column="1" Name="txtName" FontSize="14" Margin="0,0,0,6" Padding="3"/>

    <TextBox Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="2" Name="txtLog" FontSize="14"
             IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Margin="0,0,0,6" Padding="4"/>

    <Grid Grid.Row="4" Grid.Column="0" Grid.ColumnSpan="2">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="Auto"/>
      </Grid.ColumnDefinitions>
      <TextBox Grid.Row="0" Grid.Column="0" Name="txtMsg" FontSize="14" Height="56" TextWrapping="Wrap"
               AcceptsReturn="True" VerticalScrollBarVisibility="Auto" Padding="3"/>
      <Button  Grid.Row="0" Grid.Column="1" Name="btnSend" Content="Send" Width="80" Margin="6,0,0,0" FontSize="14"/>
      <TextBlock Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="2" Name="lblStatus" Margin="0,6,0,0" Foreground="#555555" TextWrapping="Wrap"/>
    </Grid>
  </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
$txtMyIP  = $window.FindName('txtMyIP')
$txtPeer  = $window.FindName('txtPeer')
$txtName  = $window.FindName('txtName')
$txtLog   = $window.FindName('txtLog')
$txtMsg   = $window.FindName('txtMsg')
$btnSend  = $window.FindName('btnSend')
$lblStatus = $window.FindName('lblStatus')

$settings = Load-Settings
$txtPeer.Text = $settings.peer
$txtName.Text = $settings.name
$myIPs = Get-LocalIPs
if ($myIPs.Count -gt 0) { $txtMyIP.Text = ($myIPs -join '   ') } else { $txtMyIP.Text = '(not connected to a network)' }

function Log([string]$text) {
    $txtLog.AppendText($text + "`r`n")
    $txtLog.ScrollToEnd()
}

# ---------- listeners (all ports open the whole time) ----------
$listeners = @()
foreach ($p in $ports) {
    try {
        $l = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Any, $p)
        $l.Start()
        $listeners += $l
    } catch {}
}
if ($listeners.Count -gt 0) {
    $lblStatus.Text = 'Listening on port(s): ' + (($listeners | ForEach-Object { $_.LocalEndpoint.Port }) -join ', ') + '.  Enter your friend''s IP above and start chatting.'
} else {
    $lblStatus.Text = 'ERROR: could not listen on any port (is another copy already open?). You can still send.'
}

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(150)
$timer.Add_Tick({
    foreach ($l in $listeners) {
        try {
            while ($l.Pending()) {
                $client = $l.AcceptTcpClient()
                try {
                    $client.ReceiveTimeout = 3000
                    $stream = $client.GetStream()
                    $data = Read-Frame $stream
                    $from = ([System.Net.IPEndPoint]$client.Client.RemoteEndPoint).Address.ToString()
                    if ($data.StartsWith('MSG|')) {
                        $parts = $data.Split([char[]]@('|'), 3)
                        if ($parts.Count -eq 3) {
                            $who = $parts[1]; $body = $parts[2]
                        } else {
                            $who = 'Peer'; $body = $data.Substring(4)
                        }
                        $time = (Get-Date).ToString('HH:mm:ss')
                        Log "[$time] $who ($from):`r`n$body`r`n"
                        [System.Media.SystemSounds]::Asterisk.Play()
                        if (-not $window.IsActive) { $window.Title = 'LAN Chat v5.1  *new message*' }
                        if ([string]::IsNullOrWhiteSpace($txtPeer.Text)) { $txtPeer.Text = $from }
                    }
                } catch {
                    # ignore a broken/partial connection, keep listening
                } finally {
                    try { $client.Close() } catch {}
                }
            }
        } catch {}
    }
})
$timer.Start()

$window.Add_Activated({ $window.Title = 'LAN Chat v5.1' })

# ---------- sending ----------
function Send-Message {
    $peer = $txtPeer.Text.Trim()
    $name = $txtName.Text.Trim().Replace('|', '')
    $msg  = $txtMsg.Text.TrimEnd()
    if ([string]::IsNullOrWhiteSpace($msg)) { return }
    if ($peer -eq '') { $lblStatus.Text = 'Enter the other laptop''s IP address first.'; return }
    if ($name -eq '') { $name = 'Me' }

    $btnSend.IsEnabled = $false
    $lblStatus.Text = "Sending to $peer ..."

    $sent = $false
    $lastErr = ''
    foreach ($port in $ports) {
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $iar = $client.BeginConnect($peer, $port, $null, $null)
            if (-not $iar.AsyncWaitHandle.WaitOne(1500)) { throw 'timed out' }
            $client.EndConnect($iar)
            $stream = $client.GetStream()
            Write-Frame $stream ("MSG|$name|$msg")
            $sent = $true
            break
        } catch {
            $lastErr = $_.Exception.Message
        } finally {
            try { $client.Close() } catch {}
        }
    }

    if ($sent) {
        $time = (Get-Date).ToString('HH:mm:ss')
        Log "[$time] You:`r`n$msg`r`n"
        $txtMsg.Clear()
        $lblStatus.Text = "Sent to $peer."
        Save-Settings $peer $name
    } else {
        $lblStatus.Text = "Could not reach $peer ($lastErr). Check: same Wi-Fi, correct IP, other laptop has LAN Chat open, firewall allowed (run Setup)."
    }
    $btnSend.IsEnabled = $true
    $txtMsg.Focus() | Out-Null
}

$btnSend.Add_Click({ Send-Message })
$txtMsg.Add_PreviewKeyDown({
    param($s, $e)
    if ($e.Key -eq 'Return' -and -not ([System.Windows.Input.Keyboard]::Modifiers -band [System.Windows.Input.ModifierKeys]::Shift)) {
        $e.Handled = $true
        Send-Message
    }
})

$window.Add_Closing({
    try { $timer.Stop() } catch {}
    Save-Settings $txtPeer.Text.Trim() $txtName.Text.Trim()
    foreach ($l in $listeners) { try { $l.Stop() } catch {} }
})
$window.Add_ContentRendered({ $txtMsg.Focus() | Out-Null })

$window.ShowDialog() | Out-Null

} catch {
    [System.Windows.MessageBox]::Show("LAN Chat failed to start:`n`n$($_.Exception.Message)`n`n$($_.ScriptStackTrace)", 'LAN Chat error') | Out-Null
}
