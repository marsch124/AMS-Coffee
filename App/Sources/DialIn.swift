import SwiftUI

// MARK: - The dial-in chart (2.5)

/// One line on the chart. Each reads one number off a brew.
enum DialMeasure: String, CaseIterable, Identifiable {
    case grind, dose, time, taste

    var id: String { rawValue }

    var label: String {
        switch self {
        case .grind: return "Grind"
        case .dose:  return "Dose"
        case .time:  return "Time"
        case .taste: return "Taste"
        }
    }

    var tint: Color {
        switch self {
        case .grind: return Candy.blueberry
        case .dose:  return Candy.grape
        case .time:  return Candy.sky
        case .taste: return Candy.bubblegum
        }
    }

    func value(of shot: Shot) -> Double {
        switch self {
        case .grind: return shot.grind
        case .dose:  return shot.doseGrams
        case .time:  return shot.totalSeconds
        case .taste: return shot.sourBitter
        }
    }
}

/// How a bag's numbers moved, in words. Pure, so every sentence is tested.
enum DialIn {

    /// One bag, one method, oldest first — the order you dialled it in.
    static func brews(in data: CoffeeData, beanID: UUID, method: BrewMethod) -> [Shot] {
        data.liveShots
            .filter { $0.beanID == beanID && $0.method == method }
            .sorted { $0.date < $1.date }
    }

    /// The chart opens on whatever you made last with this bag.
    static func defaultMethod(in data: CoffeeData, beanID: UUID) -> BrewMethod? {
        data.liveShots
            .filter { $0.beanID == beanID }
            .max { $0.date < $1.date }?
            .method
    }

    /// Every method has a grind, a dose, a clock of some kind and a taste.
    static func measures(for method: BrewMethod) -> [DialMeasure] {
        DialMeasure.allCases
    }

    /// "15 → 13.5 · finer". Nil until there are two brews to compare.
    static func heading(_ measure: DialMeasure, _ shots: [Shot], method: BrewMethod) -> String? {
        guard shots.count >= 2, let first = shots.first, let last = shots.last else { return nil }
        let a = measure.value(of: first)
        let b = measure.value(of: last)
        let same = abs(a - b) < 0.001

        switch measure {
        case .grind:
            if same { return "\(Coach.trim(a)) all along" }
            return "\(Coach.trim(a)) → \(Coach.trim(b)) · \(b < a ? "finer" : "coarser")"
        case .dose:
            if same { return "\(Coach.trim(a)) g all along" }
            return "\(Coach.trim(a)) → \(Coach.trim(b)) g"
        case .time:
            let moved = same ? "\(timeText(a, method)) all along"
                             : "\(timeText(a, method)) → \(timeText(b, method))"
            return "\(moved) · \(standing(b, method))"
        case .taste:
            let from = tasteWord(a)
            let to = tasteWord(b)
            if from == to { return "\(to) all along" }
            return "\(from) → \(to)"
        }
    }

    /// The taste slider runs from -1 (sour) to +1 (bitter).
    static func tasteWord(_ v: Double) -> String {
        if abs(v) < 0.15 { return "balanced" }
        let side = v < 0 ? "sour" : "bitter"
        return abs(v) < 0.45 ? "a little \(side)" : side
    }

    /// "3 brews · 1 green · the last one green".
    static func summary(_ shots: [Shot]) -> String {
        let greens = shots.filter { $0.light == .green }.count
        let last = shots.last?.light.rawValue ?? "amber"
        return "\(shots.count) brews · \(greens) green · the last one \(last)"
    }

    /// The same units the coach uses for this method's window.
    static func timeText(_ seconds: Double, _ method: BrewMethod) -> String {
        let low = method.idealSeconds.lowerBound
        if low >= 3600 { return "\(Coach.trim((seconds / 3600 * 2).rounded() / 2)) h" }
        if low >= 120 { return "\(Coach.trim((seconds / 60 * 2).rounded() / 2)) min" }
        return "\(Coach.trim(seconds.rounded())) s"
    }

    /// Where the latest brew sits against the coach's own window.
    private static func standing(_ seconds: Double, _ method: BrewMethod) -> String {
        let w = method.idealSeconds
        if seconds < w.lowerBound { return "short of \(Coach.window(method))" }
        if seconds > w.upperBound { return "past \(Coach.window(method))" }
        return "in the window"
    }
}

// MARK: - Search across every brew (2.5)

/// One search over every brew: the bag, its roaster and origin, the method,
/// the notes — and (2.6) its light and when it was made. Every word typed
/// must turn up somewhere; case and accents never matter, so "cafe" finds
/// "Café", and "kenya green october" finds exactly that.
enum BrewSearch {

    static func fold(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    static func words(_ query: String) -> [String] {
        var q = " " + fold(query) + " "
        // "medium dark" typed as two words is the one level, not two.
        for (two, one) in [("medium dark", "medium-dark"), ("medium light", "medium-light")] {
            q = q.replacingOccurrences(of: " \(two) ", with: " \(one) ")
        }
        return q.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    static func matches(_ shot: Shot, bean: Bean?, query: String, now: Date = Date()) -> Bool {
        let wanted = words(query)
        if wanted.isEmpty { return true }
        var parts = [shot.method.title, shot.note, shot.basket]
        if let bean {
            parts += [bean.displayName, bean.roaster, bean.name, bean.origin,
                      bean.process, bean.notes]
        }
        parts += lightWords(shot.light)
        parts += dateWords(shot.date, now: now)
        let haystack = fold(parts.joined(separator: " "))
        let roast = roastWords(bean?.roastLevel ?? "")
        return wanted.allSatisfy { haystack.contains($0) || roast.contains($0) }
    }

    // MARK: The bag's roast (2.9)
    //
    // The roast is matched as a whole word, never as part of one: "dark"
    // finds a dark bag, not a medium-dark one. Medium-dark is its own step
    // on the scale — the bag says so — and typing "medium dark" finds it.

    private static let levelWords: [String: [String]] = [
        "Light": ["light", "ljus", "ljusrost", "ljusrostat", "ljusrostad",
                  "hell", "helle", "heller", "hellen"],
        "Medium-light": ["medium-light", "mellanljus"],
        "Medium": ["medium", "mellan", "mellanrost", "mellanrostat", "mellanrostad",
                   "mittel", "mittlere", "mittlerer", "mittleren"],
        "Medium-dark": ["medium-dark", "mellanmork"],
        "Dark": ["dark", "mork", "morkrost", "morkrostat", "morkrostad",
                 "dunkel", "dunkle", "dunkler", "dunklen"],
    ]

    /// Any roast filled in also answers to the word roast itself.
    private static let roastingWords: Set<String> = ["roast", "rost", "rostung", "rostning",
                                                     "rostgrad"]

    /// Every whole word a bag's roast answers to, in English, Swedish and
    /// German — read the same way the label reader reads a label, so
    /// "Ljusrost" typed by hand answers to "light" too.
    static func roastWords(_ roast: String) -> Set<String> {
        let typed = fold(roast).map { $0.isLetter || $0 == "-" ? $0 : " " }
        let words = Set(String(typed).split(separator: " ").map(String.init))
        guard !words.isEmpty else { return [] }
        // A known level answers to its own words only — "medium dark"
        // typed with a space must not answer to "dark". Anything else
        // ("Omni") answers to what was typed.
        if let level = LabelReader.roastLevel(in: [roast]), let known = levelWords[level] {
            return roastingWords.union(known)
        }
        return roastingWords.union(words)
    }

    /// The colour and the word the light picker shows.
    static func lightWords(_ light: TrafficLight) -> [String] {
        switch light {
        case .green: return ["green", "lovely"]
        case .amber: return ["amber", "drinkable"]
        case .red:   return ["red", "tipped out"]
        }
    }

    /// "October Oct 2026", plus today or yesterday when it is.
    static func dateWords(_ date: Date, now: Date) -> [String] {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "MMMM MMM yyyy"
        var words = [f.string(from: date)]
        let cal = Calendar.current
        if cal.isDate(date, inSameDayAs: now) { words.append("today") }
        if let yesterday = cal.date(byAdding: .day, value: -1, to: now),
           cal.isDate(date, inSameDayAs: yesterday) { words.append("yesterday") }
        return words
    }

    /// Newest first, the Sink left out, and the method filter still honoured.
    static func results(in data: CoffeeData, query: String, method: BrewMethod?) -> [Shot] {
        data.liveShots
            .filter { method == nil || $0.method == method }
            .filter { matches($0, bean: data.bean($0.beanID), query: query) }
            .sorted { $0.date > $1.date }
    }
}

// MARK: - The card on a bag

/// "How you dialled it in" — one small line per number, oldest brew on the
/// left, the newest on the right, each dot coloured by its light.
struct DialInCard: View {
    @EnvironmentObject private var store: CoffeeStore
    let beanID: UUID
    @State private var picked: BrewMethod?
    @State private var again: Shot?

    private var methods: [BrewMethod] { store.data.methodsUsed(beanID: beanID) }
    private var method: BrewMethod? {
        picked ?? DialIn.defaultMethod(in: store.data, beanID: beanID)
    }

    var body: some View {
        if let method {
            let brews = DialIn.brews(in: store.data, beanID: beanID, method: method)
            WobbleCard(tint: Candy.sky) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("How you dialled it in")
                        .font(.system(size: 19, weight: .black, design: .rounded))

                    if methods.count > 1 {
                        FlowRow(spacing: 8) {
                            ForEach(methods) { m in
                                Button { picked = m } label: {
                                    Chip(text: m.title, tint: m == method ? Candy.ink : m.tint) {
                                        MethodMark(method: m, size: 20)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("dialin-method-\(m.rawValue)")
                            }
                        }
                    }

                    if brews.count < 2 {
                        Text("One \(method.title.lowercased()) so far. Make another with this bag and the line starts here.")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                            .accessibilityIdentifier("bag-dialin-waiting")
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(DialIn.summary(brews))
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(Candy.inkSoft)
                            ForEach(DialIn.measures(for: method)) { measure in
                                DialLine(measure: measure, brews: brews, method: method)
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("bag-dialin")
                    }

                    // Same again from here (2.6): only once a brew of this
                    // method on this bag has been green.
                    if let green = store.data.bestGreen(beanID: beanID, method: method) {
                        Button { again = Shot.again(from: green) } label: {
                            HStack(spacing: 10) {
                                MethodMark(method: method, size: 24)
                                Text("Same again from here")
                            }
                        }
                        .buttonStyle(SquashyButton(tint: Candy.mint))
                        .accessibilityIdentifier("dialin-same-again")
                        Text("Your green \(method.title.lowercased()) from \(KitCare.shortDate(green.date)): grind \(Coach.trim(green.grind)) · \(Coach.trim(green.doseGrams)) g · \(green.timeText)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                    }
                }
            }
            .sheet(item: $again) { ShotEditor(shot: $0) }
        }
    }
}

/// One measure: its name, where it went in words, and the line itself.
private struct DialLine: View {
    let measure: DialMeasure
    let brews: [Shot]
    let method: BrewMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(measure.label)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Candy.inkSoft)
                Spacer()
                Text(DialIn.heading(measure, brews, method: method) ?? "")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(measure.tint)
                    .multilineTextAlignment(.trailing)
            }
            Sparkline(values: brews.map { measure.value(of: $0) },
                      lights: brews.map(\.light),
                      band: band,
                      tint: measure.tint)
                .frame(height: 44)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("dialin-\(measure.rawValue)")
    }

    /// The shaded strip that means "this is where you want to be": the
    /// coach's window for time, the balanced middle for taste.
    private var band: ClosedRange<Double>? {
        switch measure {
        case .time:  return method.idealSeconds
        case .taste: return -0.15...0.15
        default:     return nil
        }
    }
}

/// A plain drawn line with a dot per brew. Every value is typed out and
/// every step kept short — CI's older compiler gives up on long expressions.
private struct Sparkline: View {
    let values: [Double]
    let lights: [TrafficLight]
    let band: ClosedRange<Double>?
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let w: Double = Double(geo.size.width)
            let h: Double = Double(geo.size.height)
            let pad: Double = 6
            let (low, high) = span
            ZStack(alignment: .topLeading) {
                if let band {
                    let top: Double = y(band.upperBound, low, high, h, pad)
                    let bottom: Double = y(band.lowerBound, low, high, h, pad)
                    Rectangle()
                        .fill(tint.opacity(0.16))
                        .frame(width: w, height: max(2, bottom - top))
                        .offset(y: top)
                }
                Path { p in
                    for i in values.indices {
                        let pt = CGPoint(x: x(i, w, pad), y: y(values[i], low, high, h, pad))
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }
                .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                ForEach(values.indices, id: \.self) { i in
                    Circle()
                        .fill(colour(lights[i]))
                        .overlay(Circle().strokeBorder(Candy.card, lineWidth: 2))
                        .frame(width: 12, height: 12)
                        .position(x: x(i, w, pad), y: y(values[i], low, high, h, pad))
                }
            }
        }
    }

    /// The range drawn: the values, stretched to include the band, so the
    /// strip is always on the chart even when every brew missed it.
    private var span: (Double, Double) {
        var low: Double = values.min() ?? 0
        var high: Double = values.max() ?? 1
        if let band {
            low = min(low, band.lowerBound)
            high = max(high, band.upperBound)
        }
        if high - low < 0.0001 {
            low -= 1
            high += 1
        }
        return (low, high)
    }

    private func x(_ i: Int, _ w: Double, _ pad: Double) -> Double {
        if values.count < 2 { return w / 2 }
        let usable: Double = w - pad * 2
        let step: Double = usable / Double(values.count - 1)
        return pad + step * Double(i)
    }

    private func y(_ v: Double, _ low: Double, _ high: Double, _ h: Double, _ pad: Double) -> Double {
        let usable: Double = h - pad * 2
        let share: Double = (v - low) / (high - low)
        return pad + usable * (1 - share)
    }

    private func colour(_ light: TrafficLight) -> Color {
        switch light {
        case .green: return Candy.mint
        case .amber: return Candy.mango
        case .red:   return Candy.bubblegum
        }
    }
}
