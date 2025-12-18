Add-Type -AssemblyName PresentationFramework

# ---- GUI ----
$window = New-Object System.Windows.Window
$window.Title = "LAN Receiver"
$window.Width = 450
$window.Height = 350

$panel = New-Object System.Windows.Controls.StackPanel
$panel.Margin = 10

$lblStatus = New-Object System.Windows.Controls.Label
$lblStatus.FontSize = 16
$lblStatus.Content = "Waiting..."

$txtLog = New-Object System.Windows.Controls.TextBox
$txtLog.FontSize = 14
$txtLog.Height = 250
$txtLog.IsReadOnly = $true
$txtLog.TextWrapping = "Wrap"
$txtLog.VerticalScrollBarVisibility = "Auto"

$panel.Children.Add($lblStatus)
$panel.Children.Add($txtLog)
$window.Content = $panel


# ---- BACKGROUND LISTENER ----
$ps = [PowerShell]::Create()

$script = {
    param($window,$lblStatus,$txtLog)

    $ports = @(9999,9998,9997)

    while ($true) {
        foreach ($port in $ports) {

            try {
               $listener = New-Object System.Net.Sockets.TcpListener([Net.IPAddress]::Any,$port)

$listener.Server.SetSocketOption(
    [System.Net.Sockets.SocketOptionLevel]::Socket,
    [System.Net.Sockets.SocketOptionName]::ReuseAddress,
    $true
)

$listener.Start()


                $window.Dispatcher.Invoke({
                    $lblStatus.Content = "Listening on port $port..."
                })

                # Only continue if someone is trying to connect
                $client = $listener.AcceptTcpClient()
                $stream = $client.GetStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $msg = $reader.ReadToEnd()

                $reader.Close()
                $client.Close()
                $listener.Stop()

                $window.Dispatcher.Invoke({
                    $lblStatus.Content = "Message Received!"
                    $txtLog.AppendText("[$port] $msg`r`n")
                    $txtLog.ScrollToEnd()
                })

            } catch {
                $listener.Stop()
                $window.Dispatcher.Invoke({
                    $lblStatus.Content = "Error: $($_.Exception.Message)"
                })
            }

            Start-Sleep -Milliseconds 200
        }
    }
}

$ps.AddScript($script).AddArgument($window).AddArgument($lblStatus).AddArgument($txtLog) | Out-Null
$ps.BeginInvoke()

# ---- Show GUI ----
$window.ShowDialog() | Out-Null
