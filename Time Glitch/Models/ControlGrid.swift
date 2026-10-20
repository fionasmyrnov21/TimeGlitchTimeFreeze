import Foundation
import CoreGraphics

enum ControlGrid {
    static func columns(width: CGFloat, idealWidths: [CGFloat], spacing: CGFloat) -> Int {
        guard !idealWidths.isEmpty else { return 1 }
        let minimum = max(44, idealWidths.max() ?? 44)
        return max(1, min(idealWidths.count, Int(min(CGFloat(idealWidths.count), max(0, width + spacing) / (minimum + spacing)))))
    }

    static func frames(width: CGFloat, columns: Int, heights: [CGFloat], spacing: CGFloat) -> [CGRect] {
        guard !heights.isEmpty else { return [] }
        let count = max(1, min(columns, heights.count))
        let gap = min(max(0, spacing), max(0, width) / CGFloat(count))
        let cellWidth = max(0, (width - CGFloat(count - 1) * gap) / CGFloat(count))
        var frames: [CGRect] = []
        var y: CGFloat = 0
        for row in stride(from: 0, to: heights.count, by: count) {
            let end = min(row + count, heights.count)
            let rowHeight = max(44, heights[row..<end].max() ?? 44)
            for index in row..<end {
                frames.append(CGRect(x: CGFloat(index - row) * (cellWidth + gap), y: y, width: cellWidth, height: rowHeight))
            }
            y += rowHeight + gap
        }
        return frames
    }
}
