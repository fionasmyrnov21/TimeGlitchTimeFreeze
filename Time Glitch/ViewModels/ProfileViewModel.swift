import Foundation
import Combine
import PhotosUI
import SwiftUI

final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile = PlayerProfile()
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    private let storage: ProfileStorage
    private var requestID = UUID()

    init(storage: ProfileStorage = ProfileStorage()) {
        self.storage = storage
        do { profile = try storage.load() }
        catch { errorMessage = "Your saved image could not be loaded. Please choose it again." }
    }

    func importPhoto(from item: PhotosPickerItem) async {
        let request = UUID()
        requestID = request
        isLoading = true
        defer { if requestID == request { isLoading = false } }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { throw AvatarImageError.unreadable }
            try Task.checkCancellation()
            let prepared = try await Task.detached(priority: .userInitiated) { try AvatarImageProcessor.prepare(data) }.value
            try Task.checkCancellation()
            guard requestID == request else { return }
            try storage.saveAvatar(prepared)
            profile = PlayerProfile(avatarData: prepared)
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled, requestID == request else { return }
            errorMessage = "The image could not be saved. Please try another photo."
        }
    }

    func removePhoto() {
        requestID = UUID()
        isLoading = false
        do {
            try storage.removeAvatar()
            profile = PlayerProfile()
        } catch { errorMessage = "Your image could not be removed. Please try again." }
    }
}
