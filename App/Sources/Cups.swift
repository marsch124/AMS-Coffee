import Foundation

// MARK: - The Cup System
//
// Every save is poured into a cup. Cups sit on a shelf you can see.
// Three rules keep it honest:
//   1. Each cup proves itself — it is read back, decoded and counted before
//      it is ever stamped "tested". An unproven cup says so, in orange.
//   2. A cup never shrinks silently. A new cup holding less than the last
//      one does NOT replace it; the old one stays and the shelf raises a flag.
//   3. Nothing is deleted, it is rinsed — into the Sink, for 30 days.

enum CupKind: String, Codable, CaseIterable, Identifiable {
    case quick, daily, keepsake

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quick:    return "Quick cup"
        case .daily:    return "Daily cup"
        case .keepsake: return "Keepsake cup"
        }
    }

    /// How many of this kind the shelf holds. Keepsakes are kept forever.
    var keep: Int? {
        switch self {
        case .quick:    return 10
        case .daily:    return 7
        case .keepsake: return nil
        }
    }
}

struct Cup: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: CupKind = .quick
    var name = ""
    var pouredAt = Date()
    var beanCount = 0
    var shotCount = 0
    var purchaseCount = 0
    var photoCount = 0
    /// Set only after the cup has been read back and its contents counted.
    var tested = false
    var testedNote = ""
    var filename = ""

    var isEmpty: Bool { beanCount == 0 && shotCount == 0 && purchaseCount == 0 }

    var contentsLine: String {
        var parts = ["\(beanCount) bag\(beanCount == 1 ? "" : "s")",
                     "\(shotCount) brew\(shotCount == 1 ? "" : "s")"]
        if purchaseCount > 0 {
            parts.append("\(purchaseCount) thing\(purchaseCount == 1 ? "" : "s")")
        }
        if photoCount > 0 {
            parts.append("\(photoCount) photo\(photoCount == 1 ? "" : "s")")
        }
        return parts.joined(separator: " · ")
    }

    /// Tolerant: a cup poured by 1.0 has no purchase count, and must still
    /// open and still be restorable.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try c.decodeIfPresent(CupKind.self, forKey: .kind) ?? .quick
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        pouredAt = try c.decodeIfPresent(Date.self, forKey: .pouredAt) ?? Date()
        beanCount = try c.decodeIfPresent(Int.self, forKey: .beanCount) ?? 0
        shotCount = try c.decodeIfPresent(Int.self, forKey: .shotCount) ?? 0
        purchaseCount = try c.decodeIfPresent(Int.self, forKey: .purchaseCount) ?? 0
        photoCount = try c.decodeIfPresent(Int.self, forKey: .photoCount) ?? 0
        tested = try c.decodeIfPresent(Bool.self, forKey: .tested) ?? false
        testedNote = try c.decodeIfPresent(String.self, forKey: .testedNote) ?? ""
        filename = try c.decodeIfPresent(String.self, forKey: .filename) ?? ""
    }

    init(id: UUID = UUID(), kind: CupKind = .quick, name: String = "",
         pouredAt: Date = Date(), beanCount: Int = 0, shotCount: Int = 0,
         purchaseCount: Int = 0, photoCount: Int = 0, tested: Bool = false,
         testedNote: String = "", filename: String = "") {
        self.id = id; self.kind = kind; self.name = name; self.pouredAt = pouredAt
        self.beanCount = beanCount; self.shotCount = shotCount
        self.purchaseCount = purchaseCount; self.photoCount = photoCount
        self.tested = tested; self.testedNote = testedNote; self.filename = filename
    }
}

struct CupShelf: Codable, Equatable {
    var cups: [Cup] = []
    /// Raised when a cup was refused for holding less than the last one.
    var warning: String?

    init(cups: [Cup] = [], warning: String? = nil) {
        self.cups = cups
        self.warning = warning
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cups = try c.decodeIfPresent([Cup].self, forKey: .cups) ?? []
        warning = try c.decodeIfPresent(String.self, forKey: .warning)
    }

    var newest: Cup? { cups.sorted { $0.pouredAt > $1.pouredAt }.first }

    func newest(of kind: CupKind) -> Cup? {
        cups.filter { $0.kind == kind }.sorted { $0.pouredAt > $1.pouredAt }.first
    }
}

/// Decides *whether* a cup may be poured and *which* cups may be tipped out.
/// Pure on purpose — the whole safety story is unit-testable without files.
enum CupPolicy {

    /// Rule 2. A cup that holds less than the newest cup on the shelf is
    /// refused, unless the person said so out loud (`force`).
    static func mayPour(_ candidate: Cup, shelf: CupShelf, force: Bool = false) -> Bool {
        if force { return true }
        guard let last = shelf.newest else { return true }
        if candidate.beanCount < last.beanCount { return false }
        if candidate.shotCount < last.shotCount { return false }
        if candidate.purchaseCount < last.purchaseCount { return false }
        return true
    }

    static func refusal(_ candidate: Cup, shelf: CupShelf) -> String? {
        guard let last = shelf.newest, !mayPour(candidate, shelf: shelf) else { return nil }
        return "A cup holding \(candidate.contentsLine) was not poured — the last cup holds \(last.contentsLine). Nothing was overwritten."
    }

    /// Rule: pruning never takes the newest cup of a kind, never takes an
    /// untested cup in preference to a tested one, and never takes a keepsake.
    static func prunable(_ shelf: CupShelf) -> [Cup] {
        var doomed: [Cup] = []
        for kind in CupKind.allCases {
            guard let keep = kind.keep else { continue }
            let mine = shelf.cups.filter { $0.kind == kind }
                .sorted { $0.pouredAt > $1.pouredAt }
            guard mine.count > keep else { continue }
            doomed += mine.dropFirst(keep)
        }
        return doomed
    }
}

// MARK: - Cups on disk

final class CupCupboard {
    private let folder: URL
    /// Where the photo files are, so a cup can check its pictures survived.
    private let photoFolder: URL?
    private let fm = FileManager.default
    private var indexURL: URL { folder.appendingPathComponent("shelf.json") }

    init(folder: URL, photoFolder: URL? = nil) {
        self.folder = folder
        self.photoFolder = photoFolder
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    func loadShelf() -> CupShelf {
        guard let data = try? Data(contentsOf: indexURL),
              let shelf = try? JSONDecoder.coffee.decode(CupShelf.self, from: data)
        else { return CupShelf() }
        return shelf
    }

    private func save(_ shelf: CupShelf) {
        guard let data = try? JSONEncoder.coffee.encode(shelf) else { return }
        try? data.writeAtomically(to: indexURL)
    }

    func url(for cup: Cup) -> URL { folder.appendingPathComponent(cup.filename) }

    /// Pours a cup, then immediately proves it by reading it back.
    /// Returns the cup, or nil when policy refused it (and says why on the shelf).
    @discardableResult
    func pour(_ data: CoffeeData, kind: CupKind, name: String = "", force: Bool = false) -> Cup? {
        var shelf = loadShelf()
        var cup = Cup(kind: kind,
                      name: name,
                      beanCount: data.liveBeans.count,
                      shotCount: data.liveShots.count,
                      purchaseCount: data.livePurchases.count,
                      photoCount: data.photoIDs.count)
        cup.filename = "cup-\(Int(cup.pouredAt.timeIntervalSince1970))-\(cup.id.uuidString.prefix(8)).json"

        // Keepsakes are always allowed — you asked for them by hand.
        let allowed = kind == .keepsake || CupPolicy.mayPour(cup, shelf: shelf, force: force)
        guard allowed else {
            shelf.warning = CupPolicy.refusal(cup, shelf: shelf)
            save(shelf)
            return nil
        }

        guard let payload = try? JSONEncoder.coffee.encode(data),
              (try? payload.writeAtomically(to: url(for: cup))) != nil else {
            shelf.warning = "A cup could not be written to disk. Your data is untouched."
            save(shelf)
            return nil
        }

        // Rule 1 — prove it.
        let proof = test(cup)
        cup.tested = proof.passed
        cup.testedNote = proof.note

        shelf.cups.append(cup)
        shelf.warning = proof.passed ? nil : proof.note

        // Prune only what policy allows, and only after the new cup is proven.
        if proof.passed {
            for old in CupPolicy.prunable(shelf) {
                try? fm.removeItem(at: url(for: old))
                shelf.cups.removeAll { $0.id == old.id }
            }
        }
        save(shelf)
        return cup
    }

    /// Reads the cup back off disk, decodes it and counts what came out.
    /// This is what "tested ✓" means — not "the write returned no error".
    func test(_ cup: Cup) -> (passed: Bool, note: String) {
        guard let raw = try? Data(contentsOf: url(for: cup)) else {
            return (false, "This cup could not be read back.")
        }
        guard let restored = try? JSONDecoder.coffee.decode(CoffeeData.self, from: raw) else {
            return (false, "This cup could not be opened — the contents did not make sense.")
        }
        let beans = restored.liveBeans.count
        let shots = restored.liveShots.count
        let buys = restored.livePurchases.count
        guard beans == cup.beanCount, shots == cup.shotCount,
              buys == cup.purchaseCount else {
            return (false, "This cup came back as \(beans) bags · \(shots) brews · \(buys) things "
                    + "instead of \(cup.contentsLine).")
        }
        // A cup that remembers a photo whose file has gone is not whole.
        if let photoFolder {
            let missing = restored.photoIDs.filter {
                !fm.fileExists(atPath: photoFolder.appendingPathComponent("\($0).jpg").path)
            }
            if !missing.isEmpty {
                return (false, "This cup opened, but \(missing.count) of its photos are missing.")
            }
        }
        return (true, "Opened and counted: \(cup.contentsLine).")
    }

    func read(_ cup: Cup) -> CoffeeData? {
        guard let raw = try? Data(contentsOf: url(for: cup)) else { return nil }
        return try? JSONDecoder.coffee.decode(CoffeeData.self, from: raw)
    }

    func clearWarning() {
        var shelf = loadShelf()
        shelf.warning = nil
        save(shelf)
    }

    func retest(_ cup: Cup) {
        var shelf = loadShelf()
        guard let i = shelf.cups.firstIndex(where: { $0.id == cup.id }) else { return }
        let proof = test(cup)
        shelf.cups[i].tested = proof.passed
        shelf.cups[i].testedNote = proof.note
        save(shelf)
    }

    func tipOut(_ cup: Cup) {
        var shelf = loadShelf()
        try? fm.removeItem(at: url(for: cup))
        shelf.cups.removeAll { $0.id == cup.id }
        save(shelf)
    }
}

// MARK: - Small shared helpers

extension JSONEncoder {
    static var coffee: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
}

extension JSONDecoder {
    static var coffee: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

extension Data {
    /// Write to a neighbour file first, then swap it in. A crash half-way
    /// through leaves the old file whole rather than a truncated new one.
    func writeAtomically(to url: URL) throws {
        let tmp = url.deletingLastPathComponent()
            .appendingPathComponent(".\(url.lastPathComponent).writing")
        try write(to: tmp, options: .atomic)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
        } else {
            try FileManager.default.moveItem(at: tmp, to: url)
        }
    }
}
