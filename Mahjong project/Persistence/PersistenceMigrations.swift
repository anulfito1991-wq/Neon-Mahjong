//
//  PersistenceMigrations.swift
//  Mahjong Zen Garden
//
//  Manual `init(from:)` for every persisted Codable user struct.
//  Mirrors Ola/LunaLoop's v1.5.1 pattern. The synthesized `init(from:)`
//  is forbidden for persisted types — see PersistedStore.swift header.
//
//  When you add a NEW property to one of these structs:
//    1. Give it a default in the struct definition (always).
//    2. Add a `decodeIfPresent` line in this file's `init(from:)`.
//    3. Bump `currentSchemaVersion` on the struct.
//

import Foundation

// MARK: - StatsSnapshot

extension StatsSnapshot {
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case gamesPlayed, gamesWon, totalSeconds
        case bestTimeByLayout, bestScoreByLayout
        case dailyCompleted, currentStreak, longestStreak, lastDailyDate
    }

    init(from decoder: Decoder) throws {
        var instance = StatsSnapshot()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let _ = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1

        instance.gamesPlayed = try c.decodeIfPresent(Int.self, forKey: .gamesPlayed) ?? instance.gamesPlayed
        instance.gamesWon = try c.decodeIfPresent(Int.self, forKey: .gamesWon) ?? instance.gamesWon
        instance.totalSeconds = try c.decodeIfPresent(Int.self, forKey: .totalSeconds) ?? instance.totalSeconds
        instance.bestTimeByLayout = try c.decodeIfPresent([String: Int].self, forKey: .bestTimeByLayout) ?? instance.bestTimeByLayout
        instance.bestScoreByLayout = try c.decodeIfPresent([String: Int].self, forKey: .bestScoreByLayout) ?? instance.bestScoreByLayout
        instance.dailyCompleted = try c.decodeIfPresent(Set<String>.self, forKey: .dailyCompleted) ?? instance.dailyCompleted
        instance.currentStreak = try c.decodeIfPresent(Int.self, forKey: .currentStreak) ?? instance.currentStreak
        instance.longestStreak = try c.decodeIfPresent(Int.self, forKey: .longestStreak) ?? instance.longestStreak
        instance.lastDailyDate = try c.decodeIfPresent(String.self, forKey: .lastDailyDate) ?? instance.lastDailyDate

        instance.schemaVersion = StatsSnapshot.currentSchemaVersion
        self = instance
    }
}
