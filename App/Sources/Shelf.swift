import Foundation

/// Everything the app knows, in one value.
struct CoffeeData: Codable, Equatable {
    var schema = 2
    var beans: [Bean] = []
    var shots: [Shot] = []
    var purchases: [Purchase] = []
    var savedAt = Date()

    var liveBeans: [Bean] { beans.filter { $0.rinsedAt == nil } }
    var liveShots: [Shot] { shots.filter { $0.rinsedAt == nil } }
    var livePurchases: [Purchase] { purchases.filter { $0.rinsedAt == nil } }

    init() {}

    init(beans: [Bean] = [], shots: [Shot] = [], purchases: [Purchase] = []) {
        self.beans = beans
        self.shots = shots
        self.purchases = purchases
    }

    /// Tolerant: a 1.0 file has no `purchases` key at all, and must still open.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schema = try c.decodeIfPresent(Int.self, forKey: .schema) ?? 1
        beans = try c.decodeIfPresent([Bean].self, forKey: .beans) ?? []
        shots = try c.decodeIfPresent([Shot].self, forKey: .shots) ?? []
        purchases = try c.decodeIfPresent([Purchase].self, forKey: .purchases) ?? []
        savedAt = try c.decodeIfPresent(Date.self, forKey: .savedAt) ?? Date()
    }

    func bean(_ id: UUID?) -> Bean? {
        guard let id else { return nil }
        return beans.first { $0.id == id }
    }

    // MARK: Bags

    /// Grams of a bag already brewed with, by any method.
    func gramsUsed(beanID: UUID) -> Double {
        liveShots.filter { $0.beanID == beanID }.reduce(0) { $0 + $1.doseGrams }
    }

    func gramsLeft(for bean: Bean) -> Double {
        max(0, bean.bagWeightGrams - gramsUsed(beanID: bean.id))
    }

    /// The recipe a bag offers next time, per method — a pour-over recipe is
    /// no use when you are pulling a shot.
    func bestShot(beanID: UUID, method: BrewMethod) -> Shot? {
        let mine = liveShots
            .filter { $0.beanID == beanID && $0.method == method }
            .sorted { $0.date > $1.date }
        return mine.first { $0.light == .green } ?? mine.first
    }

    /// Which methods this bag has actually been used for.
    func methodsUsed(beanID: UUID) -> [BrewMethod] {
        let used = Set(liveShots.filter { $0.beanID == beanID }.map(\.method))
        return BrewMethod.allCases.filter { used.contains($0) }
    }

    // MARK: Money

    /// Beans are counted from the bags themselves, so a bag is never entered
    /// twice — once as a bag and once as a purchase.
    func beanSpend(in year: Int? = nil) -> Double {
        liveBeans
            .filter { year == nil || Calendar.current.component(.year, from: $0.createdAt) == year }
            .reduce(0) { $0 + $1.priceSEK }
    }

    func gearSpend(in year: Int? = nil) -> Double {
        livePurchases
            .filter { year == nil || Calendar.current.component(.year, from: $0.date) == year }
            .reduce(0) { $0 + $1.priceSEK }
    }

    func totalSpend(in year: Int? = nil) -> Double {
        beanSpend(in: year) + gearSpend(in: year)
    }

    func gearSpend(kind: PurchaseKind) -> Double {
        livePurchases.filter { $0.kind == kind }.reduce(0) { $0 + $1.priceSEK }
    }

    /// What a cup costs you in beans alone. Gear is a one-off, so counting a
    /// grinder against this morning's coffee would just be depressing.
    var costPerCup: Double? {
        let spend = beanSpend()
        let cups = liveShots.count
        guard spend > 0, cups > 0 else { return nil }
        return spend / Double(cups)
    }

    /// What a cup costs once the gear is paid off too — shown separately.
    var costPerCupWithGear: Double? {
        let spend = totalSpend()
        let cups = liveShots.count
        guard spend > 0, cups > 0 else { return nil }
        return spend / Double(cups)
    }

    var warrantiesRunningOut: [Purchase] {
        let soon = Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date()
        return livePurchases
            .filter { p in
                guard let until = p.warrantyUntil else { return false }
                return until >= Date() && until <= soon
            }
            .sorted { ($0.warrantyUntil ?? .distantFuture) < ($1.warrantyUntil ?? .distantFuture) }
    }

    // MARK: Two devices, one file

    /// Newer `modifiedAt` wins per record, and a rinse (tombstone) travels
    /// like any other change, so a delete on the phone cannot come back to
    /// life from the Mac.
    static func merged(_ a: CoffeeData, _ b: CoffeeData) -> CoffeeData {
        var out = CoffeeData()
        out.schema = max(a.schema, b.schema)
        out.beans = mergeRecords(a.beans, b.beans, id: \.id, stamp: \.modifiedAt)
        out.shots = mergeRecords(a.shots, b.shots, id: \.id, stamp: \.modifiedAt)
        out.purchases = mergeRecords(a.purchases, b.purchases, id: \.id, stamp: \.modifiedAt)
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
