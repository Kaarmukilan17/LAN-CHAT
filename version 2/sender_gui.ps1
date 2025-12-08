Add-Type -AssemblyName PresentationFramework

# Ports to rotate
$ports = 9999, 9998, 9997

# Create Window
$window = New-Object System.Windows.Window
$window.Title = "LAN Sender"
$window.Width = 450
$window.Height = 250

$panel = New-Object System.Windows.Controls.StackPanel
$panel.Margin = '10'

# IP input
$lblIP = New-Object System.Windows.Controls.Label
$lblIP.Content = "Receiver IP:"
$txtIP = New-Object System.Windows.Controls.TextBox
$txtIP.FontSize = 14

# Message input
$lblMsg = New-Object System.Windows.Controls.Label
$lblMsg.Content = "Message:"
$txtMsg = New-Object System.Windows.Controls.TextBox
$txtMsg.FontSize = 14
$txtMsg.Height = 100
$txtMsg.TextWrapping = "Wrap"

# Status label
$lblStatus = New-Object System.Windows.Controls.Label
$lblStatus.FontSize = 14
$lblStatus.Content = "Status: Idle"

# Send button
$btnSend = New-Object System.Windows.Controls.Button
$btnSend.Content = "Send Message"
$btnSend.Width = 150
$btnSend.Height = 30
$btnSend.Margin = '0,10,0,0'

$panel.Children.Add($lblIP)
$panel.Children.Add($txtIP)
$panel.Children.Add($lblMsg)
$panel.Children.Add($txtMsg)
$panel.Children.Add($btnSend)
$panel.Children.Add($lblStatus)
$window.Content = $panel

# Button click event
$btnSend.Add_Click({
    $ip = $txtIP.Text.Trim()
    $msg = $txtMsg.Text
    if ($ip -eq "" -or $msg -eq "") {
        $lblStatus.Content = "Status: Enter IP and message!"
        return
    }
    $sent = $false
    foreach ($port in $ports) {
        try {
            $lblStatus.Content = "Status: Sending on port $port ..."
            $client = New-Object System.Net.Sockets.TcpClient($ip, $port)
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.AutoFlush = $true
            $writer.Write($msg)
            $writer.Close()
            $client.Close()
            $lblStatus.Content = "Status: Message sent successfully on port $port"
            $sent = $true
            break
        } catch {
            $lblStatus.Content = "Status: Port $port unavailable, trying next..."
        }
    }
    if (-not $sent) { $lblStatus.Content = "Status: Failed to send message!" }
})

# Show window
$window.ShowDialog()
