LAN CHAT v5  (two laptops, same Wi-Fi / hotspot / Ethernet)
============================================================

FIRST TIME (on each laptop)
 1. Unzip the whole folder (right-click > Extract All). Do not run from inside the zip.
 2. Double-click Setup.bat
 3. Click YES on the Windows prompt (this opens the firewall for the chat ports).
 4. The chat window opens. A "LAN Chat" shortcut is put on the Desktop.

CHATTING
 - The top line "Your IP" is this laptop's address.
 - Type the OTHER laptop's IP in "Peer IP" (read it from their window).
 - Type a message, press Enter (Shift+Enter = new line).
 - Both laptops must have LAN Chat open.

IF IT SAYS "Could not reach"
 - Same Wi-Fi/hotspot on both? (Some public/guest Wi-Fi blocks laptop-to-laptop traffic;
   use a phone hotspot or home router instead.)
 - IP typed correctly? Use the IPv4 shown in the other laptop's window.
 - Run Setup.bat again on BOTH laptops and click Yes on the firewall prompt.
 - If the window never opens: run Start-Chat.bat, or in PowerShell:
     powershell -ExecutionPolicy Bypass -STA -File "%LOCALAPPDATA%\LANChat\chat.ps1"

Ports: 9999, 9998, 9997 (TCP). Messages are not encrypted. Windows only.
