import SwiftUI

/// The things you brew with. Machine, grinder, scales, that third tamper.
///
/// This used to be a tab called Money, full of totals and cost per cup. That
/// was the wrong idea about what this app is for: it is about the coffee, not
/// the accounting. What it cost is a quiet detail on one line, and no number
/// anywhere is added up.
struct KitView: View {
    @EnvironmentObject private var store: CoffeeStore
    @Environment(\.dismiss) private var dismiss
    @State private var editing: Purchase?
    @State private var adding = false

    var body: some View {
        ZStack {
            CoffeeBackground()
            Screen(emoji: "🧰", title: "Your kit") {

                if !store.data.warrantiesRunningOut.isEmpty {
                    WobbleCard(tint: Candy.apricot, tilt: -0.5) {
                        VStack(alignment: .leading, spacing: 9) {
                            Text("⏳ Warranty running out")
                                .font(.system(size: 19, weight: .black, design: .rounded))
                            ForEach(store.data.warrantiesRunningOut) { p in
                                Text("\(p.kind.emoji) \(p.displayName) — \(p.warrantyUntil?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("kit-warranties")
                }

                Button { adding = true } label: {
                    HStack(spacing: 12) {
                        PlusMark(size: 28, weight: 6)
                        Text("Add something")
                        Spacer()
                    }
                }
                .buttonStyle(SquashyButton(tint: Candy.apricot))
                .accessibilityIdentifier("kit-add")

                if store.data.livePurchases.isEmpty {
                    WobbleCard(tint: Candy.sky, tilt: 0.6) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("🧰 Nothing here yet")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                            Text("Your machine, grinder, scales, filters. Keep a photo of the receipt with each one and the warranty date will find you before it runs out.")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("kit-empty")
                }

                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, item in
                    Button { editing = item } label: {
                        KitCard(item: item, tilt: index.isMultiple(of: 2) ? -0.8 : 0.8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("kit-row-\(index)")
                    .poppyAppear(Double(index) * 0.03)
                }
            } bar: {
                StickyBar(saveTitle: "Done", tint: Candy.apricot,
                          saveIdentifier: "kit-done", closeIdentifier: "kit-close",
                          save: { dismiss() }, close: { dismiss() })
            }
        }
        .sheet(isPresented: $adding) { KitEditor(purchase: Purchase()) }
        .sheet(item: $editing) { KitEditor(purchase: $0) }
    }

    private var sorted: [Purchase] {
        store.data.livePurchases.sorted { $0.date > $1.date }
    }
}

struct KitCard: View {
    @EnvironmentObject private var store: CoffeeStore
    let item: Purchase
    var tilt: Double

    private var tint: Color { item.kind.tint }

    var body: some View {
        WobbleCard(tint: tint, tilt: tilt) {
            HStack(spacing: 14) {
                if let id = item.photoID {
                    PhotoImage(data: store.photo(id), corner: 16)
                        .frame(width: 78, height: 78)
                        .clipped()
                } else {
                    Text(item.kind.emoji).font(.system(size: 40))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.displayName)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(Candy.cocoa)
                    Text(item.date.formatted(date: .abbreviated, time: .omitted)
                         + (item.shop.isEmpty ? "" : " · \(item.shop)"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    FlowRow(spacing: 7) {
                        Chip(text: item.kind.title, tint: tint)
                        if item.warrantyIsLive, let until = item.warrantyUntil {
                            Chip(text: "to \(until.formatted(date: .abbreviated, time: .omitted))",
                                 tint: Candy.mint, symbol: "🛡")
                        }
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Editing one

struct KitEditor: View {
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
            Screen(emoji: "🧰", title: isNew ? "Something new" : "Your kit") {

                WobbleCard(tint: Candy.apricot, tilt: -0.5) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("📦 What kind of thing?")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                        FlowRow(spacing: 9) {
                            ForEach(PurchaseKind.allCases) { kind in
                                let on = purchase.kind == kind
                                Button { purchase.kind = kind } label: {
                                    HStack(spacing: 6) {
                                        Text(kind.emoji).font(.system(size: 20))
                                        Text(kind.title)
                                    }
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundStyle(on ? .white : Candy.cocoa)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(Capsule().fill(on ? kind.tint : Color.white.opacity(0.7)))
                                    .overlay(Capsule().strokeBorder(kind.tint.opacity(0.6), lineWidth: 2))
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("kit-kind-\(kind.rawValue)")
                            }
                        }
                        FatField(label: "What is it?", text: $purchase.what,
                                 tint: Candy.apricot, identifier: "kit-what")
                        FatField(label: "Where from?", text: $purchase.shop,
                                 tint: Candy.apricot, identifier: "kit-shop")
                    }
                }

                WobbleCard(tint: Candy.sky, tilt: 0.5) {
                    PhotoRow(title: "🧾 The receipt",
                             hint: "Keep it, so you never hunt for it",
                             photoID: $purchase.photoID,
                             identifier: "kit-photo")
                }

                WobbleCard(tint: Candy.mint, tilt: -0.6) {
                    VStack(alignment: .leading, spacing: 10) {
                        DatePicker("Got it on", selection: $purchase.date,
                                   displayedComponents: .date)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .accessibilityIdentifier("kit-date")
                        Toggle(isOn: $hasWarranty) {
                            Text("Warranty until")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                        .tint(Candy.mint)
                        .accessibilityIdentifier("kit-has-warranty")
                        if hasWarranty {
                            DatePicker("", selection: $warrantyUntil, displayedComponents: .date)
                                .labelsHidden()
                                .accessibilityIdentifier("kit-warranty")
                        }
                        NumberDial(label: "What it cost, if you want it noted",
                                   unit: "kr", value: $purchase.priceSEK,
                                   step: 50, range: 0...200000, tint: Candy.mint,
                                   identifier: "kit-price")
                        FatField(label: "Notes", text: $purchase.notes,
                                 tint: Candy.mint, identifier: "kit-notes")
                    }
                }

                if !isNew {
                    Button { confirmRinse = true } label: {
                        HStack(spacing: 12) {
                            Text("🚰").font(.system(size: 26))
                            Text("Rinse it into the Sink")
                            Spacer()
                        }
                    }
                    .buttonStyle(SquashyButton(tint: Candy.sky))
                    .accessibilityIdentifier("kit-rinse")
                }
            } bar: {
                StickyBar(saveTitle: "Save it", tint: Candy.apricot,
                          saveIdentifier: "kit-save", closeIdentifier: "kit-close-editor",
                          save: {
                              purchase.warrantyUntil = hasWarranty ? warrantyUntil : nil
                              store.upsert(purchase)
                              dismiss()
                          },
                          close: { dismiss() })
            }
        }
        .onAppear {
            if let until = purchase.warrantyUntil { hasWarranty = true; warrantyUntil = until }
        }
        .alert("Rinse this?", isPresented: $confirmRinse) {
            Button("Rinse it", role: .destructive) { store.rinse(purchase); dismiss() }
            Button("Keep it", role: .cancel) { }
        } message: {
            Text("It waits 30 days in the Sink.")
        }
    }
}
