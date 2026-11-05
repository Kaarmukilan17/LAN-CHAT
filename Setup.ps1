# LAN Chat setup: copies files, opens firewall ports (asks for admin once), makes a desktop shortcut.
$ErrorActionPreference = 'Continue'
$src  = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $env:LOCALAPPDATA 'LANChat'

Write-Host ''
Write-Host '=== LAN Chat setup ===' -ForegroundColor Cyan

# 1. copy files
if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
Copy-Item (Join-Path $src 'chat.ps1') $dest -Force
Copy-Item (Join-Path $src 'README.txt') $dest -Force -ErrorAction SilentlyContinue
Get-ChildItem $dest -File | Unblock-File -ErrorAction SilentlyContinue
Write-Host "[1/3] Installed to $dest"

# 2. firewall (needs admin; Windows will show a Yes/No prompt)
$fwCmd = "Remove-NetFirewallRule -DisplayName 'LAN Chat' -ErrorAction SilentlyContinue; " +
         "New-NetFirewallRule -DisplayName 'LAN Chat' -Direction Inbound -Protocol TCP -LocalPort 9997-9999 -Action Allow -Profile Any | Out-Null"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
try {
    if ($isAdmin) {
        Invoke-Expression $fwCmd
    } else {
        Write-Host '[2/3] Opening firewall ports - click YES on the Windows prompt...'
        Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-Command',$fwCmd
    }
    $rule = Get-NetFirewallRule -DisplayName 'LAN Chat' -ErrorAction SilentlyContinue
    if ($rule) { Write-Host '[2/3] Firewall rule added (TCP 9997-9999).' -ForegroundColor Green }
    else       { Write-Host '[2/3] Firewall rule NOT added. Receiving may be blocked - run Setup again and click Yes.' -ForegroundColor Yellow }
} catch {
    Write-Host '[2/3] Firewall step skipped. Receiving may be blocked - run Setup again and click Yes.' -ForegroundColor Yellow
}

# 3. desktop shortcut
try {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut((Join-Path $desktop 'LAN Chat.lnk'))
    $lnk.TargetPath = 'powershell.exe'
    $lnk.Arguments  = "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$dest\chat.ps1`""
    $lnk.WorkingDirectory = $dest
    $lnk.Save()
    Write-Host '[3/3] Desktop shortcut "LAN Chat" created.' -ForegroundColor Green
} catch {
    Write-Host '[3/3] Could not create shortcut. Use Start-Chat.bat instead.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Done. Starting LAN Chat...' -ForegroundColor Cyan
Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-STA','-WindowStyle','Hidden','-File',"$dest\chat.ps1"
