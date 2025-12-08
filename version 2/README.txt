===============================
 LAN CHAT - Version 2
===============================

This version improves the LAN messaging system with continuous message
receiving, logging, and automatic port rotation, without restarting scripts.

---------------------------------
 NEW FEATURES IN VERSION 2
---------------------------------

✔ Receiver now runs continuously  
✔ Messages are logged in a scrollable chat window  
✔ Automatically cycles ports: 9999 → 9998 → 9997 → repeat  
✔ GUI stays responsive while listening  
✔ Multiple messages can be received in the same session  
✔ No restart required after each message  

---------------------------------
 STATUS OF FILES
---------------------------------

1. **receiver_v2.ps1** ✔ COMPLETE  
   - Runs nonstop  
   - Displays all messages with port info  
   - Shows real-time status: listening / received / error  

2. **sender_v1.ps1** (Temporary)
   - Still works  
   - Sends multiple messages  
   - Already supports port rotation  
   - No chat history yet  

---------------------------------
 HOW TO USE THIS VERSION
---------------------------------

1. Connect both PCs to the same local network or hotspot.

2. Run `receiver_v2.ps1` on the machine you want to receive messages on.
   The window will show:
   > Listening on port 9999...

3. On the sending machine, run the sender script.
   - Enter the receiver's IPv4 address
   - Type a message
   - Click **Send Message**

4. Every new message will appear in the receiver's log automatically.

---------------------------------
 NETWORK REMINDER
---------------------------------

Receiver’s IP must match the correct adapter.
Use `ipconfig` and look for:

- Wi-Fi Adapter
- Mobile Hotspot Adapter

Typical format:  
`192.168.43.xxx` or `10.x.x.x`

---------------------------------
 LIMITATIONS STILL PRESENT
---------------------------------

- Sender still has no chat log  
- Not yet full two-way messaging  
- No timestamps on messages  
- Receiver does not show sender IP (only port)  
- UI is functional but not styled  

---------------------------------
 PLANNED FOR VERSION 3
---------------------------------

➡ Add send history on sender  
➡ Add timestamps on both sides  
➡ Allow receiver to also send (full two-way chat)  
➡ Optionally add sound notification  
➡ Add "clear chat" button  
➡ Improve UI layout  

---------------------------------
 SUMMARY
---------------------------------

Version 2 provides a stable, continuous LAN message receiver with 
automatic port rotation and message history.

It marks the first version that behaves like a simple live chat listener.

---------------------------------
 END OF README
---------------------------------
