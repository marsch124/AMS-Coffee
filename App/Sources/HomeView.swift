import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: CoffeeStore
    @Binding var tab: Tab

    @State private var showHistory = false
    @State private var showGuide = false
    @State private var pulling = false

    private var todaysShots: [Shot] {
        store.data.liveShots.filter { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        Screen(emoji: "☕️", title: "AMS Coffee") {

            if let warning = store.shelf.warning {
                WobbleCard(tint: Candy.apricot, tilt: 0.6) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🛟 The shelf stopped something")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                        Text(warning)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        Button("Got it") { store.dismissWarning() }
                            .buttonStyle(SquashyButton(tint: Candy.apricot))
                            .accessibilityIdentifier("home-dismiss-warning")
                    }
                }
                .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-warning")
                .poppyAppear()
            }

            // The one big button.
            Button {
                pulling = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer.fill").font(.system(size: 26, weight: .black))
                    Text("Pull a shot")
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill").font(.system(size: 24))
                }
            }
            .buttonStyle(SquashyButton(tint: Candy.bubblegum))
            .accessibilityIdentifier("home-pull-shot")
            .poppyAppear(0.05)

            // Today at a glance.
            WobbleCard(tint: Candy.mint, tilt: -0.8) {
                HStack(spacing: 4) {
                    BigNumber(value: "\(todaysShots.count)", caption: "today", tint: Candy.mint)
                    BigNumber(value: "\(store.data.liveShots.count)", caption: "shots ever", tint: Candy.blueberry)
                    BigNumber(value: "\(store.data.liveBeans.count)", caption: "bags", tint: Candy.bubblegum)
                    BigNumber(value: store.data.costPerCup.map { String(format: "%.0f", $0) } ?? "—",
                              caption: "kr / cup", tint: Candy.mango)
                }
            }
            .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-numbers")
            .poppyAppear(0.10)

            // What the coach said about the last shot.
            if let advice = store.lastAdvice {
                WobbleCard(tint: Candy.sky, tilt: 0.7) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(advice.emoji) \(advice.headline)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.sky)
                        Text(advice.detail)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                }
                .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home-advice")
                .poppyAppear()
            }

            // The bag you are drinking now.
            if let bean = currentBag {
                Button { tab = .bags } label: {
                    WobbleCard(tint: Candy.forSeed(bean.id.uuidString), tilt: -0.5) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🫘 In the hopper")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(.secondary)
                            Text(bean.displayName)
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(Candy.cocoa)
                            HStack(spacing: 8) {
                                Chip(text: "\(Int(store.data.gramsLeft(for: bean))) g left",
                                     tint: Candy.mint, symbol: "scalemass.fill")
                                if bean.rating > 0 {
                                    Chip(text: String(repeating: "★", count: bean.rating),
                                         tint: Candy.mango)
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-current-bag")
                .poppyAppear(0.15)
            }

            // Version history — right here, folded.
            FoldPill(emoji: "📜",
                     title: "Version history",
                     subtitle: "v\(Guide.appVersion) · \(Guide.current.headline)",
                     tint: Candy.grape,
                     isOpen: $showHistory,
                     identifier: "home-version") {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Guide.releases) { release in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text(release.emoji).font(.system(size: 22))
                                Text("v\(release.version)")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundStyle(Candy.grape)
                                Text(release.headline)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                Spacer()
                                Text(release.date)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(Array(release.lines.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .accessibilityIdentifier("home-version-list")
            }
            .poppyAppear(0.20)

            // How it works — also folded.
            FoldPill(emoji: "📖",
                     title: "How this works",
                     subtitle: "\(Guide.chapters.count) short chapters",
                     tint: Candy.blueberry,
                     isOpen: $showGuide,
                     identifier: "home-guide") {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Guide.chapters) { chapter in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(chapter.emoji) \(chapter.title)")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(Candy.blueberry)
                            Text(chapter.body)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .accessibilityIdentifier("home-guide-list")
            }
            .poppyAppear(0.25)

            HStack(spacing: 8) {
                Chip(text: store.syncPlace, tint: Candy.sky, symbol: "icloud.fill")
                Chip(text: "\(store.shelf.cups.count) cups", tint: Candy.mint, symbol: "archivebox.fill")
            }
            .accessibilityIdentifier("home-footer")
        }
        .sheet(isPresented: $pulling) {
            ShotEditor(shot: store.draftShot(beanID: currentBag?.id))
        }
    }

    /// The bag of the most recent shot, else the newest bag.
    private var currentBag: Bean? {
        if let last = store.data.liveShots.sorted(by: { $0.date > $1.date }).first,
           let bean = store.data.bean(last.beanID), bean.rinsedAt == nil {
            return bean
        }
        return store.data.liveBeans.sorted { $0.createdAt > $1.createdAt }.first
    }
}

/// The folded pill that unfolds. Used for version history and the guide.
struct FoldPill<Content: View>: View {
    let emoji: String
    let title: String
    let subtitle: String
    let tint: Color
    @Binding var isOpen: Bool
    let identifier: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) { isOpen.toggle() }
            } label: {
                HStack(spacing: 12) {
                    Text(emoji).font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(tint)
                        Text(subtitle)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(tint)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("\(identifier)-toggle")

            if isOpen {
                content
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(tint.opacity(0.55), lineWidth: 3))
                .shadow(color: tint.opacity(0.28), radius: 0, x: 0, y: 5)
        )
    }
}
