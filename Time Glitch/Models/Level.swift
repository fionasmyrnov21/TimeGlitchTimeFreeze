import Foundation
import CoreGraphics

enum TimePower: String, CaseIterable, Identifiable {
    case freeze = "Freeze"
    case rewind = "Rewind"
    case accelerate = "Accelerate"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .freeze: return "pause.fill"
        case .rewind: return "backward.fill"
        case .accelerate: return "forward.fill"
        }
    }
    var detail: String {
        switch self {
        case .freeze: return "Hold for 3 seconds"
        case .rewind: return "Reverse its timeline"
        case .accelerate: return "Move at twice the pace"
        }
    }
}

enum ObjectKind: String, Codable {
    case platform = "Moving platform"
    case block = "Falling block"
    case laser = "Laser gate"
    case door = "Phase door"
}

enum MotionAxis: String {
    case horizontal, vertical
}

struct ObjectSpec: Identifiable, Equatable {
    let id: Int
    let kind: ObjectKind
    let origin: CGPoint
    let size: CGSize
    let travel: CGFloat
    let period: Double
    let offset: Double
    var axis: MotionAxis = .vertical
    var activeFraction: Double = 0.52
}

struct Level: Identifiable, Equatable {
    let id: Int
    let title: String
    let chapter: String
    let hint: String
    let focus: String
    let par: Int
    let speed: CGFloat
    let objects: [ObjectSpec]
    let floors: [CGRect]
    let exit: CGFloat

    static let all: [Level] = LevelCatalog.levels

    var exitHeight: CGFloat {
        floors.first { exit >= $0.minX && exit <= $0.maxX }?.maxY ?? 100
    }

    var worldEnd: CGFloat { max(exit + 100, floors.map(\.maxX).max() ?? exit + 100) }

}

struct TemporalObject: Identifiable, Equatable {
    let spec: ObjectSpec
    var localTime: Double = 0
    var remaining: Double = 0
    var power: TimePower?
    var id: Int { spec.id }

    var phase: Double {
        let value = (localTime + spec.offset).truncatingRemainder(dividingBy: spec.period)
        let fraction = (value < 0 ? value + spec.period : value) / spec.period
        return min(max(fraction, 0), Double(1).nextDown)
    }
    var active: Bool { spec.kind == .laser && phase < spec.activeFraction }
    var rect: CGRect {
        var center = spec.origin
        switch spec.kind {
        case .platform:
            let movement = CGFloat(sin(phase * .pi * 2)) * spec.travel
            if spec.axis == .horizontal { center.x += movement } else { center.y += movement }
        case .block:
            center.y += CGFloat((1 + cos(phase * .pi * 2)) / 2) * spec.travel
        case .door:
            center.y += phase > spec.activeFraction ? spec.travel : 0
        case .laser: break
        }
        return CGRect(x: center.x - spec.size.width / 2, y: center.y - spec.size.height / 2, width: spec.size.width, height: spec.size.height)
    }
    mutating func advance(_ delta: Double) {
        let affected = min(delta, remaining)
        let rate: Double = power == .freeze ? 0 : power == .rewind ? -1 : power == .accelerate ? 2 : 1
        localTime += affected * rate + (delta - affected)
        remaining = max(0, remaining - delta)
        if remaining == 0 { power = nil }
    }
}

enum RunStatus: Equatable {
    case ready, running, paused, failed, completed
}

struct RunResult: Identifiable {
    let id = UUID()
    let levelID: Int
    let seconds: Double
    let changes: Int
    let stars: Int
}
