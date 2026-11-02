import XCTest
@testable import AMSCoffee

/// 2.5 — the dial-in chart and the search across every brew. Both are pure
/// rules pulled out of their screens, so each can be checked without a
/// simulator.
final class DialInTests: XCTestCase {

    private let bag = Bean(roaster: "Hill & Hollow", name: "Kiamaina", origin: "Kenya")

    private func shot(_ day: Int, grind: Double, seconds: Double = 28,
                      dose: Double = 18, taste: Double = 0,
                      light: TrafficLight = .amber,
                      method: BrewMethod = .espresso, beanID: UUID? = nil) -> Shot {
        var s = method.starter()
        s.beanID = beanID ?? bag.id
        s.date = Date(timeIntervalSince1970: Double(day) * 86_400)
        s.grind = grind
        s.seconds = seconds
        s.doseGrams = dose
        s.sourBitter = taste
        s.light = light
        return s
    }

    // MARK: The chart

    func testTheChartRunsOldestToNewestForOneBagAndOneMethod() {
        let other = Bean(name: "Someone else's")
        var rinsed = shot(4, grind: 1)
        rinsed.rinsedAt = Date()
        let data = CoffeeData(beans: [bag, other], shots: [
            shot(3, grind: 13),
            shot(1, grind: 15),
            shot(2, grind: 14),
            shot(5, grind: 30, method: .v60),          // another method
            shot(6, grind: 2, beanID: other.id),       // another bag
            rinsed,                                    // in the Sink
        ])
        let brews = DialIn.brews(in: data, beanID: bag.id, method: .espresso)
        XCTAssertEqual(brews.map(\.grind), [15, 14, 13])
    }

    func testTheChartOpensOnTheMethodLastUsed() {
        let data = CoffeeData(beans: [bag], shots: [
            shot(1, grind: 15),
            shot(2, grind: 25, method: .v60),
        ])
        XCTAssertEqual(DialIn.defaultMethod(in: data, beanID: bag.id), .v60)
        XCTAssertNil(DialIn.defaultMethod(in: CoffeeData(beans: [bag]), beanID: bag.id))
    }

    func testEachMeasureReadsItsOwnNumber() {
        let s = shot(1, grind: 14, seconds: 31, dose: 18.5, taste: -0.4)
        XCTAssertEqual(DialMeasure.grind.value(of: s), 14)
        XCTAssertEqual(DialMeasure.dose.value(of: s), 18.5)
        XCTAssertEqual(DialMeasure.time.value(of: s), 31)
        XCTAssertEqual(DialMeasure.taste.value(of: s), -0.4)
    }

    /// Cold brew is timed in hours; the chart must read the same clock the
    /// card does, not the empty seconds field.
    func testTimeOnAColdBrewIsItsSteep() {
        var s = BrewMethod.coldBrew.starter()
        s.steepHours = 14
        XCTAssertEqual(DialMeasure.time.value(of: s), 14 * 3600)
    }

    func testGrindGoingDownIsFiner() {
        let line = DialIn.heading(.grind, [shot(1, grind: 15), shot(2, grind: 13.5)], method: .espresso)
        XCTAssertEqual(line, "15 → 13.5 · finer")
        let back = DialIn.heading(.grind, [shot(1, grind: 13), shot(2, grind: 15)], method: .espresso)
        XCTAssertEqual(back, "13 → 15 · coarser")
    }

    func testNothingMovedSaysSo() {
        let line = DialIn.heading(.dose, [shot(1, grind: 15), shot(2, grind: 14)], method: .espresso)
        XCTAssertEqual(line, "18 g all along")
    }

    /// Time is judged against the coach's own window, so the chart and the
    /// coach can never tell two different stories.
    func testTimeSaysWhetherItLandedInTheWindow() {
        let into = DialIn.heading(.time, [shot(1, grind: 15, seconds: 21),
                                          shot(2, grind: 14, seconds: 28)], method: .espresso)
        XCTAssertEqual(into, "21 s → 28 s · in the window")
        let short = DialIn.heading(.time, [shot(1, grind: 15, seconds: 28),
                                           shot(2, grind: 14, seconds: 20)], method: .espresso)
        XCTAssertEqual(short, "28 s → 20 s · short of 25–32 s")
        let long = DialIn.heading(.time, [shot(1, grind: 15, seconds: 28),
                                          shot(2, grind: 14, seconds: 40)], method: .espresso)
        XCTAssertEqual(long, "28 s → 40 s · past 25–32 s")
    }

    func testTasteIsToldInWordsNotNumbers() {
        let line = DialIn.heading(.taste, [shot(1, grind: 15, taste: -0.7),
                                           shot(2, grind: 14, taste: 0.1)], method: .espresso)
        XCTAssertEqual(line, "sour → balanced")
        XCTAssertEqual(DialIn.tasteWord(0.6), "bitter")
        XCTAssertEqual(DialIn.tasteWord(-0.25), "a little sour")
        XCTAssertEqual(DialIn.tasteWord(0.25), "a little bitter")
    }

    func testOneBrewIsNotATrend() {
        XCTAssertNil(DialIn.heading(.grind, [shot(1, grind: 15)], method: .espresso))
        XCTAssertNil(DialIn.heading(.grind, [], method: .espresso))
    }

    /// The chart only draws dials the method has. Cold brew has no stopwatch
    /// but does steep, so it keeps its time line.
    func testEveryMethodChartsGrindDoseTimeAndTaste() {
        for method in BrewMethod.allCases {
            XCTAssertEqual(DialIn.measures(for: method), [.grind, .dose, .time, .taste],
                           "\(method) should chart all four")
        }
    }

    func testTheSummaryCountsTheGreens() {
        let line = DialIn.summary([shot(1, grind: 15, light: .red),
                                   shot(2, grind: 14, light: .amber),
                                   shot(3, grind: 13, light: .green)])
        XCTAssertEqual(line, "3 brews · 1 green · the last one green")
    }

    // MARK: Search

    private func match(_ q: String, _ s: Shot, _ b: Bean?) -> Bool {
        BrewSearch.matches(s, bean: b, query: q)
    }

    func testAnEmptySearchMatchesEverything() {
        XCTAssertTrue(match("", shot(1, grind: 15), nil))
        XCTAssertTrue(match("   ", shot(1, grind: 15), bag))
    }

    func testSearchFindsBagRoasterOriginMethodAndNote() {
        var s = shot(1, grind: 15, method: .v60)
        s.note = "Channelled on the left"
        XCTAssertTrue(match("kiamaina", s, bag), "the bag")
        XCTAssertTrue(match("HOLLOW", s, bag), "the roaster, any case")
        XCTAssertTrue(match("kenya", s, bag), "the origin")
        XCTAssertTrue(match("pour", s, bag), "the method")
        XCTAssertTrue(match("channelled", s, bag), "the note")
        XCTAssertFalse(match("ethiopia", s, bag))
    }

    func testEveryWordMustMatchSomewhere() {
        let s = shot(1, grind: 15, method: .v60)
        XCTAssertTrue(match("kenya pour", s, bag), "two words in two places")
        XCTAssertFalse(match("kenya espresso", s, bag), "one word that is nowhere")
    }

    func testAccentsDoNotMatter() {
        let b = Bean(roaster: "Café Älva", name: "Señor")
        let s = shot(1, grind: 15, beanID: b.id)
        XCTAssertTrue(match("cafe alva", s, b))
        XCTAssertTrue(match("senor", s, b))
    }

    func testABrewWithNoBagIsStillFoundByItsMethodAndNote() {
        var s = shot(1, grind: 15, method: .aeropress)
        s.note = "upside down"
        XCTAssertTrue(match("aeropress", s, nil))
        XCTAssertTrue(match("upside", s, nil))
        XCTAssertFalse(match("kenya", s, nil))
    }

    func testSearchListsNewestFirstAndSkipsTheSink() {
        var rinsed = shot(9, grind: 1)
        rinsed.rinsedAt = Date()
        let data = CoffeeData(beans: [bag], shots: [shot(1, grind: 15), shot(3, grind: 13), rinsed])
        let found = BrewSearch.results(in: data, query: "kenya", method: nil)
        XCTAssertEqual(found.map(\.grind), [13, 15])
    }

    func testSearchAndTheMethodFilterWorkTogether() {
        let data = CoffeeData(beans: [bag], shots: [shot(1, grind: 15),
                                                     shot(2, grind: 25, method: .v60)])
        XCTAssertEqual(BrewSearch.results(in: data, query: "kenya", method: .v60).count, 1)
        XCTAssertEqual(BrewSearch.results(in: data, query: "", method: nil).count, 2)
    }
}
