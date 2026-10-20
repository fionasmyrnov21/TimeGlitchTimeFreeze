import SwiftUI

struct WrappingControls: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let frames = frames(proposal: proposal, subviews: subviews)
        return CGSize(width: frames.map(\.maxX).max() ?? 0, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = frames(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        for (index, frame) in frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), anchor: .topLeading, proposal: ProposedViewSize(frame.size))
        }
    }

    private func frames(proposal: ProposedViewSize, subviews: Subviews) -> [CGRect] {
        let idealWidths = subviews.map { $0.sizeThatFits(.unspecified).width }
        let idealWidth = idealWidths.reduce(0, +) + CGFloat(max(0, subviews.count - 1)) * spacing
        let width = max(0, proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? idealWidth)
        let columns = ControlGrid.columns(width: width, idealWidths: idealWidths, spacing: spacing)
        let cellWidth = max(0, (width - CGFloat(columns - 1) * spacing) / CGFloat(columns))
        let heights = subviews.map { $0.sizeThatFits(ProposedViewSize(width: cellWidth, height: nil)).height }
        return ControlGrid.frames(width: width, columns: columns, heights: heights, spacing: spacing)
    }
}
