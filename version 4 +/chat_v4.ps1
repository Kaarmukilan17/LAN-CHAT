Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ---- CONSTANTS ----
$maxFileSizeMB = 10
$ports = @(9999, 9998, 9997)
$chunkSize = 8192

# ---- WINDOW ----
$window = New-Object System.Windows.Window
$window.Title = "LAN Chat v4.1 (Fixed File Transfer)"
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

# ---- SEND MESSAGE (UNCHANGED) ----
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

# ---- SEND FILE (FIXED VERSION) ----
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
        "[$time] Requesting to send:`r`n$fileName ($fileSizeMB MB)`r`n"
    )
    $txtLog.ScrollToEnd()

    # Send file request (unchanged)
    $requestSent = $false
    foreach ($port in $ports) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient($txtIP.Text.Trim(), $port)
            $stream = $client.GetStream()
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.AutoFlush = $true

            $writer.WriteLine("FILEREQ|$fileName|$fileSizeBytes")

            $writer.Close()
            $client.Close()
            $requestSent = $true
            break
        } catch {}
    }

    if (-not $requestSent) {
        $txtLog.AppendText("Failed to send request.`r`n`r`n")
        $txtLog.ScrollToEnd()
        return
    }

    # Wait for acceptance response
    Start-Sleep -Milliseconds 800

    # FIXED: Send file using proper header/binary separation
    $fileSent = $false
    foreach ($port in $ports) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient($txtIP.Text.Trim(), $port)
            $stream = $client.GetStream()
            
            # FIX 1: Use BinaryWriter for clean separation
            $binaryWriter = New-Object System.IO.BinaryWriter($stream)
            
            # Send header as separate message with length prefix
            $header = "FILEDATA|$fileName|$fileSizeBytes"
            $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
            
            # Write header length (4 bytes) then header bytes
            $binaryWriter.Write($headerBytes.Length)
            $binaryWriter.Write($headerBytes)
            
            # Send actual file content
            $fileStream = [System.IO.File]::OpenRead($filePath)
            $buffer = New-Object byte[] $chunkSize
            $totalSent = 0

            while (($bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $binaryWriter.Write($buffer, 0, $bytesRead)
                $totalSent += $bytesRead
                
                $window.Dispatcher.Invoke({
                    $percent = [Math]::Round(($totalSent / $fileSizeBytes) * 100, 1)
                    $lblStatus.Content = "Sending: $percent%"
                })
            }

            $fileStream.Close()
            $binaryWriter.Flush()
            $stream.Close()
            $client.Close()
            
            $fileSent = $true

            $window.Dispatcher.Invoke({
                $time = (Get-Date).ToString("HH:mm:ss")
                $txtLog.AppendText("[$time] File sent successfully!`r`n`r`n")
                $txtLog.ScrollToEnd()
                $lblStatus.Content = "Listening..."
            })

            break
        } catch {
            $window.Dispatcher.Invoke({
                $lblStatus.Content = "Send failed, retrying..."
            })
        }
    }

    if (-not $fileSent) {
        $window.Dispatcher.Invoke({
            $time = (Get-Date).ToString("HH:mm:ss")
            $txtLog.AppendText("[$time] Failed to send file.`r`n`r`n")
            $txtLog.ScrollToEnd()
            $lblStatus.Content = "Listening..."
        })
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

# ---- BACKGROUND LISTENER (FIXED VERSION) ----
$ps = [PowerShell]::Create()
$receiveScript = {
    param($window, $txtLog, $lblStatus)

    $ports = @(9999, 9998, 9997)
    $chunkSize = 8192

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
                $binaryReader = New-Object System.IO.BinaryReader($stream)

                $time = (Get-Date).ToString("HH:mm:ss")

                # Read the first byte to determine message type
                $firstByte = $binaryReader.PeekChar()
                
                if ($firstByte -eq 77) { # 'M' = MSG (text message)
                    # Text message - read as UTF-8 string
                    $reader = New-Object System.IO.StreamReader($stream)
                    $message = $reader.ReadLine()
                    
                    if ($message.StartsWith("MSG|")) {
                        $text = $message.Substring(4)
                        $window.Dispatcher.Invoke({
                            $txtLog.AppendText("[$time] Peer:`r`n$text`r`n`r`n")
                            $txtLog.ScrollToEnd()
                        })
                    }
                    elseif ($message.StartsWith("FILEREQ|")) {
                        # Handle file request (unchanged)
                        $parts = $message.Split("|")
                        $fileName = $parts[1]
                        $fileSize = [int64]$parts[2]
                        $fileSizeMB = [Math]::Round($fileSize / 1MB, 2)

                        $window.Dispatcher.Invoke({
                            $result = [System.Windows.MessageBox]::Show(
                                "Accept file from peer?`n`nFile: $fileName`nSize: $fileSizeMB MB",
                                "Incoming File",
                                [System.Windows.MessageBoxButton]::YesNo,
                                [System.Windows.MessageBoxImage]::Question
                            )

                            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                                $txtLog.AppendText("[$time] Waiting for file: $fileName`r`n")
                                $txtLog.ScrollToEnd()
                            } else {
                                $txtLog.AppendText("[$time] Rejected file: $fileName`r`n`r`n")
                                $txtLog.ScrollToEnd()
                            }
                        })
                    }
                    $reader.Close()
                }
                else {
                    # Binary data - handle file transfer
                    try {
                        # Read header length
                        $headerLength = $binaryReader.ReadInt32()
                        
                        # Read header bytes
                        $headerBytes = $binaryReader.ReadBytes($headerLength)
                        $header = [System.Text.Encoding]::UTF8.GetString($headerBytes)
                        
                        if ($header.StartsWith("FILEDATA|")) {
                            $parts = $header.Split("|")
                            $fileName = $parts[1]
                            $fileSize = [int64]$parts[2]
                            
                            # Extract file extension
                            $fileExtension = [System.IO.Path]::GetExtension($fileName)

                            $window.Dispatcher.Invoke({
                                $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
                                $saveDialog.FileName = $fileName
                                $saveDialog.Title = "Save received file"
                                
                                # Set filter based on file extension
                                if ($fileExtension) {
                                    $extName = $fileExtension.TrimStart('.')
                                    $saveDialog.Filter = "$extName files (*$fileExtension)|*$fileExtension|All files (*.*)|*.*"
                                    $saveDialog.DefaultExt = $fileExtension
                                } else {
                                    $saveDialog.Filter = "All files (*.*)|*.*"
                                }

                                if ($saveDialog.ShowDialog() -eq "OK") {
                                    $savePath = $saveDialog.FileName
                                    
                                    # Ensure file has correct extension
                                    if ($fileExtension -and -not $savePath.EndsWith($fileExtension)) {
                                        $savePath = $savePath + $fileExtension
                                    }
                                    
                                    try {
                                        $fileStream = [System.IO.File]::Create($savePath)
                                        $totalReceived = 0
                                        $buffer = New-Object byte[] $chunkSize
                                        
                                        # Read remaining file data
                                        while ($totalReceived -lt $fileSize) {
                                            $bytesToRead = [Math]::Min($chunkSize, $fileSize - $totalReceived)
                                            $data = $binaryReader.ReadBytes($bytesToRead)
                                            
                                            if ($data.Length -eq 0) { break }
                                            
                                            $fileStream.Write($data, 0, $data.Length)
                                            $totalReceived += $data.Length
                                            
                                            $percent = [Math]::Round(($totalReceived / $fileSize) * 100, 1)
                                            $lblStatus.Content = "Receiving: $percent%"
                                        }

                                        $fileStream.Close()

                                        $time = (Get-Date).ToString("HH:mm:ss")
                                        $fileSizeMB = [Math]::Round($fileSize / 1MB, 2)
                                        $txtLog.AppendText("[$time] File received successfully!`r`n")
                                        $txtLog.AppendText("Name: $fileName`r`n")
                                        $txtLog.AppendText("Size: $fileSizeMB MB`r`n")
                                        $txtLog.AppendText("Saved to: $savePath`r`n`r`n")
                                        $txtLog.ScrollToEnd()
                                        $lblStatus.Content = "Listening..."

                                    } catch {
                                        $txtLog.AppendText("[$time] Error saving file: $_`r`n`r`n")
                                        $txtLog.ScrollToEnd()
                                    }
                                } else {
                                    $txtLog.AppendText("[$time] Save cancelled by user.`r`n`r`n")
                                    $txtLog.ScrollToEnd()
                                    
                                    # Discard remaining file data if user cancels
                                    $bytesToDiscard = $fileSize
                                    while ($bytesToDiscard -gt 0) {
                                        $chunk = [Math]::Min($chunkSize, $bytesToDiscard)
                                        $binaryReader.ReadBytes($chunk) | Out-Null
                                        $bytesToDiscard -= $chunk
                                    }
                                }
                            })
                        }
                    } catch {
                        $window.Dispatcher.Invoke({
                            $txtLog.AppendText("[$time] Error receiving file: $_`r`n`r`n")
                            $txtLog.ScrollToEnd()
                        })
                    }
                }

                $binaryReader.Close()
                $stream.Close()
                $client.Close()
                $listener.Stop()

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