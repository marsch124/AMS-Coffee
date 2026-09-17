import XCTest
@testable import AMSCoffee

/// Photos are files beside the data, not inside it. The rule that makes that
/// safe is the one worth pinning down: a photo is deleted only when NOTHING
/// refers to it — not a bag, not the Sink, and not a cup on the shelf.
final class PhotoStoreTests: XCTestCase {

    private func freshStore() -> (PhotoStore, URL) {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("photos-\(UUID().uuidString)")
        return (PhotoStore(folder: folder), folder)
    }

    /// A tiny but real JPEG, so the downscaler has something to chew on.
    private func jpeg(_ side: Int = 40) -> Data {
        let size = CGSize(width: side, height: side)
        let space = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
                            bytesPerRow: 0, space: space,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        ctx.setFillColor(CGColor(red: 0.8, green: 0.5, blue: 0.3, alpha: 1))
        ctx.fill(CGRect(origin: .zero, size: size))
        let image = ctx.makeImage()!
        let out = NSMutableData()
        let dest = CGImageDestinationCreateWithData(out, "public.jpeg" as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
        return out as Data
    }

    func testAPhotoCanBeSavedAndReadBack() throws {
        let (store, _) = freshStore()
        let id = try XCTUnwrap(store.save(jpeg()))
        XCTAssertTrue(store.exists(id))
        XCTAssertNotNil(store.load(id))
        XCTAssertEqual(store.allIDs, [id])
    }

    func testABigPictureIsMadeSmall() throws {
        let big = jpeg(3000)
        let small = try XCTUnwrap(PhotoStore.downscaled(big, maxPixel: 200))
        XCTAssertLessThan(small.count, big.count, "a bag photo should not be a print")
        let source = CGImageSourceCreateWithData(small as CFData, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as! [CFString: Any]
        XCTAssertLessThanOrEqual(props[kCGImagePropertyPixelWidth] as! Int, 200)
    }

    func testOnlyPhotosNothingRefersToArePurged() throws {
        let (store, _) = freshStore()
        let kept = try XCTUnwrap(store.save(jpeg()))
        let orphan = try XCTUnwrap(store.save(jpeg()))

        let removed = store.purgeOrphans(keeping: [kept])
        XCTAssertEqual(removed, 1)
        XCTAssertTrue(store.exists(kept), "a photo something refers to must survive")
        XCTAssertFalse(store.exists(orphan))
    }

    /// The promise: pour back a cup from a month ago and its pictures are there.
    func testAPhotoOnlyACupRemembersIsNotPurged() throws {
        let (store, _) = freshStore()
        let inACupOnly = try XCTUnwrap(store.save(jpeg()))

        // The live data has forgotten it; a cup has not.
        var cupData = CoffeeData()
        var bean = Bean(name: "Kenya")
        bean.photoID = inACupOnly
        cupData.beans = [bean]

        let referenced = CoffeeData().photoIDs.union(cupData.photoIDs)
        XCTAssertEqual(store.purgeOrphans(keeping: referenced), 0)
        XCTAssertTrue(store.exists(inACupOnly),
                      "a cup that remembers a photo must keep it alive")
    }

    func testPhotoIDsCoversBagsKitAndTheSink() {
        var data = CoffeeData()
        var live = Bean(name: "live"); live.photoID = "a"
        var rinsed = Bean(name: "rinsed"); rinsed.photoID = "b"; rinsed.rinsedAt = Date()
        var thing = Purchase(what: "Niche"); thing.photoID = "c"
        data.beans = [live, rinsed]
        data.purchases = [thing]
        XCTAssertEqual(data.photoIDs, ["a", "b", "c"],
                       "the Sink can give a bag back, so its photo still counts")
    }

    /// A cup that remembers a photo whose file has gone is not a whole cup.
    func testACupMissingAPhotoFailsItsTest() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("cupphoto-\(UUID().uuidString)")
        let photos = PhotoStore(folder: root.appendingPathComponent("Photos"))
        let cupboard = CupCupboard(folder: root.appendingPathComponent("Cups"),
                                   photoFolder: root.appendingPathComponent("Photos"))
        let id = try XCTUnwrap(photos.save(jpeg()))
        var bean = Bean(name: "Kenya"); bean.photoID = id
        let data = CoffeeData(beans: [bean])

        let cup = try XCTUnwrap(cupboard.pour(data, kind: .keepsake, name: "with photo"))
        XCTAssertTrue(cup.tested)
        XCTAssertEqual(cup.photoCount, 1)

        // Now lose the picture behind its back.
        try FileManager.default.removeItem(at: photos.url(for: id))
        let proof = cupboard.test(cup)
        XCTAssertFalse(proof.passed)
        XCTAssertTrue(proof.note.contains("photo"), "and it should say so plainly")
    }
}
