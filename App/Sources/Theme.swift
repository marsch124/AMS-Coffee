import SwiftUI

// MARK: - Candy palette
//
// Bright and flat. Nothing glows, nothing hums — it just pops.

enum Candy {
    static let mango     = Color(red: 1.00, green: 0.70, blue: 0.13)
    static let apricot   = Color(red: 1.00, green: 0.55, blue: 0.20)
    static let bubblegum = Color(red: 1.00, green: 0.30, blue: 0.55)
    static let mint      = Color(red: 0.13, green: 0.82, blue: 0.62)
    static let blueberry = Color(red: 0.44, green: 0.40, blue: 1.00)
    static let sky       = Color(red: 0.20, green: 0.76, blue: 1.00)
    static let grape     = Color(red: 0.70, green: 0.40, blue: 1.00)
    static let cocoa     = Color(red: 0.28, green: 0.16, blue: 0.09)
    static let cream     = Color(red: 1.00, green: 0.97, blue: 0.90)

    static let all: [Color] = [mango, apricot, bubblegum, mint, blueberry, sky, grape]

    /// A stable colour for a thing, so a bag keeps its colour forever.
    static func forSeed(_ seed: String) -> Color {
        let hash = seed.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFFFF }
        return all[hash % all.count]
    }
}

/// The soft candy-stripe backdrop the whole app sits on.
struct CoffeeBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            (scheme == .dark ? Color(red: 0.11, green: 0.08, blue: 0.07) : Candy.cream)
            LinearGradient(colors: scheme == .dark
                           ? [Candy.grape.opacity(0.22), .clear, Candy.mango.opacity(0.14)]
                           : [Candy.mango.opacity(0.28), .clear, Candy.bubblegum.opacity(0.20)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            // A few fat blurry blobs — cheap and cheerful.
            Circle().fill(Candy.mint.opacity(scheme == .dark ? 0.18 : 0.26))
                .frame(width: 280).blur(radius: 60).offset(x: 130, y: -240)
            Circle().fill(Candy.sky.opacity(scheme == .dark ? 0.16 : 0.24))
                .frame(width: 230).blur(radius: 60).offset(x: -140, y: 300)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Flimsy, springy, squashy

/// Buttons that squash when pressed and bounce back.
struct SquashyButton: ButtonStyle {
    var tint: Color = Candy.mango

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.vertical, 18)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(tint)
                    .shadow(color: tint.opacity(0.45), radius: 0, x: 0, y: configuration.isPressed ? 2 : 6)
            )
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .rotationEffect(.degrees(configuration.isPressed ? -1.2 : 0))
            .animation(.spring(response: 0.28, dampingFraction: 0.45), value: configuration.isPressed)
    }
}

/// A chunky card that tilts a hair, so nothing looks like a spreadsheet.
struct WobbleCard<Content: View>: View {
    var tint: Color = Candy.mint
    var tilt: Double = -0.7
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(scheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(tint.opacity(0.55), lineWidth: 3)
                    )
                    .shadow(color: tint.opacity(0.30), radius: 0, x: 0, y: 5)
            )
            .rotationEffect(.degrees(tilt))
    }
}

extension View {
    /// Pops in with a bounce when it first appears.
    func poppyAppear(_ delay: Double = 0) -> some View {
        modifier(PoppyAppear(delay: delay))
    }
}

private struct PoppyAppear: ViewModifier {
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(shown ? 1 : 0.85)
            .opacity(shown ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(delay)) {
                    shown = true
                }
            }
    }
}

// MARK: - Confetti

/// Fires whenever `trigger` changes. Pure SwiftUI, no dependencies.
struct Confetti: View {
    let trigger: Int
    @State private var pieces: [Piece] = []

    struct Piece: Identifiable {
        let id = UUID()
        let x: Double
        let colour: Color
        let spin: Double
        let delay: Double
        let size: Double
        let drift: Double
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    Flake(piece: piece, height: geo.size.height, width: geo.size.width)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, new in
            guard new > 0 else { return }
            pieces = (0..<28).map { _ in
                Piece(x: Double.random(in: 0.05...0.95),
                      colour: Candy.all.randomElement() ?? Candy.mango,
                      spin: Double.random(in: -540...540),
                      delay: Double.random(in: 0...0.35),
                      size: Double.random(in: 8...16),
                      drift: Double.random(in: -60...60))
            }
            Task {
                try? await Task.sleep(nanoseconds: 2_600_000_000)
                pieces = []
            }
        }
    }

    private struct Flake: View {
        let piece: Piece
        let height: Double
        let width: Double
        @State private var fallen = false

        var body: some View {
            RoundedRectangle(cornerRadius: 3)
                .fill(piece.colour)
                .frame(width: piece.size, height: piece.size * 0.6)
                .rotationEffect(.degrees(fallen ? piece.spin : 0))
                .position(x: width * piece.x + (fallen ? piece.drift : 0),
                          y: fallen ? height + 40 : -30)
                .opacity(fallen ? 0 : 1)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.9).delay(piece.delay)) { fallen = true }
                }
        }
    }
}

// MARK: - Hand-drawn marks
//
// No stock symbol sets. Every mark in the app is drawn here, with the same
// slightly-off-true line as the app icon, and sized to be read at a glance.

/// A plus, drawn rather than borrowed.
struct PlusMark: View {
    var size: Double = 26
    var weight: Double = 5

    var body: some View {
        ZStack {
            Capsule().frame(width: size, height: weight)
            Capsule().frame(width: weight, height: size)
        }
        .rotationEffect(.degrees(-2))
        .frame(width: size, height: size)
    }
}

/// A tick with an honest wobble.
struct TickMark: View {
    var size: Double = 26
    var weight: Double = 5

    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: size * 0.16, y: size * 0.55))
            p.addLine(to: CGPoint(x: size * 0.42, y: size * 0.78))
            p.addLine(to: CGPoint(x: size * 0.86, y: size * 0.22))
        }
        .stroke(style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
        .rotationEffect(.degrees(-3))
        .frame(width: size, height: size)
    }
}

/// A cross, for closing things.
struct CrossMark: View {
    var size: Double = 22
    var weight: Double = 5

    var body: some View {
        ZStack {
            Capsule().frame(width: size, height: weight).rotationEffect(.degrees(44))
            Capsule().frame(width: size, height: weight).rotationEffect(.degrees(-44))
        }
        .frame(width: size, height: size)
    }
}

/// A minus, for the dials.
struct MinusMark: View {
    var size: Double = 26
    var weight: Double = 5

    var body: some View {
        Capsule()
            .frame(width: size, height: weight)
            .rotationEffect(.degrees(-2))
            .frame(width: size, height: size)
    }
}

/// An arrow head that points wherever it is turned.
struct ChevronMark: View {
    var size: Double = 22
    var weight: Double = 5

    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: size * 0.22, y: size * 0.34))
            p.addLine(to: CGPoint(x: size * 0.5, y: size * 0.68))
            p.addLine(to: CGPoint(x: size * 0.78, y: size * 0.34))
        }
        .stroke(style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A star you can fill, for rating a bag.
struct StarMark: View {
    var size: Double = 34
    var filled: Bool

    var body: some View {
        let path = Path { p in
            let r = size / 2
            let c = CGPoint(x: r, y: r)
            for i in 0..<10 {
                let angle = Double(i) * .pi / 5 - .pi / 2
                let radius = i.isMultiple(of: 2) ? r : r * 0.44
                let pt = CGPoint(x: c.x + cos(angle) * radius, y: c.y + sin(angle) * radius)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
        Group {
            if filled {
                path.fill()
            } else {
                path.stroke(style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            }
        }
        .rotationEffect(.degrees(-4))
        .frame(width: size, height: size)
    }
}

// MARK: - Little shared pieces

/// A fat pill used everywhere for counts and labels.
struct Chip: View {
    let text: String
    var tint: Color = Candy.blueberry
    var symbol: String?   // an emoji, never a stock glyph

    var body: some View {
        HStack(spacing: 5) {
            if let symbol { Text(symbol).font(.system(size: 17)) }
            Text(text)
        }
        .font(.system(size: 16, weight: .heavy, design: .rounded))
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .foregroundStyle(tint)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Capsule().fill(tint.opacity(0.18)))
        .overlay(Capsule().strokeBorder(tint.opacity(0.45), lineWidth: 2))
    }
}

/// Big rounded headline used at the top of every screen. Takes either an
/// emoji — fine for content, a bag or a brew method — or one of the drawn
/// marks, for the four places the tab bar names.
struct BigTitle<Mark: View>: View {
    let mark: Mark
    let text: String

    init(text: String, @ViewBuilder mark: () -> Mark) {
        self.mark = mark()
        self.text = text
    }

    var body: some View {
        HStack(spacing: 12) {
            mark
            Text(text)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Candy.cocoa)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension BigTitle where Mark == Text {
    init(emoji: String, text: String) {
        self.init(text: text) { Text(emoji).font(.system(size: 38)) }
    }
}

/// A number you can actually read with your glasses off.
struct BigNumber: View {
    let value: String
    let caption: String
    var tint: Color = Candy.mango

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(caption)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Five taps, no keyboard.
struct StarRating: View {
    @Binding var rating: Int
    var identifierPrefix = "star"

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    rating = (rating == i) ? 0 : i
                } label: {
                    StarMark(size: 38, filled: i <= rating)
                        .foregroundStyle(i <= rating ? Candy.mango : Color.secondary.opacity(0.35))
                        .scaleEffect(i <= rating ? 1.06 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(identifierPrefix)-\(i)")
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: rating)
    }
}

// MARK: - A colour per method

extension BrewMethod {
    /// Chosen by hand, not hashed — colour is how you tell them apart at a
    /// glance, so no two may land on the same one.
    var tint: Color {
        switch self {
        case .espresso:    return Candy.bubblegum
        case .v60:         return Candy.sky
        case .aeropress:   return Candy.grape
        case .frenchPress: return Candy.mint
        case .moka:        return Candy.apricot
        case .coldBrew:    return Candy.blueberry
        case .filter:      return Candy.mango
        }
    }
}

extension PurchaseKind {
    var tint: Color {
        switch self {
        case .machine:      return Candy.bubblegum
        case .grinder:      return Candy.blueberry
        case .accessory:    return Candy.mint
        case .subscription: return Candy.grape
        case .other:        return Candy.apricot
        }
    }
}

extension BrewField {
    /// Picked by hand so that neighbouring dials never share a colour in any
    /// method's list — hashing put two oranges side by side on a pour-over.
    var tint: Color {
        switch self {
        case .grind:         return Candy.bubblegum
        case .dose:          return Candy.apricot
        case .yield:         return Candy.mango
        case .water:         return Candy.sky
        case .temp:          return Candy.grape
        case .seconds:       return Candy.blueberry
        case .preInfusion:   return Candy.mint
        case .bloomWater:    return Candy.mint
        case .bloomSeconds:  return Candy.mango
        case .pours:         return Candy.apricot
        case .steepMinutes:  return Candy.mint
        case .steepHours:    return Candy.mint
        case .plungeSeconds: return Candy.mango
        }
    }
}
