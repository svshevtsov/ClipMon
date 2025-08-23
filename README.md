# ClipMon

A modern macOS command-line tool that monitors clipboard changes and stores all clipboard text entries in a local SQLite database with rich metadata collection.

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org/)
[![Platform](https://img.shields.io/badge/platform-macOS%2015.5+-lightgrey.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Features

- 📋 **Real-time Clipboard Monitoring** - Continuously monitors system clipboard for text changes
- 🗃️ **SQLite Database Storage** - Stores clipboard history with comprehensive metadata
- 🎯 **Smart Content Detection** - Automatically detects URLs, emails, and content types
- 🌍 **Language Detection** - Uses Apple's NaturalLanguage framework for automatic language recognition
- 📱 **App Source Tracking** - Identifies which application generated the clipboard content
- ⚡ **Modern Async Architecture** - Built with Swift's async/await concurrency model
- 🛠️ **Professional CLI Interface** - Powered by Swift Argument Parser
- 🔧 **YAML Configuration** - Flexible configuration with sensible defaults
- 🛡️ **Graceful Signal Handling** - Proper shutdown on SIGINT/SIGTERM with cleanup

## Installation

### Prerequisites

- macOS 15.5 or later
- Xcode 16.4 or later (for building from source)

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/clipmon.git
cd clipmon

# Build with Xcode
xcodebuild -project ClipMon.xcodeproj -scheme ClipMon -configuration Release build

# Install to /usr/local/bin (optional)
sudo cp "/path/to/DerivedData/ClipMon/Build/Products/Release/ClipMon" /usr/local/bin/clipmon
```

## Usage

### Basic Commands

```bash
# Start monitoring clipboard
clipmon

# Show help
clipmon --help

# Show version
clipmon --version

# Use custom configuration file
clipmon --config /path/to/config.yaml

# Enable verbose logging
clipmon --verbose

# Stop monitoring (Ctrl+C)
^C  # Graceful shutdown with cleanup
```

### Example Output

```
ClipMon is monitoring clipboard changes. Press Ctrl+C to stop.

^C
Received SIGINT, shutting down gracefully...
```

## Configuration

### Default Configuration

ClipMon creates a configuration directory at `~/.clipmon/` on first run:

```
~/.clipmon/
├── config.yaml          # Configuration file
└── database.sqlite      # SQLite database
```

### Configuration File

Edit `~/.clipmon/config.yaml` to customize settings:

```yaml
# ClipMon Configuration File
# Database path - where clipboard history will be stored
database_path: "~/.clipmon/database.sqlite"

# You can also use absolute paths:
# database_path: "/Users/username/Documents/clipboard.sqlite"
```

## Database Schema

ClipMon stores clipboard entries with comprehensive metadata:

```sql
CREATE TABLE clipboard_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,                 -- The clipboard text content
    app_name TEXT,                        -- Source application name
    app_bundle_id TEXT,                   -- Source application bundle ID
    timestamp INTEGER,                    -- Unix timestamp
    character_count INTEGER,              -- Number of characters
    word_count INTEGER,                   -- Number of words
    line_count INTEGER,                   -- Number of lines
    content_type TEXT,                    -- Content classification
    is_url INTEGER DEFAULT 0,            -- URL detection flag
    is_email INTEGER DEFAULT 0,          -- Email detection flag
    language_detected TEXT               -- Auto-detected language
);
```

### Content Types

ClipMon automatically classifies clipboard content:

- `url` - Valid HTTP/HTTPS URLs
- `email` - Valid email addresses  
- `date_containing` - Text containing date patterns
- `numeric_containing` - Text containing numbers
- `long_text` - Text over 100 characters or multiple lines
- `short_text` - Short text snippets

## Architecture

### Modern Swift Concurrency

ClipMon uses modern Swift concurrency features:

- **AsyncSignalHandler** - Custom actor for safe signal handling with async/await
- **Task-based Architecture** - Leverages Swift's structured concurrency
- **Thread-safe Operations** - Actor-based design prevents race conditions

### Key Components

```
ClipMon/
├── main.swift              # CLI entry point with ArgumentParser
├── ContentView.swift       # ClipboardMonitor class (legacy filename)
└── Configuration.swift     # YAML configuration management
```

**Core Classes:**

- `ClipMon` - Main CLI command structure using Swift Argument Parser
- `AsyncSignalHandler` - Modern async-based signal handling actor
- `ClipboardMonitor` - NSPasteboard monitoring with SQLite integration
- `ConfigurationManager` - YAML config parsing and management

### Dependencies

- **Swift Argument Parser** - Professional CLI argument parsing
- **Native macOS Frameworks** - AppKit, Foundation, NaturalLanguage, SQLite3
- **No External Dependencies** - Self-contained with system frameworks only

## Development

### Building

```bash
# Debug build
xcodebuild -project ClipMon.xcodeproj -scheme ClipMon -configuration Debug build

# Release build  
xcodebuild -project ClipMon.xcodeproj -scheme ClipMon -configuration Release build

# Clean
xcodebuild -project ClipMon.xcodeproj -scheme ClipMon clean
```

### Project Structure

```
ClipMon/
├── README.md                           # This file
├── CLAUDE.md                          # Claude Code documentation
├── .editorconfig                      # Code formatting rules
├── ClipMon.xcodeproj/                # Xcode project
│   ├── project.pbxproj               # Project configuration
│   └── project.xcworkspace/          # Workspace with Swift packages
└── ClipMon/                          # Source code
    ├── main.swift                    # CLI entry point
    ├── ContentView.swift             # ClipboardMonitor implementation
    └── Configuration.swift           # Configuration management
```

### Code Style

The project uses EditorConfig for consistent formatting:

- **Swift files**: 4 spaces, 120 character limit, UTF-8
- **YAML files**: 2 spaces for configuration files
- **Markdown files**: 2 spaces, preserve trailing whitespace

### Logging

ClipMon uses the Unified Logging System with structured categories:

```bash
# View all ClipMon logs
log show --predicate 'subsystem == "me.svshevtsov.ClipMon"' --last 1h

# View specific category logs
log show --predicate 'subsystem == "me.svshevtsov.ClipMon" AND category == "clipboard"' --last 1h

# Stream live logs
log stream --predicate 'subsystem == "me.svshevtsov.ClipMon"'
```

**Log Categories:**
- `clipboard` - Monitoring events and content processing
- `database` - SQLite operations and data storage
- `config` - Configuration loading and parsing
- `app` - Application lifecycle events

## Privacy & Security

- **Local Storage Only** - All data stays on your Mac
- **No Network Access** - No data transmission or cloud storage
- **Privacy-Aware Logging** - Sensitive data marked as private in logs
- **Configurable Location** - Choose where to store your clipboard history

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Swift API Design Guidelines
- Use modern Swift concurrency (async/await, actors)
- Maintain EditorConfig formatting standards
- Add comprehensive logging with appropriate privacy levels
- Test signal handling and graceful shutdown scenarios

## Technical Details

### Performance

- **Efficient Polling** - Uses `NSPasteboard.changeCount` for minimal overhead
- **Structured Concurrency** - Async/await prevents blocking operations
- **SQLite Optimization** - Prepared statements and batch operations
- **Memory Safety** - Actor-based design with weak references

### Compatibility

- **Universal Binary** - Supports both Intel and Apple Silicon Macs
- **System Integration** - Uses native macOS APIs for reliability
- **Sandboxing** - Runs as command-line tool without sandbox restrictions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Swift Argument Parser](https://github.com/apple/swift-argument-parser)
- Uses Apple's NaturalLanguage framework for language detection
- Inspired by the need for better clipboard management on macOS