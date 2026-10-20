import Foundation
import Combine
import UIKit

final class GameViewModel: ObservableObject {
    @Published private(set) var engine: TimeEngine
    @Published var selectedID: Int?
    @Published var power: TimePower = .freeze
    @Published var result: RunResult?
    let scene: GameScene
    private let store: ProgressStore
    private var lastPublication: Double = 0
    private var simulation: TimeEngine
    private var effectsReduced: Bool

    init(level: Level, store: ProgressStore) {
        engine = TimeEngine(level: level)
        simulation = TimeEngine(level: level)
        self.store = store
        effectsReduced = store.reducedEffects
        scene = GameScene(size: CGSize(width: 420, height: 480))
        selectedID = level.objects.first?.id
        scene.configure(engine: engine, reducedEffects: effectsReduced)
        scene.onFrame = { [weak self] delta in self?.tick(delta) }
        scene.onSelect = { [weak self] id in self?.select(id) }
    }

    var selected: TemporalObject? { engine.objects.first { $0.id == selectedID } }

    func select(_ id: Int) {
        selectedID = id
        scene.select(id)
        if store.haptics { UISelectionFeedbackGenerator().selectionChanged() }
    }

    func setReducedEffects(_ reduced: Bool) {
        effectsReduced = reduced
        scene.setReducedEffects(reduced)
    }

    func start() { simulation.status = .running; engine = simulation }
    func pause() { if simulation.status == .running { simulation.status = .paused; engine = simulation } }
    func resume() { if simulation.status == .paused { simulation.status = .running; engine = simulation } }
    func restart() {
        simulation = TimeEngine(level: engine.level)
        engine = simulation
        result = nil
        scene.configure(engine: engine, reducedEffects: effectsReduced)
        if let selectedID { scene.select(selectedID) }
    }
    func apply() {
        guard let selectedID else { return }
        simulation.apply(power, to: selectedID)
        engine = simulation
        if store.haptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        scene.render(engine)
    }
    private func tick(_ delta: Double) {
        guard simulation.status == .running else { return }
        simulation.update(delta)
        let next = simulation
        scene.render(next)
        lastPublication += delta
        if lastPublication >= 0.08 || next.status != .running {
            engine = next
            lastPublication = 0
        }
        if next.status == .completed && result == nil {
            let stars = next.changes <= next.level.par ? 3 : next.changes <= next.level.par + 3 ? 2 : 1
            let value = RunResult(levelID: next.level.id, seconds: next.elapsed, changes: next.changes, stars: stars)
            store.save(value)
            result = value
            if store.haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
    }
}
