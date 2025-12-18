
# README — LAN Chat (Version 4)

## Overview

LAN Chat Version 4 is a peer-to-peer chat application built using PowerShell and WPF.
It allows two computers (or two instances on the same computer) to exchange messages over a local network without using any server.

This version supports two-way messaging in a single unified window that both sends and receives messages automatically.

---

## Features (Version 4)

* Unified Sender and Receiver in one window
* Two-way chat (both peers can send and receive)
* Automatic listening on application startup
* Port rotation for reliability (9999 / 9998 / 9997)
* Clean chat labels (You / Peer)
* Self-echo prevention
* Scrollable chat history
* Timestamped messages
* Works on a single laptop using loopback testing

---

## System Requirements

* Windows 10 or Windows 11
* PowerShell 5 or higher
* No administrator privileges required
* No internet connection required

---

## How to Run

### Step 1: Open PowerShell

Navigate to the folder containing:

```
chat_v4.ps1
```

### Step 2: Run the script

```powershell
.\chat_v4.ps1
```

---

## How to Test

### Testing on One Laptop (Recommended for Development)

1. Open two separate PowerShell windows
2. Run `chat_v4.ps1` in both windows
3. In both windows, set:

```
Peer IP = 127.0.0.1
```

4. Start chatting between the two windows

Notes:

* `127.0.0.1` is the loopback address
* This allows full two-way chat testing on a single machine
* This behavior is expected and correct

---

### Testing on Two Laptops (Same Network)

1. Connect both laptops to the same Wi-Fi or hotspot
2. Find the IP address on each laptop:

```powershell
ipconfig
```

3. In Laptop A, set:

```
Peer IP = Laptop B IPv4 address
```

4. In Laptop B, set:

```
Peer IP = Laptop A IPv4 address
```

---

## Networking Details

* Communication uses TCP sockets
* Ports are rotated automatically in the following order:

```
9999 → 9998 → 9997
```

* One port is used per message
* Ports are released immediately after each message
* Background listener runs without blocking the UI

---

## How It Works (High Level)

1. Application starts
2. Background listener begins listening automatically
3. User types a message and clicks Send
4. Application tries available ports
5. Message is sent to the peer
6. Receiver displays message as "Peer"
7. Sender displays message as "You"
8. Self-sent messages are not duplicated

---

## Known Limitations (Expected at This Stage)

* File transfer is not implemented yet
* Messages are not encrypted
* No usernames (only You / Peer labels)
* Chat history is session-only and not saved

These are planned for future versions.

---

## Roadmap

### Version 5 (Next)

* File transfer (small files only)
* Progress bar
* Chunked file sending
* File size limits

### Version 6 (Future)

* AES encryption
* Optional authentication
* Secure key exchange

---

## Notes for the Developer

* This project is intentionally incremental
* Each version is frozen before adding new features
* Stability is prioritized over features

---
