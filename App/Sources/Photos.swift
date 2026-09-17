import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - Where photos live
//
// Photos are files, not JSON. Putting a bag's photo inside coffee.json would
// bloat the file every device syncs and every cup that is poured. So each
// photo is a file named by its own id, and a bag or a purchase just remembers
// the id.
//
// That raises the question the Cup System has to answer: what happens to a
// photo when you pour back a cup from before it existed, or after you rinsed
// the bag that used it? The rule here is that a photo is only ever deleted
// when NOTHING refers to it — not the live data, not the Sink, and not any
// cup on the shelf. Photos outlive their records on purpose.

final class PhotoStore {
    private let folder: URL
    private let fm = FileManager.default

    init(folder: URL) {
        self.folder = folder
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    func url(for id: String) -> URL {
        folder.appendingPathComponent("\(id).jpg")
    }

    func exists(_ id: String) -> Bool {
        fm.fileExists(atPath: url(for: id).path)
    }

    /// Saves already-downscaled JPEG data and returns the new photo's id.
    @discardableResult
    func save(_ data: Data) -> String? {
        let id = UUID().uuidString
        do {
            try data.writeAtomically(to: url(for: id))
            return id
        } catch {
            return nil
        }
    }

    func load(_ id: String) -> Data? {
        let target = url(for: id)
        // In iCloud the file may not be on this device yet. Ask for it, and
        // show the placeholder until it lands rather than pretending it is gone.
        if !fm.fileExists(atPath: target.path) {
            try? fm.startDownloadingUbiquitousItem(at: target)
            return nil
        }
        return try? Data(contentsOf: target)
    }

    var allIDs: Set<String> {
        let names = (try? fm.contentsOfDirectory(atPath: folder.path)) ?? []
        return Set(names.filter { $0.hasSuffix(".jpg") }
            .map { String($0.dropLast(4)) })
    }

    /// Deletes only photos that nothing refers to any more.
    @discardableResult
    func purgeOrphans(keeping referenced: Set<String>) -> Int {
        var removed = 0
        for id in allIDs.subtracting(referenced) {
            if (try? fm.removeItem(at: url(for: id))) != nil { removed += 1 }
        }
        return removed
    }

    // MARK: Making a photo small enough to live in a synced folder

    /// A bag photo is a reminder of which bag it was, not a print. Long edge
    /// 1600px at 70% JPEG keeps it recognisable and around 200 KB, so a year
    /// of bags does not turn the shelf into something that takes minutes to
    /// sync.
    static func downscaled(_ data: Data, maxPixel: Int = 1600,
                           quality: Double = 0.7) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,   // respect EXIF rotation
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        guard let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else { return nil }

        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            out, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, thumb,
                                   [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return out as Data
    }
}

// MARK: - Showing one

/// A photo, or a friendly gap where one will go.
struct PhotoImage: View {
    let data: Data?
    var corner: Double = 18

    var body: some View {
        if let data, let image = Self.image(from: data) {
            image
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Candy.cocoa.opacity(0.08))
                .overlay(
                    Text("📷")
                        .font(.system(size: 28))
                        .opacity(0.45)
                )
        }
    }

    static func image(from data: Data) -> Image? {
        #if os(iOS)
        guard let ui = UIImage(data: data) else { return nil }
        return Image(uiImage: ui)
        #else
        guard let ns = NSImage(data: data) else { return nil }
        return Image(nsImage: ns)
        #endif
    }
}
