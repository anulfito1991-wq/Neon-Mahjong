//
//  PersistedStore.swift
//  Mahjong Zen Garden
//
//  Preventive port of Ola's (LunaLoop) v1.5.1 SafeStore. Closes the
//  silent-decode-failure bug pattern BEFORE any user data has shipped.
//
//  THE RULE (also documented in CLAUDE.md, do not break this):
//
//    1. Never call `try?` on a JSONDecoder for a persisted user struct.
//       Use `do { try ... } catch { ... }` so failures are observable.
//
//    2. Every persisted Codable struct MUST implement a manual
//       `init(from:)` that reads every field with `decodeIfPresent(...)`
//       and falls back to a sensible default. Adding a new property
//       must never be capable of wiping prior data.
//
//    3. Every persisted Codable struct MUST carry a `schemaVersion: Int`
//       so future migrations can branch on it explicitly.
//
//    4. On decode failure, the raw bytes MUST be preserved to a
//       `<key>.backup.preMigration.v<N>` UserDefaults key so a future
//       release can attempt recovery. Never overwrite a backup that
//       already exists for a given version.
//

import Foundation
import os.log

struct PersistenceRecoveryReport: Equatable {
    var decodeFailures: [String] = []
    var restoredFromBackup: [String] = []

    var didRestore: Bool { !restoredFromBackup.isEmpty }
}

enum SafeStore {

    /// Bumped when the on-disk JSON shape of one or more persisted
    /// structs changes in a way that requires a recovery-eligible
    /// backup. Backups land at `<key>.backup.preMigration.v<this>`.
    static let currentBackupGeneration = 1

    private static let logger = Logger(
        subsystem: "anulfito.MahjongZen",
        category: "SafeStore"
    )

    private static let defaults = UserDefaults.standard

    // MARK: - Encode / Decode

    static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    // MARK: - Save

    static func save<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let data = try encoder().encode(value)
            defaults.set(data, forKey: key)
        } catch {
            logger.error("Encode failed for \(key, privacy: .public): \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: - Load with recovery

    static func load<T: Codable>(
        _: T.Type,
        forKey key: String,
        report: inout PersistenceRecoveryReport
    ) -> T? {
        if let data = defaults.data(forKey: key) {
            do {
                return try decoder().decode(T.self, from: data)
            } catch {
                logger.error("Decode failed for \(key, privacy: .public): \(String(describing: error), privacy: .public)")
                preserveBackupIfNeeded(rawData: data, originalKey: key)
                report.decodeFailures.append(key)
            }
        }

        for generation in (1...currentBackupGeneration).reversed() {
            let backupKey = "\(key).backup.preMigration.v\(generation)"
            guard let backupData = defaults.data(forKey: backupKey) else { continue }
            do {
                let recovered = try decoder().decode(T.self, from: backupData)
                logger.notice("Recovered \(key, privacy: .public) from \(backupKey, privacy: .public)")
                save(recovered, forKey: key)
                report.restoredFromBackup.append(key)
                return recovered
            } catch {
                continue
            }
        }

        return nil
    }

    static func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        var report = PersistenceRecoveryReport()
        return load(type, forKey: key, report: &report)
    }

    // MARK: - Backup machinery

    private static func preserveBackupIfNeeded(rawData: Data, originalKey: String) {
        let backupKey = "\(originalKey).backup.preMigration.v\(currentBackupGeneration)"
        guard defaults.data(forKey: backupKey) == nil else { return }
        defaults.set(rawData, forKey: backupKey)
        logger.notice("Preserved decode-failed blob to \(backupKey, privacy: .public) (\(rawData.count, privacy: .public) bytes)")
    }

    // MARK: - Test / debug helpers

    static func _resetBackups(forKey key: String) {
        for generation in 1...currentBackupGeneration {
            defaults.removeObject(forKey: "\(key).backup.preMigration.v\(generation)")
        }
    }
}
