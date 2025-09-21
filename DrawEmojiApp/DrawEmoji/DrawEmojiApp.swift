//
//  DrawEmojiApp.swift
//  DrawEmoji
//
//  Created by Tang Anthony on 2025/5/15.
//

import SwiftUI

let appURL = "https://7d60-36-224-62-77.ngrok-free.app/";

@main
struct DrawEmojiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: AppSettings.self)
    }
}
