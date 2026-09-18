import SwiftUI

/// A number with fat − and + buttons either side, and a field for when you
/// want to just type it. Glasses off, one thumb.
struct NumberDial: View {
    let label: String
    let unit: String
    @Binding var value: Double
    var step: Double = 1
    var range: ClosedRange<Double> = 0...999
    var tint: Color = Candy.blueberry
    let identifier: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Candy.inkSoft)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    TextField(label, value: $value, format: .number.precision(.fractionLength(0...1)))
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(tint)
                        .frame(width: 74)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.leading)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .accessibilityIdentifier(identifier)
                    Text(unit)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(Candy.inkSoft)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                dialButton(identifier: "\(identifier)-minus") {
                    value = max(range.lowerBound, value - step)
                } mark: {
                    MinusMark(size: 22, weight: 5)
                }
                dialButton(identifier: "\(identifier)-plus") {
                    value = min(range.upperBound, value + step)
                } mark: {
                    PlusMark(size: 22, weight: 5)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func dialButton<M: View>(identifier: String,
                                     action: @escaping () -> Void,
                                     @ViewBuilder mark: () -> M) -> some View {
        Button(action: action) {
            mark()
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Circle().fill(tint))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}

/// The taste slider: a word at each end, a fat handle in the middle.
struct TasteSlider: View {
    let leftWord: String
    let rightWord: String
    @Binding var value: Double
    var tint: Color = Candy.bubblegum
    let identifier: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(leftWord)
                Spacer()
                Text(rightWord)
            }
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(Candy.inkSoft)

            Slider(value: $value, in: -1...1)
                .tint(tint)
                .accessibilityIdentifier(identifier)
        }
    }
}

/// 🔴 🟡 🟢 — three big taps, no words needed.
struct LightPicker: View {
    @Binding var light: TrafficLight

    var body: some View {
        HStack(spacing: 12) {
            ForEach(TrafficLight.allCases) { option in
                Button {
                    light = option
                } label: {
                    VStack(spacing: 4) {
                        LightMark(light: option, size: light == option ? 46 : 36)
                        Text(option.title)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(light == option ? Candy.mint.opacity(0.22) : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(light == option ? Candy.mint : Candy.inkSoft.opacity(0.40),
                                              lineWidth: light == option ? 3 : 2))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("light-\(option.rawValue)")
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: light)
    }
}

/// Tap the flavours you taste. No typing.
struct FlavourWheel: View {
    @Binding var picked: [Flavour]

    var body: some View {
        FlowRow(spacing: 8) {
            ForEach(Flavour.allCases) { flavour in
                let on = picked.contains(flavour)
                Button {
                    if on { picked.removeAll { $0 == flavour } } else { picked.append(flavour) }
                } label: {
                    Text(flavour.title)
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(on ? .white : Candy.ink)
                    .padding(.vertical, 11)
                    .padding(.horizontal, 15)
                    .background(Capsule().fill(on ? Candy.forSeed(flavour.rawValue) : Candy.field))
                    .overlay(Capsule().strokeBorder(Candy.forSeed(flavour.rawValue).opacity(0.6), lineWidth: 2))
                    .scaleEffect(on ? 1.04 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("flavour-\(flavour.rawValue)")
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: picked)
    }
}

/// A plain wrapping row, so chips flow onto the next line by themselves.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// A fat text row with a rounded box, used for names and notes.
struct FatField: View {
    let label: String
    @Binding var text: String
    var tint: Color = Candy.blueberry
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(Candy.inkSoft)
            TextField(label, text: $text)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .textFieldStyle(.plain)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Candy.field))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(tint.opacity(0.45), lineWidth: 2))
                .accessibilityIdentifier(identifier)
        }
    }
}

/// A folded pill that unfolds in place. Used for the guide and the history.
struct FoldPill<Mark: View, Content: View>: View {
    let mark: Mark
    let title: String
    let subtitle: String
    let tint: Color
    @Binding var isOpen: Bool
    let identifier: String
    @ViewBuilder var content: Content

    init(title: String, subtitle: String, tint: Color, isOpen: Binding<Bool>,
         identifier: String, @ViewBuilder mark: () -> Mark,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self._isOpen = isOpen
        self.identifier = identifier
        self.mark = mark()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) { isOpen.toggle() }
            } label: {
                HStack(spacing: 15) {
                    mark
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 21, weight: .black, design: .rounded))
                            .foregroundStyle(tint)
                        Text(subtitle)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                    }
                    Spacer()
                    ChevronMark(size: 26, weight: 5)
                        .foregroundStyle(tint)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(18)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("\(identifier)-toggle")

            if isOpen {
                content
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Candy.card)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(tint.opacity(0.55), lineWidth: 3))
                .shadow(color: tint.opacity(0.28), radius: 0, x: 0, y: 5)
        )
    }
}
