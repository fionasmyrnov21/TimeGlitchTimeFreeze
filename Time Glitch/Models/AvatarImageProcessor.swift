import Foundation
import ImageIO
import UniformTypeIdentifiers

enum AvatarImageError: Error {
    case unreadable
}

enum AvatarImageProcessor {
    nonisolated static func prepare(_ data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 512,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw AvatarImageError.unreadable }
        let side = min(thumbnail.width, thumbnail.height)
        let crop = CGRect(x: (thumbnail.width - side) / 2, y: (thumbnail.height - side) / 2, width: side, height: side)
        guard let square = thumbnail.cropping(to: crop) else { throw AvatarImageError.unreadable }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { throw AvatarImageError.unreadable }
        CGImageDestinationAddImage(destination, square, [kCGImageDestinationLossyCompressionQuality: 0.88] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw AvatarImageError.unreadable }
        return output as Data
    }
}
