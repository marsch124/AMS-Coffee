import XCTest
@testable import AMSCoffee

final class CupSafetyTests: XCTestCase {

    /// Rule 2 — the one that lost real data in another app. A cup holding
    /// less than the last one must never be written over it.
    func testAShrinkingCupIsRefused() {
        let shelf = CupShelf(cups: [Cup(beanCount: 4, shotCount: 40, tested: true)])
        let emptyish = Cup(beanCount: 0, shotCount: 0)
        XCTAssertFalse(CupPolicy.mayPour(emptyish, shelf: shelf))
        XCTAssertNotNil(CupPolicy.refusal(emptyish, shelf: shelf))
    }

    func testAGrowingCupIsAllowed() {
        let shelf = CupShelf(cups: [Cup(beanCount: 4, shotCount: 40, tested: true)])
        XCTAssertTrue(CupPolicy.mayPour(Cup(beanCount: 4, shotCount: 41), shelf: shelf))
    }

    func testTheFirstCupIsAlwaysAllowed() {
        XCTAssertTrue(CupPolicy.mayPour(Cup(), shelf: CupShelf()))
    }

    func testPruningNeverTakesAKeepsakeOrTheNewest() {
        var shelf = CupShelf()
        for i in 0..<15 {
            shelf.cups.append(Cup(kind: .quick,
                                  pouredAt: Date().addingTimeInterval(Double(i)),
                                  beanCount: 1, shotCount: i, tested: true))
        }
        shelf.cups.append(Cup(kind: .keepsake, name: "Mine", tested: true))
        let doomed = CupPolicy.prunable(shelf)
        XCTAssertEqual(doomed.count, 5, "10 quick cups are kept")
        XCTAssertFalse(doomed.contains { $0.kind == .keepsake })
        XCTAssertFalse(doomed.contains { $0.id == shelf.newest(of: .quick)?.id })
    }

    /// Rule 1 — a cup counts as tested only after it is read back and counted.
    func testAPouredCupProvesItself() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("cup-test-\(UUID().uuidString)")
        let cupboard = CupCupboard(folder: folder)
        var data = CoffeeData()
        data.beans = [Bean(roaster: "Koppi", name: "Kenya")]
        data.shots = [Shot(), Shot()]

        let cup = try XCTUnwrap(cupboard.pour(data, kind: .daily))
        XCTAssertTrue(cup.tested)
        XCTAssertEqual(cup.beanCount, 1)
        XCTAssertEqual(cup.shotCount, 2)
        XCTAssertEqual(cupboard.read(cup)?.liveShots.count, 2)
    }

    func testACupWithBrokenContentsFailsItsTest() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("cup-test-\(UUID().uuidString)")
        let cupboard = CupCupboard(folder: folder)
        let cup = try XCTUnwrap(cupboard.pour(CoffeeData(), kind: .keepsake, name: "x"))
        try "not json at all".data(using: .utf8)!.write(to: cupboard.url(for: cup))
        XCTAssertFalse(cupboard.test(cup).passed)
    }
}

final class SyncMergeTests: XCTestCase {

    func testTheNewerChangeWins() {
        let id = UUID()
        var mine = Bean(id: id, name: "old")
        mine.modifiedAt = Date(timeIntervalSince1970: 100)
        var theirs = Bean(id: id, name: "new")
        theirs.modifiedAt = Date(timeIntervalSince1970: 200)

        let merged = CoffeeData.merged(CoffeeData(beans: [mine]), CoffeeData(beans: [theirs]))
        XCTAssertEqual(merged.beans.count, 1)
        XCTAssertEqual(merged.beans.first?.name, "new")
    }

    /// A bag rinsed on the phone must not come back from the Mac.
    func testARinseTravels() {
        let id = UUID()
        var live = Bean(id: id, name: "Kenya")
        live.modifiedAt = Date(timeIntervalSince1970: 100)
        var rinsed = live
        rinsed.rinsedAt = Date(timeIntervalSince1970: 200)
        rinsed.modifiedAt = Date(timeIntervalSince1970: 200)

        let merged = CoffeeData.merged(CoffeeData(beans: [live]), CoffeeData(beans: [rinsed]))
        XCTAssertEqual(merged.liveBeans.count, 0)
        XCTAssertEqual(merged.beans.count, 1, "the tombstone is kept, not dropped")
    }

    func testNeitherSideLosesItsOwnRecords() {
        let merged = CoffeeData.merged(CoffeeData(beans: [Bean(name: "a")]),
                                       CoffeeData(beans: [Bean(name: "b")]))
        XCTAssertEqual(merged.beans.count, 2)
    }
}

final class CoffeeMathTests: XCTestCase {

    func testRatioAndFlow() {
        var shot = Shot()
        shot.doseGrams = 18
        shot.yieldGrams = 36
        shot.seconds = 30
        XCTAssertEqual(shot.ratio ?? 0, 2, accuracy: 0.001)
        XCTAssertEqual(shot.flowGramsPerSecond ?? 0, 1.2, accuracy: 0.001)
        XCTAssertEqual(shot.ratioText, "1 : 2.0")
    }

    func testGramsLeftCountsDownAsYouPullShots() {
        let bean = Bean(bagWeightGrams: 250)
        var data = CoffeeData(beans: [bean])
        data.shots = [Shot(beanID: bean.id, doseGrams: 18),
                      Shot(beanID: bean.id, doseGrams: 18)]
        XCTAssertEqual(data.gramsLeft(for: bean), 214, accuracy: 0.001)
    }

    func testARinsedShotStopsCountingAgainstTheBag() {
        let bean = Bean(bagWeightGrams: 250)
        var used = Shot(beanID: bean.id, doseGrams: 18)
        used.rinsedAt = Date()
        let data = CoffeeData(beans: [bean], shots: [used])
        XCTAssertEqual(data.gramsLeft(for: bean), 250, accuracy: 0.001)
    }
}

final class CoachTests: XCTestCase {

    func testSourAndFastMeansFiner() {
        var shot = Shot()
        shot.seconds = 18
        shot.sourBitter = -0.6
        shot.light = .red
        XCTAssertEqual(Coach.advise(for: shot).headline, "Grind finer")
    }

    func testBitterAndSlowMeansCoarser() {
        var shot = Shot()
        shot.seconds = 40
        shot.sourBitter = 0.6
        shot.light = .amber
        XCTAssertEqual(Coach.advise(for: shot).headline, "Grind coarser")
    }

    func testGreenMeansLeaveItAlone() {
        var shot = Shot()
        shot.light = .green
        shot.sourBitter = -0.9      // even a wild slider cannot override a green
        XCTAssertEqual(Coach.advise(for: shot).headline, "Keep it exactly here")
    }

    func testAShortSourShotIsToldToRunLonger() {
        var shot = Shot()
        shot.seconds = 28
        shot.doseGrams = 18
        shot.yieldGrams = 27          // 1 : 1.5
        shot.sourBitter = -0.5
        XCTAssertEqual(Coach.advise(for: shot).headline, "Let it run longer")
    }
}

final class VersionHistoryTests: XCTestCase {

    /// The version on screen and the newest entry in the history are one thing.
    func testTheHistoryMatchesTheAppVersion() {
        XCTAssertEqual(Guide.current.version, Guide.appVersion)
        XCTAssertFalse(Guide.current.lines.isEmpty)
    }

    func testEveryReleaseIsDescribed() {
        for release in Guide.releases {
            XCTAssertFalse(release.headline.isEmpty)
            XCTAssertFalse(release.date.isEmpty)
        }
    }
}
