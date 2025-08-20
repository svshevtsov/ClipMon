//
//  ClipboardMonitor.swift
//  ClipMon
//
//  Created by Sergey Shevtsov on 20.08.2025.
//

import Foundation
import AppKit
import SQLite3
import NaturalLanguage
import os.log

// MARK: - Logging Categories
extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let clipboard = OSLog(subsystem: subsystem, category: "clipboard")
    static let database = OSLog(subsystem: subsystem, category: "database")
    static let config = OSLog(subsystem: subsystem, category: "config")
    static let app = OSLog(subsystem: subsystem, category: "app")
}

struct ClipboardEntry {
    let content: String
    let contentHash: String
    let appName: String?
    let appBundleId: String?
    let timestamp: Date
    let characterCount: Int
    let wordCount: Int
    let lineCount: Int
    let contentType: String
    let isURL: Bool
    let isEmail: Bool
    let languageDetected: String?
}

class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var database: OpaquePointer?
    private let configuration: ClipMonConfiguration

    init() {
        self.configuration = ConfigurationManager.loadConfiguration()
        ConfigurationManager.createSampleConfig()
        setupDatabase()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
        sqlite3_close(database)
    }

    private func setupDatabase() {
        let expandedPath = NSString(string: configuration.databasePath).expandingTildeInPath
        let databaseURL = URL(fileURLWithPath: expandedPath)

        // Create directory if it doesn't exist
        let databaseDir = databaseURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: databaseDir.path) {
            do {
                try FileManager.default.createDirectory(at: databaseDir, withIntermediateDirectories: true, attributes: nil)
                os_log("Created database directory", log: .database, type: .info)
                os_log("Directory path: %{public}@", log: .database, type: .debug, databaseDir.path)
            } catch {
                os_log("Failed to create database directory: %{public}@", log: .database, type: .error, error.localizedDescription)
            }
        }

        if sqlite3_open(databaseURL.path, &database) == SQLITE_OK {
            os_log("Database opened successfully", log: .database, type: .info)
            os_log("Database path: %{public}@", log: .database, type: .debug, databaseURL.path)
            createTable()
        } else {
            os_log("Failed to open database", log: .database, type: .error)
            os_log("Database path: %{public}@", log: .database, type: .debug, databaseURL.path)
        }
    }

    private func createTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS clipboard_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content TEXT NOT NULL,
                content_hash TEXT UNIQUE,
                app_name TEXT,
                app_bundle_id TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                character_count INTEGER,
                word_count INTEGER,
                line_count INTEGER,
                content_type TEXT,
                is_url INTEGER DEFAULT 0,
                is_email INTEGER DEFAULT 0,
                language_detected TEXT
            );
        """

        if sqlite3_exec(database, createTableSQL, nil, nil, nil) != SQLITE_OK {
            os_log("Failed to create database table", log: .database, type: .error)
            if let errorMsg = sqlite3_errmsg(database) {
                os_log("SQLite error: %{public}s", log: .database, type: .error, errorMsg)
            }
        } else {
            os_log("Database table created successfully", log: .database, type: .info)
        }
    }

    private func startMonitoring() {
        let pasteboard = NSPasteboard.general
        lastChangeCount = pasteboard.changeCount

        os_log("Starting clipboard monitoring", log: .clipboard, type: .info)
        os_log("Initial clipboard change count: %d", log: .clipboard, type: .debug, lastChangeCount)

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    private func stopMonitoring() {
        os_log("Stopping clipboard monitoring", log: .clipboard, type: .info)
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general

        if pasteboard.changeCount != lastChangeCount {
            os_log("Clipboard change detected", log: .clipboard, type: .debug)
            os_log("Change count: %d -> %d", log: .clipboard, type: .debug, lastChangeCount, pasteboard.changeCount)
            lastChangeCount = pasteboard.changeCount

            if let string = pasteboard.string(forType: .string), !string.isEmpty {
                let entry = createClipboardEntry(from: string)
                os_log("Processing clipboard entry", log: .clipboard, type: .info)
                os_log("Content preview: %{private}@", log: .clipboard, type: .debug, String(entry.content.prefix(50)))
                os_log("Source app: %{public}@", log: .clipboard, type: .info, entry.appName ?? "Unknown")
                saveClipboardEntry(entry)
            } else {
                os_log("Clipboard change detected but no string content found", log: .clipboard, type: .debug)
            }
        }
    }

    private func createClipboardEntry(from content: String) -> ClipboardEntry {
        let frontmostApp = NSWorkspace.shared.frontmostApplication

        return ClipboardEntry(
            content: content,
            contentHash: content.sha256,
            appName: frontmostApp?.localizedName,
            appBundleId: frontmostApp?.bundleIdentifier,
            timestamp: Date(),
            characterCount: content.count,
            wordCount: countWords(in: content),
            lineCount: countLines(in: content),
            contentType: determineContentType(content),
            isURL: isValidURL(content),
            isEmail: isValidEmail(content),
            languageDetected: detectLanguage(in: content)
        )
    }

    private func countWords(in text: String) -> Int {
        return text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    private func countLines(in text: String) -> Int {
        return text.components(separatedBy: .newlines).count
    }

    private func determineContentType(_ content: String) -> String {
        if isValidURL(content) {
            return "url"
        } else if isValidEmail(content) {
            return "email"
        } else if content.range(of: "\\d{4}-\\d{2}-\\d{2}", options: .regularExpression) != nil {
            return "date_containing"
        } else if content.range(of: "\\d+", options: .regularExpression) != nil {
            return "numeric_containing"
        } else if content.contains("\n") || content.count > 100 {
            return "long_text"
        } else {
            return "short_text"
        }
    }

    private func isValidURL(_ string: String) -> Bool {
        let urlRegex = "^https?://[\\w\\-_]+(\\.[\\w\\-_]+)+([\\w\\-\\.,@?^=%&:/~\\+#]*[\\w\\-\\@?^=%&/~\\+#])?"
        return string.range(of: urlRegex, options: .regularExpression) != nil
    }

    private func isValidEmail(_ string: String) -> Bool {
        let emailRegex = "^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$"
        return string.range(of: emailRegex, options: .regularExpression) != nil
    }

    private func detectLanguage(in text: String) -> String? {
        guard text.count > 10 else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        if let language = recognizer.dominantLanguage {
            return language.rawValue
        }

        return nil
    }

    private func saveClipboardEntry(_ entry: ClipboardEntry) {
        let insertSQL = """
            INSERT OR IGNORE INTO clipboard_entries (
                content, content_hash, app_name, app_bundle_id, timestamp,
                character_count, word_count, line_count, content_type,
                is_url, is_email, language_detected
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?

        if sqlite3_prepare_v2(database, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, entry.content, -1, nil)
            sqlite3_bind_text(statement, 2, entry.contentHash, -1, nil)
            sqlite3_bind_text(statement, 3, entry.appName, -1, nil)
            sqlite3_bind_text(statement, 4, entry.appBundleId, -1, nil)
            sqlite3_bind_text(statement, 5, ISO8601DateFormatter().string(from: entry.timestamp), -1, nil)
            sqlite3_bind_int(statement, 6, Int32(entry.characterCount))
            sqlite3_bind_int(statement, 7, Int32(entry.wordCount))
            sqlite3_bind_int(statement, 8, Int32(entry.lineCount))
            sqlite3_bind_text(statement, 9, entry.contentType, -1, nil)
            sqlite3_bind_int(statement, 10, entry.isURL ? 1 : 0)
            sqlite3_bind_int(statement, 11, entry.isEmail ? 1 : 0)
            sqlite3_bind_text(statement, 12, entry.languageDetected, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                os_log("Clipboard entry saved to database", log: .database, type: .info)
                os_log("Entry metadata - App: %{public}@, Type: %{public}@, Chars: %d, Words: %d",
                      log: .database, type: .debug,
                      entry.appName ?? "Unknown",
                      entry.contentType,
                      entry.characterCount,
                      entry.wordCount)
            } else {
                os_log("Failed to insert clipboard entry into database", log: .database, type: .error)
                if let errorMsg = sqlite3_errmsg(database) {
                    os_log("SQLite error: %{public}s", log: .database, type: .error, errorMsg)
                }
            }
        }

        sqlite3_finalize(statement)
    }
}

extension String {
    var sha256: String {
        let data = Data(utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

import CommonCrypto
