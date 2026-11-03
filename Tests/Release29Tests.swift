import XCTest
@testable import AMSCoffee

/// 2.9 — the bag's roast on its card, and the Brews search finds a brew by
/// its bag's roast. Every example here is invented.
final class Release29Tests: XCTestCase {

    // MARK: - 1. The card line

    func testTheCardSaysTheRoast() {
        XCTAssertEqual(Bean(roastLevel: "Light").roastCardText, "Light roast")
        XCTAssertEqual(Bean(roastLevel: "medium-dark").roastCardText, "Medium-dark roast")
        XCTAssertEqual(Bean(roastLevel: "Light roast").roastCardText, "Light roast",
                       "never \"Light roast roast\"")
        XCTAssertEqual(Bean(roastLevel: "Ljusrost").roastCardText, "Ljusrost",
                       "a Swedish word that already says roast stays as typed")
        XCTAssertEqual(Bean(roastLevel: "Helle Röstung").roastCardText, "Helle Röstung")
    }

    func testAnEmptyRoastSaysNothing() {
        XCTAssertNil(Bean(roastLevel: "").roastCardText)
        XCTAssertNil(Bean(roastLevel: "   ").roastCardText)
    }

    func testTheCardLineJoinsOriginProcessAndRoast() {
        XCTAssertEqual(Bean(origin: "Kenya", process: "Washed", roastLevel: "Light").cardDetails,
                       "Kenya · Washed · Light roast")
        XCTAssertEqual(Bean(origin: "Kenya").cardDetails, "Kenya", "no roast, no roast words")
        XCTAssertEqual(Bean(roastLevel: "Dark").cardDetails, "Dark roast")
        XCTAssertNil(Bean().cardDetails, "nothing filled, no line")
    }

    // MARK: - 2. Search by the bag's roast

    private func finds(_ query: String, roast: String, origin: String = "") -> Bool {
        BrewSearch.matches(Shot(), bean: Bean(origin: origin, roastLevel: roast), query: query)
    }

    func testSearchFindsTheRoastInEveryLanguage() {
        XCTAssertTrue(finds("light", roast: "Light"))
        XCTAssertTrue(finds("ljusrost", roast: "Light"))
        XCTAssertTrue(finds("helle röstung", roast: "Light"))
        XCTAssertTrue(finds("medium", roast: "Medium"))
        XCTAssertTrue(finds("mellanrost", roast: "Medium"))
        XCTAssertTrue(finds("mittlere Röstung", roast: "Medium"))
        XCTAssertTrue(finds("dark", roast: "Dark"))
        XCTAssertTrue(finds("mörkrost", roast: "Dark"))
        XCTAssertTrue(finds("dunkle röstung", roast: "Dark"))
        XCTAssertTrue(finds("medium-dark", roast: "Medium-dark"))
        XCTAssertTrue(finds("medium dark", roast: "Medium-dark"), "two words mean the same")
        XCTAssertTrue(finds("light roast", roast: "Light"))
    }

    func testTheStoredRoastCanBeInAnyLanguageToo() {
        XCTAssertTrue(finds("light", roast: "Ljusrost"))
        XCTAssertTrue(finds("dark", roast: "Dunkle Röstung"))
        XCTAssertTrue(finds("ljusrost", roast: "light roast"))
    }

    func testDarkIsNotMediumDark() {
        XCTAssertFalse(finds("dark", roast: "Medium-dark"))
        XCTAssertFalse(finds("medium", roast: "Medium-dark"))
        XCTAssertFalse(finds("light", roast: "Medium-light"))
        XCTAssertFalse(finds("medium-dark", roast: "Dark"))
        XCTAssertFalse(finds("dark", roast: "Light"))
        XCTAssertFalse(finds("light", roast: ""), "no roast, nothing to find")
    }

    func testEveryWordStillHasToMatch() {
        XCTAssertTrue(finds("kenya light", roast: "Light", origin: "Kenya"))
        XCTAssertFalse(finds("kenya dark", roast: "Light", origin: "Kenya"))
        XCTAssertFalse(finds("brazil light", roast: "Light", origin: "Kenya"))
    }
}
