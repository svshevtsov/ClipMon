//
//  Configuration.swift
//  ClipMon
//
//  Created by Sergey Shevtsov on 20.08.2025.
//

import Foundation

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
            print("Config file not found, using defaults")
            return .default
        }
        
        // Read and parse config file
        do {
            let configContent = try String(contentsOfFile: expandedConfigPath, encoding: .utf8)
            return parseYAML(content: configContent)
        } catch {
            print("Error reading config file: \(error), using defaults")
            return .default
        }
    }
    
    private static func createConfigDirectoryIfNeeded(at path: String) {
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                print("Created config directory at: \(path)")
            } catch {
                print("Failed to create config directory: \(error)")
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
                default:
                    print("Unknown config key: \(key)")
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
                print("Created sample config file at: \(expandedConfigPath)")
            } catch {
                print("Failed to create sample config file: \(error)")
            }
        }
    }
}