# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClipMon is a configurable macOS command-line tool that monitors clipboard changes and stores all clipboard text entries in a local SQLite database. The tool runs as a background process, continuously monitoring the system clipboard for text changes and automatically saving them with timestamps and rich metadata. Configuration is handled via YAML files with sensible defaults, and the tool includes command-line options for help, version info, and custom configuration.

## Development Commands

### Building the Project
```bash
# Build the project for Debug configuration
xcodebuild -project ClipMon.xcodeproj -scheme ClipMon -configuration Debug build

# Build the project for Release configuration
xcodebuild -project ClipMon.xcodeproj -scheme ClipMon -configuration Release build

# Clean build folder
xcodebuild -project ClipMon.xcodeproj -scheme ClipMon clean
```

### Running the CLI Tool
```bash
# Basic usage - start monitoring
./ClipMon.app/Contents/MacOS/ClipMon

# Show help
./ClipMon.app/Contents/MacOS/ClipMon --help

# Show version
./ClipMon.app/Contents/MacOS/ClipMon --version

# Use custom config file
./ClipMon.app/Contents/MacOS/ClipMon --config /path/to/config.yaml

# Stop the tool with Ctrl+C
# ClipMon is monitoring clipboard changes. Press Ctrl+C to stop.
```

### Installing the CLI Tool
```bash
# After building, create a symlink for easy access
ln -sf "$PWD/ClipMon.app/Contents/MacOS/ClipMon" /usr/local/bin/clipmon

# Or copy the binary directly
cp "ClipMon.app/Contents/MacOS/ClipMon" /usr/local/bin/clipmon
```

## Code Architecture

### Project Structure
```
ClipMon/
├── .claude/                         # Claude Code configuration
│   └── settings.local.json          # Permitted commands and restrictions
├── .editorconfig                    # Code formatting configuration
├── CLAUDE.md                        # This documentation file
├── ClipMon.xcodeproj/               # Xcode project files
└── ClipMon/                         # Main source code
    ├── main.swift                   # CLI entry point with argument parsing
    ├── ContentView.swift            # ClipboardMonitor class implementation
    └── Configuration.swift          # YAML config management
```

**Source Files:**
- **`main.swift`**: CLI entry point with command-line argument parsing and signal handling
- **`ContentView.swift`**: Contains `ClipboardMonitor` class with SQLite integration (note: legacy filename from SwiftUI conversion)
- **`Configuration.swift`**: YAML configuration management and parsing

### Key Technical Details
- **Framework**: Swift with macOS target, runs as command-line tool
- **Database**: SQLite3 integration for clipboard history storage with rich metadata
- **Monitoring**: NSPasteboard polling every 0.5 seconds for clipboard changes
- **App Detection**: Uses NSWorkspace to identify source applications
- **Language Detection**: NaturalLanguage framework for automatic language recognition
- **Content Analysis**: Automatic classification of URLs, emails, and text types
- **Logging**: Unified Logging System (os_log) with structured categories
- **Security**: Command-line tool runs without sandbox restrictions for direct file system access
- **Configuration**: YAML file parsing with tilde expansion for paths
- **CLI Interface**: Professional command-line interface with help, version, and config options

### Product Type
The project is configured as:
- **Product Type**: Command-line tool (`com.apple.product-type.tool`)
- **Deployment Target**: macOS 15.5+
- **Architecture**: Universal (arm64 and x86_64 support)
- **Dependencies**: Only native macOS frameworks (no external dependencies)

### CLI Interface

ClipMon provides a professional command-line interface with the following options:

**Usage:** `clipmon [OPTIONS]`

**Available Options:**
- `-h, --help`: Show detailed usage information and examples
- `-v, --version`: Display version information
- `-c, --config PATH`: Specify custom configuration file path

**Signal Handling:**
- **SIGINT (Ctrl+C)**: Graceful shutdown with database cleanup
- **SIGTERM**: Graceful shutdown for process management

**Runtime Behavior:**
- Continuous monitoring until interrupted
- Automatic config directory and file creation
- Clear console feedback for start/stop operations

### Database Schema
```sql
CREATE TABLE clipboard_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    app_name TEXT,
    app_bundle_id TEXT,
    timestamp INTEGER,
    character_count INTEGER,
    word_count INTEGER,
    line_count INTEGER,
    content_type TEXT,
    is_url INTEGER DEFAULT 0,
    is_email INTEGER DEFAULT 0,
    language_detected TEXT
);
```

**Field Descriptions:**
- `content`: The actual clipboard text content
- `app_name`: Display name of the source application
- `app_bundle_id`: Bundle identifier of the source application
- `timestamp`: Unix timestamp (seconds since epoch) of when content was copied
- `character_count`: Number of characters in the content
- `word_count`: Number of words in the content
- `line_count`: Number of lines in the content
- `content_type`: Classified type (url, email, short_text, long_text, etc.)
- `is_url`: Boolean flag if content is a valid URL
- `is_email`: Boolean flag if content is a valid email address
- `language_detected`: Auto-detected language using NaturalLanguage framework

## Configuration

### Config File Location
The CLI tool reads configuration from `$HOME/.clipmon/config.yaml` (e.g., `/Users/username/.clipmon/config.yaml` on macOS). If the file doesn't exist, the app will create a sample configuration file with default settings.

### Configuration Options
```yaml
# ClipMon Configuration File
#
# Database path - where clipboard history will be stored
# Use ~ for home directory expansion
database_path: "~/.clipmon/database.sqlite"

# You can also use absolute paths:
# database_path: "/Users/username/Documents/clipboard.sqlite"
```

### Default Settings
- **Config Directory**: `$HOME/.clipmon/` (e.g., `/Users/username/.clipmon/`)
- **Database Path**: `$HOME/.clipmon/database.sqlite`
- **Config File**: `$HOME/.clipmon/config.yaml`

## Code Style

The project uses EditorConfig to maintain consistent formatting across different editors and IDEs.

### EditorConfig Settings

The `.editorconfig` file defines formatting rules for different file types:

- **Swift files**: 4 spaces, UTF-8, LF line endings, 120 character line limit
- **YAML files**: 2 spaces for consistent config file formatting
- **Markdown files**: 2 spaces, preserve trailing whitespace for formatting
- **JSON files**: 2 spaces for readability
- **Xcode files**: Tab indentation (preserves Xcode's native format)

### Editor Support

EditorConfig is supported by:
- **Xcode**: Via EditorConfig plugin or built-in support (Xcode 14+)
- **VS Code**: Built-in support
- **Vim/Neovim**: Via EditorConfig plugin
- **Emacs**: Via EditorConfig package
- **JetBrains IDEs**: Built-in support

## Development Notes

### Current Project State
- **No Test Suite**: The project currently has no test files (unit or UI tests)
- **No Git Ignore**: Consider adding `.gitignore` for Xcode-generated files
- **Self-Contained**: Uses only native macOS frameworks, no external dependencies
- **Modern Xcode Project**: Uses File System Synchronized Root Group structure

### Technical Implementation
- The CLI tool automatically creates the config directory and sample config file on first run
- Uses proper HOME environment variable detection for cross-platform compatibility
- SQLite database location is configurable via YAML config file
- Clipboard monitoring uses `NSPasteboard.changeCount` for efficient change detection
- Rich metadata collection includes source app detection, content analysis, and language detection
- Command-line tool with proper signal handling (SIGINT/SIGTERM) for graceful shutdown
- CLI options: --help, --version, --config for custom configuration files
- Uses NaturalLanguage for language detection
- Content type classification: url, email, short_text, long_text, date_containing, numeric_containing
- Automatic word count, character count, and line count statistics
- Supports tilde (`~`) expansion in file paths

## Metadata Collected

For each clipboard entry, the following metadata is automatically collected:
- **Source Application**: Name and bundle identifier of the app that generated the clipboard content
- **Timestamps**: Precise unix timestamps (seconds since epoch)
- **Content Statistics**: Character count, word count, line count
- **Content Classification**: Automatic detection of URLs, emails, and content types
- **Language Detection**: Uses Apple's NaturalLanguage framework for text longer than 10 characters

## Logging System

ClipMon uses the Unified Logging System (os_log) for structured, performance-optimized logging across all app components.

### Logging Subsystem
**Subsystem**: `me.svshevtsov.ClipMon` (hardcoded, not using Bundle.main.bundleIdentifier)

### Logging Categories

The CLI tool organizes logs into four main categories:

- **`clipboard`**: Clipboard monitoring events, change detection, content processing
- **`database`**: SQLite operations, table creation, data insertion, errors
- **`config`**: Configuration file loading, YAML parsing, directory creation
- **`app`**: General application lifecycle events

### Log Levels

- **`.info`**: Important operational events (startup, config loaded, entries saved)
- **`.debug`**: Detailed diagnostic information (change counts, file paths, metadata)
- **`.error`**: Error conditions (database failures, file I/O errors)
- **`.default`**: Standard informational messages

### Privacy Considerations

- **Public data**: App names, bundle IDs, content types, error messages
- **Private data**: Clipboard content (only first 50 chars in debug logs), file paths
- Uses `%{public}@` and `%{private}@` formatters for proper privacy handling

### Viewing Logs

Use Console.app or command line tools to view ClipMon logs:

```bash
# View all ClipMon logs
log show --predicate 'subsystem == "me.svshevtsov.ClipMon"' --last 1h

# View specific category
log show --predicate 'subsystem == "me.svshevtsov.ClipMon" AND category == "clipboard"' --last 1h

# Stream live logs
log stream --predicate 'subsystem == "me.svshevtsov.ClipMon"'
```
