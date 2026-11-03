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

    /// Test 6 (added in 2.2) — the brew timer writes the real time into the
    /// brew. The espresso starter says 28 s; if stopping the clock after two
    /// seconds leaves 28 s in the dial, the timer is decoration.
    func testTheTimerWritesTheTimeIntoTheBrew() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-shots")
        tap(app, "shots-add")

        XCTAssertTrue(waitFor(app, "shot-timer"), "an espresso is worth timing")
        XCTAssertEqual(seconds(app), 28, "the starter time, before we touch anything")

        tap(app, "timer-start")
        Thread.sleep(forTimeInterval: 2.5)
        tap(app, "timer-stop")

        // Two and a half seconds of pouring, not twenty-eight.
        let logged = seconds(app)
        XCTAssertGreaterThan(logged, 0, "the timer should have written something")
        XCTAssertLessThan(logged, 10, "and it should be the time we just timed")
        XCTAssertTrue(waitFor(app, "timer-reset"), "a stopped clock offers Start over")

        tap(app, "light-green")
        tap(app, "shot-save")
        XCTAssertTrue(waitFor(app, "shot-row-0"), "the timed shot should be on the list")
    }

    /// Test 7 — cold brew steeps overnight, so it is NOT given a stopwatch.
    /// This guards `worthTiming`, which is easy to widen by accident.
    func testColdBrewGetsNoStopwatch() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-shots")
        tap(app, "method-coldBrew")
        XCTAssertTrue(waitFor(app, "shot-steephours"), "cold brew is counted in hours")
        XCTAssertTrue(absent(app, "shot-timer"), "and nobody stands there with a stopwatch")
    }

    /// Test 8 (added in 2.3) — the timer knows where it is going. The aim
    /// line proves the coach's window reached the timer; without it the
    /// colours and the buzz would have nothing to measure against.
    func testTheTimerShowsWhatToAimFor() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-shots")
        tap(app, "shots-add")
        XCTAssertTrue(waitFor(app, "timer-aim"), "an espresso should say what to aim for")
    }

    /// Test 9 (added in 2.4) — ask outright what to change, without filling
    /// a whole brew in first. Needs one logged brew to talk about.
    func testAskingWhatToChangeAnswersOnTheSpot() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))
        XCTAssertTrue(absent(app, "home-ask"), "nothing to ask about on a fresh app")

        // Log one brew so there is something to ask about.
        tap(app, "tab-shots")
        tap(app, "shots-add")
        tap(app, "light-green")
        tap(app, "shot-save")
        XCTAssertTrue(waitFor(app, "shot-row-0"))

        tap(app, "tab-today")
        XCTAssertTrue(waitFor(app, "home-ask"), "now it can be asked")
        XCTAssertTrue(absent(app, "ask-answer"), "it answers only once asked")

        tap(app, "ask-bitter")
        XCTAssertTrue(waitFor(app, "ask-answer"), "one concrete change")
    }

    /// Test 10 — a new brew says where its numbers came from, so you can
    /// tell your own recipe from the book's.
    func testANewBrewSaysWhereItsNumbersCameFrom() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-shots")
        tap(app, "shots-add")
        XCTAssertTrue(waitFor(app, "shot-starting-from"))
    }

    /// Test 11 (added in 2.5) — a bag shows how it was dialled in once it
    /// has two brews to draw a line between, and not before.
    func testABagShowsHowItWasDialledIn() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-bags")
        tap(app, "bags-add")
        let name = app.textFields["bag-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText("Test bag")
        dismissKeyboard(app)
        tap(app, "bag-save")
        XCTAssertTrue(waitFor(app, "bag-row-0"))

        // One brew is a dot, not a line.
        tap(app, "tab-shots")
        tap(app, "shots-add")
        tap(app, "shot-save")
        XCTAssertTrue(waitFor(app, "shot-row-0"))
        tap(app, "tab-bags")
        tap(app, "bag-row-0")
        XCTAssertTrue(waitFor(app, "bag-dialin-waiting"), "one brew says the chart is coming")
        XCTAssertTrue(absent(app, "bag-dialin"), "and draws nothing yet")
        tap(app, "bag-close")

        // A second brew, a click finer.
        tap(app, "tab-shots")
        tap(app, "shots-add")
        tap(app, "shot-grind-minus")
        tap(app, "light-green")
        tap(app, "shot-save")
        XCTAssertTrue(waitFor(app, "shot-row-1"))

        tap(app, "tab-bags")
        tap(app, "bag-row-0")
        XCTAssertTrue(waitFor(app, "bag-dialin"), "two brews make a chart")
        XCTAssertTrue(waitFor(app, "dialin-grind"), "with the grind line on it")
    }

    /// Test 12 (added in 2.5) — one search finds a brew by what it is.
    func testSearchFindsABrewByItsMethod() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-shots")
        XCTAssertTrue(absent(app, "brews-search"), "nothing to search on a fresh app")

        tap(app, "shots-add")
        tap(app, "shot-save")
        tap(app, "method-v60")
        tap(app, "shot-save")
        XCTAssertTrue(waitFor(app, "shot-row-1"), "two brews to search through")

        let field = app.textFields["brews-search"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("pour")
        XCTAssertTrue(waitFor(app, "shot-row-0"), "the pour-over is found")
        XCTAssertTrue(absent(app, "shot-row-1"), "and the espresso is not")

        field.typeText("zzz")
        XCTAssertTrue(waitFor(app, "brews-search-empty"), "no match says so")
        XCTAssertTrue(absent(app, "shot-row-0"))
    }

    // MARK: 2.6

    /// Logs a brew from the Brews tab, optionally green.
    private func logBrew(_ app: XCUIApplication, green: Bool = false) {
        tap(app, "tab-shots")
        tap(app, "shots-add")
        if green { tap(app, "light-green") }
        tap(app, "shot-save")
    }

    private func addBag(_ app: XCUIApplication, named: String) {
        tap(app, "tab-bags")
        tap(app, "bags-add")
        let name = app.textFields["bag-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText(named)
        dismissKeyboard(app)
        tap(app, "bag-save")
    }

    /// Test 13 — what the label says is offered, tapped in one at a time,
    /// and never lands on something already typed. The words stand in for
    /// a photo: a test cannot hold a bag up to the camera.
    func testTheBagLabelIsOfferedButNeverOverwrites() {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTesting"]
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        app.launchEnvironment["LABEL_LINES"] =
            "Little Owl Rosteri|Kenya|Roasted \(f.string(from: tenDaysAgo))"
        app.launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-bags")
        tap(app, "bags-add")
        XCTAssertTrue(waitFor(app, "bag-label-suggest-roaster"), "the roaster is offered")

        // The offers push the roaster box down behind the Save bar; bring
        // it up before typing, then go back to the top for the offers.
        let roaster = app.textFields["bag-roaster"]
        XCTAssertTrue(roaster.waitForExistence(timeout: 10))
        app.scrollViews.firstMatch.swipeUp()
        roaster.tap()
        roaster.typeText("Typed by hand")
        dismissKeyboard(app)
        app.scrollViews.firstMatch.swipeDown()
        app.scrollViews.firstMatch.swipeDown()
        XCTAssertTrue(absent(app, "bag-label-suggest-roaster"),
                      "once something is typed, it is not offered any more")

        tap(app, "bag-label-suggest-origin")
        XCTAssertEqual(app.textFields["bag-origin"].value as? String, "Kenya")
        tap(app, "bag-label-suggest-roastdate")
        let roasted = app.switches["bag-has-roastdate"]
        XCTAssertTrue(roasted.waitForExistence(timeout: 10))
        XCTAssertEqual(roasted.value as? String, "1", "the roast date is switched on and filled")
        XCTAssertTrue(absent(app, "bag-label-suggestions"), "and nothing is left to offer")
        XCTAssertEqual(roaster.value as? String, "Typed by hand", "and the typed roaster is untouched")
    }

    /// Test 14 — a machine counts its shots, Today says when the backflush
    /// is due, and one tap puts it away.
    func testTodaySaysWhenTheBackflushIsDue() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))

        tap(app, "tab-settings")
        tap(app, "settings-kit")
        tap(app, "kit-add")
        tap(app, "kit-kind-machine")
        XCTAssertTrue(waitFor(app, "kit-care"), "a machine is looked after")
        for _ in 0..<9 { tap(app, "kit-care-every-minus") }     // 50 → 5 shots
        tap(app, "kit-save")
        tap(app, "kit-close")

        XCTAssertTrue(absent(app, "home-kit-due"), "nothing is due yet")
        for _ in 0..<5 { logBrew(app) }

        tap(app, "tab-today")
        XCTAssertTrue(waitFor(app, "home-kit-due"), "five shots: the backflush is due")
        tap(app, "home-kit-done-0")
        XCTAssertTrue(waitFor(app, "home-pull-shot"))
        XCTAssertTrue(absent(app, "home-kit-due"), "done, so the line goes")
    }

    /// Test 15 — a backup file is named, written and proved before it gets
    /// its tick. (Under test it goes to a scratch folder instead of the
    /// system's place picker, which a test cannot drive.)
    func testABackupFileProvesItself() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))
        logBrew(app, green: true)

        tap(app, "tab-settings")
        tap(app, "settings-backup")
        let name = app.textFields["backup-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 10))
        name.tap()
        name.typeText(" before the trip")
        dismissKeyboard(app)
        tap(app, "backup-save")
        XCTAssertTrue(waitFor(app, "backup-proved"), "read back and counted")
    }

    /// Test 16 — Same again from the chart, only once there is a green brew.
    func testSameAgainFromTheDialInChart() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))
        addBag(app, named: "Test bag")
        logBrew(app)

        tap(app, "tab-bags")
        tap(app, "bag-row-0")
        XCTAssertTrue(waitFor(app, "bag-dialin-waiting"))
        XCTAssertTrue(absent(app, "dialin-same-again"), "no green brew, no button")
        tap(app, "bag-close")

        logBrew(app, green: true)
        tap(app, "tab-bags")
        tap(app, "bag-row-0")
        tap(app, "dialin-same-again")
        XCTAssertTrue(waitFor(app, "shot-starting-from"), "a new brew from the green one")
        tap(app, "shot-save")
        tap(app, "bag-close")
        tap(app, "tab-shots")
        XCTAssertTrue(waitFor(app, "shot-row-2"), "and it is the third brew")
    }

    /// Test 17 — search knows the light.
    func testSearchFindsABrewByItsLight() {
        let app = launch()
        XCTAssertTrue(waitFor(app, "home-pull-shot"))
        logBrew(app)
        logBrew(app, green: true)
        XCTAssertTrue(waitFor(app, "shot-row-1"))

        let field = app.textFields["brews-search"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("lovely today")
        XCTAssertTrue(waitFor(app, "shot-row-0"), "the green one is found")
        XCTAssertTrue(absent(app, "shot-row-1"), "and the amber one is not")
    }

    /// The number in the Total time dial, read back out of the field.
    private func seconds(_ app: XCUIApplication) -> Double {
        let field = app.textFields["shot-seconds"]
        guard field.waitForExistence(timeout: 10),
              let shown = field.value as? String else { return -1 }
        // A Swedish phone writes 2,5 where a British one writes 2.5.
        return Double(shown.replacingOccurrences(of: ",", with: ".")) ?? -1
    }
}
