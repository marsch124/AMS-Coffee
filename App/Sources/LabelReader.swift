import Foundation
import ImageIO
import Vision

// MARK: - Reading a bag's label (2.6)
//
// The photo is read on the phone itself — Apple's text recognition, no
// internet, nothing sent anywhere. What comes back is only ever a
// suggestion: it is shown, tapped in one at a time, and never lands on a
// field that already has something in it.

/// One line of text found on the picture, and how tall it stood.
struct LabelLine: Equatable {
    var text: String
    var height: Double = 1
}

struct LabelSuggestion: Equatable {
    var roaster: String?
    var origin: String?
    var roastDate: Date?

    var isEmpty: Bool { roaster == nil && origin == nil && roastDate == nil }

    /// Only what would fill an EMPTY field. Something typed is never offered
    /// a replacement — that is the whole promise.
    func offered(for bean: Bean, hasRoastDate: Bool) -> LabelSuggestion {
        func blank(_ s: String) -> Bool { s.trimmingCharacters(in: .whitespaces).isEmpty }
        return LabelSuggestion(roaster: blank(bean.roaster) ? roaster : nil,
                               origin: blank(bean.origin) ? origin : nil,
                               roastDate: hasRoastDate ? nil : roastDate)
    }
}

enum LabelReader {

    // MARK: The words → suggestions (pure, so every rule is tested)

    static func suggest(fromText lines: [String], now: Date = Date()) -> LabelSuggestion {
        suggest(from: lines.map { LabelLine(text: $0) }, now: now)
    }

    static func suggest(from lines: [LabelLine], now: Date = Date()) -> LabelSuggestion {
        let texts = lines
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return LabelSuggestion(roaster: roaster(in: texts),
                               origin: origin(in: texts),
                               roastDate: roastDate(in: texts, now: now))
    }

    private static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// A roaster is only suggested when the line says it is one. Guessing
    /// from the biggest letters would mostly pick the bean's name.
    private static let roasterWords = ["roaster", "roastery", "roasting co", "rosteri",
                                       "rosterei", "coffee co", "coffee company",
                                       "torrefazione", "brulerie"]

    static func roaster(in lines: [String]) -> String? {
        for line in lines {
            let f = fold(line)
            guard roasterWords.contains(where: { f.contains($0) }) else { continue }
            let hasLower = line.contains { $0.isLowercase }
            return hasLower ? line : line.capitalized
        }
        return nil
    }

    /// Coffee countries, each with the spellings a label might use —
    /// English, Swedish and German, accents folded away.
    private static let countries: [(String, [String])] = [
        ("Ethiopia", ["ethiopia", "etiopien", "athiopien", "ethiopie"]),
        ("Kenya", ["kenya", "kenia"]),
        ("Colombia", ["colombia", "colombie", "kolumbien", "kolombia"]),
        ("Brazil", ["brazil", "brasil", "brasilien", "bresil"]),
        ("Costa Rica", ["costa rica"]),
        ("Guatemala", ["guatemala"]),
        ("Honduras", ["honduras"]),
        ("El Salvador", ["el salvador"]),
        ("Nicaragua", ["nicaragua"]),
        ("Panama", ["panama"]),
        ("Peru", ["peru"]),
        ("Bolivia", ["bolivia", "bolivien"]),
        ("Ecuador", ["ecuador"]),
        ("Mexico", ["mexico", "mexiko"]),
        ("Rwanda", ["rwanda", "ruanda"]),
        ("Burundi", ["burundi"]),
        ("Uganda", ["uganda"]),
        ("Tanzania", ["tanzania", "tansania"]),
        ("DR Congo", ["congo", "kongo"]),
        ("Yemen", ["yemen", "jemen"]),
        ("India", ["india", "indien"]),
        ("Indonesia", ["indonesia", "indonesien", "sumatra", "sulawesi", "java"]),
        ("Papua New Guinea", ["papua new guinea", "papua nya guinea", "papua-neuguinea"]),
        ("Vietnam", ["vietnam"]),
        ("China", ["china", "kina", "yunnan"]),
        ("Myanmar", ["myanmar"]),
        ("Thailand", ["thailand"]),
        ("Laos", ["laos"]),
        ("Hawaii", ["hawaii", "kona"]),
        ("Jamaica", ["jamaica"]),
        ("Haiti", ["haiti"]),
        ("Dominican Republic", ["dominican republic", "dominikanska republiken"]),
        ("Cuba", ["cuba", "kuba"]),
        ("Malawi", ["malawi"]),
        ("Zambia", ["zambia", "sambia"]),
        ("Zimbabwe", ["zimbabwe", "simbabwe"]),
        ("Timor-Leste", ["timor"]),
        ("Taiwan", ["taiwan"]),
        ("Nepal", ["nepal"]),
        ("Cameroon", ["cameroon", "kamerun"]),
    ]

    static func origin(in lines: [String]) -> String? {
        for line in lines {
            let f = " " + fold(line).map { $0.isLetter ? $0 : " " }.reduce("") { $0 + String($1) } + " "
            for (name, spellings) in countries {
                for s in spellings where f.contains(" \(s) ") {
                    return name
                }
            }
        }
        return nil
    }

    // MARK: Roast date

    private static let notARoast = ["best", "bast", "use by", "exp", "bbe", "mhd", "haltbar"]

    /// Prefers a line that says roasted (rostad, geröstet…). A best-before
    /// line is never read as a roast date. A date in the future, or more
    /// than a year back, is not believed.
    static func roastDate(in lines: [String], now: Date) -> Date? {
        let earliest = Calendar.current.date(byAdding: .day, value: -366, to: now) ?? now
        let latest = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        var plain: Date?
        for line in lines {
            let f = fold(line)
            if notARoast.contains(where: { f.contains($0) }) { continue }
            let found = dates(in: f).filter { $0 >= earliest && $0 <= latest }
            guard let date = found.first else { continue }
            if f.contains("roast") || f.contains("rost") { return date }
            if plain == nil { plain = date }
        }
        return plain
    }

    private static let months: [String: Int] = [
        "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "maj": 5, "mai": 5,
        "jun": 6, "jul": 7, "aug": 8, "sep": 9, "oct": 10, "okt": 10,
        "nov": 11, "dec": 12, "dez": 12,
    ]

    private static func month(_ word: String) -> Int? {
        guard word.count >= 3 else { return nil }
        return months[String(word.prefix(3))]
    }

    /// Every date written on a (folded) line, in the shapes labels use.
    /// Day before month, as in Sweden, when the numbers alone are ambiguous.
    static func dates(in line: String) -> [Date] {
        var out: [Date] = []
        for m in groups(#"\b(\d{4})[-./](\d{1,2})[-./](\d{1,2})\b"#, line) {
            if let d = make(Int(m[0]), Int(m[1]), Int(m[2])) { out.append(d) }
        }
        for m in groups(#"\b(\d{1,2})[-./](\d{1,2})[-./](\d{2,4})\b"#, line) {
            if let d = make(year(m[2]), Int(m[1]), Int(m[0])) { out.append(d) }
        }
        for m in groups(#"\b(\d{1,2})(?:st|nd|rd|th)?\.?\s+([a-z]{3,9})\.?,?\s+(\d{4})\b"#, line) {
            if let d = make(Int(m[2]), month(m[1]), Int(m[0])) { out.append(d) }
        }
        for m in groups(#"\b([a-z]{3,9})\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})\b"#, line) {
            if let d = make(Int(m[2]), month(m[0]), Int(m[1])) { out.append(d) }
        }
        return out
    }

    private static func year(_ s: String) -> Int? {
        guard let y = Int(s) else { return nil }
        return y < 100 ? 2000 + y : y
    }

    private static func make(_ y: Int?, _ m: Int?, _ d: Int?) -> Date? {
        guard let y, let m, let d, (1...12).contains(m), (1...31).contains(d) else { return nil }
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = 12
        guard let date = Calendar.current.date(from: c),
              Calendar.current.component(.day, from: date) == d else { return nil }
        return date
    }

    private static func groups(_ pattern: String, _ text: String) -> [[String]] {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        return re.matches(in: text, range: NSRange(location: 0, length: ns.length)).map { m in
            (1..<m.numberOfRanges).map { i in
                let r = m.range(at: i)
                return r.location == NSNotFound ? "" : ns.substring(with: r)
            }
        }
    }

    // MARK: The picture → words (on the device)

    static func read(_ image: Data) async -> [LabelLine] {
        await withCheckedContinuation { done in
            DispatchQueue.global(qos: .userInitiated).async {
                done.resume(returning: readNow(image))
            }
        }
    }

    private static func readNow(_ image: Data) -> [LabelLine] {
        guard let source = CGImageSourceCreateWithData(image as CFData, nil),
              let picture = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return [] }
        // A phone photo is stored sideways and says which way up it goes.
        var orientation = CGImagePropertyOrientation.up
        if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let raw = props[kCGImagePropertyOrientation] as? UInt32,
           let o = CGImagePropertyOrientation(rawValue: raw) {
            orientation = o
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        let handler = VNImageRequestHandler(cgImage: picture, orientation: orientation)
        do { try handler.perform([request]) } catch { return [] }
        return (request.results ?? []).compactMap { seen in
            guard let best = seen.topCandidates(1).first else { return nil }
            return LabelLine(text: best.string, height: Double(seen.boundingBox.height))
        }
    }

    /// Under a screen test, the label's words come from the launch
    /// environment — a test cannot hold a bag up to the camera.
    static var testLines: [String]? {
        guard ProcessInfo.processInfo.arguments.contains("-uiTesting"),
              let raw = ProcessInfo.processInfo.environment["LABEL_LINES"] else { return nil }
        return raw.components(separatedBy: "|")
    }
}
