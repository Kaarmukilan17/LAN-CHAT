

## 1️⃣ What “protocol” means in *your* LAN Chat

Right now, your app uses **TCP**, which only guarantees this:

> “Bytes sent → bytes received in order”

TCP does **NOT** tell:

* what the bytes mean
* whether they are text or file
* where one message ends and another begins

So **you must define rules** for meaning.
Those rules = **your protocol**.

---

## 2️⃣ Your protocol (simple, explicit, scalable)

We will use **prefix-based framing**.

Every transmission starts with a **type identifier**.

### 🔹 Message Types

| Type   | Meaning                    |
| ------ | -------------------------- |
| `MSG`  | Chat message               |
| `FILE` | File metadata (header)     |
| `DATA` | File binary chunks (later) |
| `ACK`  | Accept / reject (later)    |
| `ERR`  | Error info (later)         |

---

## 3️⃣ Protocol diagram (TEXT FLOW DIAGRAM)

### 🟢 Normal Chat Message

```
Sender
  |
  |  "MSG|Hello how are you?"
  |
Receiver
  |
  |  Parse prefix → MSG
  |  Display as chat message
```

---

### 🟡 File Header (current step)

```
Sender
  |
  |  "FILE|photo.png|42876"
  |
Receiver
  |
  |  Parse prefix → FILE
  |  Show: Incoming file request
```

At this stage:

* ❌ No file bytes yet
* ❌ No auto-download
* ✅ Only metadata

---

### 🔵 File Transfer (next version)

```
Sender
  |
  | "FILE|photo.png|42876"
  |
Receiver
  |
  | "ACK|ACCEPT"
  |
Sender
  |
  | "DATA|<binary chunk 1>"
  | "DATA|<binary chunk 2>"
  | ...
  |
Receiver
  |
  | Reassemble → Save file
```

---

## 4️⃣ Why your current bug is happening (now it will click 💡)

### ❌ Current behavior (problem)

* Messages are sent as plain text
* File headers are also sent as plain text

Receiver does:

```
ReadToEnd()
AppendText()
```

So:

* Sometimes message listener catches file header
* Sometimes file header blocks message port
* Order breaks

👉 **Receiver has no idea what it just received**

---

### ✅ Correct behavior (after protocol)

Receiver does:

```
$data = ReadToEnd()

if ($data starts with "MSG|") {
    show message
}
elseif ($data starts with "FILE|") {
    handle file header
}
```

Now:

* Message never blocks file
* File never blocks message
* Order no longer matters

---

## 5️⃣ Error Log System (from now on)

This is a very professional move 👏

### 📄 `ERROR_LOG.md`

We will maintain **one file**, updated every version.

#### Format (fixed)

```
## Version X.Y

### Issue
- Short description

### Root Cause
- Why it happened

### Fix
- What was changed

### Prevention
- Rule added to avoid repeat
```

---

### 🧾 Example (we will add this soon)

```
## Version 4.1

### Issue
Messages and file headers blocked each other.

### Root Cause
No protocol prefix to distinguish data types.

### Fix
Introduced MSG| and FILE| prefixes.

### Prevention
All future data must start with a type header.
```

This will:

* Help future you
* Help GitHub readers
* Make debugging 10× faster

---

## 6️⃣ What happens next (very important order)

Now that protocol is clear, next steps are **safe**:

1. Add `MSG|` prefix (small change)
2. Update receiver parser
3. Verify:

   * message → works
   * file header → works
   * any order → works
4. Update `ERROR_LOG.md`
5. Commit → tag version
6. Then move to file chunks

---