import SwiftUI
import SpriteKit

struct GameHost: View {
    @State private var levelID: Int
    @ObservedObject var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss

    init(level: Level, progress: ProgressStore) {
        _levelID = State(initialValue: level.id)
        self.progress = progress
    }

    var body: some View {
        GameScreen(level: Level.all[levelID - 1], progress: progress, close: { dismiss() }, next: { levelID = min(20, levelID + 1) })
            .id(levelID)
            .appSurface()
            .preferredColorScheme(.dark)
            .tint(Palette.lime)
    }
}

struct GameScreen: View {
    @StateObject private var model: GameViewModel
    @ObservedObject var progress: ProgressStore
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let close: () -> Void
    let next: () -> Void

    init(level: Level, progress: ProgressStore, close: @escaping () -> Void, next: @escaping () -> Void) {
        _model = StateObject(wrappedValue: GameViewModel(level: level, store: progress))
        self.progress = progress
        self.close = close
        self.next = next
    }

    var body: some View {
        Group {
            if #available(iOS 27.1, *) {
                foldableContent
            } else {
                legacyContent
            }
        }
        .onChange(of: scenePhase) { phase in if phase != .active { model.pause() } }
        .onChange(of: reduceMotion) { value in model.setReducedEffects(progress.reducedEffects || value) }
        .onAppear {
            model.setReducedEffects(progress.reducedEffects || reduceMotion)
            if let selectedID = model.selectedID { model.scene.select(selectedID) }
        }
        .sheet(item: $model.result) { result in
            ResultScreen(result: result, level: model.engine.level, next: {
                model.result = nil
                next()
            }, replay: {
                model.result = nil
                model.restart()
            }, close: {
                model.result = nil
                close()
            }).interactiveDismissDisabled()
        }
    }

    @available(iOS 27.1, *)
    private var foldableContent: some View {
        NavigationStack {
            ArrangementView {
                ReservedContent {
                    stageWithStatus
                }
                .splitArrangementLayoutRatio(minHorizontal: 0.5, idealHorizontal: 0.66, maxHorizontal: 0.75, minVertical: 0.4, idealVertical: 0.58, maxVertical: 0.7)
                .layoutPriority(1)
            } secondary: {
                ReservedContent {
                    ScrollView {
                        VStack(spacing: 0) {
                            statusBar
                            controlPanel.padding(20)
                        }
                    }
                    .background(Palette.background)
                }
                .splitArrangementLayoutSize(minWidth: 240, idealWidth: 320, minHeight: 220, idealHeight: 320)
            }
            .arrangementViewStyle(.split)
            .background(Palette.background)
            .navigationTitle(model.engine.level.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { closeButton }
                gameToolbar
            }
        }
    }

    private var legacyContent: some View {
        GeometryReader { geometry in
            Group {
                if horizontalSizeClass == .regular && geometry.size.width >= 700 {
                    NavigationSplitView {
                        ScrollView { controlPanel.padding(22) }
                            .background(Palette.background)
                            .navigationTitle("Time controls")
                            .navigationSplitViewColumnWidth(min: 240, ideal: 300, max: 360)
                            .toolbar { ToolbarItem(placement: .navigationBarLeading) { closeButton } }
                    } detail: {
                        stageWithStatus
                            .navigationTitle(model.engine.level.title)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar { gameToolbar }
                    }.navigationSplitViewStyle(.balanced)
                } else {
                    NavigationStack {
                        VStack(spacing: 0) {
                            statusBar
                            if geometry.size.height < 520 {
                                HStack(spacing: 0) {
                                    stageWithStatus
                                    ScrollView { controlPanel.padding(16) }.frame(maxWidth: geometry.size.width * 0.36).background(Palette.background)
                                }
                            } else {
                                stageWithStatus
                                ScrollView { controlPanel.padding(20) }.frame(maxHeight: 360).background(Palette.background)
                            }
                        }.background(Palette.background)
                            .navigationTitle(model.engine.level.title).navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) { closeButton }
                                gameToolbar
                            }
                    }
                }
            }
        }
    }

    private var closeButton: some View {
        Button { model.pause(); close() } label: { Label("Leave level", systemImage: "xmark") }
    }

    @ToolbarContentBuilder private var gameToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                if model.engine.status == .paused { model.resume() } else { model.pause() }
            } label: { Label(model.engine.status == .paused ? "Resume" : "Pause", systemImage: model.engine.status == .paused ? "play.fill" : "pause.fill") }
                .disabled(model.engine.status == .ready || model.engine.status == .completed || model.engine.status == .failed)
            Button { model.restart() } label: { Label("Restart", systemImage: "arrow.counterclockwise") }
        }
    }

    private var statusBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Eyebrow(text: String(format: "LEVEL %02d / 20", model.engine.level.id), color: Palette.lime).fixedSize()
                Spacer()
                timeStatistics.fixedSize()
            }
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: String(format: "LEVEL %02d / 20", model.engine.level.id), color: Palette.lime)
                timeStatistics
            }
        }.padding(.horizontal, 20).padding(.vertical, 14)
    }

    private var timeStatistics: some View {
        HStack {
            Text(String(format: "%05.1fs", model.engine.elapsed)).monospacedDigit()
            Text("·").foregroundStyle(Palette.muted)
            Text("\(model.engine.changes) changes").monospacedDigit()
        }.font(.system(.caption, design: .monospaced)).fixedSize(horizontal: false, vertical: true)
    }

    private var selectedStatus: String {
        guard let selected = model.selected else { return "SELECT AN OBJECT" }
        if selected.spec.kind == .laser { return selected.active ? "DANGER" : "SAFE PHASE" }
        return selected.remaining > 0 ? String(format: "%.1fs LEFT", selected.remaining) : "NORMAL PACE"
    }

    private func panelHeading(_ title: String, detail: String, color: Color) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Eyebrow(text: title).fixedSize()
                Spacer()
                Text(detail).font(.system(.caption2, design: .monospaced)).foregroundStyle(color).fixedSize()
            }
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: title)
                Text(detail).font(.system(.caption2, design: .monospaced)).foregroundStyle(color)
            }.fixedSize(horizontal: false, vertical: true)
        }
    }

    private var stageWithStatus: some View {
        ZStack {
            SpriteView(scene: model.scene, preferredFramesPerSecond: 60)
                .accessibilityLabel("Automatic traveler in a temporal obstacle course. Select objects using the list below.")
                .accessibilityElement(children: .ignore)
            VStack {
                HStack(spacing: 7) {
                    Circle().fill(model.engine.status == .running ? Palette.lime : Palette.violet).frame(width: 5, height: 5)
                    Text(model.engine.status == .running ? "TIMELINE ACTIVE" : "TIMELINE ON HOLD")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced)).tracking(1.5).foregroundStyle(Palette.muted)
                    Spacer()
                }.padding(18)
                Spacer()
                if progress.showHints && model.engine.status == .running && model.engine.elapsed < 7 {
                    Text(model.engine.level.hint).font(.caption).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center)
                        .padding(14).background(Palette.background.opacity(0.9), in: RoundedRectangle(cornerRadius: 12)).padding(16)
                        .allowsHitTesting(false)
                }
            }.allowsHitTesting(false)
            if model.engine.status == .ready {
                stageOverlay(symbol: "hourglass", title: "Find your moment.", detail: "Choose an object and prepare your power. Your traveler moves as soon as you begin.", button: "Begin level", action: model.start)
            } else if model.engine.status == .paused {
                stageOverlay(symbol: "pause.circle", title: "Take your time.", detail: "Every timeline is paused. Continue when you are ready.", button: "Resume journey", action: model.resume)
            } else if model.engine.status == .failed {
                stageOverlay(symbol: "arrow.uturn.backward.circle", title: "Another possibility.", detail: "A different moment can change everything. Try holding the platform near the path, or a laser while it is dim.", button: "Try again", action: model.restart)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
    }

    private func stageOverlay(symbol: String, title: String, detail: String, button: String, action: @escaping () -> Void) -> some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: symbol).font(.system(size: 30, weight: .light)).foregroundStyle(Palette.lime)
                    Text(title).font(.system(.title2, design: .rounded, weight: .bold))
                    Text(detail).font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    Button(action: action) {
                        Label(button, systemImage: "play.fill").fixedSize(horizontal: false, vertical: true).font(.headline).foregroundStyle(Palette.background).padding(.horizontal, 25).padding(.vertical, 15).background(Palette.lime, in: Capsule())
                    }.buttonStyle(.plain)
                }.padding(24).frame(maxWidth: 360).frame(maxWidth: .infinity).frame(minHeight: proxy.size.height)
            }.background(Palette.background.opacity(0.86))
        }
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            panelHeading("01  SELECT AN OBJECT", detail: "\(model.engine.objects.count) IN RANGE", color: Palette.muted)
            WrappingControls {
                ForEach(model.engine.objects) { object in
                    Button { model.select(object.id) } label: {
                        HStack(spacing: 7) {
                            Text(String(format: "%02d", object.id + 1)).font(.system(.caption2, design: .monospaced))
                            Text(shortName(object.spec.kind)).font(.caption.weight(.medium))
                            Image(systemName: object.power?.symbol ?? "clock")
                                .font(.system(size: 12)).frame(width: 16, height: 16)
                                .opacity(object.remaining > 0 ? 1 : 0).accessibilityHidden(true)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 12).padding(.vertical, 14)
                        .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(model.selectedID == object.id ? Palette.lime : Palette.muted)
                            .background(model.selectedID == object.id ? Palette.lime.opacity(0.08) : Palette.panel, in: RoundedRectangle(cornerRadius: 11))
                            .overlay(RoundedRectangle(cornerRadius: 11).stroke(model.selectedID == object.id ? Palette.lime.opacity(0.55) : Palette.line))
                    }.buttonStyle(.plain).accessibilityLabel("Select \(object.spec.kind.rawValue) \(object.id + 1)")
                }
            }
            panelHeading("02  ALTER ITS TIME", detail: selectedStatus, color: model.selected?.active == true ? Palette.coral : Palette.lime)
            WrappingControls {
                ForEach(TimePower.allCases) { power in
                    Button { model.power = power } label: {
                        VStack(spacing: 8) {
                            Image(systemName: power.symbol).font(.system(size: 16, weight: .semibold))
                            Text(power.rawValue).font(.caption.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                        }.padding(.horizontal, 12).padding(.vertical, 14).frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(model.power == power ? Palette.background : Palette.muted)
                            .background(model.power == power ? Palette.lime : Palette.panel, in: RoundedRectangle(cornerRadius: 13))
                    }.buttonStyle(.plain).accessibilityAddTraits(model.power == power ? [.isSelected] : [])
                }
            }
            Button(action: model.apply) {
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Label(applyTitle, systemImage: model.power.symbol).fixedSize()
                        Spacer()
                        Text("3 SEC").font(.system(.caption2, design: .monospaced)).fixedSize()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Label(applyTitle, systemImage: model.power.symbol).fixedSize(horizontal: false, vertical: true)
                        Text("3 SEC").font(.system(.caption2, design: .monospaced))
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.font(.subheadline.weight(.semibold)).foregroundStyle(Palette.lime)
                    .padding(17).background(Palette.lime.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.lime.opacity(0.25)))
            }.buttonStyle(.plain).disabled((model.selected?.remaining ?? 0) > 0 || (model.engine.status != .ready && model.engine.status != .running))
                .opacity((model.selected?.remaining ?? 0) > 0 ? 0.5 : 1)
            if horizontalSizeClass == .regular && progress.showHints {
                Text(model.engine.level.hint).font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4).padding(.top, 8)
                Label("Target: \(model.engine.level.par) changes or fewer", systemImage: "star").font(.caption).foregroundStyle(Palette.lime)
            }
        }
    }

    private var applyTitle: String {
        (model.selected?.remaining ?? 0) > 0 ? "Object time altered" : "Apply \(model.power.rawValue.lowercased())"
    }

    private func shortName(_ kind: ObjectKind) -> String {
        switch kind {
        case .platform: return "Platform"
        case .block: return "Block"
        case .laser: return "Laser"
        case .door: return "Door"
        }
    }
}

struct ResultScreen: View {
    let result: RunResult
    let level: Level
    let next: () -> Void
    let replay: () -> Void
    let close: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Eyebrow(text: "FRACTURE \(String(format: "%02d", level.id)) RESTORED", color: Palette.lime)
                    ZStack {
                        Circle().stroke(Palette.lime.opacity(0.12), lineWidth: 1).frame(width: 150, height: 150)
                        Circle().stroke(Palette.lime.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 8])).frame(width: 180, height: 180)
                        Image(systemName: "checkmark").font(.system(size: 52, weight: .ultraLight)).foregroundStyle(Palette.lime)
                    }.padding(.top, 8)
                    VStack(spacing: 12) {
                        Text(level.id == 20 ? "Time, rewritten." : "A future, restored.").font(.system(size: 32, weight: .bold, design: .rounded)).tracking(-1)
                        Text(level.title).font(.subheadline).foregroundStyle(Palette.muted)
                    }
                    StarRating(count: result.stars, size: 30)
                    HStack(spacing: 12) {
                        resultMetric(String(format: "%.1fs", result.seconds), title: "ELAPSED")
                        resultMetric("\(result.changes)", title: "CHANGES")
                        resultMetric("\(level.par)", title: "3-STAR TARGET")
                    }
                    Text(result.stars == 3 ? "Beautiful timing. Every change had a purpose." : "Try fewer time changes to restore all three stars.")
                        .font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    VStack(spacing: 12) {
                        if level.id < 20 { ActionButton(title: "Next fracture", action: next) }
                        ActionButton(title: "Replay level", symbol: "arrow.counterclockwise", filled: false, action: replay)
                        Button("Return to overview", action: close).font(.subheadline).foregroundStyle(Palette.muted).padding(10)
                    }
                }.padding(28).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }.background(Palette.background)
                .respectingReservedRegions()
                .navigationBarTitleDisplayMode(.inline)
        }.appSurface().tint(Palette.lime).preferredColorScheme(.dark)
    }

    private func resultMetric(_ value: String, title: String) -> some View {
        VStack(spacing: 10) {
            Text(value).font(.system(.title2, design: .monospaced))
            Text(title).font(.system(size: 8, design: .monospaced)).foregroundStyle(Palette.muted)
        }.frame(maxWidth: .infinity).padding(.vertical, 22).background(Palette.panel, in: RoundedRectangle(cornerRadius: 16))
    }
}
