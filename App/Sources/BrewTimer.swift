import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - The timer
//
// It counts while you pour, and when you stop it writes the time into the
// brew — so the seconds in the log are the seconds that actually happened,
// not what you remembered afterwards.
//
// The elapsed time is worked out from a start DATE, never from counting
// ticks. Lock the phone mid-pour, take a call, come back: the clock is still
// right, because nothing was being counted in the first place.
//
// Since 2.3 it also knows where it is going. The number carries the message
// in colour — settling, nearly there, there, gone past — and buzzes at the
// two moments you would otherwise have to watch for. Glasses off, hands wet.

/// Where a running clock stands against the window it is aiming at.
///
/// Pulled out of the view on purpose: this is the whole of the timer's
/// judgement, and a rule you can only check by watching a screenshot for
/// thirty seconds is a rule nobody checks.
enum TimerStanding: String {
    case settling, nearly, there, past

    /// How far ahead of the window the clock starts warning you. Five
    /// seconds is right for an espresso and absurd for a filter, so it is a
    /// share of the window rather than a fixed number.
    static func lead(for target: ClosedRange<Double>) -> Double {
        max(5, target.lowerBound * 0.15)
    }

    static func at(_ elapsed: Double, target: ClosedRange<Double>) -> TimerStanding {
        if elapsed > target.upperBound { return .past }
        if elapsed >= target.lowerBound { return .there }
        if elapsed >= target.lowerBound - lead(for: target) { return .nearly }
        return .settling
    }

    /// Nothing is said while it is still settling — the number is enough.
    var word: String? {
        switch self {
        case .settling: return nil
        case .nearly:   return "nearly"
        case .there:    return "there"
        case .past:     return "past it"
        }
    }
}

struct BrewTimer: View {
    /// Total brew time, in seconds — the field every method has.
    @Binding var seconds: Double
    /// Set for the methods that have a bloom, so the timer can split it out.
    var bloomSeconds: Binding<Double>?
    /// Set for the methods measured in minutes of steeping.
    var steepMinutes: Binding<Double>?
    /// Where this method usually lands — the coach's own window, so the
    /// timer and the advice can never tell you two different stories.
    var target: ClosedRange<Double>?
    /// The pre-infusion, when there is one: the timer buzzes when it ends.
    var preInfusion: Double = 0

    @State private var startedAt: Date?
    @State private var banked: Double = 0
    @State private var bloomMark: Double?
    @State private var buzzed: Set<String> = []
    @State private var watcher: Task<Void, Never>?

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
                        .foregroundStyle(colour(at: shown))
                        .contentTransition(.numericText())
                    if let bloomMark {
                        Text("bloom \(Int(bloomMark)) s")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                    }
                    if let note = standing(at: shown)?.word {
                        Text(note)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(colour(at: shown))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("timer-display")
                .accessibilityLabel(standing(at: shown)?.word ?? "Timer")
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
                        knock()
                    } label: {
                        Text("Bloom done")
                    }
                    .buttonStyle(SquashyButton(tint: Candy.sky))
                    .accessibilityIdentifier("timer-bloom")
                }
            }

            if let aim = aimText {
                Text(aim)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Candy.inkSoft)
                    .accessibilityIdentifier("timer-aim")
            }

            if !isRunning && (banked > 0 || bloomMark != nil) {
                Button {
                    banked = 0
                    bloomMark = nil
                    buzzed = []
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
        .onDisappear { watcher?.cancel() }
    }

    private var elapsed: Double {
        guard let startedAt else { return banked }
        return banked + Date().timeIntervalSince(startedAt)
    }

    // MARK: - Where you are

    private func standing(at t: Double) -> TimerStanding? {
        guard isRunning || banked > 0, let target else { return nil }
        return TimerStanding.at(t, target: target)
    }

    private func colour(at t: Double) -> Color {
        guard let standing = standing(at: t) else {
            return isRunning ? Candy.mint : Candy.ink
        }
        return Candy.forStanding(standing)
    }

    private var aimText: String? {
        guard let target else { return nil }
        if target.lowerBound >= 120 {
            return "aim \(Coach.trim(target.lowerBound / 60))–\(Coach.trim(target.upperBound / 60)) min"
        }
        return "aim \(Coach.trim(target.lowerBound))–\(Coach.trim(target.upperBound)) s"
    }

    // MARK: - Running it

    private func start() {
        startedAt = Date()
        knock()
        watch()
    }

    /// Stopping is what commits the time to the brew.
    private func stop() {
        let total = elapsed.rounded()
        banked = total
        startedAt = nil
        watcher?.cancel()
        seconds = total
        // A steeped brew is written in minutes, to the nearest half.
        if let steepMinutes {
            steepMinutes.wrappedValue = ((total / 60) * 2).rounded() / 2
        }
        knock()
    }

    /// The buzzes. Watched on their own clock rather than worked out while
    /// the view draws — a view body must not set state, and firing a haptic
    /// from inside one would fire it again on every redraw.
    private func watch() {
        watcher?.cancel()
        watcher = Task { @MainActor in
            while !Task.isCancelled && startedAt != nil {
                let now = elapsed
                if preInfusion > 0, now >= preInfusion { fireOnce("pre-infusion") }
                if let target {
                    switch TimerStanding.at(now, target: target) {
                    case .there: fireOnce("there", good: true)
                    case .past:  fireOnce("past", good: false)
                    default:     break
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    private func fireOnce(_ mark: String, good: Bool? = nil) {
        guard !buzzed.contains(mark) else { return }
        buzzed.insert(mark)
        #if os(iOS)
        switch good {
        case .some(true):  UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .some(false): UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .none:        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        #endif
    }

    /// A plain knock for the taps you made yourself.
    private func knock() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func clock(_ t: Double) -> String {
        let whole = Int(t)
        let minutes = whole / 60
        let secs = whole % 60
        if minutes == 0 { return "\(secs)" }
        return String(format: "%d:%02d", minutes, secs)
    }
}
