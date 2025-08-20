//
//  main.swift
//  ClipMon
//
//  Created by Sergey Shevtsov on 20.08.2025.
//

import Foundation
import AppKit
import os.log

// MARK: - Signal Handling
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
                exit(0)
            }
        }
        source.resume()
        return source
    }
    
    // Set up handlers for SIGINT (Ctrl+C) and SIGTERM
    signalSources.append(createSignalSource(for: SIGINT))
    signalSources.append(createSignalSource(for: SIGTERM))
}

// MARK: - Command Line Handling
func printUsage() {
    print("ClipMon - Clipboard Monitor CLI Tool")
    print("")
    print("USAGE:")
    print("    clipmon [OPTIONS]")
    print("")
    print("OPTIONS:")
    print("    -h, --help       Show this help message")
    print("    -v, --version    Show version information")
    print("    -c, --config     Specify custom config file path")
    print("")
    print("DESCRIPTION:")
    print("    ClipMon monitors clipboard changes and stores all text entries")
    print("    in a SQLite database. Configuration is read from ~/.clipmon/config.yaml")
    print("")
    print("EXAMPLES:")
    print("    clipmon                                    # Start monitoring with default config")
    print("    clipmon --config /path/to/config.yaml     # Use custom config file")
    print("")
}

func printVersion() {
    print("ClipMon v1.0.0")
    print("A macOS clipboard monitoring CLI tool")
}

// MARK: - Main Entry Point
let arguments = CommandLine.arguments

// Handle command line arguments
for i in 1..<arguments.count {
    let arg = arguments[i]
    switch arg {
    case "-h", "--help":
        printUsage()
        exit(0)
    case "-v", "--version":
        printVersion()
        exit(0)
    case "-c", "--config":
        if i + 1 < arguments.count {
            // Custom config handling would go here
            print("Custom config file: \(arguments[i + 1])")
        } else {
            print("Error: --config requires a file path")
            exit(1)
        }
    default:
        if arg.hasPrefix("-") {
            print("Error: Unknown option '\(arg)'")
            print("Use --help for usage information")
            exit(1)
        }
    }
}

os_log("ClipMon CLI starting...", log: .app, type: .info)

setupSignalHandlers()

// Initialize clipboard monitor
clipboardMonitor = ClipboardMonitor()

os_log("ClipMon is now monitoring clipboard changes. Press Ctrl+C to stop.", log: .app, type: .info)
print("ClipMon is monitoring clipboard changes. Press Ctrl+C to stop.")

// Keep the app running until termination signal
RunLoop.main.run()