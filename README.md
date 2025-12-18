
# LAN Chat 

A peer-to-peer LAN chat application with file transfer capabilities using a custom TCP-based protocol.

## Features

- Real-time text messaging between peers
- File transfer with size limits (10MB max)
- Multi-port fallback system (9999, 9998, 9997)
- Protocol-based communication ensuring data integrity
- Simple WPF-based user interface

## Protocol Specification

### Protocol Version: 1.0

The application implements a custom TCP-based protocol with clear message framing:

### Message Types

1. **Text Messages**
   - Format: `MSG|<message_text>`
   - Example: `MSG|Hello, how are you?`
   - Transmission: Plain text over TCP

2. **File Metadata (Header)**
   - Format: `FILE|<filename>|<filesize_in_bytes>`
   - Example: `FILE|document.pdf|1048576`
   - Purpose: Notify receiver of incoming file transfer

3. **File Data Chunks**
   - Format: Binary transmission with header: `DATA|<filename>|<chunk_number>|<chunk_size>`
   - Example Header: `DATA|document.pdf|1|8192`
   - Transmission: Binary data after header

### Communication Flow

#### Text Messaging
```
Sender: MSG|Hello there
Receiver: [Parses MSG| prefix] → Displays in chat log
```

#### File Transfer
```
1. Sender: FILE|photo.png|42876 (metadata)
2. Receiver: Shows accept/reject dialog
3. If accepted:
   Sender: DATA|photo.png|1|8192 [binary data]
   Sender: DATA|photo.png|2|8192 [binary data]
   ...
   Sender: DATA|photo.png|END|0 (completion marker)
4. Receiver: Saves assembled file
```

## Installation and Usage

### Requirements
- Windows PowerShell 5.1 or later
- .NET Framework 4.5 or later

### Running the Application
1. Copy the script to a PowerShell (.ps1) file
2. Run PowerShell as administrator (for network access)
3. Execute: `powershell -ExecutionPolicy Bypass -File "LAN_Chat_v4.2.ps1"`
4. Repeat on another computer for peer-to-peer communication

### Configuration
- Default peer IP: 127.0.0.1 (localhost for testing)
- Change IP address to target computer's LAN IP
- Ports used: 9999 (primary), 9998 (fallback), 9997 (fallback)

## Technical Details

### Architecture
- **Transport Layer**: TCP sockets for reliable communication
- **Protocol Layer**: Custom prefix-based framing system
- **Presentation Layer**: WPF GUI for user interaction
- **Error Handling**: Multi-port fallback with retry logic

### File Transfer Security
- Maximum file size: 10MB (configurable)
- User must explicitly accept incoming files
- Files saved with original extensions preserved
- Transfer progress monitoring

### Network Resilience
- Three-port redundancy system
- Automatic fallback on connection failure
- Concurrent listening on all ports
- Graceful error recovery

## Error Logging

The application maintains an error log at `ERROR_LOG.md` tracking:
- Protocol version changes
- Issue descriptions and root causes
- Fix implementations
- Prevention measures

## Limitations and Known Issues

1. **Local Network Only**: Designed for LAN environments
2. **No Encryption**: Data transmitted in plain text/binary
3. **Single Session**: One active transfer at a time
4. **Windows Only**: Requires Windows PowerShell and .NET

## Troubleshooting

### Common Issues

1. **Connection Failed**
   - Verify both computers are on same network
   - Check Windows Firewall settings
   - Ensure no antivirus blocking the ports

2. **File Transfer Fails**
   - Verify file size is under 10MB
   - Check disk space on receiving computer
   - Ensure proper file permissions

3. **Protocol Errors**
   - Restart both instances
   - Verify same version is running on both ends
   - Check ERROR_LOG.md for known issues

### Port Configuration
To change ports, modify the `$ports` array in the script:
```powershell
$ports = @(9999, 9998, 9997)  # Change these values
```

## Development Notes

### Protocol Evolution
- Version 1.0: Initial protocol with MSG|, FILE|, DATA| prefixes
- Future versions may add: ACK|, ERR|, encryption, compression

### Code Structure
- Clear separation of protocol handling
- Thread-safe UI updates via Dispatcher
- Modular design for easy feature addition

## License

Free for personal and educational use. Not recommended for sensitive communications.

## Version History

- v4.2: Complete protocol implementation with proper text/binary separation
- v4.1: Initial protocol framework
- v4.0: Basic chat with file transfer (buggy)
- Earlier: Text-only chat versions
```

## **Key Improvements in This Version:**

1. **Complete Protocol Implementation**: Proper MSG|, FILE|, DATA| prefixes
2. **Protocol Separation**: Clear distinction between text and binary transmission paths
3. **Error Log System**: Automatic ERROR_LOG.md creation and maintenance
4. **Chunk-Based Transfer**: Files sent in manageable chunks with progress tracking
5. **Better Error Handling**: Graceful recovery from protocol errors
6. **Professional Documentation**: Comprehensive README with protocol specifications
