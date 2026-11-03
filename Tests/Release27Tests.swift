import XCTest
@testable import AMSCoffee

/// 2.7 — the label also gives the bean's name and process, and Settings
/// says when the last backup file was saved. Every example here is invented.
final class Release27Tests: XCTestCase {

    // A fixed "now": 3 November 2026, noon.
    private let now: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 11; c.day = 3; c.hour = 12
        return Calendar.current.date(from: c)!
    }()

    private func read(_ lines: [String]) -> LabelSuggestion {
        LabelReader.suggest(fromText: lines, now: now)
    }

    // MARK: - 1. Process

    func testTheLabelGivesNameAndProcess() {
        let s = read(["HILL & HOLLOW COFFEE ROASTERS", "Kiamaina AA", "Kenya",
                      "Washed · SL28", "Roasted 12.10.2026", "250 g"])
        XCTAssertEqual(s.name, "Kiamaina AA")
        XCTAssertEqual(s.process, "Washed")
    }

    func testProcessWordsInEnglishSwedishAndGerman() {
        XCTAssertEqual(read(["Tvättad"]).process, "Washed")
        XCTAssertEqual(read(["Process: gewaschen"]).process, "Washed")
        XCTAssertEqual(read(["Fully washed"]).process, "Washed")
        XCTAssertEqual(read(["NATURLIG"]).process, "Natural")
        XCTAssertEqual(read(["Aufbereitung: Natur"]).process, "Natural")
        XCTAssertEqual(read(["Red honey"]).process, "Honey")
        XCTAssertEqual(read(["Honung"]).process, "Honey")
        XCTAssertEqual(read(["Anaerobic Natural"]).process, "Anaerobic natural")
        XCTAssertEqual(read(["Wet-hulled"]).process, "Wet-hulled")
        XCTAssertEqual(read(["wet hulled"]).process, "Wet-hulled")
        XCTAssertEqual(read(["Carbonic maceration"]).process, "Carbonic maceration")
    }

    func testProcessIsAWholeWordAndNeverATastingNote() {
        XCTAssertNil(read(["Notes: honey, peach, black tea"]).process)
        XCTAssertNil(read(["Peach · honey · black tea"]).process)
        XCTAssertNil(read(["Smak: honung och persika"]).process)
        XCTAssertNil(read(["Naturally sweet"]).process)
        XCTAssertNil(read(["Unwashed cup"]).process)
        XCTAssertNil(read(["Honey · peach · black tea"]).process, "a flavour list that starts with honey")
    }

    /// A spec line lists things too — but its first item is the process.
    func testAProcessLeadingASpecLineIsRead() {
        XCTAssertEqual(read(["Tvättad · SL28 · SL34"]).process, "Washed")
        XCTAssertEqual(read(["Natural, Heirloom, 2100 masl"]).process, "Natural")
        XCTAssertEqual(read(["Honey · Catuai · 1600 masl"]).process, "Honey")
    }

    // MARK: - 2. Name

    func testANameIsOnlySuggestedWhenOneLineIsPlainlyAName() {
        XCTAssertEqual(read(["Kiamaina AA", "250 g", "Whole bean", "Kenya", "Washed"]).name,
                       "Kiamaina AA", "weight, whole bean, origin and process are not names")
        XCTAssertNil(read(["Little Owl Rosteri", "Kenya", "Roasted 12.10.2026", "Natural"]).name,
                     "nothing left over is not a name")
        XCTAssertNil(read(["Kiamaina AA", "Gatomboya Peaberry"]).name,
                     "two lines alike — no guess")
        XCTAssertNil(read(["Espresso", "Kenya"]).name, "a roast profile is not a name")
        XCTAssertNil(read(["Net weight 1 kg", "www.example.com"]).name)
        XCTAssertNil(read(["Notes: plum, cocoa, orange"]).name)
        XCTAssertNil(read(["Best before 01.03.2027"]).name)
    }

    func testATallerLineIsTheNameOnlyWhenItIsClearlyTaller() {
        let clear = LabelReader.suggest(from: [LabelLine(text: "Kiamaina AA", height: 0.08),
                                               LabelLine(text: "Juicy and bright", height: 0.03),
                                               LabelLine(text: "Kenya", height: 0.05)], now: now)
        XCTAssertEqual(clear.name, "Kiamaina AA")
        let close = LabelReader.suggest(from: [LabelLine(text: "Kiamaina AA", height: 0.05),
                                               LabelLine(text: "Juicy and bright", height: 0.048)], now: now)
        XCTAssertNil(close.name, "nearly the same size — no guess")
    }

    func testAShoutedNameReadsNaturally() {
        XCTAssertEqual(read(["KIAMAINA AA", "KENYA"]).name, "Kiamaina AA")
        XCTAssertEqual(read(["FINCA EL SOL"]).name, "Finca El Sol")
        XCTAssertEqual(read(["Finca de la Luna"]).name, "Finca de la Luna", "typed case is kept")
    }

    func testNameAndProcessAreOnlyOfferedForEmptyFields() {
        let s = read(["Kiamaina AA", "Kenya", "Natural"])
        var bag = Bean()
        var offer = s.offered(for: bag, hasRoastDate: false)
        XCTAssertEqual(offer.name, "Kiamaina AA")
        XCTAssertEqual(offer.process, "Natural")
        bag.name = "Typed by hand"
        bag.process = "Honey"
        offer = s.offered(for: bag, hasRoastDate: false)
        XCTAssertNil(offer.name)
        XCTAssertNil(offer.process)
        XCTAssertFalse(read(["Natural"]).isEmpty, "a process alone is something")
    }

    // MARK: - 3. When the last backup file was saved

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: now)!
    }

    func testTheLastBackupLineInPlainWords() {
        XCTAssertEqual(BackupFile.lastSavedLine(nil, now: now), "No backup file saved yet")
        XCTAssertEqual(BackupFile.lastSavedLine(now.addingTimeInterval(-3600), now: now),
                       "Last backup file: today")
        XCTAssertEqual(BackupFile.lastSavedLine(daysAgo(1), now: now), "Last backup file: yesterday")
        XCTAssertEqual(BackupFile.lastSavedLine(daysAgo(3), now: now), "Last backup file: 3 days ago")
        XCTAssertEqual(BackupFile.lastSavedLine(daysAgo(20), now: now), "Last backup file: 2 weeks ago")
        XCTAssertEqual(BackupFile.lastSavedLine(daysAgo(90), now: now), "Last backup file: 3 months ago")
    }

    func testTheDateTravelsInTheFileAndOldFilesStillOpen() throws {
        let old = Data(#"{"schema":2,"beans":[],"shots":[]}"#.utf8)
        XCTAssertNil(try JSONDecoder.coffee.decode(CoffeeData.self, from: old).lastBackupFileAt)
        var d = CoffeeData()
        d.lastBackupFileAt = daysAgo(2)
        let back = try JSONDecoder.coffee.decode(CoffeeData.self, from: JSONEncoder.coffee.encode(d))
        XCTAssertNotNil(back.lastBackupFileAt)
    }

    func testThePhoneAndTheMacKeepTheLaterOne() {
        var phone = CoffeeData(); phone.lastBackupFileAt = daysAgo(1)
        var mac = CoffeeData(); mac.lastBackupFileAt = daysAgo(5)
        XCTAssertEqual(CoffeeData.merged(phone, mac).lastBackupFileAt, daysAgo(1))
        XCTAssertEqual(CoffeeData.merged(mac, phone).lastBackupFileAt, daysAgo(1))
        XCTAssertEqual(CoffeeData.merged(CoffeeData(), mac).lastBackupFileAt, daysAgo(5))
    }

    @MainActor
    func testOnlyAProvedSaveCountsAndARestoreDoesNotTurnItBack() {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("backup-date-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = CoffeeStore(root: folder)
        XCTAssertNil(store.data.lastBackupFileAt)
        store.backupFileProved(at: daysAgo(1))
        XCTAssertEqual(store.data.lastBackupFileAt, daysAgo(1))

        var older = CoffeeData(beans: [Bean(name: "Invented bag")])
        older.lastBackupFileAt = daysAgo(30)
        store.restore(from: older, safetyName: "Before opening a backup")
        XCTAssertEqual(store.data.lastBackupFileAt, daysAgo(1), "an old file does not wind it back")
    }
}
