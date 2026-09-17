import Foundation
import SwiftUI

/// Everything the app knows, and the only thing allowed to touch disk.
@MainActor
final class CoffeeStore: ObservableObject {

    @Published private(set) var data = CoffeeData()
    @Published private(set) var shelf = CupShelf()
    @Published var lastAdvice: Advice?
    @Published var celebrate = 0          // bumped to fire confetti
    @Published var syncPlace = "This device"

    private let cupboard: CupCupboard
    private let dataURL: URL
    private let coordinator = NSFileCoordinator()
    private var saveWork: Task<Void, Never>?
    private let isTestRun: Bool

    // MARK: Where things live

    init(root: URL? = nil) {
        isTestRun = ProcessInfo.processInfo.arguments.contains("-uiTesting")
        let home = root ?? CoffeeStore.defaultRoot(freshForTests: isTestRun)
        try? FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        dataURL = home.appendingPathComponent("coffee.json")
        cupboard = CupCupboard(folder: home.appendingPathComponent("Cups"))
        load()
    }

    private static func defaultRoot(freshForTests: Bool) -> URL {
        if freshForTests {
            return FileManager.default.temporaryDirectory
                .appendingPathComponent("AMSCoffee-UITest-\(UUID().uuidString)")
        }
        // One file in iCloud Drive means the phone and the Mac are literally
        // reading the same shelf. No cloud account? Fall back to this device.
        let fm = FileManager.default
        if let cloud = fm.url(forUbiquityContainerIdentifier: "iCloud.com.schabbauer.AMSCoffee") {
            let docs = cloud.appendingPathComponent("Documents")
            try? fm.createDirectory(at: docs, withIntermediateDirectories: true)
            return docs
        }
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("AMSCoffee")
    }

    // MARK: Load & save

    func load() {
        var loaded = CoffeeData()
        var err: NSError?
        coordinator.coordinate(readingItemAt: dataURL, options: [], error: &err) { url in
            if let raw = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder.coffee.decode(CoffeeData.self, from: raw) {
                loaded = decoded
            }
        }
        data = loaded
        shelf = cupboard.loadShelf()
        syncPlace = dataURL.path.contains("Mobile Documents") ? "iCloud Drive" : "This device"
        emptyTheSink()
    }

    /// Debounced so a drag on a slider does not write the file 60 times.
    private func scheduleSave(pourCup: Bool = true) {
        saveWork?.cancel()
        saveWork = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await self?.saveNow(pourCup: pourCup)
        }
    }

    func saveNow(pourCup: Bool = true) {
        data.savedAt = Date()

        // Merge against whatever is on disk before writing, so the other
        // device's work is never flattened by this one's copy.
        var toWrite = data
        var err: NSError?
        coordinator.coordinate(writingItemAt: dataURL, options: .forMerging, error: &err) { url in
            if let raw = try? Data(contentsOf: url),
               let onDisk = try? JSONDecoder.coffee.decode(CoffeeData.self, from: raw) {
                toWrite = CoffeeData.merged(onDisk, toWrite)
            }
            if let payload = try? JSONEncoder.coffee.encode(toWrite) {
                try? payload.writeAtomically(to: url)
            }
        }
        data = toWrite

        if pourCup {
            cupboard.pour(data, kind: .quick)
            pourDailyCupIfDue()
            shelf = cupboard.loadShelf()
        }
    }

    // MARK: Cups

    private func pourDailyCupIfDue() {
        let shelf = cupboard.loadShelf()
        if let last = shelf.newest(of: .daily),
           Calendar.current.isDateInToday(last.pouredAt) { return }
        cupboard.pour(data, kind: .daily)
    }

    func saveKeepsake(named name: String) {
        saveNow(pourCup: false)
        cupboard.pour(data, kind: .keepsake, name: name.isEmpty ? "Keepsake" : name)
        shelf = cupboard.loadShelf()
        celebrate += 1
    }

    func retest(_ cup: Cup) {
        cupboard.retest(cup)
        shelf = cupboard.loadShelf()
    }

    func tipOut(_ cup: Cup) {
        cupboard.tipOut(cup)
        shelf = cupboard.loadShelf()
    }

    func dismissWarning() {
        cupboard.clearWarning()
        shelf = cupboard.loadShelf()
    }

    func preview(of cup: Cup) -> String? {
        guard let incoming = cupboard.read(cup) else { return nil }
        let dBeans = incoming.liveBeans.count - data.liveBeans.count
        let dShots = incoming.liveShots.count - data.liveShots.count
        func line(_ n: Int, _ noun: String) -> String {
            n == 0 ? "same \(noun)" : (n > 0 ? "+\(n) \(noun)" : "\(n) \(noun)")
        }
        return "\(line(dBeans, "bags")) · \(line(dShots, "shots"))"
    }

    /// Pours a cup back in. Takes a safety cup of *now* first, always.
    func restore(_ cup: Cup) -> Bool {
        guard let incoming = cupboard.read(cup) else { return false }
        cupboard.pour(data, kind: .keepsake, name: "Before restore")
        data = incoming
        saveNow(pourCup: false)
        shelf = cupboard.loadShelf()
        return true
    }

    func exportFile() -> URL? {
        guard let payload = try? JSONEncoder.coffee.encode(data) else { return nil }
        let stamp = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AMS Coffee \(stamp).amscoffee")
        try? payload.writeAtomically(to: url)
        return url
    }

    @discardableResult
    func importFile(_ url: URL) -> Bool {
        guard let raw = try? Data(contentsOf: url),
              let incoming = try? JSONDecoder.coffee.decode(CoffeeData.self, from: raw)
        else { return false }
        cupboard.pour(data, kind: .keepsake, name: "Before import")
        data = CoffeeData.merged(data, incoming)
        saveNow(pourCup: false)
        shelf = cupboard.loadShelf()
        return true
    }

    // MARK: Beans

    func upsert(_ bean: Bean) {
        var b = bean
        b.modifiedAt = Date()
        if let i = data.beans.firstIndex(where: { $0.id == b.id }) {
            data.beans[i] = b
        } else {
            data.beans.append(b)
        }
        scheduleSave()
    }

    func rinse(_ bean: Bean) {
        guard let i = data.beans.firstIndex(where: { $0.id == bean.id }) else { return }
        data.beans[i].rinsedAt = Date()
        data.beans[i].modifiedAt = Date()
        scheduleSave()
    }

    func unrinse(_ bean: Bean) {
        guard let i = data.beans.firstIndex(where: { $0.id == bean.id }) else { return }
        data.beans[i].rinsedAt = nil
        data.beans[i].modifiedAt = Date()
        scheduleSave()
    }

    // MARK: Shots

    func upsert(_ shot: Shot) {
        var s = shot
        s.modifiedAt = Date()
        if let i = data.shots.firstIndex(where: { $0.id == s.id }) {
            data.shots[i] = s
        } else {
            data.shots.append(s)
        }
        lastAdvice = Coach.advise(for: s)
        if s.light == .green { celebrate += 1 }
        scheduleSave()
    }

    func rinse(_ shot: Shot) {
        guard let i = data.shots.firstIndex(where: { $0.id == shot.id }) else { return }
        data.shots[i].rinsedAt = Date()
        data.shots[i].modifiedAt = Date()
        scheduleSave()
    }

    func unrinse(_ shot: Shot) {
        guard let i = data.shots.firstIndex(where: { $0.id == shot.id }) else { return }
        data.shots[i].rinsedAt = nil
        data.shots[i].modifiedAt = Date()
        scheduleSave()
    }

    /// A new brew, pre-filled from the last good one on this bag *with this
    /// method* — a pour-over recipe is no use when you are pulling a shot.
    /// Nothing to copy? The method's own sensible starting point.
    func draftShot(beanID: UUID?, method: BrewMethod = .espresso) -> Shot {
        var draft = method.starter()
        draft.beanID = beanID ?? data.liveBeans.first?.id
        if let id = draft.beanID, let best = data.bestShot(beanID: id, method: method) {
            draft.grind = best.grind
            draft.doseGrams = best.doseGrams
            draft.yieldGrams = best.yieldGrams
            draft.waterGrams = best.waterGrams
            draft.seconds = best.seconds
            draft.tempC = best.tempC
            draft.preInfusionSeconds = best.preInfusionSeconds
            draft.basket = best.basket
            draft.bloomGrams = best.bloomGrams
            draft.bloomSeconds = best.bloomSeconds
            draft.pours = best.pours
            draft.steepMinutes = best.steepMinutes
            draft.steepHours = best.steepHours
            draft.plungeSeconds = best.plungeSeconds
            draft.inverted = best.inverted
        }
        draft.date = Date()
        return draft
    }

    // MARK: Purchases

    func upsert(_ purchase: Purchase) {
        var p = purchase
        p.modifiedAt = Date()
        if let i = data.purchases.firstIndex(where: { $0.id == p.id }) {
            data.purchases[i] = p
        } else {
            data.purchases.append(p)
        }
        scheduleSave()
    }

    func rinse(_ purchase: Purchase) {
        guard let i = data.purchases.firstIndex(where: { $0.id == purchase.id }) else { return }
        data.purchases[i].rinsedAt = Date()
        data.purchases[i].modifiedAt = Date()
        scheduleSave()
    }

    func unrinse(_ purchase: Purchase) {
        guard let i = data.purchases.firstIndex(where: { $0.id == purchase.id }) else { return }
        data.purchases[i].rinsedAt = nil
        data.purchases[i].modifiedAt = Date()
        scheduleSave()
    }

    // MARK: The Sink

    var sinkBeans: [Bean] { data.beans.filter { $0.rinsedAt != nil } }
    var sinkShots: [Shot] { data.shots.filter { $0.rinsedAt != nil } }
    var sinkPurchases: [Purchase] { data.purchases.filter { $0.rinsedAt != nil } }
    var sinkCount: Int { sinkBeans.count + sinkShots.count + sinkPurchases.count }

    /// Rinsed things wait 30 days before they actually go.
    private func emptyTheSink() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        let before = (data.beans.count, data.shots.count, data.purchases.count)
        data.beans.removeAll { ($0.rinsedAt ?? .distantFuture) < cutoff }
        data.shots.removeAll { ($0.rinsedAt ?? .distantFuture) < cutoff }
        data.purchases.removeAll { ($0.rinsedAt ?? .distantFuture) < cutoff }
        if before != (data.beans.count, data.shots.count, data.purchases.count) {
            saveNow(pourCup: false)
        }
    }
}
