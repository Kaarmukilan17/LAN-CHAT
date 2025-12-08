===============================
 LAN CHAT - Version 1 (Stable)
===============================

This version includes a basic working LAN chat system using PowerShell GUI.
It allows sending and receiving text messages over the same Wi-Fi/hotspot LAN.

---------------------------------
 FEATURES
---------------------------------

✔ Send text messages between two PCs on the same network  
✔ Simple graphical interface (no command typing required)  
✔ Sender can send multiple messages without restarting  
✔ Receiver displays the latest received message  
✔ Automatic port rotation on Sender (9999 → 9998 → 9997)  
✔ No admin rights required  
✔ Works over hotspot, Wi-Fi router, or Ethernet LAN  

---------------------------------
 FILES INCLUDED
---------------------------------

1. **receiver_gui.ps1**
   - Runs on the receiving PC.
   - Opens a small window and waits for one message.

2. **sender_gui.ps1**
   - Runs on the sending PC.
   - Lets you enter:
     - Receiver IP address
     - Message text
     - Then send via button

---------------------------------
 HOW TO USE
---------------------------------

1. Make sure both PCs are connected to the same hotspot or Wi-Fi.

2. On receiver PC:
   - Run `receiver_gui.ps1`
   - The window will show:
     "Listening on port 9999..."
   - Leave it open.

3. On sender PC:
   - Run `sender_gui.ps1`
   - Enter the receiver's IPv4 address (found using `ipconfig`)
   - Type a message
   - Click **Send Message**
   - Status will update to show whether delivery succeeded.

4. The receiver will display:
   - "Message Received!"
   - Followed by the message text.

---------------------------------
 NETWORK TIP
---------------------------------

Receiver’s IP should match the IPv4 address under:

> Wi-Fi / Wireless LAN Adapter  
or  
> Mobile Hotspot adapter

Example IP format:  
`192.168.xx.xx` or `10.x.x.x`

---------------------------------
 LIMITATIONS (CURRENT VERSION)
---------------------------------

- Receiver only receives **one message per run**  
- Sender already supports multiple sends
- No message history/logging yet
- No encryption (plaintext LAN traffic)
- Chat is one-way (send → receive only)

---------------------------------
 NEXT IMPROVEMENTS (VERSION 2 PLAN)
---------------------------------

➡ Receiver loops and listens continuously  
➡ Add scrollable chat history display  
➡ Add timestamps  
➡ Improve UI layout  
➡ Make chat 2-way  
➡ Optional message notification sound  
➡ Auto-detect receiver IP on same LAN  

---------------------------------
 SUMMARY
---------------------------------

This version is a working proof of concept.  
Messages CAN be sent and received over LAN using a friendly GUI with no freezing.

It is stable enough to build on for future versions.

---------------------------------
 END OF README
---------------------------------
