# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClipMon is a configurable macOS background application that monitors clipboard changes and stores all clipboard text entries in a local SQLite database. The app runs as a menu bar extra with minimal UI, continuously monitoring the system clipboard for text changes and automatically saving them with timestamps and deduplication. Configuration is handled via YAML files with sensible defaults.

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

### Running Tests
```bash
# Run unit tests
xcodebuild -project ClipMon.xcodeproj -scheme ClipMon -destination 'platform=macOS' test

# Run only unit tests (excluding UI tests)
xcodebuild -project ClipMon.xcodeproj -scheme ClipMon -destination 'platform=macOS' -only-testing:ClipMonTests test

# Run only UI tests
xcodebuild -project ClipMon.xcodeproj -scheme ClipMon -destination 'platform=macOS' -only-testing:ClipMonUITests test
```

### Running the Application
The application should be run through Xcode for development, or built and run via:
```bash
# Build and run (for development, use Xcode IDE)
xcodebuild -project ClipMon.xcodeproj -scheme ClipMon -configuration Debug
```

## Code Architecture

### Project Structure
- **ClipMon/**: Main application source code
  - `ClipMonApp.swift`: Main app entry point with MenuBarExtra configuration
  - `ContentView.swift`: Contains `ClipboardMonitor` class with SQLite integration
  - `Configuration.swift`: YAML configuration management and parsing
  - `ClipMon.entitlements`: App sandbox entitlements for file access
- **ClipMonTests/**: Unit tests using Swift Testing framework
- **ClipMonUITests/**: UI tests using XCTest framework

### Key Technical Details
- **Framework**: SwiftUI with macOS target, runs as MenuBarExtra
- **Database**: SQLite3 integration for clipboard history storage with rich metadata
- **Monitoring**: NSPasteboard polling every 0.5 seconds for clipboard changes
- **App Detection**: Uses NSWorkspace to identify source applications
- **Language Detection**: NaturalLanguage framework for automatic language recognition
- **Content Analysis**: Automatic classification of URLs, emails, and text types
- **Logging**: Unified Logging System (os_log) with structured categories
- **Security**: App runs in sandbox mode with file read/write permissions
- **Configuration**: YAML file parsing with tilde expansion for paths

### App Entitlements
The app is configured with:
- App Sandbox enabled
- Read-only and read-write access to user-selected files
- Read-write access to Downloads folder

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
The app reads configuration from `$HOME/.clipmon/config.yaml` (e.g., `/Users/username/.clipmon/config.yaml` on Linux, `/Users/username/.clipmon/config.yaml` on macOS). If the file doesn't exist, the app will create a sample configuration file with default settings.

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

- The app automatically creates the config directory and sample config file on first run
- Uses proper HOME environment variable detection for cross-platform compatibility
- SQLite database location is configurable via YAML config file
- Clipboard monitoring uses `NSPasteboard.changeCount` for efficient change detection
- Rich metadata collection includes source app detection, content analysis, and language detection
- Menu bar icon provides basic quit functionality
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

### Logging Categories

The app organizes logs into four main categories:

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
