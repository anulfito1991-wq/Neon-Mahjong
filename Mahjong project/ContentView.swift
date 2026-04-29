//
//  ContentView.swift
//  Mahjong project
//
//  Created by Anulfito on 4/28/26.
//

import SwiftUI

enum AppScreen: Hashable {
    case menu
    case game(GameSession)
    case stats
    case settings
    case leaderboards
}

struct ContentView: View {
    @State private var screen: AppScreen = .menu

    var body: some View {
        ZStack {
            switch screen {
            case .menu:
                MenuView(
                    onPlay:        { session in screen = .game(session) },
                    onOpenStats:   { screen = .stats },
                    onOpenSettings:{ screen = .settings }
                )
                .transition(.opacity)

            case .game(let session):
                GameView(session: session, onExit: { screen = .menu })
                    .transition(.opacity)

            case .stats:
                StatsView(
                    onClose: { screen = .menu },
                    onOpenLeaderboards: { screen = .leaderboards }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))

            case .settings:
                SettingsView(onClose: { screen = .menu })
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .leaderboards:
                LeaderboardsBrowser(onClose: { screen = .menu })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: screen)
        .preferredColorScheme(.dark)
        .task {
            // Warm up SoundManager + IAPManager early so the first interactions
            // are snappy and theme entitlements load before the user opens Themes.
            _ = SoundManager.shared
            _ = IAPManager.shared
            LeaderboardManager.shared.authenticate()
            if let scene = ScreenshotMode.requestedScene {
                ScreenshotMode.primeStats()
                switch scene {
                case .menu, .layouts:
                    screen = .menu
                case .game, .win:
                    let session = GameSession(layout: .neonPyramid, seed: 42,
                                              isDaily: false, dailyDate: nil)
                    screen = .game(session)
                case .stats:
                    screen = .stats
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
