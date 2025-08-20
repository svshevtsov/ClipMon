//
//  Configuration.swift
//  ClipMon
//
//  Created by Sergey Shevtsov on 20.08.2025.
//

import Foundation
import os.log

struct ClipMonConfiguration {
    let databasePath: String
    
    static let `default` = ClipMonConfiguration(
        databasePath: "~/.clipmon/database.sqlite"
    )
    
    init(databasePath: String) {
        self.databasePath = databasePath
    }
}

class ConfigurationManager {
    private static let configDirectory = "~/.clipmon"
    private static let configFilePath = "~/.clipmon/config.yaml"
    
    static func loadConfiguration() -> ClipMonConfiguration {
        let expandedConfigPath = NSString(string: configFilePath).expandingTildeInPath
        let expandedConfigDir = NSString(string: configDirectory).expandingTildeInPath
        
        // Create config directory if it doesn't exist
        createConfigDirectoryIfNeeded(at: expandedConfigDir)
        
        // Check if config file exists
        guard FileManager.default.fileExists(atPath: expandedConfigPath) else {
            os_log("Config file not found, using default settings", log: .config, type: .info)
            os_log("Expected config path: %{public}@", log: .config, type: .debug, expandedConfigPath)
            return .default
        }
        
        // Read and parse config file
        do {
            let configContent = try String(contentsOfFile: expandedConfigPath, encoding: .utf8)
            os_log("Config file loaded successfully", log: .config, type: .info)
            return parseYAML(content: configContent)
        } catch {
            os_log("Error reading config file, using defaults: %{public}@", log: .config, type: .error, error.localizedDescription)
            return .default
        }
    }
    
    private static func createConfigDirectoryIfNeeded(at path: String) {
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                os_log("Created config directory", log: .config, type: .info)
                os_log("Directory path: %{public}@", log: .config, type: .debug, path)
            } catch {
                os_log("Failed to create config directory: %{public}@", log: .config, type: .error, error.localizedDescription)
            }
        }
    }
    
    private static func parseYAML(content: String) -> ClipMonConfiguration {
        var config = ClipMonConfiguration.default
        
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip comments and empty lines
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            // Parse key-value pairs
            if let colonIndex = trimmedLine.firstIndex(of: ":") {
                let key = String(trimmedLine[..<colonIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                let value = String(trimmedLine[trimmedLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Remove quotes if present
                let cleanValue = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                
                switch key {
                case "database_path":
                    config = ClipMonConfiguration(databasePath: cleanValue)
                    os_log("Config: database_path set to %{public}@", log: .config, type: .debug, cleanValue)
                default:
                    os_log("Unknown config key: %{public}@", log: .config, type: .default, key)
                }
            }
        }
        
        return config
    }
    
    static func createSampleConfig() {
        let expandedConfigDir = NSString(string: configDirectory).expandingTildeInPath
        let expandedConfigPath = NSString(string: configFilePath).expandingTildeInPath
        
        createConfigDirectoryIfNeeded(at: expandedConfigDir)
        
        let sampleConfig = """
        # ClipMon Configuration File
        # 
        # Database path - where clipboard history will be stored
        # Use ~ for home directory expansion
        database_path: "~/.clipmon/database.sqlite"
        
        # You can also use absolute paths:
        # database_path: "/Users/username/Documents/clipboard.sqlite"
        """
        
        if !FileManager.default.fileExists(atPath: expandedConfigPath) {
            do {
                try sampleConfig.write(toFile: expandedConfigPath, atomically: true, encoding: .utf8)
                os_log("Created sample config file", log: .config, type: .info)
                os_log("Config file path: %{public}@", log: .config, type: .debug, expandedConfigPath)
            } catch {
                os_log("Failed to create sample config file: %{public}@", log: .config, type: .error, error.localizedDescription)
            }
        }
    }
}