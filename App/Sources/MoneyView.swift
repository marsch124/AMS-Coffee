import SwiftUI

/// What the habit costs. Bags carry their own price and are counted here
/// automatically, so a bag is never typed in twice.
struct MoneyView: View {
    @EnvironmentObject private var store: CoffeeStore
    @State private var editing: Purchase?
    @State private var adding = false

    private var year: Int { Calendar.current.component(.year, from: Date()) }

    var body: some View {
        Screen(emoji: "🛒", title: "Money") {

            WobbleCard(tint: Candy.mango, tilt: -0.7) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("This year")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        BigNumber(value: kr(store.data.beanSpend(in: year)),
                                  caption: "beans", tint: Candy.bubblegum)
                        BigNumber(value: kr(store.data.gearSpend(in: year)),
                                  caption: "gear", tint: Candy.blueberry)
                        BigNumber(value: kr(store.data.totalSpend(in: year)),
                                  caption: "together", tint: Candy.mango)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("money-year")
            }

            WobbleCard(tint: Candy.mint, tilt: 0.6) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Per cup")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        BigNumber(value: store.data.costPerCup.map { kr($0) } ?? "—",
                                  caption: "beans only", tint: Candy.mint)
                        BigNumber(value: store.data.costPerCupWithGear.map { kr($0) } ?? "—",
                                  caption: "with the gear", tint: Candy.grape)
                        BigNumber(value: "\(store.data.liveShots.count)",
                                  caption: "cups made", tint: Candy.sky)
                    }
                    Text("The gear is a one-off, so the first number is the one that tells you what this morning cost.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("money-percup")
            }

            if !store.data.warrantiesRunningOut.isEmpty {
                WobbleCard(tint: Candy.apricot, tilt: -0.5) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⏳ Warranty running out")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                        ForEach(store.data.warrantiesRunningOut) { p in
                            Text("\(p.kind.emoji) \(p.displayName) — \(p.warrantyUntil?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("money-warranties")
            }

            Button {
                adding = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 24, weight: .black))
                    Text("Add a purchase")
                    Spacer()
                }
            }
            .buttonStyle(SquashyButton(tint: Candy.blueberry))
            .accessibilityIdentifier("money-add")

            if store.data.livePurchases.isEmpty {
                WobbleCard(tint: Candy.sky, tilt: 0.6) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🛒 No gear logged yet")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                        Text("Machine, grinder, scale, tamper, filters, that subscription. Your bags of beans are already counted above — you only add gear here.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("money-empty")
            }

            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, purchase in
                Button { editing = purchase } label: {
                    PurchaseCard(purchase: purchase,
                                 tilt: index.isMultiple(of: 2) ? -0.8 : 0.8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("purchase-row-\(index)")
                .poppyAppear(Double(index) * 0.03)
            }

            if store.sinkCount > 0 {
                NavigationLinkless(label: "🚰 The Sink",
                                   subtitle: "\(store.sinkCount) rinsed, waiting 30 days",
                                   tint: Candy.sky,
                                   identifier: "money-sink") {
                    SinkView()
                }
            }
        }
        .sheet(isPresented: $adding) { PurchaseEditor(purchase: Purchase()) }
        .sheet(item: $editing) { PurchaseEditor(purchase: $0) }
    }

    private var sorted: [Purchase] {
        store.data.livePurchases.sorted { $0.date > $1.date }
    }

    private func kr(_ v: Double) -> String {
        v >= 10000 ? String(format: "%.0fk", v / 1000) : String(format: "%.0f", v)
    }
}

struct PurchaseCard: View {
    let purchase: Purchase
    var tilt: Double

    private var tint: Color { purchase.kind.tint }

    var body: some View {
        WobbleCard(tint: tint, tilt: tilt) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(purchase.kind.emoji).font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(purchase.displayName)
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.cocoa)
                        Text(purchase.date.formatted(date: .abbreviated, time: .omitted)
                             + (purchase.shop.isEmpty ? "" : " · \(purchase.shop)"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(Coach.trim(purchase.priceSEK)) kr")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(tint)
                }
                FlowRow(spacing: 6) {
                    Chip(text: purchase.kind.title, tint: tint)
                    if purchase.warrantyIsLive, let until = purchase.warrantyUntil {
                        Chip(text: "🛡 to \(until.formatted(date: .abbreviated, time: .omitted))",
                             tint: Candy.mint)
                    }
                }
                if !purchase.notes.isEmpty {
                    Text(purchase.notes)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
            }
        }
    }
}

// MARK: - Purchase editor

struct PurchaseEditor: View {
    @EnvironmentObject private var store: CoffeeStore
    @Environment(\.dismiss) private var dismiss
    @State var purchase: Purchase
    @State private var hasWarranty = false
    @State private var warrantyUntil = Calendar.current.date(byAdding: .year, value: 2,
                                                             to: Date()) ?? Date()
    @State private var confirmRinse = false

    private var isNew: Bool { store.data.purchases.allSatisfy { $0.id != purchase.id } }

    var body: some View {
        ZStack {
            CoffeeBackground()
            Screen(emoji: "🛒", title: isNew ? "New purchase" : "The purchase") {

                WobbleCard(tint: Candy.blueberry, tilt: -0.5) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📦 What kind of thing?")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                        FlowRow(spacing: 8) {
                            ForEach(PurchaseKind.allCases) { kind in
                                let on = purchase.kind == kind
                                Button { purchase.kind = kind } label: {
                                    HStack(spacing: 4) {
                                        Text(kind.emoji)
                                        Text(kind.title)
                                    }
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundStyle(on ? .white : Candy.cocoa)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Capsule().fill(on
                                        ? kind.tint
                                        : Color.white.opacity(0.7)))
                                    .overlay(Capsule().strokeBorder(
                                        kind.tint.opacity(0.6), lineWidth: 2))
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("purchase-kind-\(kind.rawValue)")
                            }
                        }
                        FatField(label: "What is it?", text: $purchase.what,
                                 tint: Candy.blueberry, identifier: "purchase-what")
                        FatField(label: "Where from?", text: $purchase.shop,
                                 tint: Candy.blueberry, identifier: "purchase-shop")
                    }
                }

                WobbleCard(tint: Candy.mango, tilt: 0.5) {
                    VStack(alignment: .leading, spacing: 8) {
                        NumberDial(label: "Price", unit: "kr", value: $purchase.priceSEK,
                                   step: 50, range: 0...200000, tint: Candy.mango,
                                   identifier: "purchase-price")
                        DatePicker("Bought on", selection: $purchase.date,
                                   displayedComponents: .date)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .accessibilityIdentifier("purchase-date")
                        Toggle(isOn: $hasWarranty) {
                            Text("Warranty until")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                        }
                        .tint(Candy.mint)
                        .accessibilityIdentifier("purchase-has-warranty")
                        if hasWarranty {
                            DatePicker("", selection: $warrantyUntil,
                                       displayedComponents: .date)
                                .labelsHidden()
                                .accessibilityIdentifier("purchase-warranty")
                        }
                        FatField(label: "Notes", text: $purchase.notes,
                                 tint: Candy.mango, identifier: "purchase-notes")
                    }
                }

                if !isNew {
                    Button { confirmRinse = true } label: {
                        HStack {
                            Image(systemName: "drop.circle.fill").font(.system(size: 22, weight: .black))
                            Text("Rinse it into the Sink")
                            Spacer()
                        }
                    }
                    .buttonStyle(SquashyButton(tint: Candy.sky))
                    .accessibilityIdentifier("purchase-rinse")
                }
            } bar: {
                StickyBar(saveTitle: "Save the purchase", tint: Candy.blueberry,
                          saveIdentifier: "purchase-save", closeIdentifier: "purchase-close",
                          save: {
                              purchase.warrantyUntil = hasWarranty ? warrantyUntil : nil
                              store.upsert(purchase)
                              dismiss()
                          },
                          close: { dismiss() })
            }
        }
        .onAppear {
            if let until = purchase.warrantyUntil {
                hasWarranty = true
                warrantyUntil = until
            }
        }
        .alert("Rinse this purchase?", isPresented: $confirmRinse) {
            Button("Rinse it", role: .destructive) {
                store.rinse(purchase)
                dismiss()
            }
            Button("Keep it", role: .cancel) { }
        } message: {
            Text("It waits 30 days in the Sink.")
        }
    }
}
