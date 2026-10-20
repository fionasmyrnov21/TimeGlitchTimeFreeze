import SwiftUI
import PhotosUI
import UIKit

struct ProfileScreen: View {
    @ObservedObject var model: ProfileViewModel
    @ObservedObject var progress: ProgressStore
    @State private var selectedItem: PhotosPickerItem?
    @State private var confirmRemoval = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ScreenHeading(eyebrow: "THE TRAVELER BEHIND THE TIMELINE", title: "Make it yours.", subtitle: "Give your expedition a familiar face.")
                Panel(accent: Palette.lime.opacity(0.25)) {
                    VStack(spacing: 18) {
                        ZStack {
                            ProfileAvatar(data: model.profile.avatarData, size: 120)
                            if model.isLoading {
                                Circle().fill(Palette.background.opacity(0.7))
                                ProgressView().tint(Palette.lime)
                            }
                        }.frame(width: 120, height: 120)
                        Text("Traveler").font(.system(.title2, design: .rounded, weight: .bold))
                        Text(model.isLoading ? "Preparing your image…" : "Your player portrait")
                            .font(.subheadline).foregroundStyle(Palette.muted)
                        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                            Label(model.profile.avatarData == nil ? "Choose an image" : "Change image", systemImage: "photo.on.rectangle")
                                .font(.headline).fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .padding(12).foregroundStyle(Palette.background)
                                .background(Palette.lime, in: RoundedRectangle(cornerRadius: 14))
                        }.buttonStyle(.plain).disabled(model.isLoading)
                        if model.profile.avatarData != nil {
                            Button(role: .destructive) { confirmRemoval = true } label: {
                                Label("Remove image", systemImage: "trash")
                                    .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, minHeight: 44)
                            }.buttonStyle(.plain).foregroundStyle(Palette.coral).disabled(model.isLoading)
                        }
                    }.frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                Text("Choose an image from your photo library. It is fitted to a square portrait and saved on this device.")
                    .font(.subheadline).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
                SectionHeading(title: "Your expedition")
                Panel {
                    LabeledContent("Levels solved", value: "\(progress.records.count) / 20")
                    LabeledContent("Stars earned", value: "\(progress.totalStars) / 60")
                    LabeledContent("Current chapter", value: "\((progress.nextLevel.id - 1) / 5 + 1) / 4")
                }
            }.padding(24).frame(maxWidth: 660).frame(maxWidth: .infinity)
        }
        .background(Palette.background)
        .respectingReservedRegions()
        .navigationTitle("Player profile").navigationBarTitleDisplayMode(.inline)
        .task(id: selectedItem) {
            guard let selectedItem else { return }
            await model.importPhoto(from: selectedItem)
            if self.selectedItem == selectedItem { self.selectedItem = nil }
        }
        .confirmationDialog("Remove your profile image?", isPresented: $confirmRemoval, titleVisibility: .visible) {
            Button("Remove image", role: .destructive) { model.removePhoto() }
            Button("Keep image", role: .cancel) { }
        } message: { Text("You can choose another image at any time.") }
        .alert("Profile image", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
    }
}

struct ProfileAvatar: View {
    let data: Data?
    var size: CGFloat = 30

    var body: some View {
        ZStack {
            Circle().fill(Palette.elevated)
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().padding(size * 0.13).foregroundStyle(Palette.lime)
            }
        }
        .frame(width: size, height: size).clipShape(Circle())
        .overlay(Circle().stroke(Palette.lime.opacity(0.35), lineWidth: 1))
        .accessibilityLabel(data == nil ? "Default player portrait" : "Your player portrait")
    }
}
