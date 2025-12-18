

# ERROR_LOG.md

## LAN Chat Project —  Error Log

## Scope

This document records **major technical errors, architectural mistakes, and design fixes** encountered during the development of the LAN Chat project.

**Excluded:**
Startup/shutdown glitches (PowerShell window opening/closing, runspace exit issues) — these are acknowledged once and not repeated.

---

## General Known Issue (Acknowledged Once)

**Issue:**
PowerShell + WPF applications may terminate immediately due to:

* Syntax errors
* Duplicate UI objects
* Exceptions before `ShowDialog()`

**Status:**
Expected during iterative development. Not logged repeatedly.

---

## 1. Receiver Accepted Only One Message

**Symptom:**
Receiver stopped responding after one message and required restart.

**Root Cause:**
`TcpListener.AcceptTcpClient()` executed once without looping.

**Fix:**

* Wrapped listener logic in infinite loop
* Restarted listener after each message
* Added port rotation

**Status:** Resolved

---

## 2. Socket Address Already in Use Error

**Symptom:**

```
Only one usage of each socket address is normally permitted
```

**Root Cause:**
Ports reused too quickly without proper socket options.

**Fix:**

* Enabled `SocketOptionName.ReuseAddress`
* Added small delay between port retries

**Status:** Resolved

---

## 3. Reason for Port Rotation (9999 / 9998 / 9997)

**Problem Addressed:**
Unreliable connection attempts and socket binding failures during rapid send/receive cycles.

**Why a Single Port Was Not Enough:**

* TCP sockets remain in `TIME_WAIT` after closure
* Windows may block immediate reuse of the same port
* Background listeners and foreground senders could conflict

**Design Decision:**
Rotate across multiple ports to:

* Avoid `Address already in use` errors
* Allow sender and receiver to recover automatically
* Reduce dependency on precise socket timing

**How It Works:**

* Sender attempts ports in sequence: `9999 → 9998 → 9997`
* Receiver listens in the same rotating order
* First available port is used per message

**Trade-off:**
Slightly increased complexity, significantly improved reliability.

**Status:** Intentional and stable design choice

---

## 4. Self-Echo (Duplicate Messages)

**Symptom:**
Sender received its own message as Peer.

**Root Cause:**
Receiver accepted connections from same machine during loopback testing.

**Fix:**

* Collected local IPv4 addresses
* Ignored messages where sender IP matched local IP

**Status:** Resolved

---

## 5. WPF Visual Already Has a Parent

**Symptom:**

```
Specified Visual is already a child of another Visual
```

**Root Cause:**
Same UI controls added multiple times due to copy-paste edits.

**Fix:**

* Ensured each UI element is created once
* Ensured each element is added to panel only once

**Status:** Resolved

---

## 6. Script Opened and Closed Immediately

**Symptom:**
GUI flashed briefly and exited.

**Root Cause:**

* Syntax errors
* Missing brackets
* Unicode/emoji parsing issues

**Fix:**

* Ran script from PowerShell to inspect errors
* Fixed syntax before UI initialization

**Status:** Resolved

---

## 7. File Picker Worked but Nothing Was Sent

**Symptom:**
File selection logged but peer received nothing.

**Root Cause:**
Send File button implemented as UI-only without networking logic.

**Fix:**

* Implemented file header transmission (`FILE|name|size`)
* Deferred actual file data transfer

**Status:** Expected behavior (by design)

---

## 8. File Size Missing or Incorrect

**Symptom:**
Displayed as `(MB)` with no numeric value.

**Root Cause:**

* File size calculated after logging
* Variables used before assignment

**Fix:**

* Used `Get-Item` → `.Length`
* Converted bytes to MB before UI log

**Status:** Resolved

---

## 9. File Size Limit Not Enforced

**Symptom:**
Large files allowed without rejection.

**Root Cause:**

* `$maxFileSizeMB` undefined
* Guard clause placed after logging

**Fix:**

* Defined `$maxFileSizeMB` globally
* Added early return guard clause

**Status:** Resolved

---

## 10. All Files Rejected (Including Small Files)

**Symptom:**
Even very small files were rejected.

**Root Cause:**
`$maxFileSizeMB` was `$null`, causing incorrect comparisons.

**Fix:**
Explicitly defined:

```powershell
$maxFileSizeMB = 10
```

**Status:** Resolved

---

## 11. Message and File Logic Interfered

**Symptom:**

* Sending a file broke chat
* Sending chat broke file handling
* Order of operations mattered

**Root Cause (Critical):**
Same TCP stream used for different data types without identification.

**Fix (Major Architectural Change):**
Introduced **protocol prefixes**:

```
MSG|<text>
FILE|<filename>|<size>
```

Receiver parses prefixes and routes logic accordingly.

**Status:** Resolved (Major milestone)

---

## 12. Rejected Files Still Sent Headers

**Symptom:**
File rejected locally but peer still received header.

**Root Cause:**
Header send logic executed even after rejection.

**Fix:**

* Added immediate `return` after rejection
* Header send only after size validation

**Status:** Resolved

---

## 13. Messages Not Sent After File Header

**Symptom:**
After sending a file header, chat messages stopped working.

**Root Cause:**
Receiver treated all incoming data as plain text.

**Fix:**

* Implemented protocol prefix parsing
* Separated message and file handling paths

**Status:** Resolved

---

## 14. Protocol Prefixes Visible in UI

**Symptom:**
UI displayed `MSG|hello` or `FILE|name|size`.

**Root Cause:**
Prefix not stripped before rendering.

**Fix:**

* Receiver removes protocol prefix
* UI displays clean human-readable content

**Status:** Resolved

---

## Summary of Major Improvements

* Migration from raw TCP text → structured application protocol
* Unified sender/receiver architecture
* Reliable loopback testing (`127.0.0.1`)
* Guard-clause-driven error prevention
* Port-rotation-based socket reliability
* Clear separation of UI, protocol, and transport layers

---

## Current Status

**Stable baseline achieved:**

* Two-way chat
* File selection UI
* File size validation
* File header exchange
* Protocol-safe communication

**Next Planned Step:**

* Chunked file transfer
* Progress bar
* Resume-safe design

---

**End of Error Log**
