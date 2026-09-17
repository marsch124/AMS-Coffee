import Foundation

// MARK: - Brew methods

/// v1.0 logs espresso. The other methods are already in the model so that
/// adding their screens later cannot force a data migration.
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

    var symbol: String {
        switch self {
        case .espresso:    return "cup.and.saucer.fill"
        case .v60:         return "drop.fill"
        case .aeropress:   return "arrow.down.circle.fill"
        case .frenchPress: return "cylinder.fill"
        case .moka:        return "flame.fill"
        case .coldBrew:    return "snowflake"
        case .filter:      return "line.3.horizontal.decrease.circle.fill"
        }
    }

    /// Shipped in v1.0? The rest show as "coming" so nothing looks broken.
    var isLive: Bool { self == .espresso }
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

    var symbol: String {
        switch self {
        case .undecided: return "questionmark.circle.fill"
        case .buyAgain:  return "star.fill"
        case .never:     return "hand.thumbsdown.fill"
        }
    }
}

/// The flavour wheel, kept short on purpose — pick, don't type.
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

    var emoji: String {
        switch self {
        case .chocolate:  return "🍫"
        case .caramel:    return "🍮"
        case .nutty:      return "🥜"
        case .berry:      return "🫐"
        case .citrus:     return "🍋"
        case .stoneFruit: return "🍑"
        case .floral:     return "🌸"
        case .spice:      return "🌶"
        case .earthy:     return "🌿"
        case .wine:       return "🍷"
        case .honey:      return "🍯"
        case .bread:      return "🍞"
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
}

// MARK: - Shots

enum TrafficLight: String, Codable, CaseIterable, Identifiable {
    case red, amber, green

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .red:   return "🔴"
        case .amber: return "🟡"
        case .green: return "🟢"
        }
    }

    var title: String {
        switch self {
        case .red:   return "Tipped it out"
        case .amber: return "Drinkable"
        case .green: return "Lovely"
        }
    }
}

struct Shot: Identifiable, Codable, Equatable {
    var id = UUID()
    var beanID: UUID?
    var date = Date()
    var method: BrewMethod = .espresso

    var grind: Double = 15          // the number on your grinder
    var doseGrams: Double = 18
    var yieldGrams: Double = 36
    var seconds: Double = 28
    var tempC: Double = 93
    var preInfusionSeconds: Double = 0
    var basket = ""

    /// −1 sour … 0 balanced … +1 bitter
    var sourBitter: Double = 0
    /// −1 thin … 0 fine … +1 syrupy
    var thinSyrupy: Double = 0
    var light: TrafficLight = .amber
    var note = ""

    var createdAt = Date()
    var modifiedAt = Date()
    var rinsedAt: Date?

    var ratio: Double? {
        guard doseGrams > 0 else { return nil }
        return yieldGrams / doseGrams
    }

    var flowGramsPerSecond: Double? {
        guard seconds > 0 else { return nil }
        return yieldGrams / seconds
    }

    var ratioText: String {
        guard let r = ratio else { return "—" }
        return String(format: "1 : %.1f", r)
    }
}

// MARK: - The coach

/// One clear next move, in your words, from the shot you just rated.
/// Deliberately pure and boring so it can be unit-tested.
struct Advice: Equatable {
    var headline: String
    var detail: String
    var emoji: String
}

enum Coach {
    static func advise(for shot: Shot) -> Advice {
        let sour = shot.sourBitter < -0.15
        let bitter = shot.sourBitter > 0.15
        let thin = shot.thinSyrupy < -0.2
        let fast = shot.seconds < 22
        let slow = shot.seconds > 35
        let ratio = shot.ratio ?? 2

        if shot.light == .green {
            return Advice(headline: "Keep it exactly here",
                          detail: "Grind \(trim(shot.grind)), \(trim(shot.doseGrams)) g in, \(trim(shot.yieldGrams)) g out, \(trim(shot.seconds)) s. Saved as this bag's recipe.",
                          emoji: "🎉")
        }
        if sour && fast {
            return Advice(headline: "Grind finer",
                          detail: "About 2 clicks. It ran through in \(trim(shot.seconds)) s — too quick to taste sweet.",
                          emoji: "🔧")
        }
        if bitter && slow {
            return Advice(headline: "Grind coarser",
                          detail: "About 2 clicks. \(trim(shot.seconds)) s is choking it and pulling out the harsh bits.",
                          emoji: "🔧")
        }
        if sour && ratio < 1.7 {
            return Advice(headline: "Let it run longer",
                          detail: "Aim for about \(trim(shot.doseGrams * 2)) g out. A short shot tastes sour before it tastes sweet.",
                          emoji: "⏱")
        }
        if bitter && ratio > 2.6 {
            return Advice(headline: "Stop it earlier",
                          detail: "Aim for about \(trim(shot.doseGrams * 2)) g out. Past 1 : 2.6 you are mostly rinsing the puck.",
                          emoji: "⏱")
        }
        if thin && ratio > 2.4 {
            return Advice(headline: "Less water",
                          detail: "Thin and long. Try \(trim(shot.doseGrams * 2)) g out and a click finer.",
                          emoji: "💧")
        }
        if sour {
            return Advice(headline: "A touch finer, a touch hotter",
                          detail: "Try grind \(trim(shot.grind - 1)) and \(trim(min(96, shot.tempC + 1)))°C.",
                          emoji: "🔧")
        }
        if bitter {
            return Advice(headline: "A touch coarser, a touch cooler",
                          detail: "Try grind \(trim(shot.grind + 1)) and \(trim(max(88, shot.tempC - 1)))°C.",
                          emoji: "🔧")
        }
        if fast {
            return Advice(headline: "Finer",
                          detail: "\(trim(shot.seconds)) s is fast for espresso. Two clicks finer and taste again.",
                          emoji: "🔧")
        }
        if slow {
            return Advice(headline: "Coarser",
                          detail: "\(trim(shot.seconds)) s is slow. Two clicks coarser and taste again.",
                          emoji: "🔧")
        }
        return Advice(headline: "Change one thing only",
                      detail: "Nothing is obviously off. Nudge the grind by one click and see which way it moves.",
                      emoji: "🤏")
    }

    static func trim(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - The whole shelf

struct CoffeeData: Codable, Equatable {
    var schema = 1
    var beans: [Bean] = []
    var shots: [Shot] = []
    var savedAt = Date()

    var liveBeans: [Bean] { beans.filter { $0.rinsedAt == nil } }
    var liveShots: [Shot] { shots.filter { $0.rinsedAt == nil } }

    func bean(_ id: UUID?) -> Bean? {
        guard let id else { return nil }
        return beans.first { $0.id == id }
    }

    /// Grams of a bag already pulled through the machine.
    func gramsUsed(beanID: UUID) -> Double {
        liveShots.filter { $0.beanID == beanID }.reduce(0) { $0 + $1.doseGrams }
    }

    func gramsLeft(for bean: Bean) -> Double {
        max(0, bean.bagWeightGrams - gramsUsed(beanID: bean.id))
    }

    /// The best shot on a bag: newest green one, else newest at all.
    func bestShot(beanID: UUID) -> Shot? {
        let mine = liveShots.filter { $0.beanID == beanID }.sorted { $0.date > $1.date }
        return mine.first { $0.light == .green } ?? mine.first
    }

    var costPerCup: Double? {
        let spend = liveBeans.reduce(0) { $0 + $1.priceSEK }
        let cups = liveShots.count
        guard spend > 0, cups > 0 else { return nil }
        return spend / Double(cups)
    }

    /// Two devices, one file. Newer `modifiedAt` wins per record, and a
    /// rinse (tombstone) travels like any other change, so a delete on the
    /// phone cannot come back to life from the Mac.
    static func merged(_ a: CoffeeData, _ b: CoffeeData) -> CoffeeData {
        var out = CoffeeData()
        out.schema = max(a.schema, b.schema)
        out.beans = mergeRecords(a.beans, b.beans, id: \.id, stamp: \.modifiedAt)
        out.shots = mergeRecords(a.shots, b.shots, id: \.id, stamp: \.modifiedAt)
        out.savedAt = max(a.savedAt, b.savedAt)
        return out
    }

    private static func mergeRecords<T>(_ a: [T], _ b: [T],
                                        id: KeyPath<T, UUID>,
                                        stamp: KeyPath<T, Date>) -> [T] {
        var byID: [UUID: T] = [:]
        for item in a { byID[item[keyPath: id]] = item }
        for item in b {
            let key = item[keyPath: id]
            if let existing = byID[key] {
                if item[keyPath: stamp] > existing[keyPath: stamp] { byID[key] = item }
            } else {
                byID[key] = item
            }
        }
        return Array(byID.values)
    }
}
