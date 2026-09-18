import Foundation

// MARK: - Brew methods

enum BrewMethod: String, Codable, CaseIterable, Identifiable {
    case espresso, v60, aeropress, frenchPress, moka, coldBrew, filter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .espresso:    return "Espresso"
        case .v60:         return "Pour-over"
        case .aeropress:   return "AeroPress"
        case .frenchPress: return "French press"
        case .moka:        return "Moka"
        case .coldBrew:    return "Cold brew"
        case .filter:      return "Filter"
        }
    }

    /// Espresso is weighed out of the cup; everything else is weighed in.
    var isWeighedByWaterIn: Bool { self != .espresso }

    /// Which dials this method shows, in the order you would actually use them.
    var fields: [BrewField] {
        switch self {
        case .espresso:
            return [.grind, .dose, .yield, .seconds, .temp, .preInfusion]
        case .v60, .filter:
            return [.grind, .dose, .water, .temp, .bloomWater, .bloomSeconds, .pours, .seconds]
        case .aeropress:
            return [.grind, .dose, .water, .temp, .steepMinutes, .plungeSeconds]
        case .frenchPress:
            return [.grind, .dose, .water, .temp, .steepMinutes]
        case .moka:
            return [.grind, .dose, .water, .seconds]
        case .coldBrew:
            return [.grind, .dose, .water, .steepHours]
        }
    }

    var hasInvertedSwitch: Bool { self == .aeropress }

    /// Cold brew steeps overnight; a stopwatch would be silly. Everything
    /// else is worth timing.
    var worthTiming: Bool { self != .coldBrew }

    /// The methods that pour a bloom first, so the timer can split it out.
    var hasBloom: Bool { fields.contains(.bloomWater) }

    /// The methods whose time is written in minutes of steeping.
    var steepsInMinutes: Bool { fields.contains(.steepMinutes) }

    /// A sensible place to start when there is no previous brew to copy.
    func starter() -> Shot {
        var s = Shot()
        s.method = self
        switch self {
        case .espresso:
            s.grind = 15; s.doseGrams = 18; s.yieldGrams = 36
            s.seconds = 28; s.tempC = 93; s.preInfusionSeconds = 0
        case .v60:
            s.grind = 25; s.doseGrams = 15; s.waterGrams = 250; s.tempC = 94
            s.bloomGrams = 45; s.bloomSeconds = 45; s.pours = 3; s.seconds = 180
        case .filter:
            s.grind = 28; s.doseGrams = 30; s.waterGrams = 500; s.tempC = 93
            s.bloomGrams = 60; s.bloomSeconds = 30; s.pours = 1; s.seconds = 300
        case .aeropress:
            s.grind = 22; s.doseGrams = 16; s.waterGrams = 230; s.tempC = 85
            s.steepMinutes = 2; s.plungeSeconds = 30; s.seconds = 150
        case .frenchPress:
            s.grind = 34; s.doseGrams = 30; s.waterGrams = 500; s.tempC = 94
            s.steepMinutes = 4; s.seconds = 240
        case .moka:
            s.grind = 20; s.doseGrams = 18; s.waterGrams = 150; s.seconds = 240
            s.tempC = 100
        case .coldBrew:
            s.grind = 38; s.doseGrams = 80; s.waterGrams = 1000
            s.steepHours = 16; s.tempC = 20
        }
        return s
    }
}

/// One dial in the brew editor. Everything about how it looks and steps lives
/// here, so a method only has to name the fields it wants.
enum BrewField: String, CaseIterable, Identifiable {
    case grind, dose, yield, water, seconds, temp, preInfusion
    case bloomWater, bloomSeconds, pours, steepMinutes, steepHours, plungeSeconds

    var id: String { rawValue }

    var label: String {
        switch self {
        case .grind:         return "Grind setting"
        case .dose:          return "Coffee in"
        case .yield:         return "Yield out"
        case .water:         return "Water in"
        case .seconds:        return "Total time"
        case .temp:          return "Temperature"
        case .preInfusion:   return "Pre-infusion"
        case .bloomWater:    return "Bloom water"
        case .bloomSeconds:  return "Bloom time"
        case .pours:         return "Pours after the bloom"
        case .steepMinutes:  return "Steep"
        case .steepHours:    return "Steep"
        case .plungeSeconds: return "Plunge"
        }
    }

    var unit: String {
        switch self {
        case .grind, .pours:                        return ""
        case .dose, .yield, .water, .bloomWater:    return "g"
        case .seconds, .bloomSeconds, .plungeSeconds, .preInfusion: return "s"
        case .temp:                                 return "°C"
        case .steepMinutes:                         return "min"
        case .steepHours:                           return "h"
        }
    }

    var step: Double {
        switch self {
        case .grind:         return 0.5
        case .dose:          return 0.5
        case .yield, .water, .bloomWater: return 5
        case .seconds:       return 5
        case .temp:          return 1
        case .preInfusion, .bloomSeconds, .plungeSeconds: return 5
        case .pours:         return 1
        case .steepMinutes:  return 0.5
        case .steepHours:    return 1
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .grind:         return 0...100
        case .dose:          return 0...200
        case .yield:         return 0...300
        case .water, .bloomWater: return 0...3000
        case .seconds:       return 0...1800
        case .temp:          return 0...100
        case .preInfusion, .bloomSeconds, .plungeSeconds: return 0...300
        case .pours:         return 0...12
        case .steepMinutes:  return 0...60
        case .steepHours:    return 0...72
        }
    }

    var identifier: String { "shot-\(rawValue.lowercased())" }
}

// MARK: - Beans

enum Verdict: String, Codable, CaseIterable {
    case undecided, buyAgain, never

    var title: String {
        switch self {
        case .undecided: return "Undecided"
        case .buyAgain:  return "Buy again"
        case .never:     return "Never again"
        }
    }
}

/// The taste wheel, kept short on purpose — pick, don't type. No pictures:
/// twelve tiny drawn fruits would read worse than twelve clear words, and
/// each one already has its own colour.
enum Flavour: String, Codable, CaseIterable, Identifiable {
    case chocolate, caramel, nutty, berry, citrus, stoneFruit
    case floral, spice, earthy, wine, honey, bread

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stoneFruit: return "Stone fruit"
        default:          return rawValue.capitalized
        }
    }
}

struct Bean: Identifiable, Codable, Equatable {
    var id = UUID()
    var roaster = ""
    var name = ""
    var origin = ""
    var process = ""
    var roastLevel = ""
    var roastDate: Date?
    var bagWeightGrams: Double = 250
    var priceSEK: Double = 0
    var rating: Int = 0
    var verdict: Verdict = .undecided
    var flavours: [Flavour] = []
    var notes = ""
    /// The photo lives as a file; this is only its name.
    var photoID: String?
    var createdAt = Date()
    var modifiedAt = Date()
    /// The Sink. Nothing is ever hard-deleted from under you.
    var rinsedAt: Date?

    var displayName: String {
        let n = name.trimmingCharacters(in: .whitespaces)
        let r = roaster.trimmingCharacters(in: .whitespaces)
        if n.isEmpty && r.isEmpty { return "New bag" }
        if n.isEmpty { return r }
        return n
    }

    var pricePerKilo: Double? {
        guard bagWeightGrams > 0, priceSEK > 0 else { return nil }
        return priceSEK / bagWeightGrams * 1000
    }

    /// Tolerant on purpose: a field added in a later version must never stop
    /// an older file — or an older cup — from opening.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        roaster = try c.decodeIfPresent(String.self, forKey: .roaster) ?? ""
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        origin = try c.decodeIfPresent(String.self, forKey: .origin) ?? ""
        process = try c.decodeIfPresent(String.self, forKey: .process) ?? ""
        roastLevel = try c.decodeIfPresent(String.self, forKey: .roastLevel) ?? ""
        roastDate = try c.decodeIfPresent(Date.self, forKey: .roastDate)
        bagWeightGrams = try c.decodeIfPresent(Double.self, forKey: .bagWeightGrams) ?? 250
        priceSEK = try c.decodeIfPresent(Double.self, forKey: .priceSEK) ?? 0
        rating = try c.decodeIfPresent(Int.self, forKey: .rating) ?? 0
        verdict = try c.decodeIfPresent(Verdict.self, forKey: .verdict) ?? .undecided
        flavours = try c.decodeIfPresent([Flavour].self, forKey: .flavours) ?? []
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        photoID = try c.decodeIfPresent(String.self, forKey: .photoID)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        modifiedAt = try c.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? createdAt
        rinsedAt = try c.decodeIfPresent(Date.self, forKey: .rinsedAt)
    }

    init(id: UUID = UUID(), roaster: String = "", name: String = "", origin: String = "",
         process: String = "", roastLevel: String = "", roastDate: Date? = nil,
         bagWeightGrams: Double = 250, priceSEK: Double = 0, rating: Int = 0,
         verdict: Verdict = .undecided, flavours: [Flavour] = [], notes: String = "",
         createdAt: Date = Date(), modifiedAt: Date = Date(), rinsedAt: Date? = nil) {
        self.id = id; self.roaster = roaster; self.name = name; self.origin = origin
        self.process = process; self.roastLevel = roastLevel; self.roastDate = roastDate
        self.bagWeightGrams = bagWeightGrams; self.priceSEK = priceSEK; self.rating = rating
        self.verdict = verdict; self.flavours = flavours; self.notes = notes
        self.createdAt = createdAt; self.modifiedAt = modifiedAt; self.rinsedAt = rinsedAt
    }
}

// MARK: - Brews

enum TrafficLight: String, Codable, CaseIterable, Identifiable {
    case red, amber, green

    var id: String { rawValue }

    var title: String {
        switch self {
        case .red:   return "Tipped it out"
        case .amber: return "Drinkable"
        case .green: return "Lovely"
        }
    }
}

/// One brew. Called Shot for historical reasons — it holds every method.
struct Shot: Identifiable, Codable, Equatable {
    var id = UUID()
    var beanID: UUID?
    var date = Date()
    var method: BrewMethod = .espresso

    var grind: Double = 15
    var doseGrams: Double = 18
    var yieldGrams: Double = 36          // espresso: weighed out of the cup
    var waterGrams: Double = 0           // everything else: weighed in
    var seconds: Double = 28
    var tempC: Double = 93
    var preInfusionSeconds: Double = 0
    var basket = ""

    // Added in 1.1 for the other methods.
    var bloomGrams: Double = 0
    var bloomSeconds: Double = 0
    var pours: Double = 0
    var steepMinutes: Double = 0
    var steepHours: Double = 0
    var plungeSeconds: Double = 0
    var inverted = false

    /// −1 sour … 0 balanced … +1 bitter
    var sourBitter: Double = 0
    /// −1 thin … 0 fine … +1 syrupy
    var thinSyrupy: Double = 0
    var light: TrafficLight = .amber
    var note = ""
    /// A photo of the brew — the crema, the bed, the cup. A file name only.
    var photoID: String?

    var createdAt = Date()
    var modifiedAt = Date()
    var rinsedAt: Date?

    /// Grams of liquid this brew was measured by.
    var liquidGrams: Double {
        method.isWeighedByWaterIn ? waterGrams : yieldGrams
    }

    var ratio: Double? {
        guard doseGrams > 0, liquidGrams > 0 else { return nil }
        return liquidGrams / doseGrams
    }

    var flowGramsPerSecond: Double? {
        guard seconds > 0, liquidGrams > 0 else { return nil }
        return liquidGrams / seconds
    }

    var ratioText: String {
        guard let r = ratio else { return "—" }
        return String(format: "1 : %.1f", r)
    }

    /// How long the brew actually took, whichever field the method uses.
    var totalSeconds: Double {
        if steepHours > 0 { return steepHours * 3600 }
        if seconds > 0 { return seconds }
        if steepMinutes > 0 { return steepMinutes * 60 }
        return 0
    }

    var timeText: String {
        let t = totalSeconds
        if t == 0 { return "—" }
        if t >= 3600 { return String(format: "%.0f h", t / 3600) }
        if t >= 120 { return String(format: "%.0f min", t / 60) }
        return String(format: "%.0f s", t)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        beanID = try c.decodeIfPresent(UUID.self, forKey: .beanID)
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        method = try c.decodeIfPresent(BrewMethod.self, forKey: .method) ?? .espresso
        grind = try c.decodeIfPresent(Double.self, forKey: .grind) ?? 15
        doseGrams = try c.decodeIfPresent(Double.self, forKey: .doseGrams) ?? 18
        yieldGrams = try c.decodeIfPresent(Double.self, forKey: .yieldGrams) ?? 36
        waterGrams = try c.decodeIfPresent(Double.self, forKey: .waterGrams) ?? 0
        seconds = try c.decodeIfPresent(Double.self, forKey: .seconds) ?? 28
        tempC = try c.decodeIfPresent(Double.self, forKey: .tempC) ?? 93
        preInfusionSeconds = try c.decodeIfPresent(Double.self, forKey: .preInfusionSeconds) ?? 0
        basket = try c.decodeIfPresent(String.self, forKey: .basket) ?? ""
        bloomGrams = try c.decodeIfPresent(Double.self, forKey: .bloomGrams) ?? 0
        bloomSeconds = try c.decodeIfPresent(Double.self, forKey: .bloomSeconds) ?? 0
        pours = try c.decodeIfPresent(Double.self, forKey: .pours) ?? 0
        steepMinutes = try c.decodeIfPresent(Double.self, forKey: .steepMinutes) ?? 0
        steepHours = try c.decodeIfPresent(Double.self, forKey: .steepHours) ?? 0
        plungeSeconds = try c.decodeIfPresent(Double.self, forKey: .plungeSeconds) ?? 0
        inverted = try c.decodeIfPresent(Bool.self, forKey: .inverted) ?? false
        sourBitter = try c.decodeIfPresent(Double.self, forKey: .sourBitter) ?? 0
        thinSyrupy = try c.decodeIfPresent(Double.self, forKey: .thinSyrupy) ?? 0
        light = try c.decodeIfPresent(TrafficLight.self, forKey: .light) ?? .amber
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        photoID = try c.decodeIfPresent(String.self, forKey: .photoID)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? date
        modifiedAt = try c.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? createdAt
        rinsedAt = try c.decodeIfPresent(Date.self, forKey: .rinsedAt)
    }

    init(id: UUID = UUID(), beanID: UUID? = nil, date: Date = Date(),
         method: BrewMethod = .espresso, doseGrams: Double = 18) {
        self.id = id; self.beanID = beanID; self.date = date
        self.method = method; self.doseGrams = doseGrams
    }
}

// MARK: - Purchases

enum PurchaseKind: String, Codable, CaseIterable, Identifiable {
    case machine, grinder, accessory, subscription, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .machine:      return "Machine"
        case .grinder:      return "Grinder"
        case .accessory:    return "Accessory"
        case .subscription: return "Subscription"
        case .other:        return "Other"
        }
    }

}

/// Gear, not beans. Bags carry their own price and are counted automatically,
/// so nothing has to be typed in twice.
struct Purchase: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: PurchaseKind = .accessory
    var what = ""
    var shop = ""
    var priceSEK: Double = 0
    var date = Date()
    var warrantyUntil: Date?
    var notes = ""
    /// The receipt. A file name, not the picture itself.
    var photoID: String?
    var createdAt = Date()
    var modifiedAt = Date()
    var rinsedAt: Date?

    var displayName: String {
        let w = what.trimmingCharacters(in: .whitespaces)
        return w.isEmpty ? kind.title : w
    }

    var warrantyIsLive: Bool {
        guard let until = warrantyUntil else { return false }
        return until >= Date()
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try c.decodeIfPresent(PurchaseKind.self, forKey: .kind) ?? .accessory
        what = try c.decodeIfPresent(String.self, forKey: .what) ?? ""
        shop = try c.decodeIfPresent(String.self, forKey: .shop) ?? ""
        priceSEK = try c.decodeIfPresent(Double.self, forKey: .priceSEK) ?? 0
        date = try c.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        warrantyUntil = try c.decodeIfPresent(Date.self, forKey: .warrantyUntil)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        photoID = try c.decodeIfPresent(String.self, forKey: .photoID)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? date
        modifiedAt = try c.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? createdAt
        rinsedAt = try c.decodeIfPresent(Date.self, forKey: .rinsedAt)
    }

    init(id: UUID = UUID(), kind: PurchaseKind = .accessory, what: String = "",
         shop: String = "", priceSEK: Double = 0, date: Date = Date(),
         warrantyUntil: Date? = nil, notes: String = "") {
        self.id = id; self.kind = kind; self.what = what; self.shop = shop
        self.priceSEK = priceSEK; self.date = date
        self.warrantyUntil = warrantyUntil; self.notes = notes
    }
}
