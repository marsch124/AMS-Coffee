import Foundation

/// Picture mode (2.10): `-pictures` starts the app with made-up coffee in a temporary folder, so
/// pictures for the Apps Overview and the course can be taken without touching the real shelf or
/// iCloud. `-startTab today|bags|shots|settings` opens that tab. Every name here is invented.
enum PictureMode {
    static var on: Bool { ProcessInfo.processInfo.arguments.contains("-pictures") }
}

enum PictureSample {
    /// Four bags, ten brews over the last week (two of them today) and two kit purchases, with dates
    /// counted back from `now`, in the app's own file format.
    static func data(now: Date) -> CoffeeData? {
        let iso = ISO8601DateFormatter()
        let calendar = Calendar.current
        func ago(days: Double) -> Date { now.addingTimeInterval(-days * 86_400) }
        func at(daysAgo: Int, hour: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            return calendar.date(bySettingHour: hour, minute: 15, second: 0, of: day) ?? day
        }
        func stamp(_ d: Date) -> String { iso.string(from: d) }

        let ids = (0..<4).map { _ in UUID().uuidString }
        func bean(_ i: Int, _ roaster: String, _ name: String, _ origin: String, _ process: String, _ roast: String,
                  roastedDaysAgo: Double, grams: Int, price: Int, rating: Int, verdict: String,
                  flavours: [String], notes: String) -> [String: Any] {
            let roasted = stamp(ago(days: roastedDaysAgo))
            return ["id": ids[i], "roaster": roaster, "name": name, "origin": origin, "process": process,
                    "roastLevel": roast, "roastDate": roasted, "bagWeightGrams": grams, "priceSEK": price,
                    "rating": rating, "verdict": verdict, "flavours": flavours, "notes": notes,
                    "createdAt": roasted, "modifiedAt": roasted]
        }
        let beans = [
            bean(0, "Hilltop Roastery", "Ethiopia Guji", "Ethiopia", "Washed", "Light", roastedDaysAgo: 9, grams: 250,
                 price: 129, rating: 5, verdict: "buyAgain", flavours: ["berry", "citrus", "floral"],
                 notes: "Jasmine and blueberry, bright and clean."),
            bean(1, "North Pier Coffee", "Colombia Huila", "Colombia", "Honey", "Medium", roastedDaysAgo: 16, grams: 500,
                 price: 189, rating: 4, verdict: "undecided", flavours: ["caramel", "stoneFruit", "chocolate"],
                 notes: "Sweet and round, great as a flat white."),
            bean(2, "Lantern Roasters", "Brazil Cerrado", "Brazil", "Natural", "Dark", roastedDaysAgo: 30, grams: 1000,
                 price: 269, rating: 3, verdict: "undecided", flavours: ["chocolate", "nutty", "spice"],
                 notes: "Everyday espresso blend base."),
            bean(3, "Fjord & Fern", "Kenya Nyeri AA", "Kenya", "Washed", "Light", roastedDaysAgo: 3, grams: 250,
                 price: 149, rating: 0, verdict: "undecided", flavours: ["citrus", "berry"],
                 notes: "Just opened, still resting."),
        ]

        func shot(_ when: Date, bean: Int, _ method: String, _ values: [String: Any]) -> [String: Any] {
            var s: [String: Any] = ["id": UUID().uuidString, "beanID": ids[bean], "date": stamp(when), "method": method,
                                    "createdAt": stamp(when), "modifiedAt": stamp(when)]
            s.merge(values) { _, new in new }
            return s
        }
        // The two of today sit just before "now", so they are today at any hour.
        let shots = [
            shot(now.addingTimeInterval(-40 * 60), bean: 0, "espresso",
                 ["grind": 14, "doseGrams": 18, "yieldGrams": 38, "seconds": 29, "tempC": 93, "preInfusionSeconds": 5,
                  "sourBitter": -0.2, "thinSyrupy": 0.3, "light": "green", "note": "Best one this week. Sweet, long finish."]),
            shot(now.addingTimeInterval(-20 * 60), bean: 1, "v60",
                 ["grind": 26, "doseGrams": 15, "waterGrams": 250, "seconds": 175, "tempC": 94, "bloomGrams": 45,
                  "bloomSeconds": 40, "pours": 3, "light": "green", "sourBitter": 0, "note": "Clean cup."]),
            shot(at(daysAgo: 1, hour: 8), bean: 0, "espresso",
                 ["grind": 14.5, "doseGrams": 18, "yieldGrams": 40, "seconds": 26, "tempC": 93, "sourBitter": -0.5,
                  "thinSyrupy": -0.3, "light": "amber", "note": "A touch sour, grind finer."]),
            shot(at(daysAgo: 2, hour: 9), bean: 1, "aeropress",
                 ["grind": 22, "doseGrams": 16, "waterGrams": 230, "seconds": 150, "tempC": 85, "steepMinutes": 2,
                  "plungeSeconds": 30, "light": "green", "sourBitter": 0.1]),
            shot(at(daysAgo: 2, hour: 7), bean: 2, "espresso",
                 ["grind": 16, "doseGrams": 18, "yieldGrams": 36, "seconds": 31, "tempC": 94, "sourBitter": 0.5,
                  "thinSyrupy": 0.4, "light": "amber", "note": "Bit bitter, fine in milk."]),
            shot(at(daysAgo: 3, hour: 8), bean: 0, "espresso",
                 ["grind": 15, "doseGrams": 18, "yieldGrams": 36, "seconds": 24, "tempC": 93, "sourBitter": -0.8,
                  "thinSyrupy": -0.5, "light": "red", "note": "Gushed through. Tipped it out."]),
            shot(at(daysAgo: 4, hour: 10), bean: 1, "frenchPress",
                 ["grind": 34, "doseGrams": 30, "waterGrams": 500, "seconds": 240, "tempC": 94, "steepMinutes": 4,
                  "light": "amber"]),
            shot(at(daysAgo: 5, hour: 8), bean: 2, "moka",
                 ["grind": 20, "doseGrams": 18, "waterGrams": 150, "seconds": 240, "tempC": 100, "light": "amber",
                  "note": "Weekend moka pot."]),
            shot(at(daysAgo: 6, hour: 9), bean: 0, "v60",
                 ["grind": 25, "doseGrams": 15, "waterGrams": 250, "seconds": 180, "tempC": 95, "bloomGrams": 45,
                  "bloomSeconds": 45, "pours": 3, "light": "green", "sourBitter": -0.1, "note": "Floral, jasmine."]),
            shot(at(daysAgo: 6, hour: 8), bean: 1, "espresso",
                 ["grind": 15, "doseGrams": 18, "yieldGrams": 36, "seconds": 28, "tempC": 93, "light": "amber"]),
        ]

        func purchase(_ kind: String, _ what: String, price: Int, daysAgo: Double) -> [String: Any] {
            let d = stamp(ago(days: daysAgo))
            return ["id": UUID().uuidString, "kind": kind, "what": what, "shop": "Bean Bar Online", "priceSEK": price,
                    "date": d, "createdAt": d, "modifiedAt": d]
        }
        let all: [String: Any] = [
            "schema": 2, "beans": beans, "shots": shots,
            "purchases": [purchase("grinder", "Conical burr grinder", price: 2490, daysAgo: 120),
                          purchase("machine", "Compact espresso machine", price: 5990, daysAgo: 200)],
            "savedAt": stamp(now),
        ]
        guard let raw = try? JSONSerialization.data(withJSONObject: all) else { return nil }
        return try? JSONDecoder.coffee.decode(CoffeeData.self, from: raw)
    }
}
