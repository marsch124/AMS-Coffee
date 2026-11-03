import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - A backup file you name and place (2.6)
//
// The same promise as a cup: the file is read back off wherever it landed,
// decoded and counted, and only then does it get its green tick.

enum BackupFile {

    static func suggestedName(now: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return "AMS Coffee \(f.string(from: now))"
    }

    /// What you typed, made safe to be a file name. Blank → today's name.
    static func fileName(for typed: String, now: Date = Date()) -> String {
        var name = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        for bad in ["/", ":", "\\"] { name = name.replacingOccurrences(of: bad, with: "-") }
        if name.isEmpty { name = suggestedName(now: now) }
        if !name.lowercased().hasSuffix(".json") { name += ".json" }
        return name
    }

    /// The quiet line under the backup buttons (2.7). Plain words, never a
    /// warning — it says when, and leaves the rest to you.
    static func lastSavedLine(_ date: Date?, now: Date = Date()) -> String {
        guard let date else { return "No backup file saved yet" }
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date),
                                      to: cal.startOfDay(for: now)).day ?? 0
        let when: String
        switch days {
        case ..<1:   when = "today"
        case 1:      when = "yesterday"
        case 2..<14: when = "\(days) days ago"
        case 14..<60: when = "\(days / 7) weeks ago"
        default:
            let months = max(2, days / 30)
            when = "\(months) months ago"
        }
        return "Last backup file: \(when)"
    }

    static func encode(_ data: CoffeeData) throws -> Data {
        try JSONEncoder.coffee.encode(data)
    }

    /// Nil unless it really is a Coffee file. Any JSON would decode — the
    /// reader is forgiving — so it must at least carry bags or brews.
    static func read(_ url: URL) -> CoffeeData? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let raw = try? Data(contentsOf: url),
              let top = try? JSONSerialization.jsonObject(with: raw) as? [String: Any],
              top["beans"] != nil || top["shots"] != nil else { return nil }
        return try? JSONDecoder.coffee.decode(CoffeeData.self, from: raw)
    }

    /// Read it back from where it landed and count what came out.
    static func prove(_ url: URL, expecting data: CoffeeData) -> (passed: Bool, note: String) {
        let want = Cup.counting(data)
        guard let back = read(url) else {
            return (false, "The file could not be opened again. Try saving it somewhere else.")
        }
        let got = Cup.counting(back)
        guard got.beanCount == want.beanCount, got.shotCount == want.shotCount,
              got.purchaseCount == want.purchaseCount else {
            return (false, "The file came back as \(got.contentsLine) instead of \(want.contentsLine).")
        }
        return (true, "Opened and counted: \(want.contentsLine)")
    }
}

extension Cup {
    /// The counts a cup would carry for this data. Photos are left out: a
    /// backup file holds the words, the pictures stay beside the app.
    static func counting(_ data: CoffeeData) -> Cup {
        Cup(beanCount: data.liveBeans.count,
            shotCount: data.liveShots.count,
            purchaseCount: data.livePurchases.count)
    }
}

/// The file handed to the system's "where shall it go?" sheet.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var bytes: Data

    init(bytes: Data) { self.bytes = bytes }

    init(configuration: ReadConfiguration) throws {
        bytes = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: bytes)
    }
}

// MARK: - Same again from the chart (2.6)

extension CoffeeData {
    /// The newest green brew of this bag with this method — nil when none
    /// has been green yet, which is when "Same again from here" stays away.
    func bestGreen(beanID: UUID, method: BrewMethod) -> Shot? {
        liveShots
            .filter { $0.beanID == beanID && $0.method == method && $0.light == .green }
            .max { $0.date < $1.date }
    }
}

extension Shot {
    /// A NEW brew carrying another brew's recipe: same bag, same numbers,
    /// not yet tasted, no note, no photo.
    static func again(from best: Shot) -> Shot {
        var d = best.method.starter()
        d.beanID = best.beanID
        d.grind = best.grind
        d.doseGrams = best.doseGrams
        d.yieldGrams = best.yieldGrams
        d.waterGrams = best.waterGrams
        d.seconds = best.seconds
        d.tempC = best.tempC
        d.preInfusionSeconds = best.preInfusionSeconds
        d.basket = best.basket
        d.bloomGrams = best.bloomGrams
        d.bloomSeconds = best.bloomSeconds
        d.pours = best.pours
        d.steepMinutes = best.steepMinutes
        d.steepHours = best.steepHours
        d.plungeSeconds = best.plungeSeconds
        d.inverted = best.inverted
        d.date = Date()
        return d
    }
}
