import Foundation
import CoreGraphics

enum ContentViewport {
    static func resolve(in bounds: CGRect, avoiding exclusions: [CGRect]) -> CGRect {
        guard bounds.width > 0, bounds.height > 0 else { return .zero }
        var candidates = [bounds]
        for exclusion in exclusions {
            guard !exclusion.isNull, !exclusion.isEmpty else { continue }
            candidates = candidates.flatMap { candidate -> [CGRect] in
                let covered = candidate.intersection(exclusion)
                guard !covered.isNull, !covered.isEmpty else { return [candidate] }
                return [
                    CGRect(x: candidate.minX, y: candidate.minY, width: candidate.width, height: covered.minY - candidate.minY),
                    CGRect(x: candidate.minX, y: covered.maxY, width: candidate.width, height: candidate.maxY - covered.maxY),
                    CGRect(x: candidate.minX, y: candidate.minY, width: covered.minX - candidate.minX, height: candidate.height),
                    CGRect(x: covered.maxX, y: candidate.minY, width: candidate.maxX - covered.maxX, height: candidate.height)
                ].filter { $0.width > 0 && $0.height > 0 }
            }
        }
        return candidates.sorted { lhs, rhs in
            let firstArea = lhs.width * lhs.height
            let secondArea = rhs.width * rhs.height
            if firstArea != secondArea { return firstArea > secondArea }
            if lhs.minY != rhs.minY { return lhs.minY < rhs.minY }
            return lhs.minX < rhs.minX
        }.first ?? .zero
    }
}
