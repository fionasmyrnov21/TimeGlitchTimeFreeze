import Foundation
import Combine

struct LevelRecord: Codable {
    var stars: Int
    var bestSeconds: Double
    var fewestChanges: Int
}

final class ProgressStore: ObservableObject {
    @Published private(set) var records: [Int: LevelRecord]
    @Published var haptics: Bool { didSet { UserDefaults.standard.set(haptics, forKey: "haptics") } }
    @Published var reducedEffects: Bool { didSet { UserDefaults.standard.set(reducedEffects, forKey: "reducedEffects") } }
    @Published var showHints: Bool { didSet { UserDefaults.standard.set(showHints, forKey: "showHints") } }

    init() {
        let defaults = UserDefaults.standard
        records = defaults.data(forKey: "levelRecords").flatMap { try? JSONDecoder().decode([Int: LevelRecord].self, from: $0) } ?? [:]
        haptics = defaults.object(forKey: "haptics") as? Bool ?? true
        reducedEffects = defaults.bool(forKey: "reducedEffects")
        showHints = defaults.object(forKey: "showHints") as? Bool ?? true
    }

    var unlockedLevel: Int { min(20, (records.keys.max() ?? 0) + 1) }
    var totalStars: Int { records.values.reduce(0) { $0 + $1.stars } }
    var completion: Double { Double(records.count) / 20 }
    var nextLevel: Level { Level.all[unlockedLevel - 1] }

    func save(_ result: RunResult) {
        let previous = records[result.levelID]
        records[result.levelID] = LevelRecord(stars: max(previous?.stars ?? 0, result.stars), bestSeconds: min(previous?.bestSeconds ?? .infinity, result.seconds), fewestChanges: min(previous?.fewestChanges ?? .max, result.changes))
        if let data = try? JSONEncoder().encode(records) { UserDefaults.standard.set(data, forKey: "levelRecords") }
    }

    func reset() {
        records = [:]
        UserDefaults.standard.removeObject(forKey: "levelRecords")
    }
}
