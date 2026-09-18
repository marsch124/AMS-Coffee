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
            Screen(title: "Your kit") { CaseMark(size: 38) } content: {

                if !store.data.warrantiesRunningOut.isEmpty {
                    WobbleCard(tint: Candy.apricot) {
                        VStack(alignment: .leading, spacing: 9) {
                            Text("Warranty running out")
                                .font(.system(size: 19, weight: .black, design: .rounded))
                            ForEach(store.data.warrantiesRunningOut) { p in
                                Text("\(p.displayName) — \(p.warrantyUntil?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("kit-warranties")
                }

                if store.data.livePurchases.isEmpty {
                    WobbleCard(tint: Candy.sky) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Nothing here yet")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                            Text("Your machine, grinder, scales, filters. Keep a photo of the receipt with each one and the warranty date will find you before it runs out.")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("kit-empty")
                }

                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, item in
                    Button { editing = item } label: {
                        KitCard(item: item, )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("kit-row-\(index)")
                    .poppyAppear(Double(index) * 0.03)
                }
            } bar: {
                StickyBar(saveTitle: "Add something", tint: Candy.apricot,
                          saveIdentifier: "kit-add", closeIdentifier: "kit-close",
                          save: { adding = true }, close: { dismiss() })
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

    private var tint: Color { item.kind.tint }

    var body: some View {
        WobbleCard(tint: tint) {
            HStack(spacing: 14) {
                if let id = item.photoID {
                    PhotoImage(data: store.photo(id), corner: 16)
                        .frame(width: 78, height: 78)
                        .clipped()
                } else {
                    KitKindMark(kind: item.kind, size: 44).foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.displayName)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(Candy.ink)
                    Text(item.date.formatted(date: .abbreviated, time: .omitted)
                         + (item.shop.isEmpty ? "" : " · \(item.shop)"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Candy.inkSoft)
                    FlowRow(spacing: 7) {
                        Chip(text: item.kind.title, tint: tint)
                        if item.warrantyIsLive, let until = item.warrantyUntil {
                            Chip(text: "to \(until.formatted(date: .abbreviated, time: .omitted))",
                                 tint: Candy.mint) { ShieldMark(size: 18) }
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
            Screen(title: isNew ? "Something new" : "Your kit") { CaseMark(size: 38) } content: {

                WobbleCard(tint: Candy.apricot) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("What kind of thing?")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                        FlowRow(spacing: 9) {
                            ForEach(PurchaseKind.allCases) { kind in
                                let on = purchase.kind == kind
                                Button { purchase.kind = kind } label: {
                                    HStack(spacing: 8) {
                                        KitKindMark(kind: kind, size: 22)
                                        Text(kind.title)
                                    }
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .foregroundStyle(on ? .white : Candy.ink)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(Capsule().fill(on ? kind.tint : Candy.field))
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

                WobbleCard(tint: Candy.sky) {
                    PhotoRow(title: "The receipt",
                             hint: "Keep it, so you never hunt for it",
                             photoID: $purchase.photoID,
                             identifier: "kit-photo")
                }

                WobbleCard(tint: Candy.mint) {
                    VStack(alignment: .leading, spacing: 10) {
                        DatePicker("Got it on", selection: $purchase.date,
                                   displayedComponents: .date)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .accessibilityIdentifier("kit-date")
                        Toggle(isOn: $hasWarranty) {
                            Text("Warranty until")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
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
                    DangerButton(title: "Remove", identifier: "kit-rinse") {
                        confirmRinse = true
                    }
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
        .alert("Remove this?", isPresented: $confirmRinse) {
            Button("Remove", role: .destructive) { store.rinse(purchase); dismiss() }
            Button("Keep it", role: .cancel) { }
        } message: {
            Text("It waits 30 days in the Sink.")
        }
    }
}
