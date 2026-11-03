import Foundation

// MARK: - Looking after the kit (2.6)
//
// A grinder counts the coffee that has gone through it, a machine counts its
// shots — both worked out from the brews already logged, never typed in.
// Each counts from the last time it was done, or from the day it arrived.

enum KitCare {

    enum Task: Equatable {
        case burrs, backflush

        var title: String {
            switch self {
            case .burrs:     return "Burrs"
            case .backflush: return "Backflush"
            }
        }

        var dueWords: String {
            switch self {
            case .burrs:     return "burrs due"
            case .backflush: return "backflush due"
            }
        }
    }

    static func task(for p: Purchase) -> Task? {
        switch p.kind {
        case .grinder: return .burrs
        case .machine: return .backflush
        default:       return nil
        }
    }

    static func lastDone(_ p: Purchase) -> Date? { p.careDone.max() }

    /// Where the count starts: the last time it was done, else the morning
    /// of the day it arrived.
    static func since(_ p: Purchase) -> Date {
        lastDone(p) ?? Calendar.current.startOfDay(for: p.date)
    }

    /// Grams through a grinder (every method grinds), or espresso shots
    /// through a machine.
    static func amountSince(_ p: Purchase, in data: CoffeeData) -> Double {
        guard let task = task(for: p) else { return 0 }
        let from = since(p)
        let brews = data.liveShots.filter { $0.date > from }
        switch task {
        case .burrs:
            return brews.reduce(0) { $0 + $1.doseGrams }
        case .backflush:
            return Double(brews.filter { $0.method == .espresso }.count)
        }
    }

    /// In the same unit as `amountSince`.
    static func every(_ p: Purchase) -> Double {
        switch task(for: p) {
        case .burrs:     return p.burrEveryKg * 1000
        case .backflush: return p.backflushEveryShots
        case nil:        return 0
        }
    }

    static func isDue(_ p: Purchase, in data: CoffeeData) -> Bool {
        guard task(for: p) != nil, p.rinsedAt == nil else { return false }
        let limit = every(p)
        return limit > 0 && amountSince(p, in: data) >= limit
    }

    static func due(in data: CoffeeData) -> [Purchase] {
        data.livePurchases
            .filter { isDue($0, in: data) }
            .sorted { $0.date < $1.date }
    }

    /// "0.6 of 1 kg since 1 Oct", "12 of 50 shots since 1 Oct".
    static func line(_ p: Purchase, in data: CoffeeData, now: Date = Date()) -> String {
        let amount = amountSince(p, in: data)
        let when = shortDate(since(p), now: now)
        switch task(for: p) {
        case .burrs:
            let kg = String(format: "%.1f", amount / 1000)
            return "\(kg) of \(Coach.trim(p.burrEveryKg)) kg since \(when)"
        case .backflush:
            return "\(Int(amount)) of \(Coach.trim(p.backflushEveryShots)) shots since \(when)"
        case nil:
            return ""
        }
    }

    /// What Today says: "Grinder — burrs due · 5.2 of 5 kg since 1 Oct".
    static func dueLine(_ p: Purchase, in data: CoffeeData) -> String {
        guard let task = task(for: p) else { return "" }
        return "\(p.displayName) — \(task.dueWords) · \(line(p, in: data))"
    }

    /// "1 Oct", in the app's own English whatever the phone's language.
    static func shortDate(_ date: Date, now: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        let sameYear = Calendar.current.component(.year, from: date)
            == Calendar.current.component(.year, from: now)
        f.dateFormat = sameYear ? "d MMM" : "d MMM yyyy"
        return f.string(from: date)
    }
}
