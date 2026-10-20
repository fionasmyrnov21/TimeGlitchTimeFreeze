import Foundation
import CoreGraphics

struct TimeEngine: Equatable {
    let level: Level
    var objects: [TemporalObject]
    var traveler = CGPoint(x: 60, y: 118)
    var velocity: CGFloat = 0
    var elapsed: Double = 0
    var changes = 0
    var status: RunStatus = .ready
    var supportedID: Int?

    init(level: Level) {
        self.level = level
        objects = level.objects.map { TemporalObject(spec: $0) }
    }

    mutating func apply(_ power: TimePower, to id: Int) {
        guard status == .running || status == .ready,
              let index = objects.firstIndex(where: { $0.id == id }), objects[index].remaining <= 0 else { return }
        objects[index].power = power
        objects[index].remaining = 3
        changes += 1
    }

    mutating func update(_ delta: Double) {
        guard status == .running else { return }
        let dt = min(max(delta, 0), 1.0 / 30)
        elapsed += dt
        let oldRects = objects.map(\.rect)
        for index in objects.indices { objects[index].advance(dt) }
        if let id = supportedID, let i = objects.firstIndex(where: { $0.id == id }) {
            traveler.x += objects[i].rect.midX - oldRects[i].midX
            traveler.y += objects[i].rect.maxY - oldRects[i].maxY
        }
        let old = traveler
        let step = level.speed * dt
        var grounded = false
        let solids = level.floors + objects.filter { $0.spec.kind != .laser }.map(\.rect)
        for surface in solids {
            if old.x + 11 > surface.minX && old.x - 11 < surface.maxX && abs(old.y - 18 - surface.maxY) < 4 && velocity <= 0 {
                grounded = true
            }
        }
        if grounded {
            let obstacle = solids.contains { $0.minX > traveler.x && $0.minX < traveler.x + 32 && $0.maxY > traveler.y - 16 && $0.maxY < traveler.y + 80 }
            let ahead = solids.contains { traveler.x + 32 >= $0.minX && traveler.x + 32 <= $0.maxX && abs($0.maxY - (traveler.y - 18)) < 12 }
            if obstacle || !ahead { velocity = 360 }
        }
        velocity -= 640 * dt
        traveler.x += step
        traveler.y += velocity * dt
        supportedID = nil
        let body = CGRect(x: traveler.x - 11, y: traveler.y - 18, width: 22, height: 36)
        for (i, surface) in solids.enumerated() {
            guard body.maxX > surface.minX + 2 && body.minX < surface.maxX - 2 else { continue }
            if velocity <= 0 && old.y - 18 >= surface.maxY - 6 && traveler.y - 18 <= surface.maxY {
                traveler.y = surface.maxY + 18
                velocity = 0
                if i >= level.floors.count {
                    let physical = objects.filter { $0.spec.kind != .laser }
                    supportedID = physical[i - level.floors.count].id
                }
            } else if body.intersects(surface) && old.x + 10 <= surface.minX + 6 && body.minY < surface.maxY - 5 {
                traveler.x = surface.minX - 12
            }
        }
        let finalBody = CGRect(x: traveler.x - 9, y: traveler.y - 16, width: 18, height: 32)
        for (i, object) in objects.enumerated() {
            if object.active && finalBody.intersects(object.rect) { status = .failed }
            if object.spec.kind == .block && object.rect.minY < oldRects[i].minY - 0.01 && finalBody.intersects(object.rect.insetBy(dx: 5, dy: 5)) && old.y < oldRects[i].minY { status = .failed }
        }
        if traveler.y < -60 { status = .failed }
        if traveler.x >= level.exit { status = .completed }
    }
}
