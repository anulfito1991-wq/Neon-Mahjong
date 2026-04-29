import Foundation
import Observation
import SwiftUI

/// Configuration for a game session.
struct GameSession: Hashable, Sendable {
    let layout: BoardLayout
    let seed: UInt64?
    let isDaily: Bool
    let dailyDate: String?

    static func freePlay(layout: BoardLayout) -> GameSession {
        GameSession(layout: layout, seed: nil, isDaily: false, dailyDate: nil)
    }

    static func daily(layout: BoardLayout = .neonPyramid) -> GameSession {
        GameSession(layout: layout,
                    seed: DailyChallenge.todaySeed,
                    isDaily: true,
                    dailyDate: DailyChallenge.todayString)
    }
}

@MainActor
@Observable
final class GameViewModel {
    private(set) var tiles: [Tile] = []
    private(set) var activeIDs: Set<UUID> = []
    private(set) var selectedID: UUID?
    private(set) var hintIDs: Set<UUID> = []
    private(set) var mismatchIDs: Set<UUID> = []

    private(set) var matchedPairs: Int = 0
    private(set) var hintsUsed: Int = 0
    private(set) var undosUsed: Int = 0
    private(set) var shufflesUsed: Int = 0
    private(set) var elapsedSeconds: Int = 0
    private(set) var phase: GamePhase = .playing

    /// Free hints spent in the current game. Once this reaches `freeHintCap`,
    /// the player must watch a rewarded ad (or have purchased Remove Ads).
    private(set) var hintsUsedThisGame: Int = 0

    /// Free-hint cap per game. Effectively unlimited once Remove Ads is owned.
    var freeHintCap: Int {
        IAPManager.shared.isAdsRemoved ? .max : 3
    }

    var freeHintsRemaining: Int {
        max(0, freeHintCap - hintsUsedThisGame)
    }

    var hasFreeHintsRemaining: Bool { freeHintsRemaining > 0 }

    private(set) var session: GameSession

    private var moveHistory: [(UUID, UUID)] = []
    private var positionIndex: [TilePosition: UUID] = [:]
    private var timerTask: Task<Void, Never>?
    private var hasRecordedWin: Bool = false

    init(session: GameSession) {
        self.session = session
        startNewGame(session: session)
    }

    // MARK: - Lifecycle

    func startNewGame(session: GameSession? = nil) {
        if let session { self.session = session }
        let board = MahjongEngine.generateSolvableBoard(layout: self.session.layout,
                                                        seed: self.session.seed)
        tiles = board
        activeIDs = Set(board.map(\.id))
        positionIndex = Dictionary(uniqueKeysWithValues: board.map { ($0.position, $0.id) })
        selectedID = nil
        hintIDs = []
        mismatchIDs = []
        matchedPairs = 0
        hintsUsed = 0
        hintsUsedThisGame = 0
        undosUsed = 0
        shufflesUsed = 0
        elapsedSeconds = 0
        moveHistory = []
        phase = .playing
        hasRecordedWin = false
        GameStats.shared.recordGameStart()
        startTimer()
    }

    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func startTimer() {
        if ScreenshotMode.isActive { return }
        stopTimer()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    guard let self else { return }
                    if self.phase == .playing { self.elapsedSeconds += 1 }
                }
            }
        }
    }

    /// Bootstraps a deterministic mid-game or won state for App Store screenshots.
    /// Silent: no haptics, sound, or stat-recording side effects.
    func loadScreenshotState(_ scene: ScreenshotScene) {
        switch scene {
        case .game:
            elapsedSeconds = 73
            // Clear roughly 60% of pairs by repeatedly matching free pairs.
            let target = Int(Double(totalPairs) * 0.6)
            var cleared = 0
            while cleared < target {
                let free = MahjongEngine.freeTiles(active: activeTiles)
                guard let pair = freePair(in: free) else { break }
                activeIDs.remove(pair.0.id)
                activeIDs.remove(pair.1.id)
                matchedPairs += 1
                cleared += 1
            }
            phase = .playing
        case .win:
            elapsedSeconds = 218
            matchedPairs = totalPairs
            activeIDs.removeAll()
            phase = .won
        default:
            break
        }
    }

    private func freePair(in free: [Tile]) -> (Tile, Tile)? {
        for i in 0..<free.count {
            for j in (i + 1)..<free.count where free[i].kind.matches(free[j].kind) {
                return (free[i], free[j])
            }
        }
        return nil
    }

    // MARK: - Derived

    var totalPairs: Int { tiles.count / 2 }
    var progress: Double { totalPairs == 0 ? 0 : Double(matchedPairs) / Double(totalPairs) }
    var formattedTime: String {
        String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
    }
    var score: Int {
        let base = matchedPairs * 100
        let timeBonus = max(0, 1000 - elapsedSeconds * 2)
        let penalty = hintsUsed * 25 + undosUsed * 15 + shufflesUsed * 50
        return max(0, base + timeBonus - penalty)
    }

    var activeTiles: [Tile] { tiles.filter { activeIDs.contains($0.id) } }

    private var activeByPosition: [TilePosition: Tile] {
        Dictionary(uniqueKeysWithValues: activeTiles.map { ($0.position, $0) })
    }

    func tile(id: UUID) -> Tile? { tiles.first { $0.id == id } }

    func isFree(_ tile: Tile) -> Bool {
        guard activeIDs.contains(tile.id) else { return false }
        return MahjongEngine.isFree(tile: tile, activeByPosition: activeByPosition)
    }

    // MARK: - Actions

    func tap(tileID: UUID) {
        guard phase == .playing else { return }
        guard let tapped = tile(id: tileID), activeIDs.contains(tileID) else { return }
        guard isFree(tapped) else { return }

        hintIDs = []
        mismatchIDs = []

        if let currentID = selectedID {
            if currentID == tileID {
                selectedID = nil
                SoundManager.shared.haptic(.select)
                return
            }
            guard let current = tile(id: currentID) else {
                selectedID = tileID
                return
            }
            if current.kind.matches(tapped.kind) {
                removePair(current, tapped)
                selectedID = nil
            } else {
                let pair: Set<UUID> = [current.id, tapped.id]
                mismatchIDs = pair
                selectedID = tileID
                SoundManager.shared.play(.mismatch)
                SoundManager.shared.haptic(.mismatch)
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    guard let self else { return }
                    if self.mismatchIDs == pair { self.mismatchIDs = [] }
                }
            }
        } else {
            selectedID = tileID
            SoundManager.shared.play(.select)
            SoundManager.shared.haptic(.select)
        }
    }

    private func removePair(_ a: Tile, _ b: Tile) {
        activeIDs.remove(a.id)
        activeIDs.remove(b.id)
        moveHistory.append((a.id, b.id))
        matchedPairs += 1
        SoundManager.shared.play(.match)
        SoundManager.shared.haptic(.match)
        evaluatePhase()
    }

    /// Free hint — only succeeds when there's a free hint slot remaining.
    /// Callers should check `hasFreeHintsRemaining` first; if false, route
    /// through `showHintAfterAd()` instead.
    func showHint() {
        guard phase == .playing, hasFreeHintsRemaining else { return }
        performHint()
    }

    /// Watches a rewarded ad, then grants a hint regardless of the free cap.
    /// Short-circuits to a free hint when Remove Ads is owned (AdManager
    /// handles that internally).
    func showHintAfterAd() async {
        guard phase == .playing else { return }
        let granted = await AdManager.shared.showRewarded(.extraHint)
        guard granted, phase == .playing else { return }
        performHint()
    }

    private func performHint() {
        guard let pair = findHintPair() else { return }
        hintsUsed += 1
        hintsUsedThisGame += 1
        hintIDs = [pair.0.id, pair.1.id]
        SoundManager.shared.play(.hint)
        SoundManager.shared.haptic(.button)
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self?.hintIDs = []
        }
    }

    func undo() {
        guard let last = moveHistory.popLast() else { return }
        activeIDs.insert(last.0)
        activeIDs.insert(last.1)
        matchedPairs = max(0, matchedPairs - 1)
        undosUsed += 1
        selectedID = nil
        hintIDs = []
        mismatchIDs = []
        SoundManager.shared.haptic(.button)
        evaluatePhase()
    }

    func shuffle() {
        guard phase != .won else { return }
        shufflesUsed += 1
        SoundManager.shared.play(.shuffle)
        SoundManager.shared.haptic(.button)

        let active = activeTiles
        let positions = active.map(\.position)
        var kinds = active.map(\.kind)
        kinds.shuffle()

        var newTiles: [Tile] = []
        var newActive = Set<UUID>()
        var ai = 0
        for old in tiles {
            if activeIDs.contains(old.id) {
                let replacement = Tile(kind: kinds[ai], position: positions[ai])
                ai += 1
                newTiles.append(replacement)
                newActive.insert(replacement.id)
            } else {
                newTiles.append(old)
            }
        }
        tiles = newTiles
        activeIDs = newActive
        positionIndex = Dictionary(uniqueKeysWithValues: tiles.map { ($0.position, $0.id) })
        moveHistory = []
        selectedID = nil
        hintIDs = []
        mismatchIDs = []
        evaluatePhase()
    }

    // MARK: - Helpers

    private func findHintPair() -> (Tile, Tile)? {
        let free = MahjongEngine.freeTiles(active: activeTiles)
        for i in 0..<free.count {
            for j in (i + 1)..<free.count where free[i].kind.matches(free[j].kind) {
                return (free[i], free[j])
            }
        }
        return nil
    }

    private func evaluatePhase() {
        if activeIDs.isEmpty {
            phase = .won
            stopTimer()
            if !hasRecordedWin {
                hasRecordedWin = true
                GameStats.shared.recordWin(
                    layoutID: session.layout.id,
                    seconds: elapsedSeconds,
                    score: score,
                    isDaily: session.isDaily,
                    dailyDate: session.dailyDate
                )
                LeaderboardManager.shared.submitBestTime(
                    seconds: elapsedSeconds,
                    layoutID: session.layout.id
                )
                SoundManager.shared.play(.win)
                SoundManager.shared.haptic(.win)
            }
        } else if findHintPair() == nil {
            if phase != .stuck {
                SoundManager.shared.play(.stuck)
                SoundManager.shared.haptic(.stuck)
            }
            phase = .stuck
        } else {
            phase = .playing
        }
    }
}
