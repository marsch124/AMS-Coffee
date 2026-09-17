import SwiftUI

/// The morning screen. One big button, what you have drunk, what you are
/// drinking, and the one thing to change next time. Nothing else.
struct HomeView: View {
    @EnvironmentObject private var store: CoffeeStore
    @Binding var tab: Tab
    @State private var pulling = false

    private var todaysBrews: [Shot] {
        store.data.liveShots.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var lovely: Int {
        store.data.liveShots.filter { $0.light == .green }.count
    }

    var body: some View {
        Screen(emoji: "☕️", title: "AMS Coffee") {

            if let warning = store.shelf.warning {
                WobbleCard(tint: Candy.apricot, tilt: 0.6) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("🛟 The shelf stopped something")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                        Text(warning)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
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
                HStack(spacing: 14) {
                    Text("☕️").font(.system(size: 34))
                    Text("Pull a shot")
                    Spacer()
                }
            }
            .buttonStyle(SquashyButton(tint: Candy.bubblegum))
            .accessibilityIdentifier("home-pull-shot")
            .poppyAppear(0.05)

            // What you have drunk. Nothing here is about money.
            WobbleCard(tint: Candy.mint, tilt: -0.8) {
                HStack(spacing: 4) {
                    BigNumber(value: "\(todaysBrews.count)", caption: "today", tint: Candy.mint)
                    BigNumber(value: "\(store.data.liveShots.count)", caption: "brews ever", tint: Candy.blueberry)
                    BigNumber(value: "\(store.data.liveBeans.count)", caption: "bags", tint: Candy.bubblegum)
                    BigNumber(value: "\(lovely)", caption: "🟢 lovely", tint: Candy.mango)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("home-numbers")
            .poppyAppear(0.10)

            // What the coach said about the last one.
            if let advice = store.lastAdvice {
                WobbleCard(tint: Candy.sky, tilt: 0.7) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("\(advice.emoji) \(advice.headline)")
                            .font(.system(size: 23, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.sky)
                        Text(advice.detail)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
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
                        HStack(spacing: 14) {
                            if let id = bean.photoID {
                                PhotoImage(data: store.photo(id), corner: 16)
                                    .frame(width: 86, height: 86)
                                    .clipped()
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🫘 In the hopper")
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text(bean.displayName)
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundStyle(Candy.cocoa)
                                Chip(text: "\(Int(store.data.gramsLeft(for: bean))) g left",
                                     tint: Candy.mint, symbol: "⚖️")
                            }
                            Spacer()
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home-current-bag")
                .poppyAppear(0.15)
            }
        }
        .sheet(isPresented: $pulling) {
            ShotEditor(shot: store.draftShot(beanID: currentBag?.id))
        }
    }

    /// The bag of the most recent brew, else the newest bag.
    private var currentBag: Bean? {
        if let last = store.data.liveShots.sorted(by: { $0.date > $1.date }).first,
           let bean = store.data.bean(last.beanID), bean.rinsedAt == nil {
            return bean
        }
        return store.data.liveBeans.sorted { $0.createdAt > $1.createdAt }.first
    }
}
