import Foundation

struct PlayerProfile {
    var avatarData: Data?
}

struct ProfileStorage {
    private let directory: String
    private var imagePath: String { (directory as NSString).appendingPathComponent("avatar.jpg") }

    init(directory: String? = nil) {
        let base = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
        self.directory = directory ?? (base as NSString).appendingPathComponent("TimeGlitchProfile")
    }

    func load() throws -> PlayerProfile {
        guard FileManager.default.fileExists(atPath: imagePath) else { return PlayerProfile() }
        guard let data = FileManager.default.contents(atPath: imagePath) else { throw CocoaError(.fileReadUnknown) }
        return PlayerProfile(avatarData: data)
    }

    func saveAvatar(_ data: Data) throws {
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        try (data as NSData).write(toFile: imagePath, options: .atomic)
    }

    func removeAvatar() throws {
        if FileManager.default.fileExists(atPath: imagePath) { try FileManager.default.removeItem(atPath: imagePath) }
    }
}
