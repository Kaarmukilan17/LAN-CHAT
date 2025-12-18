Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ---- CONSTANTS ----
$maxFileSizeMB = 10
$ports = @(9999, 9998, 9997)

# ---- WINDOW ----
$window = New-Object System.Windows.Window
$window.Title = "LAN Chat v4"
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

# ---- STATUS ----
$lblStatus = New-Object System.Windows.Controls.Label
$lblStatus.Content = "Starting receiver..."
$lblStatus.FontSize = 13

# ---- CHAT LOG ----
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

# ---- BUTTONS ----
$btnSend = New-Object System.Windows.Controls.Button
$btnSend.Content = "Send"
$btnSend.Height = 30
$btnSend.Margin = "0,10,0,0"

$btnSendFile = New-Object System.Windows.Controls.Button
$btnSendFile.Content = "+"
$btnSendFile.Width = 35
$btnSendFile.Height = 30
$btnSendFile.Margin = "5,0,0,0"
$btnSendFile.ToolTip = "Send File"

# ---- SEND MESSAGE ----
$btnSend.Add_Click({
    $msg = $txtMsg.Text.Trim()
    if (-not $msg) { return }

    $time = (Get-Date).ToString("HH:mm:ss")

    foreach ($port in $ports) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient($txtIP.Text.Trim(), $port)
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.AutoFlush = $true

            $writer.Write("MSG|$msg")

            $writer.Close()
            $client.Close()

            $txtLog.AppendText("[$time] You:`r`n$msg`r`n`r`n")
            $txtLog.ScrollToEnd()
            $txtMsg.Clear()
            break
        } catch {}
    }
})

# ---- SEND FILE (HEADER ONLY) ----
$btnSendFile.Add_Click({

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Select a file to send"

    if ($dialog.ShowDialog() -ne "OK") { return }

    $filePath = $dialog.FileName
    $fileInfo = Get-Item -LiteralPath $filePath
    $fileSizeBytes = $fileInfo.Length
    $fileSizeMB = [Math]::Round($fileSizeBytes / 1MB, 2)
    $fileName = [System.IO.Path]::GetFileName($filePath)
    $time = (Get-Date).ToString("HH:mm:ss")

    if ($fileSizeMB -gt $maxFileSizeMB) {
        $txtLog.AppendText(
            "[$time] File rejected:`r`n$fileName ($fileSizeMB MB)`r`nLimit: $maxFileSizeMB MB`r`n`r`n"
        )
        $txtLog.ScrollToEnd()
        return
    }

    $txtLog.AppendText(
        "[$time] You selected file:`r`n$fileName ($fileSizeMB MB)`r`n`r`n"
    )
    $txtLog.ScrollToEnd()

    foreach ($port in $ports) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient($txtIP.Text.Trim(), $port)
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.AutoFlush = $true

            $writer.Write("FILE|$fileName|$fileSizeBytes")

            $writer.Close()
            $client.Close()
            break
        } catch {}
    }
})

# ---- UI LAYOUT ----
$panel.Children.Add($lblIP)
$panel.Children.Add($txtIP)
$panel.Children.Add($lblStatus)
$panel.Children.Add($txtLog)
$panel.Children.Add($lblMsg)
$panel.Children.Add($txtMsg)

$sendRow = New-Object System.Windows.Controls.StackPanel
$sendRow.Orientation = "Horizontal"
$sendRow.Children.Add($btnSend)
$sendRow.Children.Add($btnSendFile)

$panel.Children.Add($sendRow)
$window.Content = $panel

# ---- BACKGROUND LISTENER ----
$ps = [PowerShell]::Create()
$receiveScript = {
    param($window, $txtLog, $lblStatus)

    $ports = @(9999, 9998, 9997)

    while ($true) {
        foreach ($port in $ports) {
            try {
                $listener = New-Object System.Net.Sockets.TcpListener(
                    [Net.IPAddress]::Any, $port
                )
                $listener.Start()

                $window.Dispatcher.Invoke({
                    $lblStatus.Content = "Listening on port $port..."
                })

                $client = $listener.AcceptTcpClient()
                $stream = $client.GetStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $raw = $reader.ReadToEnd()

                $reader.Close()
                $client.Close()
                $listener.Stop()

                $time = (Get-Date).ToString("HH:mm:ss")

                if ($raw.StartsWith("MSG|")) {
                    $text = $raw.Substring(4)
                    $window.Dispatcher.Invoke({
                        $txtLog.AppendText("[$time] Peer:`r`n$text`r`n`r`n")
                        $txtLog.ScrollToEnd()
                    })
                }
                elseif ($raw.StartsWith("FILE|")) {
                    $parts = $raw.Split("|")
                    $fileName = $parts[1]
                    $fileSizeMB = [Math]::Round(([int64]$parts[2]) / 1MB, 2)

                    $window.Dispatcher.Invoke({
                        $txtLog.AppendText(
                            "[$time] Peer wants to send file:`r`n$fileName ($fileSizeMB MB)`r`n`r`n"
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
