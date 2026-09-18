import SwiftUI

// MARK: - The four marks, drawn
//
// These replace the tab emoji. Apple's 🎛 and ⚙️ are photorealistic metal —
// chrome knobs and a grey cog — which is exactly the borrowed look this app
// is meant to avoid, and ☕️ and 🫘 are glossy in the same way.
//
// Each one is a Path in a 0…1 box scaled to whatever size it is asked for, so
// it stays crisp at any size and takes its colour from the view around it.
// The small deliberate offsets are what stop them looking machine-made.

/// A cup, side on, with its saucer. Today.
struct CupMark: View {
    var size: Double = 32
    var weight: Double = 0.075

    var body: some View {
        let w = size * weight
        Path { p in
            func pt(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: x * size, y: y * size)
            }
            // the body, a touch wider at the rim than the base
            p.move(to: pt(0.20, 0.30))
            p.addLine(to: pt(0.27, 0.64))
            p.addQuadCurve(to: pt(0.66, 0.65), control: pt(0.46, 0.76))
            p.addLine(to: pt(0.72, 0.29))
            // the rim, closing it
            p.addLine(to: pt(0.20, 0.30))
            // the handle
            p.move(to: pt(0.74, 0.37))
            p.addQuadCurve(to: pt(0.75, 0.56), control: pt(0.94, 0.47))
            // the saucer
            p.move(to: pt(0.13, 0.77))
            p.addLine(to: pt(0.83, 0.755))
        }
        .stroke(style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

/// One coffee bean with its seam — the same mark as the app icon. Beans.
struct BeanMark: View {
    var size: Double = 32
    var weight: Double = 0.075

    var body: some View {
        let w = size * weight
        ZStack {
            Ellipse()
                .stroke(style: StrokeStyle(lineWidth: w, lineCap: .round))
                .frame(width: size * 0.56, height: size * 0.76)
            Path { p in
                let n = 24
                for i in 0...n {
                    let t = Double(i) / Double(n)
                    let x = size * 0.5 + size * 0.10 * sin(t * 2 * .pi)
                    let y = size * 0.13 + t * size * 0.74
                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                    else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(style: StrokeStyle(lineWidth: w * 0.92, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

/// A dial with its pointer, and two ticks. Brews.
struct DialMark: View {
    var size: Double = 32
    var weight: Double = 0.075

    var body: some View {
        let w = size * weight
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: w, lineCap: .round))
                .frame(width: size * 0.62, height: size * 0.62)
            // the pointer, off true on purpose
            Path { p in
                p.move(to: CGPoint(x: size * 0.5, y: size * 0.5))
                p.addLine(to: CGPoint(x: size * 0.5 + size * 0.19, y: size * 0.5 - size * 0.20))
            }
            .stroke(style: StrokeStyle(lineWidth: w, lineCap: .round))
            // two ticks outside the dial
            Path { p in
                p.move(to: CGPoint(x: size * 0.5, y: size * 0.09))
                p.addLine(to: CGPoint(x: size * 0.5, y: size * 0.155))
                p.move(to: CGPoint(x: size * 0.895, y: size * 0.52))
                p.addLine(to: CGPoint(x: size * 0.955, y: size * 0.52))
            }
            .stroke(style: StrokeStyle(lineWidth: w * 0.85, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

/// A cog, hand-cut. Settings.
struct CogMark: View {
    var size: Double = 32
    var weight: Double = 0.075

    var body: some View {
        let w = size * weight
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: w, lineCap: .round))
                .frame(width: size * 0.50, height: size * 0.50)
            Circle()
                .stroke(style: StrokeStyle(lineWidth: w * 0.8, lineCap: .round))
                .frame(width: size * 0.17, height: size * 0.17)
            // seven teeth, not eight — an even ring looks stamped out
            Path { p in
                let c = CGPoint(x: size * 0.5, y: size * 0.5)
                for i in 0..<7 {
                    let a = Double(i) / 7 * 2 * .pi - .pi / 2 + 0.07
                    let inner = size * 0.27
                    let outer = size * 0.40
                    p.move(to: CGPoint(x: c.x + cos(a) * inner, y: c.y + sin(a) * inner))
                    p.addLine(to: CGPoint(x: c.x + cos(a) * outer, y: c.y + sin(a) * outer))
                }
            }
            .stroke(style: StrokeStyle(lineWidth: w, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

/// The right mark for a tab, so the bar and the screen titles agree.
struct TabMark: View {
    let tab: Tab
    var size: Double = 32

    var body: some View {
        switch tab {
        case .today:    CupMark(size: size)
        case .bags:     BeanMark(size: size)
        case .shots:    DialMark(size: size)
        case .settings: CogMark(size: size)
        }
    }
}
