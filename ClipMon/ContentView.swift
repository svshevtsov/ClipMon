//
//  ClipboardMonitor.swift
//  ClipMon
//
//  Created by Sergey Shevtsov on 20.08.2025.
//

import Foundation
import AppKit
import SQLite3

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
                print("Created database directory: \(databaseDir.path)")
            } catch {
                print("Failed to create database directory: \(error)")
            }
        }
        
        if sqlite3_open(databaseURL.path, &database) == SQLITE_OK {
            print("Database opened at: \(databaseURL.path)")
            createTable()
        } else {
            print("Unable to open database at: \(databaseURL.path)")
        }
    }
    
    private func createTable() {
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS clipboard_entries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content TEXT NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                content_hash TEXT UNIQUE
            );
        """
        
        if sqlite3_exec(database, createTableSQL, nil, nil, nil) != SQLITE_OK {
            print("Error creating table")
        }
    }
    
    private func startMonitoring() {
        let pasteboard = NSPasteboard.general
        lastChangeCount = pasteboard.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            if let string = pasteboard.string(forType: .string), !string.isEmpty {
                saveClipboardEntry(content: string)
            }
        }
    }
    
    private func saveClipboardEntry(content: String) {
        let contentHash = content.sha256
        
        let insertSQL = """
            INSERT OR IGNORE INTO clipboard_entries (content, content_hash)
            VALUES (?, ?);
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(database, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, content, -1, nil)
            sqlite3_bind_text(statement, 2, contentHash, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Clipboard entry saved: \(content.prefix(50))...")
            } else {
                print("Error inserting clipboard entry")
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
