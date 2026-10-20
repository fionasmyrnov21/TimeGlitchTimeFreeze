import SwiftUI

struct GameDestination: Identifiable {
    let level: Level
    var id: Int { level.id }
}

struct RootView: View {
    @StateObject private var progress = ProgressStore()
    @StateObject private var profile = ProfileViewModel()
    @State private var tab = 0
    @State private var destination: GameDestination?
    @State private var settingsPresented = false

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                HomeScreen(progress: progress, play: open, browse: { tab = 1 }, guide: { tab = 2 })
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Label("TIME GLITCH", systemImage: "hourglass")
                                .font(.system(.caption, design: .monospaced, weight: .bold)).tracking(2).foregroundStyle(Palette.lime)
                        }
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button { tab = 4 } label: { ProfileAvatar(data: profile.profile.avatarData) }
                                .accessibilityLabel("Player profile")
                            Button { settingsPresented = true } label: { Label("Settings", systemImage: "slider.horizontal.3") }
                        }
                    }
            }.tabItem { Label("Overview", systemImage: "square.grid.2x2") }.tag(0)
            NavigationStack {
                LevelsScreen(progress: progress, play: open)
                    .navigationTitle("Chapters").navigationBarTitleDisplayMode(.inline)
            }.tabItem { Label("Levels", systemImage: "square.stack.3d.up") }.tag(1)
            NavigationStack {
                GuideScreen().navigationTitle("Field guide").navigationBarTitleDisplayMode(.inline)
            }.tabItem { Label("Guide", systemImage: "book.closed") }.tag(2)
            NavigationStack {
                ArchiveScreen(progress: progress).navigationTitle("Your journey").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button { settingsPresented = true } label: { Label("Settings", systemImage: "slider.horizontal.3") }
                        }
                    }
            }.tabItem { Label("Archive", systemImage: "chart.bar.xaxis") }.tag(3)
            NavigationStack {
                ProfileScreen(model: profile, progress: progress)
            }.tabItem { Label("Profile", systemImage: "person.crop.circle") }.tag(4)
        }
        .appSurface()
        .tint(Palette.lime)
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en"))
        .sheet(isPresented: $settingsPresented) { SettingsScreen(progress: progress) }
        .fullScreenCover(item: $destination) { target in
            GameHost(level: target.level, progress: progress)
        }
    }

    private func open(_ level: Level) { destination = GameDestination(level: level) }
}

struct HomeScreen: View {
    @ObservedObject var progress: ProgressStore
    let play: (Level) -> Void
    let browse: () -> Void
    let guide: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Label("SYSTEM ONLINE", systemImage: "circle.fill").font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.5).foregroundStyle(Palette.lime)
                        Spacer()
                        Text("EST. 2086").font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.muted)
                    }
                    let layout = geometry.size.width > 680 ? AnyLayout(HStackLayout(spacing: 30)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                    layout {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("A little glitch.\nA whole new\ntimeline.")
                                .font(.system(size: geometry.size.width > 680 ? 52 : 44, weight: .bold, design: .rounded)).tracking(-1.8).lineSpacing(-2)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("The world moves forward.\nYou decide what doesn't.")
                                .font(.system(.subheadline)).foregroundStyle(Palette.muted).lineSpacing(4)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        ChronoArtwork().frame(height: geometry.size.width > 680 ? 300 : 240).frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 14) {
                        HStack {
                            Eyebrow(text: progress.records.isEmpty ? "YOUR FIRST EXPEDITION" : "PICK UP YOUR TIMELINE")
                            Spacer()
                            Image(systemName: "arrow.up.right").foregroundStyle(Palette.lime)
                        }
                        HStack(alignment: .center, spacing: 16) {
                            Text(String(format: "%02d", progress.nextLevel.id)).font(.system(size: 42, weight: .light, design: .monospaced)).foregroundStyle(Palette.lime)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(progress.nextLevel.title).font(.system(.title3, design: .rounded, weight: .bold))
                                Text("CHAPTER \((progress.nextLevel.id - 1) / 5 + 1)  ·  \(progress.nextLevel.chapter)").font(.system(size: 9, design: .monospaced)).foregroundStyle(Palette.muted)
                            }
                            Spacer(minLength: 0)
                        }
                        ActionButton(title: progress.records.isEmpty ? "Enter the glitch" : "Continue journey") { play(progress.nextLevel) }
                    }.padding(20).background(Palette.panel, in: RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.lime.opacity(0.2)))
                    HStack(spacing: 0) {
                        metric("\(progress.records.count)/20", "LEVELS SOLVED")
                        Rectangle().fill(Palette.line).frame(width: 1, height: 35)
                        metric("\(progress.totalStars)", "STARS EARNED")
                        Rectangle().fill(Palette.line).frame(width: 1, height: 35)
                        metric("03", "TIME POWERS")
                    }.padding(.vertical, 3)
                    SectionHeading(title: "Time is in your hands", trailing: "THE TOOLKIT")
                    HStack(spacing: 10) {
                        ForEach(TimePower.allCases) { power in
                            VStack(alignment: .leading, spacing: 14) {
                                Image(systemName: power.symbol).font(.system(size: 19)).foregroundStyle(power == .rewind ? Palette.violet : Palette.lime)
                                Text(power.rawValue).font(.system(size: 12, weight: .semibold))
                                Text(power == .freeze ? "HOLD" : power == .rewind ? "REVERSE" : "2× PACE").font(.system(size: 8, design: .monospaced)).tracking(1).foregroundStyle(Palette.muted)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(Palette.panel, in: RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    Button(action: guide) {
                        HStack(spacing: 14) {
                            Image(systemName: "lightbulb").foregroundStyle(Palette.violet)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("One object. A world of possibilities.").font(.subheadline.weight(.medium)).foregroundStyle(.white)
                                Text("Learn the rules of local time").font(.caption).foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.muted)
                        }.padding(.vertical, 6)
                    }.buttonStyle(.plain)
                    Button(action: browse) {
                        HStack { Text("Explore all chapters"); Spacer(); Image(systemName: "arrow.right") }
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Palette.lime).padding(.vertical, 12)
                    }
                }.padding(24).frame(maxWidth: 1080).frame(maxWidth: .infinity)
            }.background(Palette.background)
        }.respectingReservedRegions()
    }

    private func metric(_ value: String, _ title: String) -> some View {
        VStack(spacing: 8) {
            Text(value).font(.system(size: 25, weight: .medium, design: .monospaced))
            Text(title).font(.system(size: 8, design: .monospaced)).tracking(1).foregroundStyle(Palette.muted)
        }.frame(maxWidth: .infinity)
    }
}

struct LevelsScreen: View {
    @ObservedObject var progress: ProgressStore
    let play: (Level) -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ScreenHeading(eyebrow: "20 FRACTURES · ONE JOURNEY", title: "Rewrite the path.", subtitle: "Every chapter introduces a new way to think about time.")
                    HStack {
                        ProgressView(value: progress.completion).tint(Palette.lime)
                        Text("\(progress.records.count) / 20").font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.muted)
                    }
                    ForEach(0..<4) { chapter in
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Text(String(format: "%02d", chapter + 1)).font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.lime).padding(9).background(Palette.lime.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
                                Eyebrow(text: Level.all[chapter * 5].chapter)
                                Spacer()
                            }
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: geometry.size.width > 700 ? 4 : 2), spacing: 12) {
                                ForEach(Array(Level.all[(chapter * 5)..<(chapter * 5 + 5)])) { level in
                                    levelTile(level)
                                }
                            }
                        }
                    }
                }.padding(24).frame(maxWidth: 1080).frame(maxWidth: .infinity)
            }.background(Palette.background)
        }.respectingReservedRegions()
    }

    private func levelTile(_ level: Level) -> some View {
        let unlocked = level.id <= progress.unlockedLevel
        let record = progress.records[level.id]
        return Button { play(level) } label: {
            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    Text(String(format: "%02d", level.id)).font(.system(size: 29, weight: .light, design: .monospaced)).foregroundStyle(unlocked ? .white : Palette.muted)
                    Spacer()
                    Image(systemName: unlocked ? record == nil ? "arrow.up.right" : "checkmark" : "lock.fill")
                        .font(.system(size: 13)).foregroundStyle(unlocked ? Palette.lime : Palette.muted)
                }
                Text(level.title).font(.system(.subheadline, design: .rounded, weight: .semibold)).foregroundStyle(unlocked ? .white : Palette.muted).fixedSize(horizontal: false, vertical: true).frame(minHeight: 38, alignment: .topLeading)
                Text(level.focus).font(.caption2).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
                StarRating(count: record?.stars ?? 0)
            }.padding(17).frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.panel, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(level.id == progress.unlockedLevel ? Palette.lime.opacity(0.5) : Palette.line))
        }.buttonStyle(.plain).disabled(!unlocked)
            .accessibilityLabel("Level \(level.id), \(level.title), \(unlocked ? "unlocked" : "locked")")
    }
}
