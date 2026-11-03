import XCTest
@testable import AMSCoffee

/// 2.8 — the label also gives the roast level, and a box filled from the
/// label says so until you change it. Every example here is invented.
final class Release28Tests: XCTestCase {

    private func read(_ lines: [String]) -> LabelSuggestion {
        LabelReader.suggest(fromText: lines)
    }

    // MARK: - 1. Roast level

    func testRoastLevelInEnglishSwedishAndGerman() {
        XCTAssertEqual(read(["Light roast"]).roastLevel, "Light")
        XCTAssertEqual(read(["LJUSROST"]).roastLevel, "Light")
        XCTAssertEqual(read(["Helle Röstung"]).roastLevel, "Light")
        XCTAssertEqual(read(["Mellanrost"]).roastLevel, "Medium")
        XCTAssertEqual(read(["Roast: medium"]).roastLevel, "Medium")
        XCTAssertEqual(read(["Mittlere Röstung"]).roastLevel, "Medium")
        XCTAssertEqual(read(["Medium-light roast"]).roastLevel, "Medium-light")
        XCTAssertEqual(read(["Medium dark roast"]).roastLevel, "Medium-dark")
        XCTAssertEqual(read(["Mörkrost"]).roastLevel, "Dark")
        XCTAssertEqual(read(["Dunkle Röstung"]).roastLevel, "Dark")
        XCTAssertEqual(read(["Light"]).roastLevel, "Light", "the word alone on its line")
    }

    func testAFlavourOrABodyIsNotARoastLevel() {
        XCTAssertNil(read(["Notes: dark chocolate, plum"]).roastLevel)
        XCTAssertNil(read(["Dark chocolate"]).roastLevel)
        XCTAssertNil(read(["Light and juicy"]).roastLevel)
        XCTAssertNil(read(["Roasted 12.10.2026"]).roastLevel)
        XCTAssertNil(read(["Kiamaina AA"]).roastLevel)
    }

    func testARoastLevelLineIsNeverTheName() {
        let s = read(["Kiamaina AA", "Ljusrost", "Kenya"])
        XCTAssertEqual(s.name, "Kiamaina AA")
        XCTAssertEqual(s.roastLevel, "Light")
    }

    func testRoastLevelIsOnlyOfferedForAnEmptyBox() {
        let s = read(["Light roast"])
        XCTAssertFalse(s.isEmpty, "a roast level alone is something")
        var bag = Bean()
        XCTAssertEqual(s.offered(for: bag, hasRoastDate: false).roastLevel, "Light")
        bag.roastLevel = "Typed by hand"
        XCTAssertNil(s.offered(for: bag, hasRoastDate: false).roastLevel)
    }

    // MARK: - 2. "From the label" on a filled box

    func testABoxFilledFromTheLabelSaysSoUntilItIsChanged() {
        var fills = LabelFills()
        XCTAssertFalse(fills.shows(.name, current: "Kiamaina AA"), "never filled")
        fills.filled(.name, with: "Kiamaina AA")
        XCTAssertTrue(fills.shows(.name, current: "Kiamaina AA"))
        XCTAssertTrue(fills.shows(.name, current: " Kiamaina AA "), "spaces do not count")
        XCTAssertFalse(fills.shows(.name, current: "Kiamaina AA, my favourite"), "changed by hand")
        XCTAssertFalse(fills.shows(.origin, current: "Kiamaina AA"), "only that box")
    }

    func testARoastDateFromTheLabelIsMarkedOnlyForThatDay() {
        var fills = LabelFills()
        let day = Date(timeIntervalSince1970: 1_790_000_000)
        fills.filled(day)
        XCTAssertTrue(fills.shows(day.addingTimeInterval(3600)), "the same day")
        XCTAssertFalse(fills.shows(day.addingTimeInterval(86_400 * 2)), "another day picked by hand")
    }
}
