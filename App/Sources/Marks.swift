import SwiftUI

// MARK: - Every mark in the app, drawn here
//
// No Apple art of any kind: no symbol sets, and no emoji either — emoji are
// Apple's drawings too, and the glossy cup, shiny beans and chrome cog were
// exactly the borrowed look this app is meant to avoid.
//
// Each mark is a Path in a 0…1 box scaled to whatever size it is asked for,
// takes its colour from the view around it, and sits a degree or two off true
// so it reads as drawn rather than generated.

private func p(_ x: Double, _ y: Double, _ s: Double) -> CGPoint {
    CGPoint(x: x * s, y: y * s)
}

/// A wide-mouthed jar. The cup shelf.
struct JarMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            path.move(to: p(0.26, 0.24, size))
            path.addLine(to: p(0.30, 0.74, size))
            path.addQuadCurve(to: p(0.70, 0.74, size), control: p(0.50, 0.86, size))
            path.addLine(to: p(0.74, 0.24, size))
            path.addLine(to: p(0.26, 0.24, size))
            path.move(to: p(0.20, 0.17, size))
            path.addLine(to: p(0.80, 0.165, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A tap with a drop under it. The Sink.
struct TapMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: p(0.22, 0.22, size))
                path.addLine(to: p(0.22, 0.40, size))
                path.addLine(to: p(0.62, 0.40, size))
                path.addLine(to: p(0.62, 0.52, size))
                path.move(to: p(0.12, 0.22, size))
                path.addLine(to: p(0.34, 0.215, size))
            }
            .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
            Circle()
                .frame(width: size * 0.13, height: size * 0.13)
                .offset(x: size * 0.12, y: size * 0.22)
        }
        .frame(width: size, height: size)
    }
}

/// A case with a handle. Your kit.
struct CaseMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            path.addRoundedRect(in: CGRect(x: size * 0.16, y: size * 0.36,
                                           width: size * 0.68, height: size * 0.40),
                                cornerSize: CGSize(width: size * 0.07, height: size * 0.07))
            path.move(to: p(0.38, 0.36, size))
            path.addLine(to: p(0.39, 0.25, size))
            path.addLine(to: p(0.62, 0.25, size))
            path.addLine(to: p(0.63, 0.36, size))
            path.move(to: p(0.16, 0.56, size))
            path.addLine(to: p(0.84, 0.555, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A camera. Take a photo.
struct CameraMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        ZStack {
            Path { path in
                path.addRoundedRect(in: CGRect(x: size * 0.13, y: size * 0.30,
                                               width: size * 0.74, height: size * 0.44),
                                    cornerSize: CGSize(width: size * 0.09, height: size * 0.09))
                path.move(to: p(0.36, 0.30, size))
                path.addLine(to: p(0.42, 0.22, size))
                path.addLine(to: p(0.60, 0.22, size))
                path.addLine(to: p(0.65, 0.30, size))
            }
            .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
            Circle()
                .stroke(style: StrokeStyle(lineWidth: size * weight * 0.9))
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

/// A framed picture with a hill in it. Choose a photo.
struct PictureMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        ZStack {
            Path { path in
                path.addRoundedRect(in: CGRect(x: size * 0.14, y: size * 0.22,
                                               width: size * 0.72, height: size * 0.56),
                                    cornerSize: CGSize(width: size * 0.08, height: size * 0.08))
                path.move(to: p(0.20, 0.66, size))
                path.addLine(to: p(0.40, 0.44, size))
                path.addLine(to: p(0.56, 0.62, size))
                path.addLine(to: p(0.66, 0.51, size))
                path.addLine(to: p(0.80, 0.66, size))
            }
            .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
            Circle()
                .frame(width: size * 0.10, height: size * 0.10)
                .offset(x: size * 0.17, y: -size * 0.15)
        }
        .frame(width: size, height: size)
    }
}

/// An arrow out of a tray, or into one. Export and import.
struct TrayArrowMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var out: Bool = true

    var body: some View {
        Path { path in
            // the tray
            path.move(to: p(0.18, 0.60, size))
            path.addLine(to: p(0.18, 0.78, size))
            path.addLine(to: p(0.82, 0.775, size))
            path.addLine(to: p(0.82, 0.60, size))
            // the shaft
            path.move(to: p(0.50, out ? 0.20 : 0.52, size))
            path.addLine(to: p(0.50, out ? 0.52 : 0.20, size))
            // the head
            let tipY = out ? 0.20 : 0.52
            let backY = out ? 0.34 : 0.38
            path.move(to: p(0.36, backY, size))
            path.addLine(to: p(0.50, tipY, size))
            path.addLine(to: p(0.64, backY, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A cloud. Where the coffee lives.
struct CloudMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            path.move(to: p(0.22, 0.62, size))
            path.addQuadCurve(to: p(0.32, 0.40, size), control: p(0.16, 0.44, size))
            path.addQuadCurve(to: p(0.60, 0.34, size), control: p(0.44, 0.24, size))
            path.addQuadCurve(to: p(0.78, 0.48, size), control: p(0.78, 0.30, size))
            path.addQuadCurve(to: p(0.76, 0.62, size), control: p(0.90, 0.56, size))
            path.addLine(to: p(0.22, 0.62, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A shield. A warranty still running.
struct ShieldMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            path.move(to: p(0.50, 0.17, size))
            path.addLine(to: p(0.80, 0.28, size))
            path.addQuadCurve(to: p(0.50, 0.82, size), control: p(0.79, 0.68, size))
            path.addQuadCurve(to: p(0.20, 0.28, size), control: p(0.21, 0.68, size))
            path.addLine(to: p(0.50, 0.17, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A full tray. What a cup holds.
struct BoxMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            path.addRoundedRect(in: CGRect(x: size * 0.16, y: size * 0.28,
                                           width: size * 0.68, height: size * 0.46),
                                cornerSize: CGSize(width: size * 0.07, height: size * 0.07))
            path.move(to: p(0.16, 0.44, size))
            path.addLine(to: p(0.84, 0.435, size))
            path.move(to: p(0.42, 0.44, size))
            path.addLine(to: p(0.42, 0.74, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A balance. Grams left in a bag.
struct BalanceMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            path.move(to: p(0.50, 0.20, size))
            path.addLine(to: p(0.50, 0.74, size))
            path.move(to: p(0.32, 0.76, size))
            path.addLine(to: p(0.68, 0.755, size))
            path.move(to: p(0.19, 0.30, size))
            path.addLine(to: p(0.81, 0.295, size))
            path.move(to: p(0.19, 0.30, size))
            path.addLine(to: p(0.28, 0.48, size))
            path.addLine(to: p(0.10, 0.48, size))
            path.addLine(to: p(0.19, 0.30, size))
            path.move(to: p(0.81, 0.295, size))
            path.addLine(to: p(0.90, 0.475, size))
            path.addLine(to: p(0.72, 0.475, size))
            path.addLine(to: p(0.81, 0.295, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight * 0.85, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A receipt, torn off at the bottom.
struct ReceiptMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            path.move(to: p(0.26, 0.18, size))
            path.addLine(to: p(0.26, 0.76, size))
            for i in 0..<5 {
                let x = 0.26 + Double(i) * 0.12
                path.addLine(to: p(x + 0.06, 0.82, size))
                path.addLine(to: p(x + 0.12, 0.76, size))
            }
            path.addLine(to: p(0.74, 0.18, size))
            path.addLine(to: p(0.26, 0.18, size))
            path.move(to: p(0.36, 0.34, size))
            path.addLine(to: p(0.64, 0.335, size))
            path.move(to: p(0.36, 0.48, size))
            path.addLine(to: p(0.58, 0.475, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight * 0.8, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A triangle with a bar in it. Something needs attention.
struct WarningMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: p(0.50, 0.16, size))
                path.addLine(to: p(0.88, 0.78, size))
                path.addLine(to: p(0.12, 0.78, size))
                path.addLine(to: p(0.50, 0.16, size))
                path.move(to: p(0.50, 0.38, size))
                path.addLine(to: p(0.50, 0.56, size))
            }
            .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
            Circle()
                .frame(width: size * 0.09, height: size * 0.09)
                .offset(y: size * 0.16)
        }
        .frame(width: size, height: size)
    }
}

/// A plain filled disc, for the three lights.
struct DiscMark: View {
    var size: Double = 32
    var body: some View {
        Circle()
            .frame(width: size * 0.62, height: size * 0.62)
            .frame(width: size, height: size)
    }
}

/// A thumb turned down. Never again.
struct ThumbDownMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            path.addRoundedRect(in: CGRect(x: size * 0.17, y: size * 0.20,
                                           width: size * 0.19, height: size * 0.34),
                                cornerSize: CGSize(width: size * 0.05, height: size * 0.05))
            path.move(to: p(0.40, 0.20, size))
            path.addLine(to: p(0.74, 0.21, size))
            path.addQuadCurve(to: p(0.72, 0.54, size), control: p(0.86, 0.38, size))
            path.addLine(to: p(0.52, 0.55, size))
            path.addQuadCurve(to: p(0.50, 0.80, size), control: p(0.60, 0.68, size))
            path.addQuadCurve(to: p(0.40, 0.56, size), control: p(0.40, 0.72, size))
            path.addLine(to: p(0.40, 0.20, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight * 0.85, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A question. Undecided about a bag.
struct QueryMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: p(0.34, 0.34, size))
                path.addQuadCurve(to: p(0.62, 0.36, size), control: p(0.50, 0.16, size))
                path.addQuadCurve(to: p(0.50, 0.58, size), control: p(0.70, 0.50, size))
            }
            .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
            Circle()
                .frame(width: size * 0.11, height: size * 0.11)
                .offset(y: size * 0.23)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - The seven ways of making it

/// A cone sitting on a carafe. Pour-over.
struct ConeMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            // the cone
            path.move(to: p(0.16, 0.18, size))
            path.addLine(to: p(0.84, 0.175, size))
            path.addLine(to: p(0.56, 0.48, size))
            path.addLine(to: p(0.44, 0.48, size))
            path.addLine(to: p(0.16, 0.18, size))
            // the carafe below it, with a belly and a neck
            path.move(to: p(0.38, 0.54, size))
            path.addLine(to: p(0.34, 0.66, size))
            path.addQuadCurve(to: p(0.66, 0.66, size), control: p(0.50, 0.88, size))
            path.addLine(to: p(0.62, 0.54, size))
            path.addLine(to: p(0.38, 0.54, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A cylinder being pressed from above. AeroPress.
struct AeroMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            // the chamber
            path.move(to: p(0.32, 0.40, size))
            path.addLine(to: p(0.32, 0.82, size))
            path.addLine(to: p(0.68, 0.82, size))
            path.addLine(to: p(0.68, 0.40, size))
            path.addLine(to: p(0.32, 0.40, size))
            // the cap being pushed down
            path.move(to: p(0.27, 0.34, size))
            path.addLine(to: p(0.73, 0.335, size))
            // the arrow saying which way it goes
            path.move(to: p(0.50, 0.08, size))
            path.addLine(to: p(0.50, 0.27, size))
            path.move(to: p(0.41, 0.19, size))
            path.addLine(to: p(0.50, 0.28, size))
            path.addLine(to: p(0.59, 0.19, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A jug with a side handle and a plunger rod. French press.
struct PlungerMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            // the jug
            path.move(to: p(0.28, 0.30, size))
            path.addLine(to: p(0.31, 0.82, size))
            path.addLine(to: p(0.65, 0.82, size))
            path.addLine(to: p(0.68, 0.30, size))
            path.addLine(to: p(0.28, 0.30, size))
            // the handle on the side
            path.move(to: p(0.70, 0.44, size))
            path.addQuadCurve(to: p(0.68, 0.66, size), control: p(0.92, 0.55, size))
            // the rod and its disc
            path.move(to: p(0.48, 0.30, size))
            path.addLine(to: p(0.48, 0.12, size))
            path.move(to: p(0.34, 0.54, size))
            path.addLine(to: p(0.62, 0.535, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// The waisted pot. Moka.
struct MokaMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            path.move(to: p(0.32, 0.80, size))
            path.addLine(to: p(0.68, 0.80, size))
            path.addLine(to: p(0.62, 0.52, size))
            path.addLine(to: p(0.70, 0.50, size))
            path.addLine(to: p(0.64, 0.22, size))
            path.addLine(to: p(0.36, 0.22, size))
            path.addLine(to: p(0.30, 0.50, size))
            path.addLine(to: p(0.38, 0.52, size))
            path.addLine(to: p(0.32, 0.80, size))
            path.move(to: p(0.64, 0.30, size))
            path.addQuadCurve(to: p(0.66, 0.44, size), control: p(0.84, 0.37, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A six-pointed flake. Cold brew.
struct FlakeMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            let c = CGPoint(x: size * 0.5, y: size * 0.5)
            for i in 0..<3 {
                let a = Double(i) / 3 * .pi + 0.1
                path.move(to: CGPoint(x: c.x + cos(a) * size * 0.32,
                                      y: c.y + sin(a) * size * 0.32))
                path.addLine(to: CGPoint(x: c.x - cos(a) * size * 0.32,
                                         y: c.y - sin(a) * size * 0.32))
            }
            // little barbs, so it reads as frost rather than an asterisk
            for i in 0..<6 {
                let a = Double(i) / 6 * 2 * .pi + 0.1
                let tip = CGPoint(x: c.x + cos(a) * size * 0.32, y: c.y + sin(a) * size * 0.32)
                let back = CGPoint(x: c.x + cos(a) * size * 0.20, y: c.y + sin(a) * size * 0.20)
                let side = a + 0.9
                path.move(to: back)
                path.addLine(to: CGPoint(x: back.x + cos(side) * size * 0.10,
                                         y: back.y + sin(side) * size * 0.10))
                path.move(to: tip)
            }
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight * 0.85, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A flat filter basket with its paper, and a drip. Filter machine.
struct FunnelMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        ZStack {
            Path { path in
                // the basket: a shallow trapezoid, quite unlike a cone
                path.move(to: p(0.14, 0.26, size))
                path.addLine(to: p(0.86, 0.255, size))
                path.addLine(to: p(0.72, 0.58, size))
                path.addLine(to: p(0.28, 0.58, size))
                path.addLine(to: p(0.14, 0.26, size))
                // the paper inside
                path.move(to: p(0.27, 0.36, size))
                path.addLine(to: p(0.73, 0.355, size))
                path.move(to: p(0.33, 0.46, size))
                path.addLine(to: p(0.67, 0.455, size))
            }
            .stroke(style: StrokeStyle(lineWidth: size * weight * 0.85,
                                       lineCap: .round, lineJoin: .round))
            Circle().frame(width: size * 0.11, height: size * 0.11)
                .offset(y: size * 0.22)
        }
        .frame(width: size, height: size)
    }
}

/// The right mark for a brew method.
struct MethodMark: View {
    let method: BrewMethod
    var size: Double = 32

    var body: some View {
        switch method {
        case .espresso:    CupMark(size: size)
        case .v60:         ConeMark(size: size)
        case .aeropress:   AeroMark(size: size)
        case .frenchPress: PlungerMark(size: size)
        case .moka:        MokaMark(size: size)
        case .coldBrew:    FlakeMark(size: size)
        case .filter:      FunnelMark(size: size)
        }
    }
}

/// The right mark for a kind of kit.
struct KitKindMark: View {
    let kind: PurchaseKind
    var size: Double = 32

    var body: some View {
        switch kind {
        case .machine:      MokaMark(size: size)
        case .grinder:      DialMark(size: size)
        case .accessory:    BalanceMark(size: size)
        case .subscription: TrayArrowMark(size: size, out: false)
        case .other:        BoxMark(size: size)
        }
    }
}

/// The right mark for a traffic light, in its own colour.
struct LightMark: View {
    let light: TrafficLight
    var size: Double = 32

    private var colour: Color {
        switch light {
        case .red:   return Candy.bubblegum
        case .amber: return Candy.mango
        case .green: return Candy.mint
        }
    }

    var body: some View {
        DiscMark(size: size).foregroundStyle(colour)
    }
}

/// The right mark for a verdict on a bag.
struct VerdictMark: View {
    let verdict: Verdict
    var size: Double = 32

    var body: some View {
        switch verdict {
        case .buyAgain:  StarMark(size: size, filled: true)
        case .never:     ThumbDownMark(size: size)
        case .undecided: QueryMark(size: size)
        }
    }
}

/// An open book. How this works.
struct BookMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            path.move(to: p(0.50, 0.30, size))
            path.addQuadCurve(to: p(0.14, 0.26, size), control: p(0.32, 0.20, size))
            path.addLine(to: p(0.14, 0.70, size))
            path.addQuadCurve(to: p(0.50, 0.74, size), control: p(0.32, 0.66, size))
            path.addQuadCurve(to: p(0.86, 0.70, size), control: p(0.68, 0.66, size))
            path.addLine(to: p(0.86, 0.26, size))
            path.addQuadCurve(to: p(0.50, 0.30, size), control: p(0.68, 0.20, size))
            path.move(to: p(0.50, 0.30, size))
            path.addLine(to: p(0.50, 0.74, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// A scroll. The version history.
struct ScrollMark: View {
    var size: Double = 32
    var weight: Double = 0.075
    var body: some View {
        Path { path in
            path.move(to: p(0.26, 0.24, size))
            path.addLine(to: p(0.74, 0.235, size))
            path.addLine(to: p(0.74, 0.76, size))
            path.addLine(to: p(0.26, 0.765, size))
            path.addLine(to: p(0.26, 0.24, size))
            path.move(to: p(0.36, 0.38, size))
            path.addLine(to: p(0.64, 0.375, size))
            path.move(to: p(0.36, 0.50, size))
            path.addLine(to: p(0.64, 0.495, size))
            path.move(to: p(0.36, 0.62, size))
            path.addLine(to: p(0.56, 0.615, size))
        }
        .stroke(style: StrokeStyle(lineWidth: size * weight * 0.85, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// The right mark for a kind of cup: a tray for the quick ones, a cup for the
/// daily one, a jar for a keepsake.
struct CupKindMark: View {
    let kind: CupKind
    var size: Double = 32

    var body: some View {
        switch kind {
        case .quick:    BoxMark(size: size)
        case .daily:    CupMark(size: size)
        case .keepsake: JarMark(size: size)
        }
    }
}
