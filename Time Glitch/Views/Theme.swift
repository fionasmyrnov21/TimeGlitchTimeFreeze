import SwiftUI

enum Palette {
    static let background = Color(red: 0.043, green: 0.055, blue: 0.078)
    static let panel = Color(red: 0.076, green: 0.09, blue: 0.12)
    static let elevated = Color(red: 0.11, green: 0.13, blue: 0.16)
    static let lime = Color(red: 0.79, green: 0.97, blue: 0.36)
    static let violet = Color(red: 0.66, green: 0.56, blue: 1)
    static let muted = Color(red: 0.54, green: 0.59, blue: 0.65)
    static let line = Color.white.opacity(0.09)
    static let coral = Color(red: 1, green: 0.43, blue: 0.45)
}

struct Panel<Content: View>: View {
    var accent: Color = Palette.line
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20).background(Palette.panel, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(accent, lineWidth: 1))
    }
}

struct Eyebrow: View {
    let text: String
    var color: Color = Palette.muted
    var body: some View {
        Text(text).font(.system(.caption2, design: .monospaced, weight: .semibold)).tracking(2).foregroundStyle(color)
    }
}

struct ActionButton: View {
    let title: String
    var symbol = "arrow.right"
    var filled = true
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.system(.headline, design: .rounded)).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 12)
                Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20).padding(.vertical, 19)
            .foregroundStyle(filled ? Palette.background : .white)
            .background(filled ? Palette.lime : Palette.elevated, in: RoundedRectangle(cornerRadius: 17))
        }.buttonStyle(.plain)
    }
}

struct StarRating: View {
    let count: Int
    var size: CGFloat = 13
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { i in
                Image(systemName: i < count ? "star.fill" : "star")
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(i < count ? Palette.lime : Palette.muted.opacity(0.4))
            }
        }.accessibilityLabel("\(count) of 3 stars")
    }
}

struct SectionHeading: View {
    let title: String
    var trailing: String = ""
    var body: some View {
        HStack {
            Text(title).font(.system(.title3, design: .rounded, weight: .bold))
            Spacer()
            Text(trailing).font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.muted)
        }
    }
}

struct ScreenHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: eyebrow, color: Palette.lime)
            Text(title).font(.system(size: 36, weight: .bold, design: .rounded)).tracking(-1)
            Text(subtitle).font(.subheadline).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ChronoArtwork: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            Canvas { context, size in
                for x in stride(from: CGFloat(4), to: size.width, by: 22) {
                    for y in stride(from: CGFloat(4), to: size.height, by: 22) {
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(.white.opacity(0.12)))
                    }
                }
                let center = CGPoint(x: size.width * 0.55, y: size.height * 0.47)
                for i in 0..<4 {
                    let r = CGFloat(52 + i * 22)
                    var arc = Path()
                    arc.addArc(center: center, radius: r, startAngle: .degrees(Double(i * 35)), endAngle: .degrees(Double(i * 35 + 260)), clockwise: false)
                    context.stroke(arc, with: .color(i == 1 ? Palette.lime.opacity(0.6) : Palette.lime.opacity(0.1)), style: StrokeStyle(lineWidth: i == 1 ? 2 : 1, dash: i == 3 ? [2, 8] : []))
                }
                for i in 0..<3 {
                    let x = size.width * CGFloat([0.08, 0.4, 0.75][i])
                    let y = size.height * CGFloat([0.78, 0.66, 0.51][i])
                    var top = Path()
                    top.move(to: CGPoint(x: x, y: y))
                    top.addLine(to: CGPoint(x: x + 55, y: y - 23))
                    top.addLine(to: CGPoint(x: x + 100, y: y - 1))
                    top.addLine(to: CGPoint(x: x + 45, y: y + 23))
                    top.closeSubpath()
                    context.fill(top, with: .color(i == 1 ? Palette.lime.opacity(0.22) : Palette.elevated))
                    context.stroke(top, with: .color(i == 1 ? Palette.lime : .white.opacity(0.2)), lineWidth: 1)
                    var side = Path()
                    side.move(to: CGPoint(x: x, y: y))
                    side.addLine(to: CGPoint(x: x + 45, y: y + 23))
                    side.addLine(to: CGPoint(x: x + 100, y: y - 1))
                    side.addLine(to: CGPoint(x: x + 100, y: y + 24))
                    side.addLine(to: CGPoint(x: x + 45, y: y + 48))
                    side.addLine(to: CGPoint(x: x, y: y + 25))
                    side.closeSubpath()
                    context.fill(side, with: .color(Palette.background))
                    context.stroke(side, with: .color(.white.opacity(0.12)), lineWidth: 1)
                }
            }
            TravelerIllustration().frame(width: 56, height: 82).position(x: w * 0.55, y: h * 0.47)
            HStack(spacing: 6) {
                Image(systemName: "pause.fill")
                Text("LOCAL TIME HELD")
            }.font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1).foregroundStyle(Palette.lime)
                .padding(8).background(Palette.background.opacity(0.85), in: Capsule()).position(x: w * 0.36, y: h * 0.84)
            Text("t − 00:03").font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.violet).position(x: w * 0.8, y: h * 0.19)
        }.accessibilityHidden(true)
    }
}

struct TravelerIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5).fill(Palette.violet).frame(width: 15, height: 30).offset(x: -20, y: 7)
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.58)).frame(width: 12, height: 23)
                RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.7)).frame(width: 12, height: 23)
            }.offset(y: 29)
            RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.85)).frame(width: 36, height: 38).offset(y: 10)
            RoundedRectangle(cornerRadius: 15).fill(.white).frame(width: 48, height: 38).offset(y: -18)
            RoundedRectangle(cornerRadius: 9).fill(Palette.background).frame(width: 33, height: 21).offset(x: 7, y: -17)
            RoundedRectangle(cornerRadius: 2).fill(Palette.lime).frame(width: 15, height: 3).offset(x: 11, y: -20)
            RoundedRectangle(cornerRadius: 2).fill(Palette.violet).frame(width: 10, height: 4).offset(y: 11)
        }.rotationEffect(.degrees(-6))
    }
}
