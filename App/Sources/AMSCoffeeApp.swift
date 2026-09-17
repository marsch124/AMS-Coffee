import SwiftUI

@main
struct AMSCoffeeApp: App {
    @StateObject private var store = CoffeeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
        #if os(macOS)
        .defaultSize(width: 540, height: 920)
        #endif
    }
}

/// Four places, and only four.
///
/// Today is what you do every morning. Beans is what you are drinking. Brews
/// is how you made it. Everything you touch once — the guide, the history, the
/// cups, your kit, export — lives in Settings, out of the way.
///
/// The raw values are the test identifiers, so they stay put even when the
/// words on screen change.
enum Tab: String, CaseIterable, Identifiable {
    case today, bags, shots, settings

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .today:    return "☕️"
        case .bags:     return "🫘"
        case .shots:    return "🎛"
        case .settings: return "⚙️"
        }
    }

    var title: String {
        switch self {
        case .today:    return "Today"
        case .bags:     return "Beans"
        case .shots:    return "Brews"
        case .settings: return "Settings"
        }
    }

    var tint: Color {
        switch self {
        case .today:    return Candy.bubblegum
        case .bags:     return Candy.mint
        case .shots:    return Candy.blueberry
        case .settings: return Candy.grape
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: CoffeeStore
    @State private var tab: Tab = .today

    var body: some View {
        ZStack {
            CoffeeBackground()

            VStack(spacing: 0) {
                ZStack {
                    switch tab {
                    case .today:    HomeView(tab: $tab)
                    case .bags:     BagsView()
                    case .shots:    ShotsView()
                    case .settings: SettingsView()
                    }
                }
                .accessibilityIdentifier("screen-\(tab.rawValue)")

                CandyTabBar(tab: $tab)
            }

            Confetti(trigger: store.celebrate)
        }
    }
}

/// Four fat buttons, big enough to hit without looking.
struct CandyTabBar: View {
    @Binding var tab: Tab
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Tab.allCases) { item in
                let on = tab == item
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.5)) { tab = item }
                } label: {
                    VStack(spacing: 2) {
                        Text(item.emoji).font(.system(size: on ? 34 : 29))
                        Text(item.title)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(on ? .white : item.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 21, style: .continuous)
                            .fill(on ? item.tint : Color.clear)
                    )
                    .rotationEffect(.degrees(on ? -1.5 : 0))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab-\(item.rawValue)")
            }
        }
        .padding(7)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(scheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.80))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Candy.cocoa.opacity(0.18), lineWidth: 2))
                .shadow(color: Candy.cocoa.opacity(0.18), radius: 0, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

/// Every screen wears the same scrolling jacket, with an optional sticky bar
/// at the bottom so Save is never off the end of a long form.
struct Screen<Content: View, Bar: View>: View {
    let emoji: String
    let title: String
    @ViewBuilder var content: Content
    @ViewBuilder var bar: Bar

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BigTitle(emoji: emoji, text: title)
                    .padding(.top, 8)
                content
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .safeAreaInset(edge: .bottom) { bar }
    }
}

extension Screen where Bar == EmptyView {
    init(emoji: String, title: String, @ViewBuilder content: () -> Content) {
        self.init(emoji: emoji, title: title, content: content, bar: { EmptyView() })
    }
}

/// The sticky bar: one big coloured action, one quiet way out.
struct StickyBar: View {
    let saveTitle: String
    let tint: Color
    let saveIdentifier: String
    let closeIdentifier: String
    let save: () -> Void
    let close: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: save) {
                HStack(spacing: 10) {
                    TickMark(size: 24, weight: 5)
                    Text(saveTitle)
                }
            }
            .buttonStyle(SquashyButton(tint: tint))
            .accessibilityIdentifier(saveIdentifier)

            Button(action: close) {
                CrossMark(size: 22, weight: 5)
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(Candy.cocoa.opacity(0.55)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(closeIdentifier)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
