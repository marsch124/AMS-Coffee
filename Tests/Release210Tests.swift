import XCTest
@testable import AMSCoffee

/// 2.10 — picture mode: made-up coffee for pictures, and the tab the app opens on.
final class Release210Tests: XCTestCase {

    func testThePictureSampleIsReadableAndCountedFromNow() throws {
        let now = Date()
        let sample = try XCTUnwrap(PictureSample.data(now: now), "the sample must decode in the app's own format")
        XCTAssertEqual(sample.beans.count, 4)
        XCTAssertEqual(sample.shots.count, 10)
        XCTAssertEqual(sample.purchases.count, 2)
        XCTAssertEqual(sample.shots.filter { Calendar.current.isDate($0.date, inSameDayAs: now) }.count, 2,
                       "two brews today, at any hour")
        let words = (sample.beans.map { $0.roaster + $0.name + $0.notes }).joined()
        XCTAssertFalse(words.contains("Martin") || words.contains("Anna"), "invented names only")
    }

    func testTheStartTab() {
        XCTAssertEqual(Tab.start(from: ["AMS Coffee"]), .today)
        XCTAssertEqual(Tab.start(from: ["AMS Coffee", "-startTab", "bags"]), .bags)
        XCTAssertEqual(Tab.start(from: ["AMS Coffee", "-startTab", "shots"]), .shots)
        XCTAssertEqual(Tab.start(from: ["AMS Coffee", "-startTab", "nonsense"]), .today)
        XCTAssertEqual(Tab.start(from: ["AMS Coffee", "-startTab"]), .today)
    }
}
