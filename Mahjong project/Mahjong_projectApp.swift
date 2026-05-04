//
//  Mahjong_projectApp.swift
//  Mahjong project
//
//  Created by Anulfito on 4/28/26.
//

import SwiftUI

@main
struct Mahjong_projectApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var didBootstrap = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase, initial: true) { _, newPhase in
                    bootstrapIfReady(newPhase)
                }
        }
    }

    /// Bootstrap ads (ATT prompt + Mobile Ads SDK start) only once the scene
    /// is fully active. Apple's `requestTrackingAuthorization` silently no-ops
    /// when invoked before the first frame is on screen — this was the cause
    /// of our v1.0 (build 2) review rejection on iPadOS 26.4.2 where the
    /// reviewer never saw the ATT permission dialog.
    ///
    /// We additionally insert a small delay so the SwiftUI scene has finished
    /// presenting before the system modal appears.
    private func bootstrapIfReady(_ phase: ScenePhase) {
        guard phase == .active, !didBootstrap else { return }
        didBootstrap = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)  // 0.6s
            await AdManager.shared.bootstrap()
        }
    }
}
