//
//  Mahjong_projectApp.swift
//  Mahjong project
//
//  Created by Anulfito on 4/28/26.
//

import SwiftUI

@main
struct Mahjong_projectApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Bootstrap ads (ATT prompt + SDK start) on first appearance.
                    // No-op in screenshot mode; safe to call multiple times.
                    await AdManager.shared.bootstrap()
                }
        }
    }
}
