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
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.secondary)
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
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                dialButton("minus", identifier: "\(identifier)-minus") {
                    value = max(range.lowerBound, value - step)
                }
                dialButton("plus", identifier: "\(identifier)-plus") {
                    value = min(range.upperBound, value + step)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func dialButton(_ symbol: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Circle().fill(tint))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}

/// The taste slider: a word at each end, a fat handle in the middle.
struct TasteSlider: View {
    let leftEmoji: String
    let leftWord: String
    let rightEmoji: String
    let rightWord: String
    @Binding var value: Double
    var tint: Color = Candy.bubblegum
    let identifier: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("\(leftEmoji) \(leftWord)")
                Spacer()
                Text("\(rightWord) \(rightEmoji)")
            }
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(.secondary)

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
                    VStack(spacing: 2) {
                        Text(option.emoji)
                            .font(.system(size: light == option ? 44 : 34))
                        Text(option.title)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(light == option ? Candy.mint.opacity(0.22) : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(light == option ? Candy.mint : Color.secondary.opacity(0.25),
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
                    HStack(spacing: 4) {
                        Text(flavour.emoji)
                        Text(flavour.title)
                    }
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(on ? .white : Candy.cocoa)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Capsule().fill(on ? Candy.forSeed(flavour.rawValue) : Color.white.opacity(0.7)))
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
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary)
            TextField(label, text: $text)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .textFieldStyle(.plain)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.75)))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(tint.opacity(0.45), lineWidth: 2))
                .accessibilityIdentifier(identifier)
        }
    }
}
