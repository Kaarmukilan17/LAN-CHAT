========================================
 LAN CHAT – VERSION 2.x
========================================

This project is a simple 1-to-1 LAN messaging tool built using
PowerShell and WPF (GUI).

It allows two Windows computers on the same network to send
and receive messages without the internet.

----------------------------------------
 COMPONENTS
----------------------------------------

1. Receiver – Version 2.1
2. Sender   – Version 2.2

----------------------------------------
 RECEIVER – v2.1
----------------------------------------

FEATURES
--------
- GUI-based message receiver
- Runs continuously (no restart needed)
- Listens on rotating ports:
    9999 → 9998 → 9997 → repeat
- Displays received messages in a scrollable log
- Shows:
    - Timestamp
    - Sender IP address
    - Port number
- Handles multiple messages back-to-back
- No GUI freezing
- Socket reuse enabled for stability

MESSAGE FORMAT
--------------
[HH:mm:ss] [SENDER_IP:PORT]
MESSAGE_TEXT

Example:
[14:06:32] [172.17.182.73:9999]
Hello

HOW TO USE (Receiver)
--------------------
1. Connect both PCs to the same LAN / hotspot
2. Run `receiver.ps1`
3. Keep the window open
4. Status will show which port is being listened to
5. Messages appear automatically when received

----------------------------------------
 SENDER – v2.2
----------------------------------------

FEATURES
--------
- GUI-based message sender
- Sends messages to receiver IP
- Uses automatic port rotation:
    9999 → 9998 → 9997
- Scrollable message history (sender side)
- Timestamp for each sent message
- Clears message input after successful send
- Send button disables during send to prevent duplicates
- Status updates shown in real time

SENDER LOG FORMAT
-----------------
[HH:mm:ss] Sent to IP:PORT
MESSAGE_TEXT

Example:
[14:07:08] Sent to 172.17.182.73:9999
Hello

HOW TO USE (Sender)
------------------
1. Run `sender.ps1`
2. Enter the receiver's IPv4 address
3. Type your message
4. Click "Send Message"
5. Sent messages appear in the log

----------------------------------------
 NETWORK NOTES
----------------------------------------

- Both computers must be on the same local network
- Use `ipconfig` to find the correct IPv4 address
- Common IP ranges:
    192.168.x.x
    172.16–31.x.x
    10.x.x.x

----------------------------------------
 CURRENT LIMITATIONS
----------------------------------------

- One-way messaging (sender → receiver only)
- No file transfer
- No encryption
- No usernames
- Windows only
- PowerShell required

----------------------------------------
 VERSION HISTORY
----------------------------------------

v2.1 (Receiver)
- Continuous listening
- Port rotation
- Message log
- Timestamp + sender IP
- Socket reuse fix

v2.2 (Sender)
- Message history log
- Timestamped messages
- Clear input after send
- Button state handling
- Stable port rotation

----------------------------------------
 FUTURE IDEAS
----------------------------------------

- Two-way chat (single window)
- File transfer
- Message encryption
- UI improvements
- Convert scripts to .exe

----------------------------------------
 SUMMARY
----------------------------------------

Version 2.x provides a stable, GUI-based LAN chat foundation
with proper networking, background processing, and clean UX.

This version is considered STABLE.
----------------------------------------
