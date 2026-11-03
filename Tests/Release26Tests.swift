import XCTest
@testable import AMSCoffee

/// 2.6 — reading a bag's label, looking after the kit, a backup file that
/// proves itself, Same again from the chart, and a search that knows the
/// light and the date. Every example here is invented.
final class Release26Tests: XCTestCase {

    // A fixed "now" so the date rules never drift: 3 November 2026, noon.
    private let now: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 11; c.day = 3; c.hour = 12
        return Calendar.current.date(from: c)!
    }()

    private func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 9) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = hour
        return Calendar.current.date(from: c)!
    }

    private func sameDay(_ a: Date?, _ b: Date) -> Bool {
        guard let a else { return false }
        return Calendar.current.isDate(a, inSameDayAs: b)
    }

    // MARK: - 1. Reading the label

    private func read(_ lines: [String]) -> LabelSuggestion {
        LabelReader.suggest(fromText: lines, now: now)
    }

    func testTheLabelGivesRoasterOriginAndRoastDate() {
        let s = read(["HILL & HOLLOW COFFEE ROASTERS", "Kiamaina AA", "Kenya",
                      "Washed · SL28", "Roasted 12.10.2026", "250 g"])
        XCTAssertEqual(s.roaster, "Hill & Hollow Coffee Roasters")
        XCTAssertEqual(s.origin, "Kenya")
        XCTAssertTrue(sameDay(s.roastDate, day(2026, 10, 12)))
    }

    func testRoastDatesInTheUsualShapes() {
        XCTAssertTrue(sameDay(read(["Roast date: 2026-10-20"]).roastDate, day(2026, 10, 20)))
        XCTAssertTrue(sameDay(read(["Rostad 20/10/2026"]).roastDate, day(2026, 10, 20)))
        XCTAssertTrue(sameDay(read(["Roasted on 20 Oct 2026"]).roastDate, day(2026, 10, 20)))
        XCTAssertTrue(sameDay(read(["Roasted October 20, 2026"]).roastDate, day(2026, 10, 20)))
        XCTAssertTrue(sameDay(read(["Roasted 20.10.26"]).roastDate, day(2026, 10, 20)))
    }

    func testABestBeforeDateIsNotARoastDate() {
        XCTAssertNil(read(["Best before 20.04.2027"]).roastDate)
        let both = read(["Best before 01.03.2027", "Roasted 01.10.2026"])
        XCTAssertTrue(sameDay(both.roastDate, day(2026, 10, 1)))
    }

    func testAFutureOrAncientDateIsIgnored() {
        XCTAssertNil(read(["Roasted 12.12.2026"]).roastDate, "after today")
        XCTAssertNil(read(["Roasted 12.10.2019"]).roastDate, "years ago")
    }

    func testTheOriginIsFoundInsideALineAndSpeltProperly() {
        XCTAssertEqual(read(["Yirgacheffe, ETHIOPIA"]).origin, "Ethiopia")
        XCTAssertEqual(read(["Finca El Sol — costa rica"]).origin, "Costa Rica")
        XCTAssertEqual(read(["Kenia"]).origin, "Kenya", "the Swedish spelling")
        XCTAssertNil(read(["Espresso blend"]).origin)
    }

    func testARoasterIsOnlySuggestedWhenTheLabelSaysSo() {
        XCTAssertEqual(read(["Little Owl Rosteri", "Kenya"]).roaster, "Little Owl Rosteri")
        XCTAssertEqual(read(["Brightwater Coffee Co."]).roaster, "Brightwater Coffee Co.")
        XCTAssertNil(read(["Kiamaina AA", "Kenya"]).roaster)
    }

    func testABlankLabelSuggestsNothing() {
        XCTAssertTrue(read([]).isEmpty)
        XCTAssertTrue(read(["250 g", "Whole bean"]).isEmpty)
        XCTAssertFalse(read(["Kenya"]).isEmpty)
    }

    /// The rule that matters most: a suggestion never lands on something
    /// already typed.
    func testASuggestionIsOnlyOfferedForAnEmptyField() {
        let s = read(["Little Owl Rosteri", "Kenya", "Roasted 12.10.2026"])
        var bag = Bean(roaster: "Typed by hand")
        var offer = s.offered(for: bag, hasRoastDate: false)
        XCTAssertNil(offer.roaster, "the roaster was typed")
        XCTAssertEqual(offer.origin, "Kenya")
        XCTAssertNotNil(offer.roastDate)

        bag.origin = "  "
        offer = s.offered(for: bag, hasRoastDate: true)
        XCTAssertEqual(offer.origin, "Kenya", "spaces are still empty")
        XCTAssertNil(offer.roastDate, "a roast date is already set")
    }

    /// Real text recognition on a real picture, all on the device.
    func testTheLabelIsReadOffAPictureOnTheDevice() async throws {
        #if os(iOS)
        let picture = LabelPicture.render(["LITTLE OWL ROSTERI", "KENYA", "ROASTED 12.10.2026"])
        let lines = await LabelReader.read(picture)
        let text = lines.map(\.text).joined(separator: " ").uppercased()
        XCTAssertTrue(text.contains("KENYA"), "read: \(text)")
        XCTAssertTrue(text.contains("ROSTERI"), "read: \(text)")
        #endif
    }

    // MARK: - 2. Looking after the kit

    private func brew(_ when: Date, dose: Double = 18, method: BrewMethod = .espresso) -> Shot {
        var s = method.starter()
        s.date = when
        s.doseGrams = dose
        return s
    }

    func testAGrinderCountsTheCoffeeThroughItSinceItWasBought() {
        var grinder = Purchase(kind: .grinder, what: "Hand grinder", date: day(2026, 10, 1))
        grinder.burrEveryKg = 1
        let data = CoffeeData(shots: [
            brew(day(2026, 9, 1), dose: 500),                 // before it was bought
            brew(day(2026, 10, 2), dose: 600),
            brew(day(2026, 10, 3), dose: 30, method: .v60),   // every method goes through it
        ])
        XCTAssertEqual(KitCare.amountSince(grinder, in: data), 630)
        XCTAssertFalse(KitCare.isDue(grinder, in: data))
        XCTAssertEqual(KitCare.line(grinder, in: data, now: now), "0.6 of 1 kg since 1 Oct")
    }

    func testTheBurrsAreDueOnceEnoughHasGoneThrough() {
        var grinder = Purchase(kind: .grinder, date: day(2026, 10, 1))
        grinder.burrEveryKg = 1
        let data = CoffeeData(shots: [brew(day(2026, 10, 2), dose: 1000)])
        XCTAssertTrue(KitCare.isDue(grinder, in: data))
        XCTAssertEqual(KitCare.due(in: CoffeeData(shots: data.shots, purchases: [grinder])).count, 1)
    }

    func testAMachineCountsOnlyItsShots() {
        var machine = Purchase(kind: .machine, date: day(2026, 10, 1))
        machine.backflushEveryShots = 3
        let data = CoffeeData(shots: [
            brew(day(2026, 10, 2)), brew(day(2026, 10, 3)),
            brew(day(2026, 10, 4), method: .v60),             // not through the machine
        ])
        XCTAssertEqual(KitCare.amountSince(machine, in: data), 2)
        XCTAssertFalse(KitCare.isDue(machine, in: data))
        XCTAssertEqual(KitCare.line(machine, in: data, now: now), "2 of 3 shots since 1 Oct")
    }

    func testMarkingItDoneStartsTheCountAgainAndKeepsTheDate() {
        var machine = Purchase(kind: .machine, date: day(2026, 10, 1))
        machine.backflushEveryShots = 2
        let data = CoffeeData(shots: [brew(day(2026, 10, 2)), brew(day(2026, 10, 3)),
                                      brew(day(2026, 10, 5))])
        XCTAssertTrue(KitCare.isDue(machine, in: data))
        machine.careDone.append(day(2026, 10, 4))
        XCTAssertEqual(KitCare.amountSince(machine, in: data), 1)
        XCTAssertFalse(KitCare.isDue(machine, in: data))
        XCTAssertTrue(sameDay(KitCare.lastDone(machine), day(2026, 10, 4)))
    }

    func testSensibleStartingNumbersAndOnlyGrindersAndMachines() {
        let p = Purchase()
        XCTAssertEqual(p.burrEveryKg, 5)
        XCTAssertEqual(p.backflushEveryShots, 50)
        XCTAssertNil(KitCare.task(for: Purchase(kind: .accessory)))
        XCTAssertEqual(KitCare.task(for: Purchase(kind: .grinder)), .burrs)
        XCTAssertEqual(KitCare.task(for: Purchase(kind: .machine)), .backflush)
    }

    func testRemovedKitAndRinsedBrewsAreNotCounted() {
        var machine = Purchase(kind: .machine, date: day(2026, 10, 1))
        machine.backflushEveryShots = 1
        var gone = brew(day(2026, 10, 2))
        gone.rinsedAt = now
        XCTAssertFalse(KitCare.isDue(machine, in: CoffeeData(shots: [gone])))
        machine.rinsedAt = now
        let data = CoffeeData(shots: [brew(day(2026, 10, 2))], purchases: [machine])
        XCTAssertTrue(KitCare.due(in: data).isEmpty)
    }

    func testAnOlderFileWithoutKitCareStillOpens() throws {
        let old = #"{"id":"6F1C7A52-1D7B-4E4C-9A51-0B2D5C3E7F10","kind":"grinder","what":"Old grinder"}"#
        let p = try JSONDecoder.coffee.decode(Purchase.self, from: Data(old.utf8))
        XCTAssertEqual(p.burrEveryKg, 5)
        XCTAssertTrue(p.careDone.isEmpty)
    }

    // MARK: - 3. A backup file

    private func someData() -> CoffeeData {
        let bag = Bean(name: "Invented bag")
        var s = Shot(beanID: bag.id)
        s.light = .green
        return CoffeeData(beans: [bag], shots: [s, Shot()], purchases: [Purchase(kind: .grinder)])
    }

    private func tempFolder() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("backup-test-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testTheNameYouTypeBecomesASafeFileName() {
        XCTAssertEqual(BackupFile.fileName(for: "Before the trip"), "Before the trip.json")
        XCTAssertEqual(BackupFile.fileName(for: "a/b:c"), "a-b-c.json")
        XCTAssertEqual(BackupFile.fileName(for: "x.json"), "x.json")
        XCTAssertEqual(BackupFile.fileName(for: "   ", now: now), "AMS Coffee 2026-11-03.json")
    }

    func testABackupFileProvesItselfByBeingReadBackAndCounted() throws {
        let data = someData()
        let url = tempFolder().appendingPathComponent("proof.json")
        try BackupFile.encode(data).write(to: url)
        let proof = BackupFile.prove(url, expecting: data)
        XCTAssertTrue(proof.passed, proof.note)
        XCTAssertEqual(proof.note, "Opened and counted: 1 bag · 2 brews · 1 thing")
    }

    func testABackupFileThatComesBackShortIsNotProved() throws {
        let url = tempFolder().appendingPathComponent("short.json")
        try BackupFile.encode(CoffeeData()).write(to: url)
        XCTAssertFalse(BackupFile.prove(url, expecting: someData()).passed)
        try Data("not coffee".utf8).write(to: url)
        XCTAssertFalse(BackupFile.prove(url, expecting: someData()).passed)
        XCTAssertNil(BackupFile.read(url))
    }

    @MainActor
    func testOpeningABackupPreviewsThenTakesASafetyCup() throws {
        let store = CoffeeStore(root: tempFolder())
        store.upsert(Bean(name: "Here now"))
        store.saveNow()
        let incoming = someData()
        XCTAssertEqual(store.preview(of: incoming), "same bags · +2 brews · +1 kit")

        store.restore(from: incoming, safetyName: "Before opening a backup")
        XCTAssertEqual(store.data.liveBeans.map(\.name), ["Invented bag"])
        XCTAssertTrue(store.shelf.cups.contains { $0.name == "Before opening a backup" && $0.beanCount == 1 },
                      "where you were is kept first")
    }

    // MARK: - 4. Same again from the chart

    func testSameAgainStartsFromTheBestGreenBrewOnThatBag() {
        let bag = Bean(name: "Invented")
        var green = Shot(beanID: bag.id); green.light = .green; green.grind = 12
        green.date = day(2026, 10, 2)
        var later = Shot(beanID: bag.id); later.grind = 9; later.date = day(2026, 10, 3)
        let data = CoffeeData(beans: [bag], shots: [green, later])

        XCTAssertEqual(data.bestGreen(beanID: bag.id, method: .espresso)?.grind, 12)
        XCTAssertNil(data.bestGreen(beanID: bag.id, method: .v60), "no green pour-over")
        XCTAssertNil(CoffeeData(beans: [bag], shots: [later]).bestGreen(beanID: bag.id, method: .espresso))

        let draft = Shot.again(from: green)
        XCTAssertEqual(draft.grind, 12)
        XCTAssertEqual(draft.beanID, bag.id)
        XCTAssertNotEqual(draft.id, green.id, "a new brew, not an edit")
        XCTAssertEqual(draft.light, .amber, "it has not been tasted yet")
        XCTAssertEqual(draft.note, "")
    }

    // MARK: - Fixed: a 1 kg bag read "1 0…"

    func testADialShowsFourDigitsWholeOnASwedishPhone() {
        let swedish = NumberDial.style.locale(Locale(identifier: "sv_SE"))
        XCTAssertEqual(1000.0.formatted(swedish), "1000", "no thousands space")
        XCTAssertEqual(13.5.formatted(swedish), "13,5")
        XCTAssertGreaterThanOrEqual(NumberDial.width(for: 0...5000), 92, "room for 1000")
        XCTAssertEqual(NumberDial.width(for: 0...100), 74)
    }

    // MARK: - 5. Search knows the light and the date

    private func match(_ q: String, _ s: Shot) -> Bool {
        BrewSearch.matches(s, bean: Bean(name: "Kiamaina", origin: "Kenya"), query: q, now: now)
    }

    func testSearchFindsABrewByItsLight() {
        var s = Shot(); s.date = day(2026, 10, 20)
        s.light = .green
        XCTAssertTrue(match("green", s)); XCTAssertTrue(match("lovely", s))
        XCTAssertFalse(match("red", s))
        s.light = .red
        XCTAssertTrue(match("tipped", s)); XCTAssertTrue(match("red", s))
        s.light = .amber
        XCTAssertTrue(match("amber", s)); XCTAssertTrue(match("drinkable", s))
    }

    func testSearchFindsABrewByWhenItWasMade() {
        var s = Shot(); s.date = day(2026, 10, 20)
        XCTAssertTrue(match("october", s))
        XCTAssertTrue(match("Oct", s))
        XCTAssertTrue(match("2026", s))
        XCTAssertFalse(match("september", s))
        XCTAssertFalse(match("2025", s))
        XCTAssertFalse(match("yesterday", s))

        s.date = day(2026, 11, 2)
        XCTAssertTrue(match("yesterday", s))
        s.date = day(2026, 11, 3, hour: 7)
        XCTAssertTrue(match("today", s))
    }

    func testSeveralWordsStillAllHaveToMatch() {
        var s = Shot(); s.date = day(2026, 10, 20); s.light = .green
        XCTAssertTrue(match("kenya green october", s))
        XCTAssertFalse(match("kenya red october", s))
        XCTAssertFalse(match("kenya green november", s))
    }
}

#if os(iOS)
import UIKit

/// Draws words onto a plain white picture, like a label held flat.
enum LabelPicture {
    static func render(_ lines: [String]) -> Data {
        let size = CGSize(width: 1200, height: 900)
        let picture = UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let style: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 90, weight: .bold),
                .foregroundColor: UIColor.black,
            ]
            for (i, line) in lines.enumerated() {
                (line as NSString).draw(at: CGPoint(x: 60, y: 80 + Double(i) * 220),
                                        withAttributes: style)
            }
        }
        return picture.jpegData(compressionQuality: 0.95) ?? Data()
    }
}
#endif
