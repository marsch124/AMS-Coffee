import XCTest

/// Two tests to begin with, and one more added at a time.
///
/// Every control is found by its accessibility identifier — never by the words
/// on it — so rewording a button can never turn the suite red.
final class AMSCoffeeUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting"]     // a fresh, throwaway shelf
        app.launch()
        return app
    }

    /// Typed queries only. `descendants(matching: .any)` walks the whole tree
    /// on every call and turns a 20-second test into a five-minute one.
    /// Taps a control, scrolling the screen up until it is actually on screen.
    /// A control that exists but is below the fold is not hittable, so every
    /// long form needs this — not just this one test.
    private func tap(_ app: XCUIApplication, _ id: String,
                     timeout: TimeInterval = 20, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(timeout)
        var scrolls = 0
        while Date() < deadline {
            for candidate in [app.buttons[id], app.otherElements[id]] {
                if candidate.exists && candidate.isHittable {
                    candidate.tap()
                    return
                }
            }
            // Scroll down the left-hand gutter, clear of the taste sliders —
            // a swipe through the middle of the card would drag one of them.
            if scrolls < 8 {
                scrollDown(app)
                scrolls += 1
            }
            usleep(200_000)
        }
        XCTFail("nothing hittable with identifier \(id)", line: line)
    }

    private func scrollDown(_ app: XCUIApplication) {
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.04, dy: 0.78))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.04, dy: 0.28))
        from.press(forDuration: 0.05, thenDragTo: to)
    }

    private func waitFor(_ app: XCUIApplication, _ id: String,
                         timeout: TimeInterval = 15) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if app.buttons[id].exists { return true }
            if app.otherElements[id].exists { return true }
            if app.staticTexts[id].exists { return true }
            if app.images[id].exists { return true }
            if app.textFields[id].exists { return true }
            usleep(200_000)
        }
        return false
    }

    private func absent(_ app: XCUIApplication, _ id: String) -> Bool {
        !app.buttons[id].exists && !app.otherElements[id].exists
            && !app.staticTexts[id].exists && !app.images[id].exists
    }

    /// Test 1 — the thing the app is for: log a shot and see it in the list.
    func testLoggingAShotPutsItInTheList() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"), "the app should open on Today")

        tap(app, "tab-shots")
        XCTAssertTrue(waitFor(app, "shots-empty"), "a fresh app has no shots")

        tap(app, "shots-add")
        tap(app, "shot-yield-plus")             // 36 g → 37 g
        tap(app, "light-green")
        tap(app, "shot-save")

        XCTAssertTrue(waitFor(app, "shot-row-0"), "the shot should be on the list")
        XCTAssertTrue(absent(app, "shots-empty"), "and the empty note should be gone")
    }

    /// Test 2 — the safety net: a cup is poured AND proves itself.
    func testSavingACupProvesItself() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-cups")
        tap(app, "cups-save-keepsake")
        tap(app, "cups-keepsake-confirm")

        XCTAssertTrue(waitFor(app, "cup-restore-0"), "the cup should be on the shelf")
        XCTAssertTrue(waitFor(app, "cup-tested-0"),
                      "and it should carry its tested stamp")
    }

    /// Test 3 (added in 1.1) — each method shows its own dials and no others.
    /// This is the one that would catch a pour-over asking for grams out.
    func testEachMethodShowsOnlyItsOwnDials() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-shots")

        // Espresso is weighed out of the cup: yield, no water in.
        tap(app, "shots-add")
        XCTAssertTrue(waitFor(app, "shot-yield"), "espresso should ask for grams out")
        XCTAssertTrue(absent(app, "shot-water"), "espresso should not ask for water in")
        tap(app, "shot-close")

        // A pour-over is weighed in: water and bloom, no yield.
        tap(app, "method-v60")
        XCTAssertTrue(waitFor(app, "shot-water"), "a pour-over should ask for water in")
        XCTAssertTrue(waitFor(app, "shot-bloomwater"), "a pour-over should ask about the bloom")
        XCTAssertTrue(absent(app, "shot-yield"), "a pour-over should not ask for grams out")

        tap(app, "light-green")
        tap(app, "shot-save")
        XCTAssertTrue(waitFor(app, "shot-row-0"), "the pour-over should be on the list")
    }

    /// Test 4 (added in 1.1) — a purchase is saved and reaches the totals.
    func testAddingAPurchaseReachesTheTotals() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-money")
        XCTAssertTrue(waitFor(app, "money-empty"), "a fresh app has no gear")

        tap(app, "money-add")
        tap(app, "purchase-kind-grinder")
        tap(app, "purchase-price-plus")        // 0 kr -> 50 kr
        tap(app, "purchase-save")

        XCTAssertTrue(waitFor(app, "purchase-row-0"), "the purchase should be on the list")
        XCTAssertTrue(absent(app, "money-empty"), "and the empty note should be gone")
        XCTAssertTrue(waitFor(app, "money-year"), "the year totals should still be there")
    }
}
