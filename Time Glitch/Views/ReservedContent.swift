import SwiftUI

struct ReservedContent<Content: View>: View {
    var avoidingDivision = true
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            let viewport = ContentViewport.resolve(in: CGRect(origin: .zero, size: proxy.size), avoiding: exclusions(in: proxy))
            content
                .frame(width: viewport.width, height: viewport.height)
                .clipped()
                .accessibilityHidden(viewport.isEmpty)
                .position(x: viewport.midX, y: viewport.midY)
        }.background(Palette.background.ignoresSafeArea())
    }

    private func exclusions(in proxy: GeometryProxy) -> [CGRect] {
        if #available(iOS 27.1, *) {
            let kinds: [ReservedRegion.Kind] = avoidingDivision ? [.division, .occlusion] : [.occlusion]
            return kinds.flatMap { kind in
                proxy.reservedRegions(kind: kind, layoutDirectionBehavior: .fixed)
                    .filter(\.isActive)
                    .map(\.frame)
            }
        }
        return []
    }
}

extension View {
    func respectingReservedRegions() -> some View {
        ReservedContent { self }
    }
}
