import SwiftUI

struct GuideScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ScreenHeading(eyebrow: "THE RULES OF THE FRACTURE", title: "Think outside time.", subtitle: "Your traveler moves automatically. Change the world around them, one object at a time.")
                Panel(accent: Palette.lime.opacity(0.25)) {
                    HStack(alignment: .top, spacing: 18) {
                        Text("01").font(.system(.title, design: .monospaced)).foregroundStyle(Palette.lime)
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Observe. Select. Alter.").font(.title3.weight(.semibold))
                            Text("Tap an outlined object in the scene or choose it from the object list. Pick a power and apply it. Everything else keeps its own pace.").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
                        }
                    }
                }
                ForEach(TimePower.allCases) { power in
                    Panel {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: power.symbol).foregroundStyle(power == .rewind ? Palette.violet : Palette.lime).font(.title2).frame(width: 40, height: 40).background(Palette.elevated, in: RoundedRectangle(cornerRadius: 12))
                                Text(power.rawValue).font(.title3.bold())
                                Spacer()
                                Text(power == .accelerate ? "2× / 3 SEC" : "3 SEC").font(.system(.caption2, design: .monospaced)).foregroundStyle(Palette.muted)
                            }
                            Text(description(power)).font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
                        }
                    }
                }
                SectionHeading(title: "Know your surroundings")
                ForEach([ObjectKind.platform, .block, .laser, .door], id: \.rawValue) { kind in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: symbol(kind)).foregroundStyle(kind == .laser ? Palette.coral : Palette.violet).font(.title3).frame(width: 32)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(kind.rawValue).font(.headline)
                            Text(description(kind)).font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(3)
                        }
                    }.padding(.vertical, 8)
                }
                Panel {
                    Label("A perfect run", systemImage: "star.fill").font(.headline).foregroundStyle(Palette.lime)
                    Text("Reach the exit to earn a star. Use no more than the level's target number of changes for all three. A few extra changes earn two. Replay any solved level to improve your record.").font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
                }
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Palette.background)
            .respectingReservedRegions()
    }

    private func description(_ power: TimePower) -> String {
        switch power {
        case .freeze: return "Stop a single object's clock for three seconds. Hold a platform in place or keep a laser in its safe phase. The traveler keeps moving."
        case .rewind: return "Run an object's timeline backward for three seconds. Return a block to a previous position or reverse a gate's cycle. Only that object is affected."
        case .accelerate: return "Advance one object's clock at twice its normal rate for three seconds. Bring a platform into reach or make a closed door open sooner."
        }
    }
    private func symbol(_ kind: ObjectKind) -> String {
        switch kind {
        case .platform: return "rectangle.on.rectangle"
        case .block: return "cube"
        case .laser: return "bolt.horizontal"
        case .door: return "door.left.hand.open"
        }
    }
    private func description(_ kind: ObjectKind) -> String {
        switch kind {
        case .platform: return "A bridge with its own rhythm. Freeze it near path height to cross the gap. Your traveler jumps at edges automatically."
        case .block: return "It rises and falls. Hold it low to use it as a step. Stay clear of its downward path."
        case .laser: return "Bright means danger. Dim means safe. Freeze a dim laser to extend your crossing window."
        case .door: return "It opens and closes on a cycle. The traveler waits at a closed door, giving you a chance to change its timing."
        }
    }
}

struct ArchiveScreen: View {
    @ObservedObject var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ScreenHeading(eyebrow: "YOUR TEMPORAL FOOTPRINT", title: "Every second counts.", subtitle: "A record of the paths you have rewritten.")
                Panel(accent: Palette.lime.opacity(0.2)) {
                    HStack(spacing: 24) {
                        ZStack {
                            Circle().stroke(Palette.elevated, lineWidth: 7)
                            Circle().trim(from: 0, to: progress.completion).stroke(Palette.lime, style: StrokeStyle(lineWidth: 7, lineCap: .round)).rotationEffect(.degrees(-90))
                            Text("\(Int(progress.completion * 100))%").font(.system(.title2, design: .monospaced, weight: .medium))
                        }.frame(width: 96, height: 96)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Timeline restored").font(.headline)
                            Text("\(progress.records.count) of 20 levels solved").font(.subheadline).foregroundStyle(Palette.muted)
                            Label("\(progress.totalStars) / 60 stars", systemImage: "star.fill").font(.subheadline).foregroundStyle(Palette.lime)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                SectionHeading(title: "Expedition log", trailing: "PERSONAL BESTS")
                if progress.records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.checkmark").font(.system(size: 40, weight: .ultraLight)).foregroundStyle(Palette.violet)
                        Text("Your story starts with a second.").font(.headline)
                        Text("Complete your first level to begin the log.").font(.subheadline).foregroundStyle(Palette.muted)
                    }.frame(maxWidth: .infinity).padding(.vertical, 50)
                } else {
                    ForEach(Level.all.filter { progress.records[$0.id] != nil }) { level in
                        if let record = progress.records[level.id] {
                            HStack(spacing: 15) {
                                Text(String(format: "%02d", level.id)).font(.system(.title2, design: .monospaced)).foregroundStyle(Palette.lime)
                                VStack(alignment: .leading, spacing: 7) {
                                    Text(level.title).font(.headline)
                                    Text(String(format: "%.1fs  ·  %d changes", record.bestSeconds, record.fewestChanges)).font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.muted)
                                }
                                Spacer()
                                StarRating(count: record.stars, size: 10)
                            }.padding(18).background(Palette.panel, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Palette.background)
            .respectingReservedRegions()
    }
}

struct SettingsScreen: View {
    @ObservedObject var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Haptic feedback", isOn: $progress.haptics)
                    Toggle("Reduce visual effects", isOn: $progress.reducedEffects)
                    Toggle("Level hints", isOn: $progress.showHints)
                } header: { Text("Your experience") } footer: { Text("Visual effect changes apply when you enter or restart a level. System motion preferences are also respected.") }
                Section {
                    Button("Reset journey", role: .destructive) { confirmReset = true }
                } footer: { Text("Clears level records and stars. Your preferences stay the same.") }
            }
            .scrollContentBackground(.hidden).background(Palette.background)
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Reset your journey?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset progress", role: .destructive) { progress.reset() }
                Button("Keep progress", role: .cancel) { }
            } message: { Text("All level records and stars will be cleared.") }
        }.appSurface().tint(Palette.lime).preferredColorScheme(.dark)
    }
}
