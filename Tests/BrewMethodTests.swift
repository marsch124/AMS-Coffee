import XCTest
@testable import AMSCoffee

final class BrewMethodTests: XCTestCase {

    func testEspressoIsWeighedOutAndEverythingElseIsWeighedIn() {
        XCTAssertFalse(BrewMethod.espresso.isWeighedByWaterIn)
        for method in BrewMethod.allCases where method != .espresso {
            XCTAssertTrue(method.isWeighedByWaterIn, "\(method) should be weighed in")
        }
    }

    /// Every method must offer its own dials, and only dials it can use.
    func testEveryMethodHasFieldsAndAStarter() {
        for method in BrewMethod.allCases {
            XCTAssertFalse(method.fields.isEmpty, "\(method) has no dials")
            XCTAssertTrue(method.fields.contains(.dose), "\(method) must ask for coffee in")
            let starter = method.starter()
            XCTAssertEqual(starter.method, method)
            XCTAssertGreaterThan(starter.doseGrams, 0, "\(method) starter has no dose")
            XCTAssertGreaterThan(starter.liquidGrams, 0, "\(method) starter has no liquid")
            XCTAssertNotNil(starter.ratio, "\(method) starter cannot compute a ratio")
        }
    }

    /// A starter recipe should land inside the window the coach judges it by,
    /// otherwise the app ships advice that contradicts its own defaults.
    func testEveryStarterLandsInsideItsOwnWindow() {
        for method in BrewMethod.allCases {
            let starter = method.starter()
            let ratio = starter.ratio ?? 0
            XCTAssertTrue(method.idealRatio.contains(ratio),
                          "\(method) starter ratio \(ratio) is outside \(method.idealRatio)")
            XCTAssertTrue(method.idealSeconds.contains(starter.totalSeconds),
                          "\(method) starter time \(starter.totalSeconds)s is outside \(method.idealSeconds)")
        }
    }

    func testRatioUsesWaterInForBrewedMethodsAndYieldForEspresso() {
        var pourOver = BrewMethod.v60.starter()
        pourOver.doseGrams = 15
        pourOver.waterGrams = 250
        pourOver.yieldGrams = 999          // must be ignored
        XCTAssertEqual(pourOver.ratio ?? 0, 250.0 / 15.0, accuracy: 0.001)

        var shot = BrewMethod.espresso.starter()
        shot.doseGrams = 18
        shot.yieldGrams = 36
        shot.waterGrams = 999              // must be ignored
        XCTAssertEqual(shot.ratio ?? 0, 2, accuracy: 0.001)
    }

    func testTimeTextReadsInTheRightUnit() {
        var cold = BrewMethod.coldBrew.starter()
        cold.steepHours = 16
        XCTAssertEqual(cold.timeText, "16 h")

        var press = Shot(method: .frenchPress)
        press.seconds = 240
        XCTAssertEqual(press.timeText, "4 min")

        var shot = Shot(method: .espresso)
        shot.seconds = 29
        XCTAssertEqual(shot.timeText, "29 s")
    }

    /// A bag's pour-over recipe must never turn up when pulling a shot.
    func testRecipesAreKeptApartByMethod() {
        let bean = Bean()
        var shot = Shot(beanID: bean.id, method: .espresso)
        shot.grind = 13
        shot.light = .green
        var pourOver = Shot(beanID: bean.id, method: .v60)
        pourOver.grind = 26
        pourOver.light = .green

        let data = CoffeeData(beans: [bean], shots: [shot, pourOver])
        XCTAssertEqual(data.bestShot(beanID: bean.id, method: .espresso)?.grind, 13)
        XCTAssertEqual(data.bestShot(beanID: bean.id, method: .v60)?.grind, 26)
        XCTAssertNil(data.bestShot(beanID: bean.id, method: .moka))
        XCTAssertEqual(data.methodsUsed(beanID: bean.id), [.espresso, .v60])
    }
}

final class BrewedCoachTests: XCTestCase {

    func testAFrenchPressIsToldToSteepShorterWhenBitter() {
        var brew = BrewMethod.frenchPress.starter()
        brew.sourBitter = 0.6
        brew.light = .amber
        XCTAssertEqual(Coach.advise(for: brew).headline, "Steep it shorter")
    }

    func testAFrenchPressIsToldToSteepLongerWhenSour() {
        var brew = BrewMethod.frenchPress.starter()
        brew.sourBitter = -0.6
        brew.light = .red
        XCTAssertEqual(Coach.advise(for: brew).headline, "Steep it longer")
    }

    /// A pour-over turns the grinder, not the clock — different words.
    func testAPourOverIsToldToGrindWhenItTastesOff() {
        var brew = BrewMethod.v60.starter()
        brew.sourBitter = -0.5
        brew.light = .amber
        XCTAssertEqual(Coach.advise(for: brew).headline, "Grind finer")

        brew.sourBitter = 0.5
        XCTAssertEqual(Coach.advise(for: brew).headline, "Grind coarser")
    }

    func testThinAndOverWateredIsToldToUseLessWater() {
        var brew = BrewMethod.v60.starter()
        brew.doseGrams = 15
        brew.waterGrams = 320               // 1 : 21
        brew.sourBitter = 0
        brew.thinSyrupy = -0.6
        brew.light = .amber
        XCTAssertEqual(Coach.advise(for: brew).headline, "Less water")
    }

    func testStrongAndUnderWateredIsToldToUseMoreWater() {
        var brew = BrewMethod.frenchPress.starter()
        brew.doseGrams = 40
        brew.waterGrams = 400               // 1 : 10
        brew.thinSyrupy = 0.6
        brew.light = .amber
        XCTAssertEqual(Coach.advise(for: brew).headline, "More water")
    }

    func testGreenLeavesEveryMethodAlone() {
        for method in BrewMethod.allCases {
            var brew = method.starter()
            brew.light = .green
            brew.sourBitter = -0.9          // a wild slider cannot override green
            XCTAssertEqual(Coach.advise(for: brew).headline, "Keep it exactly here",
                           "\(method) should be left alone when it is green")
            XCTAssertTrue(Coach.advise(for: brew).detail.contains(method.title.lowercased()),
                          "\(method) recipe should name the method")
        }
    }

    /// Whatever the state, the coach always says something usable.
    func testTheCoachNeverRunsOutOfWordsForAnyMethod() {
        for method in BrewMethod.allCases {
            for sour in [-1.0, -0.2, 0.0, 0.2, 1.0] {
                for body in [-1.0, 0.0, 1.0] {
                    for light in TrafficLight.allCases {
                        var brew = method.starter()
                        brew.sourBitter = sour
                        brew.thinSyrupy = body
                        brew.light = light
                        let advice = Coach.advise(for: brew)
                        XCTAssertFalse(advice.headline.isEmpty)
                        XCTAssertFalse(advice.detail.isEmpty)
                    }
                }
            }
        }
    }
}

final class MoneyTests: XCTestCase {

    private func data() -> CoffeeData {
        let bean = Bean(bagWeightGrams: 250, priceSEK: 200)
        var d = CoffeeData(beans: [bean, Bean(priceSEK: 100)],
                           shots: [Shot(beanID: bean.id), Shot(beanID: bean.id),
                                   Shot(beanID: bean.id)])
        d.purchases = [Purchase(kind: .grinder, what: "Niche", priceSEK: 9000),
                       Purchase(kind: .accessory, what: "Scale", priceSEK: 600)]
        return d
    }

    func testBeansAndGearAreCountedSeparatelyAndTogether() {
        let d = data()
        XCTAssertEqual(d.beanSpend(), 300, accuracy: 0.001)
        XCTAssertEqual(d.gearSpend(), 9600, accuracy: 0.001)
        XCTAssertEqual(d.totalSpend(), 9900, accuracy: 0.001)
    }

    /// A bag is never entered twice — its price comes from the bag, not from
    /// a purchase row, so the two totals cannot double up.
    func testCostPerCupComesBothWays() {
        let d = data()
        XCTAssertEqual(d.costPerCup ?? 0, 100, accuracy: 0.001)
        XCTAssertEqual(d.costPerCupWithGear ?? 0, 3300, accuracy: 0.001)
    }

    func testNoCupsMeansNoCostPerCup() {
        var d = CoffeeData(beans: [Bean(priceSEK: 200)])
        XCTAssertNil(d.costPerCup)
        d.shots = [Shot()]
        XCTAssertNotNil(d.costPerCup)
    }

    func testARinsedPurchaseStopsCounting() {
        var d = data()
        d.purchases[0].rinsedAt = Date()
        XCTAssertEqual(d.gearSpend(), 600, accuracy: 0.001)
    }

    func testOnlyWarrantiesAboutToRunOutAreFlagged() {
        let soon = Calendar.current.date(byAdding: .day, value: 20, to: Date())
        let later = Calendar.current.date(byAdding: .day, value: 400, to: Date())
        let gone = Calendar.current.date(byAdding: .day, value: -5, to: Date())
        var d = CoffeeData()
        d.purchases = [
            Purchase(what: "soon", warrantyUntil: soon),
            Purchase(what: "later", warrantyUntil: later),
            Purchase(what: "gone", warrantyUntil: gone),
            Purchase(what: "none"),
        ]
        XCTAssertEqual(d.warrantiesRunningOut.map(\.what), ["soon"])
    }

    func testSpendCanBeAskedForOneYear() {
        var d = CoffeeData()
        let old = Calendar.current.date(byAdding: .year, value: -3, to: Date())!
        d.purchases = [Purchase(priceSEK: 500),
                       Purchase(priceSEK: 700, date: old)]
        let thisYear = Calendar.current.component(.year, from: Date())
        XCTAssertEqual(d.gearSpend(in: thisYear), 500, accuracy: 0.001)
        XCTAssertEqual(d.gearSpend(), 1200, accuracy: 0.001)
    }
}

/// The promise that new features can never lock him out of his own history.
final class OldFileTests: XCTestCase {

    /// A file exactly as version 1.0 wrote it: no purchases, no water, no
    /// bloom, no method on the shot.
    private let v10File = """
    {
      "beans": [
        {
          "bagWeightGrams": 250,
          "createdAt": "2026-09-01T08:00:00Z",
          "flavours": ["berry"],
          "id": "11111111-1111-1111-1111-111111111111",
          "modifiedAt": "2026-09-01T08:00:00Z",
          "name": "Kenya Gatomboya",
          "notes": "",
          "origin": "Kenya",
          "priceSEK": 245,
          "process": "Washed",
          "rating": 5,
          "roastLevel": "Light",
          "roaster": "Koppi",
          "verdict": "buyAgain"
        }
      ],
      "savedAt": "2026-09-17T08:00:00Z",
      "schema": 1,
      "shots": [
        {
          "basket": "18 g VST",
          "beanID": "11111111-1111-1111-1111-111111111111",
          "createdAt": "2026-09-17T06:00:00Z",
          "date": "2026-09-17T06:00:00Z",
          "doseGrams": 18,
          "grind": 13.5,
          "light": "green",
          "modifiedAt": "2026-09-17T06:00:00Z",
          "note": "There it is.",
          "preInfusionSeconds": 5,
          "seconds": 29,
          "sourBitter": 0.05,
          "tempC": 93,
          "thinSyrupy": 0.6,
          "yieldGrams": 37
        }
      ]
    }
    """

    func testAVersion10FileStillOpens() throws {
        let data = try JSONDecoder.coffee.decode(
            CoffeeData.self, from: Data(v10File.utf8))

        XCTAssertEqual(data.liveBeans.count, 1)
        XCTAssertEqual(data.liveShots.count, 1)
        XCTAssertEqual(data.purchases.count, 0, "1.0 had no purchases, and that is fine")
        XCTAssertEqual(data.liveBeans.first?.name, "Kenya Gatomboya")

        let shot = try XCTUnwrap(data.liveShots.first)
        XCTAssertEqual(shot.method, .espresso, "a shot with no method recorded is espresso")
        XCTAssertEqual(shot.yieldGrams, 37)
        XCTAssertEqual(shot.waterGrams, 0, "a field 1.0 never wrote comes back as nothing")
        XCTAssertEqual(shot.ratio ?? 0, 37.0 / 18.0, accuracy: 0.001)
        XCTAssertEqual(data.gramsLeft(for: try XCTUnwrap(data.liveBeans.first)), 232)
    }

    /// Re-saving an old file must not quietly lose what it held.
    func testAnOldFileSurvivesBeingSavedAgain() throws {
        let first = try JSONDecoder.coffee.decode(
            CoffeeData.self, from: Data(v10File.utf8))
        let round = try JSONDecoder.coffee.decode(
            CoffeeData.self, from: JSONEncoder.coffee.encode(first))
        XCTAssertEqual(first.liveBeans.count, round.liveBeans.count)
        XCTAssertEqual(first.liveShots.first?.id, round.liveShots.first?.id)
        XCTAssertEqual(first.liveShots.first?.yieldGrams, round.liveShots.first?.yieldGrams)
    }

    /// A cup poured by 1.0 has no purchase count and must still be restorable.
    func testAVersion10CupStillOpens() throws {
        let old = """
        {"beanCount": 4, "filename": "cup-1.json", "id": "22222222-2222-2222-2222-222222222222",
         "kind": "daily", "name": "", "pouredAt": "2026-09-17T06:00:00Z", "shotCount": 9,
         "tested": true, "testedNote": "Opened and counted."}
        """
        let cup = try JSONDecoder.coffee.decode(Cup.self, from: Data(old.utf8))
        XCTAssertEqual(cup.beanCount, 4)
        XCTAssertEqual(cup.shotCount, 9)
        XCTAssertEqual(cup.purchaseCount, 0)
        XCTAssertTrue(cup.tested)
    }

    func testGarbageIsRejectedRatherThanGuessedAt() {
        XCTAssertThrowsError(try JSONDecoder.coffee.decode(
            CoffeeData.self, from: Data("not json".utf8)))
    }
}

final class CupPurchaseTests: XCTestCase {

    func testACupCountsPurchasesAndProvesThatCountToo() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("cup-buy-\(UUID().uuidString)")
        let cupboard = CupCupboard(folder: folder)
        var data = CoffeeData(beans: [Bean()], shots: [Shot()])
        data.purchases = [Purchase(what: "Niche"), Purchase(what: "Scale")]

        let cup = try XCTUnwrap(cupboard.pour(data, kind: .daily))
        XCTAssertEqual(cup.purchaseCount, 2)
        XCTAssertTrue(cup.tested)
        XCTAssertTrue(cup.contentsLine.contains("2 things"))
    }

    /// Losing every purchase must trip the same guard that losing bags does.
    func testACupThatLostThePurchasesIsRefused() {
        let shelf = CupShelf(cups: [Cup(beanCount: 4, shotCount: 40,
                                        purchaseCount: 6, tested: true)])
        let lost = Cup(beanCount: 4, shotCount: 40, purchaseCount: 0)
        XCTAssertFalse(CupPolicy.mayPour(lost, shelf: shelf))
        XCTAssertNotNil(CupPolicy.refusal(lost, shelf: shelf))
    }
}

/// The timer's own rules, checked across every method at once — so adding an
/// eighth way of making coffee cannot quietly leave it without a stopwatch.
final class BrewTimerRuleTests: XCTestCase {

    func testEverythingButColdBrewIsWorthTiming() {
        for method in BrewMethod.allCases {
            XCTAssertEqual(method.worthTiming, method != .coldBrew,
                           "\(method.rawValue)")
        }
    }

    /// A bloom is timed separately only where there is a bloom to time.
    func testOnlyThePouredMethodsHaveABloom() {
        XCTAssertTrue(BrewMethod.v60.hasBloom)
        XCTAssertTrue(BrewMethod.filter.hasBloom)
        for method in BrewMethod.allCases where method != .v60 && method != .filter {
            XCTAssertFalse(method.hasBloom, "\(method.rawValue)")
        }
    }

    /// Stopping the clock writes minutes only for the methods that steep.
    func testOnlyTheSteepedMethodsAreCountedInMinutes() {
        XCTAssertTrue(BrewMethod.aeropress.steepsInMinutes)
        XCTAssertTrue(BrewMethod.frenchPress.steepsInMinutes)
        XCTAssertFalse(BrewMethod.coldBrew.steepsInMinutes,
                       "cold brew steeps in hours, and nobody times it")
        XCTAssertFalse(BrewMethod.espresso.steepsInMinutes)
    }

    /// Every method the timer offers itself on must have somewhere VISIBLE for
    /// the stopped clock to land, or the time you just measured vanishes.
    ///
    /// For most methods that is the Total time dial. An AeroPress and a French
    /// press have no total-time dial on purpose — their brew IS the steep, and
    /// a second dial saying nearly the same thing would be clutter — so for
    /// those the clock lands in Steep, in minutes. Either is fine; neither is
    /// not. This first ran red and caught exactly that.
    func testEveryTimedMethodHasSomewhereForTheClockToLand() {
        for method in BrewMethod.allCases where method.worthTiming {
            let landsInTotalTime = method.fields.contains(.seconds)
            let landsInTheSteep = method.steepsInMinutes && method.fields.contains(.steepMinutes)
            XCTAssertTrue(landsInTotalTime || landsInTheSteep,
                          "\(method.rawValue) is timed but the time has nowhere to go")
        }
    }
}
