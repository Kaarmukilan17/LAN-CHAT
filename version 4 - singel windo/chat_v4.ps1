Add-Type -AssemblyName PresentationFramework

# ---- WINDOW ----
$window = New-Object System.Windows.Window
$window.Title = "LAN Chat v4 "
$window.Width = 500
$window.Height = 450

$panel = New-Object System.Windows.Controls.StackPanel
$panel.Margin = 10

# ---- IP INPUT ----
$lblIP = New-Object System.Windows.Controls.Label
$lblIP.Content = "Peer IP:"
$txtIP = New-Object System.Windows.Controls.TextBox
$txtIP.Text = "127.0.0.1"
$txtIP.FontSize = 14

# ---- CHAT LOG ----

# ---- STATUS LABEL (RECEIVE STATUS) ----
$lblStatus = New-Object System.Windows.Controls.Label
$lblStatus.Content = "Starting receiver..."
$lblStatus.FontSize = 13

$txtLog = New-Object System.Windows.Controls.TextBox
$txtLog.FontSize = 14
$txtLog.Height = 250
$txtLog.IsReadOnly = $true
$txtLog.TextWrapping = "Wrap"
$txtLog.VerticalScrollBarVisibility = "Auto"

# ---- MESSAGE INPUT ----
$lblMsg = New-Object System.Windows.Controls.Label
$lblMsg.Content = "Message:"
$txtMsg = New-Object System.Windows.Controls.TextBox
$txtMsg.FontSize = 14
$txtMsg.Height = 60
$txtMsg.TextWrapping = "Wrap"

# ---- SEND BUTTON ----
$btnSend = New-Object System.Windows.Controls.Button
$btnSend.Content = "Send"
$btnSend.Height = 30
$btnSend.Margin = "0,10,0,0"

# ---- TEMP BUTTON ACTION ----
$btnSend.Add_Click({
    $btnSend.IsEnabled = $false

$ip = $txtIP.Text.Trim()
$msg = $txtMsg.Text

if ($ip -eq "" -or $msg -eq "") {
    $btnSend.IsEnabled = $true
    return
}

$ports = @(9999, 9998, 9997)
# Get local IP addresses (for self-echo detection)
$localIPs = [System.Net.Dns]::GetHostAddresses($env:COMPUTERNAME) |
    Where-Object { $_.AddressFamily -eq 'InterNetwork' } |
    ForEach-Object { $_.ToString() }

$localIPs += "127.0.0.1"

$sent = $false
$time = (Get-Date).ToString("HH:mm:ss")

foreach ($port in $ports) {
    try {
        $client = New-Object System.Net.Sockets.TcpClient($ip, $port)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true
        $writer.Write($msg)
        $writer.Close()
        $client.Close()

        $txtLog.AppendText(
           "[$time] You:`r`n$msg`r`n`r`n"
        )
        $txtLog.ScrollToEnd()

        $sent = $true
        $txtMsg.Clear()
        break
    } catch {
        # try next port
    }
}

$btnSend.IsEnabled = $true

})

# ---- ADD TO PANEL ----
$panel.Children.Add($lblIP)
$panel.Children.Add($txtIP)
$panel.Children.Add($lblStatus)
$panel.Children.Add($txtLog)
$panel.Children.Add($lblMsg)
$panel.Children.Add($txtMsg)
$panel.Children.Add($btnSend)

$window.Content = $panel
# ---- AUTO RECEIVE (BACKGROUND LISTENER) ----
$ps = [PowerShell]::Create()

$receiveScript = {
    param($window, $txtLog, $lblStatus)

    $ports = @(9999, 9998, 9997)

    while ($true) {
        foreach ($port in $ports) {
            try {
                $listener = New-Object System.Net.Sockets.TcpListener(
                    [Net.IPAddress]::Any,
                    $port
                )

                $listener.Server.SetSocketOption(
                    [System.Net.Sockets.SocketOptionLevel]::Socket,
                    [System.Net.Sockets.SocketOptionName]::ReuseAddress,
                    $true
                )

                $listener.Start()

                $window.Dispatcher.Invoke({
                    $lblStatus.Content = "Listening on port $port..."
                })

                $client = $listener.AcceptTcpClient()
                $senderIP = $client.Client.RemoteEndPoint.Address.ToString()

                $stream = $client.GetStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $msg = $reader.ReadToEnd()

                $reader.Close()
                $client.Close()
                $listener.Stop()

                $time = (Get-Date).ToString("HH:mm:ss")

          # Ignore messages sent by self (prevent echo)
		if ($localIPs -notcontains $senderIP) {
		    $window.Dispatcher.Invoke({
		        $txtLog.AppendText(
		            "[$time] Peer:`r`n$msg`r`n`r`n"
		        )
	        $txtLog.ScrollToEnd()
		    })
}


            } catch {
                try { $listener.Stop() } catch {}
            }

            Start-Sleep -Milliseconds 200
        }
    }
}

$ps.AddScript($receiveScript).
    AddArgument($window).
    AddArgument($txtLog).
    AddArgument($lblStatus) | Out-Null

$ps.BeginInvoke()

$window.ShowDialog() | Out-Null
