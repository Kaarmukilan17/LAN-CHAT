Add-Type -AssemblyName PresentationFramework

# ---- GUI ----
$window = New-Object System.Windows.Window
$window.Title = "RX Minimal Test"
$window.Width = 350
$window.Height = 200

$panel = New-Object System.Windows.Controls.StackPanel
$panel.Margin = 10

$lblStatus = New-Object System.Windows.Controls.Label
$lblStatus.FontSize = 16
$lblStatus.Content = "Waiting..."

$txtMsg = New-Object System.Windows.Controls.TextBox
$txtMsg.FontSize = 14
$txtMsg.Height = 80
$txtMsg.IsReadOnly = $true
$txtMsg.TextWrapping = "Wrap"

$panel.Children.Add($lblStatus)
$panel.Children.Add($txtMsg)
$window.Content = $panel


# ---- BACKGROUND TASK (Runspace) ----
$ps = [PowerShell]::Create()

$script = {
    param($window,$lblStatus,$txtMsg)

    try {
        $port = 9999
        $listener = New-Object System.Net.Sockets.TcpListener([Net.IPAddress]::Any,$port)
        $listener.Start()

        $window.Dispatcher.Invoke({ $lblStatus.Content = "Listening on port $port..." })

        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $msg = $reader.ReadToEnd()

        $reader.Close()
        $client.Close()
        $listener.Stop()

        $window.Dispatcher.Invoke({
            $lblStatus.Content = "Message Received!"
            $txtMsg.Text = $msg
        })
    }
    catch {
        $window.Dispatcher.Invoke({
            $lblStatus.Content = "ERROR: $($_.Exception.Message)"
        })
    }
}

$ps.AddScript($script).AddArgument($window).AddArgument($lblStatus).AddArgument($txtMsg) | Out-Null
$async = $ps.BeginInvoke()


# ---- SHOW GUI ----
$window.ShowDialog() | Out-Null
