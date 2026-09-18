import SwiftUI

// MARK: - The timer
//
// It counts while you pour, and when you stop it writes the time into the
// brew — so the seconds in the log are the seconds that actually happened,
// not what you remembered afterwards.
//
// The elapsed time is worked out from a start DATE, never from counting
// ticks. Lock the phone mid-pour, take a call, come back: the clock is still
// right, because nothing was being counted in the first place.

struct BrewTimer: View {
    /// Total brew time, in seconds — the field every method has.
    @Binding var seconds: Double
    /// Set for the methods that have a bloom, so the timer can split it out.
    var bloomSeconds: Binding<Double>?
    /// Set for the methods measured in minutes of steeping.
    var steepMinutes: Binding<Double>?

    @State private var startedAt: Date?
    @State private var banked: Double = 0
    @State private var bloomMark: Double?

    private var isRunning: Bool { startedAt != nil }

    var body: some View {
        VStack(spacing: 14) {
            // The clock. Big enough to read from across the kitchen.
            TimelineView(.periodic(from: .now, by: 0.2)) { _ in
                let shown = elapsed
                VStack(spacing: 2) {
                    Text(clock(shown))
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(isRunning ? Candy.mint : Candy.ink)
                        .contentTransition(.numericText())
                    if let bloomMark {
                        Text("bloom \(Int(bloomMark)) s")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                    }
                }
                .accessibilityIdentifier("timer-display")
                .accessibilityValue("\(Int(shown))")
            }

            HStack(spacing: 10) {
                Button {
                    isRunning ? stop() : start()
                } label: {
                    Text(isRunning ? "Stop" : (banked > 0 ? "Carry on" : "Start"))
                }
                .buttonStyle(SquashyButton(tint: isRunning ? Candy.bubblegum : Candy.mint))
                .accessibilityIdentifier(isRunning ? "timer-stop" : "timer-start")

                if isRunning, let bloom = bloomSeconds, bloomMark == nil {
                    Button {
                        let now = elapsed
                        bloomMark = now.rounded()
                        bloom.wrappedValue = now.rounded()
                    } label: {
                        Text("Bloom done")
                    }
                    .buttonStyle(SquashyButton(tint: Candy.sky))
                    .accessibilityIdentifier("timer-bloom")
                }
            }

            if !isRunning && (banked > 0 || bloomMark != nil) {
                Button {
                    banked = 0
                    bloomMark = nil
                } label: {
                    Text("Start over")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(Candy.danger)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("timer-reset")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var elapsed: Double {
        guard let startedAt else { return banked }
        return banked + Date().timeIntervalSince(startedAt)
    }

    private func start() {
        startedAt = Date()
    }

    /// Stopping is what commits the time to the brew.
    private func stop() {
        let total = elapsed.rounded()
        banked = total
        startedAt = nil
        seconds = total
        // A steeped brew is written in minutes, to the nearest half.
        if let steepMinutes {
            steepMinutes.wrappedValue = ((total / 60) * 2).rounded() / 2
        }
    }

    private func clock(_ t: Double) -> String {
        let whole = Int(t)
        let minutes = whole / 60
        let secs = whole % 60
        if minutes == 0 { return "\(secs)" }
        return String(format: "%d:%02d", minutes, secs)
    }
}
