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

// Modern async signal handling
actor AsyncSignalHandler {
    private var signalSources: [DispatchSourceSignal] = []
    private var onSignalReceived: (() async -> Void)?
    
    func setSignalHandler(_ handler: @escaping () async -> Void) {
        onSignalReceived = handler
    }
    
    func startListening(for signals: [Int32] = [SIGINT, SIGTERM]) {
        let signalQueue = DispatchQueue(label: "signal.handler")
        
        for signal in signals {
            // Ignore the signal to prevent default behavior
            Darwin.signal(signal, SIG_IGN)
            
            let source = DispatchSource.makeSignalSource(signal: signal, queue: signalQueue)
            source.setEventHandler { [weak self] in
                let signalName = signal == SIGINT ? "SIGINT" : "SIGTERM"
                print("\nReceived \(signalName), shutting down gracefully...")
                os_log("Received %{public}@, shutting down gracefully...", log: .app, type: .info, signalName)
                
                Task {
                    await self?.onSignalReceived?()
                }
            }
            source.resume()
            signalSources.append(source)
        }
    }
    
    func stopListening() {
        signalSources.forEach { $0.cancel() }
        signalSources.removeAll()
    }
}

func runClipMon(verbose: Bool, configPath: String?) {
    os_log("ClipMon CLI starting...", log: .app, type: .info)
    
    if verbose {
        print("Verbose mode enabled")
        if let configPath = configPath {
            print("Using custom config file: \(configPath)")
        }
    }
    
    // Initialize clipboard monitor
    let clipboardMonitor = ClipboardMonitor()
    
    // Set up modern async signal handling
    let signalHandler = AsyncSignalHandler()
    
    Task {
        await signalHandler.setSignalHandler {
            clipboardMonitor.stop()
            // Small delay to allow cleanup
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            Foundation.exit(0)
        }
        await signalHandler.startListening()
    }
    
    os_log("ClipMon is now monitoring clipboard changes. Press Ctrl+C to stop.", log: .app, type: .info)
    print("ClipMon is monitoring clipboard changes. Press Ctrl+C to stop.")
    
    // Keep the app running until termination signal
    RunLoop.main.run()
}

ClipMon.main()
