//
//  ClipMonApp.swift
//  ClipMon
//
//  Created by Sergey Shevtsov on 20.08.2025.
//

import SwiftUI

@main
struct ClipMonApp: App {
    @StateObject private var clipboardMonitor = ClipboardMonitor()
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
