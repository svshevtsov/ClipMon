//
//  main.swift
//  ClipMon
//
//  Created by Sergey Shevtsov on 20.08.2025.
//

import ArgumentParser
import Foundation
import AppKit
import os.log

struct ClipMon: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clipmon",
        abstract: "A macOS clipboard monitoring CLI tool",
        discussion: """
        ClipMon monitors clipboard changes and stores all clipboard text entries 
        in a local SQLite database with rich metadata collection including source 
        application detection, content analysis, and language detection.
        
        The tool runs continuously in the background until interrupted with Ctrl+C 
        or SIGTERM. Configuration is read from ~/.clipmon/config.yaml, and the 
        database is stored at ~/.clipmon/database.sqlite by default.
        """,
        version: "1.0.0"
    )
    
    @Option(name: .shortAndLong, help: "Path to custom configuration file")
    var config: String?
    
    @Flag(name: .shortAndLong, help: "Enable verbose logging output")
    var verbose = false
    
    mutating func run() throws {
        runClipMon(verbose: verbose, configPath: config)
    }
}

// Global variables for signal handling
var shouldTerminate = false
var clipboardMonitor: ClipboardMonitor?
var signalSources: [DispatchSourceSignal] = []

func setupSignalHandlers() {
    let signalQueue = DispatchQueue(label: "signal.handler")
    
    func createSignalSource(for signal: Int32) -> DispatchSourceSignal {
        // Ignore the signal to prevent default behavior
        Darwin.signal(signal, SIG_IGN)
        
        let source = DispatchSource.makeSignalSource(signal: signal, queue: signalQueue)
        source.setEventHandler {
            let signalName = signal == SIGINT ? "SIGINT" : "SIGTERM"
            print("\nReceived \(signalName), shutting down gracefully...")
            os_log("Received %{public}@, shutting down gracefully...", log: .app, type: .info, signalName)
            
            clipboardMonitor?.stop()
            shouldTerminate = true
            
            // Exit after a short delay to allow cleanup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Foundation.exit(0)
            }
        }
        source.resume()
        return source
    }
    
    // Set up handlers for SIGINT (Ctrl+C) and SIGTERM
    signalSources.append(createSignalSource(for: SIGINT))
    signalSources.append(createSignalSource(for: SIGTERM))
}

func runClipMon(verbose: Bool, configPath: String?) {
    os_log("ClipMon CLI starting...", log: .app, type: .info)
    
    if verbose {
        print("Verbose mode enabled")
        if let configPath = configPath {
            print("Using custom config file: \(configPath)")
        }
    }
    
    setupSignalHandlers()
    
    // Initialize clipboard monitor
    clipboardMonitor = ClipboardMonitor()
    
    os_log("ClipMon is now monitoring clipboard changes. Press Ctrl+C to stop.", log: .app, type: .info)
    print("ClipMon is monitoring clipboard changes. Press Ctrl+C to stop.")
    
    // Keep the app running until termination signal
    RunLoop.main.run()
}

ClipMon.main()
