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
- **Database**: SQLite3 integration for clipboard history storage
- **Monitoring**: NSPasteboard polling every 0.5 seconds for clipboard changes  
- **Security**: App runs in sandbox mode with file read/write permissions
- **Deduplication**: Uses SHA-256 hashing to prevent duplicate entries
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
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,  
    content_hash TEXT UNIQUE
);
```

## Configuration

### Config File Location
The app reads configuration from `~/.clipmon/config.yaml`. If the file doesn't exist, the app will create a sample configuration file with default settings.

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
- **Config Directory**: `~/.clipmon/`
- **Database Path**: `~/.clipmon/database.sqlite`
- **Config File**: `~/.clipmon/config.yaml`

## Development Notes

- The app automatically creates the config directory and sample config file on first run
- SQLite database location is configurable via YAML config file
- Clipboard monitoring uses `NSPasteboard.changeCount` for efficient change detection
- Menu bar icon provides basic quit functionality
- SHA-256 content hashing prevents duplicate clipboard entries from being stored
- Uses CommonCrypto for hash generation
- Supports tilde (`~`) expansion in file paths