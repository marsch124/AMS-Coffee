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

enum Tab: String, CaseIterable, Identifiable {
    case today, bags, shots, cups

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .today: return "☕️"
        case .bags:  return "🫘"
        case .shots: return "🎛"
        case .cups:  return "🏺"
        }
    }

    var title: String {
        switch self {
        case .today: return "Today"
        case .bags:  return "Bags"
        case .shots: return "Shots"
        case .cups:  return "Cups"
        }
    }

    var tint: Color {
        switch self {
        case .today: return Candy.bubblegum
        case .bags:  return Candy.mint
        case .shots: return Candy.blueberry
        case .cups:  return Candy.grape
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
                    case .today: HomeView(tab: $tab)
                    case .bags:  BagsView()
                    case .shots: ShotsView()
                    case .cups:  CupsView()
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("screen-\(tab.rawValue)")

                CandyTabBar(tab: $tab)
            }

            Confetti(trigger: store.celebrate)
        }
    }
}

/// Four fat buttons. Emoji first, word second — readable with your glasses off.
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
                    VStack(spacing: 1) {
                        Text(item.emoji).font(.system(size: on ? 27 : 23))
                        Text(item.title)
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(on ? .white : item.tint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
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
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(scheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.80))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Candy.cocoa.opacity(0.18), lineWidth: 2))
                .shadow(color: Candy.cocoa.opacity(0.18), radius: 0, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

/// Every screen wears the same scrolling jacket, with an optional sticky
/// bar at the bottom so Save is never off the end of a long form.
struct Screen<Content: View, Bar: View>: View {
    let emoji: String
    let title: String
    @ViewBuilder var content: Content
    @ViewBuilder var bar: Bar

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Steam()
                    .padding(.bottom, -18)
                BigTitle(emoji: emoji, text: title)
                content
            }
            .padding(20)
            .padding(.bottom, 30)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .safeAreaInset(edge: .bottom) {
            bar
        }
    }
}

extension Screen where Bar == EmptyView {
    init(emoji: String, title: String, @ViewBuilder content: () -> Content) {
        self.init(emoji: emoji, title: title, content: content, bar: { EmptyView() })
    }
}

/// The sticky bar: one big coloured action, one quiet Close.
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
                HStack {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 22, weight: .black))
                    Text(saveTitle)
                }
            }
            .buttonStyle(SquashyButton(tint: tint))
            .accessibilityIdentifier(saveIdentifier)

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
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
