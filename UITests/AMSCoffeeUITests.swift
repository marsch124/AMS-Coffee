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
            dismissKeyboard(app)
            if scrolls < 10 {
                scrollDown(app)
                scrolls += 1
            }
            usleep(200_000)
        }

        // A control pinned in a bottom inset — the add bars — exists but can
        // report itself as not hittable, and no amount of scrolling changes
        // that. If it is there, tap where it is.
        for candidate in [app.buttons[id], app.otherElements[id]] where candidate.exists {
            candidate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }
        XCTFail("nothing hittable with identifier \(id)", line: line)
    }

    private func scrollDown(_ app: XCUIApplication) {
        // A raw coordinate drag can land inside a text field, focus it and
        // raise the keyboard — which on a small phone covers the sticky Save
        // bar, and the test then reports Save as "not hittable". swipeUp on
        // the scroll view is a real scroll gesture and touches nothing.
        let scroll = app.scrollViews.firstMatch
        if scroll.exists { scroll.swipeUp() } else { app.swipeUp() }
    }

    /// The keyboard hides the sticky bar on a small screen. Put it away.
    private func dismissKeyboard(_ app: XCUIApplication) {
        guard app.keyboards.count > 0 else { return }
        if app.buttons["Return"].exists { app.buttons["Return"].tap(); return }
        app.scrollViews.firstMatch.swipeDown()
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

        tap(app, "tab-settings")
        tap(app, "settings-cups")
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

    /// Test 4 — your kit now lives in Settings, and carries a receipt photo.
    func testAddingSomethingToYourKit() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-settings")
        tap(app, "settings-kit")
        XCTAssertTrue(waitFor(app, "kit-empty"), "a fresh app owns no kit")

        tap(app, "kit-add")
        XCTAssertTrue(waitFor(app, "kit-photo-empty"), "a kit item can hold a receipt")
        tap(app, "kit-kind-grinder")
        tap(app, "kit-price-plus")
        tap(app, "kit-save")

        XCTAssertTrue(waitFor(app, "kit-row-0"), "it should be listed")
        XCTAssertTrue(absent(app, "kit-empty"), "and the empty note should be gone")
    }

    /// Test 5 (added in 2.0) — the restructure itself. The guide and the
    /// version history belong in Settings, and Money is gone for good.
    func testSettingsHoldsTheGuideAndTheHistory() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))
        XCTAssertTrue(absent(app, "tab-money"), "there is no Money tab any more")

        tap(app, "tab-settings")
        XCTAssertTrue(waitFor(app, "settings-where"), "Settings says where the data lives")

        tap(app, "settings-version-toggle")
        XCTAssertTrue(waitFor(app, "settings-version-list"), "the history unfolds here")

        tap(app, "settings-guide-toggle")
        XCTAssertTrue(waitFor(app, "settings-guide-list"), "and so does the guide")
    }
}
