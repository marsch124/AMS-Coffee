import SwiftUI

struct BagsView: View {
    @EnvironmentObject private var store: CoffeeStore
    @State private var editing: Bean?
    @State private var adding = false

    var body: some View {
        Screen(title: "Beans") { BeanMark(size: 38) } content: {
            if store.data.liveBeans.isEmpty {
                WobbleCard(tint: Candy.mango) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No bags yet")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                        Text("Add the bag sitting next to your machine. Roaster, name, weight, price — that is enough to start.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                    }
                }
                .accessibilityElement(children: .contain)
        .accessibilityIdentifier("bags-empty")
            }

            ForEach(Array(sortedBeans.enumerated()), id: \.element.id) { index, bean in
                Button { editing = bean } label: {
                    BagCard(bean: bean, )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("bag-row-\(index)")
                .poppyAppear(Double(index) * 0.04)
            }

        } bar: {
            AddBar(title: "Add a bag", tint: Candy.mint, identifier: "bags-add") {
                adding = true
            }
        }
        .sheet(isPresented: $adding) { BagEditor(bean: Bean()) }
        .sheet(item: $editing) { BagEditor(bean: $0) }
    }

    private var sortedBeans: [Bean] {
        store.data.liveBeans.sorted { a, b in
            let la = store.data.gramsLeft(for: a), lb = store.data.gramsLeft(for: b)
            if (la > 0) != (lb > 0) { return la > 0 }
            return a.createdAt > b.createdAt
        }
    }
}

struct BagCard: View {
    @EnvironmentObject private var store: CoffeeStore
    let bean: Bean

    private var tint: Color { Candy.forSeed(bean.id.uuidString) }

    var body: some View {
        WobbleCard(tint: tint) {
            VStack(alignment: .leading, spacing: 10) {
                if let photoID = bean.photoID {
                    PhotoImage(data: store.photo(photoID), corner: 18)
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 1) {
                        if !bean.roaster.isEmpty {
                            Text(bean.roaster.uppercased())
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                                .foregroundStyle(tint)
                        }
                        Text(bean.displayName)
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.ink)
                    }
                    Spacer()
                    VerdictMark(verdict: bean.verdict, size: 32)
                        .foregroundStyle(bean.verdict == .buyAgain ? Candy.mango
                                         : bean.verdict == .never ? Candy.bubblegum
                                         : Candy.ink.opacity(0.35))
                }

                // Grams left, as a bar you can read across the kitchen.
                let left = store.data.gramsLeft(for: bean)
                let fraction = bean.bagWeightGrams > 0 ? left / bean.bagWeightGrams : 0
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(tint.opacity(0.18))
                        Capsule().fill(tint)
                            .frame(width: max(8, geo.size.width * fraction))
                    }
                }
                .frame(height: 14)

                HStack(spacing: 8) {
                    Chip(text: "\(Int(left)) g left", tint: tint) { BalanceMark(size: 18) }
                    if bean.rating > 0 {
                        HStack(spacing: 3) {
                            ForEach(0..<max(bean.rating, 0), id: \.self) { _ in
                                StarMark(size: 17, filled: true)
                            }
                        }
                        .foregroundStyle(Candy.mango)
                    }
                }

                if !bean.flavours.isEmpty {
                    Text(bean.flavours.map(\.title).joined(separator: " · "))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }

                let methods = store.data.methodsUsed(beanID: bean.id)
                if !methods.isEmpty {
                    Text(methods.map(\.title).joined(separator: " · "))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Candy.inkSoft)
                }

                // Stickers.
                HStack(spacing: 6) {
                    if left > 0 && left <= 50 { Text("nearly gone") }
                    if let roast = bean.roastDate,
                       Calendar.current.dateComponents([.day], from: roast, to: Date()).day ?? 99 <= 7 {
                        Text("fresh roast")
                    }
                    if store.data.methodsUsed(beanID: bean.id).contains(where: {
                        store.data.bestShot(beanID: bean.id, method: $0)?.light == .green
                    }) { Text("dialled in") }
                }
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(Candy.inkSoft)
            }
        }
    }
}

// MARK: - Bag editor

struct BagEditor: View {
    @EnvironmentObject private var store: CoffeeStore
    @Environment(\.dismiss) private var dismiss
    @State var bean: Bean
    @State private var hasRoastDate = false
    @State private var roastDate = Date()
    @State private var confirmRinse = false

    private var isNew: Bool { store.data.beans.allSatisfy { $0.id != bean.id } }

    var body: some View {
        ZStack {
            CoffeeBackground()
            Screen(title: isNew ? "A new bag" : "The bag") { BeanMark(size: 38) } content: {
                WobbleCard(tint: Candy.bubblegum) {
                    PhotoRow(title: "The bag",
                             hint: "A photo of the label beats any description",
                             photoID: $bean.photoID,
                             identifier: "bag-photo")
                }

                WobbleCard(tint: Candy.mint) {
                    VStack(alignment: .leading, spacing: 12) {
                        FatField(label: "Roaster", text: $bean.roaster,
                                 tint: Candy.mint, identifier: "bag-roaster")
                        FatField(label: "Name of the bean", text: $bean.name,
                                 tint: Candy.mint, identifier: "bag-name")
                        FatField(label: "Origin", text: $bean.origin,
                                 tint: Candy.mint, identifier: "bag-origin")
                        FatField(label: "Process (washed, natural…)", text: $bean.process,
                                 tint: Candy.mint, identifier: "bag-process")
                    }
                }

                WobbleCard(tint: Candy.blueberry) {
                    VStack(alignment: .leading, spacing: 4) {
                        NumberDial(label: "Bag weight", unit: "g", value: $bean.bagWeightGrams,
                                   step: 50, range: 0...5000, tint: Candy.blueberry,
                                   identifier: "bag-weight")
                        NumberDial(label: "What it cost, if you want it noted",
                                   unit: "kr", value: $bean.priceSEK,
                                   step: 10, range: 0...9999, tint: Candy.blueberry,
                                   identifier: "bag-price")
                        Toggle(isOn: $hasRoastDate) {
                            Text("Roasted on")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                        }
                        .tint(Candy.blueberry)
                        .accessibilityIdentifier("bag-has-roastdate")
                        if hasRoastDate {
                            DatePicker("", selection: $roastDate, displayedComponents: .date)
                                .labelsHidden()
                                .accessibilityIdentifier("bag-roastdate")
                        }
                    }
                }

                WobbleCard(tint: Candy.bubblegum) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What does it taste like?")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                        FlavourWheel(picked: $bean.flavours)
                        StarRating(rating: $bean.rating, identifierPrefix: "bag-star")
                        Picker("", selection: $bean.verdict) {
                            ForEach(Verdict.allCases, id: \.self) { v in
                                Text(v.title).tag(v)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("bag-verdict")
                        FatField(label: "Notes", text: $bean.notes,
                                 tint: Candy.bubblegum, identifier: "bag-notes")
                    }
                }

                if !isNew {
                    DangerButton(title: "Remove", identifier: "bag-rinse") {
                        confirmRinse = true
                    }
                }
            } bar: {
                StickyBar(saveTitle: "Save the bag", tint: Candy.mint,
                          saveIdentifier: "bag-save", closeIdentifier: "bag-close",
                          save: {
                              bean.roastDate = hasRoastDate ? roastDate : nil
                              store.upsert(bean)
                              dismiss()
                          },
                          close: { dismiss() })
            }
        }
        .onAppear {
            if let d = bean.roastDate { hasRoastDate = true; roastDate = d }
        }
        .alert("Remove this bag?", isPresented: $confirmRinse) {
            Button("Remove", role: .destructive) {
                store.rinse(bean)
                dismiss()
            }
            .accessibilityIdentifier("bag-rinse-confirm")
            Button("Keep it", role: .cancel) { }
        } message: {
            Text("It waits 30 days in the Sink, where one tap brings it back.")
        }
    }
}

// MARK: - The Sink

struct SinkView: View {
    @EnvironmentObject private var store: CoffeeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CoffeeBackground()
            Screen(title: "The Sink") { TapMark(size: 38) } content: {
                WobbleCard(tint: Candy.sky) {
                    Text("Rinsed things sit here for 30 days. One tap puts them back where they were.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                }

                ForEach(Array(store.sinkBeans.enumerated()), id: \.element.id) { i, bean in
                    HStack {
                        Text(bean.displayName)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                        Spacer()
                        Button("Put back") { store.unrinse(bean) }
                            .buttonStyle(SquashyButton(tint: Candy.mint))
                            .accessibilityIdentifier("sink-bean-restore-\(i)")
                    }
                }

                ForEach(Array(store.sinkShots.enumerated()), id: \.element.id) { i, shot in
                    HStack {
                        HStack(spacing: 8) {
                            LightMark(light: shot.light, size: 22)
                            MethodMark(method: shot.method, size: 22)
                            Text(shot.ratioText)
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                        }
                        Spacer()
                        Button("Put back") { store.unrinse(shot) }
                            .buttonStyle(SquashyButton(tint: Candy.mint))
                            .accessibilityIdentifier("sink-shot-restore-\(i)")
                    }
                }

                ForEach(Array(store.sinkPurchases.enumerated()), id: \.element.id) { i, purchase in
                    HStack {
                        Text(purchase.displayName)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                        Spacer()
                        Button("Put back") { store.unrinse(purchase) }
                            .buttonStyle(SquashyButton(tint: Candy.mint))
                            .accessibilityIdentifier("sink-purchase-restore-\(i)")
                    }
                }

            } bar: {
                StickyBar(saveTitle: "Done", tint: Candy.sky,
                          saveIdentifier: "sink-done", closeIdentifier: "sink-close",
                          save: { dismiss() }, close: { dismiss() })
            }
        }
    }
}

/// A pill that opens a sheet — simpler than a navigation stack per tab.
struct NavigationLinkless<Content: View>: View {
    let label: String
    let subtitle: String
    let tint: Color
    let identifier: String
    @ViewBuilder var content: Content
    @State private var open = false

    var body: some View {
        Button { open = true } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(tint)
                    Text(subtitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Candy.inkSoft)
                }
                Spacer()
                ChevronMark(size: 26, weight: 5)
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(tint)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Candy.card)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(tint.opacity(0.55), lineWidth: 3)))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .sheet(isPresented: $open) { content }
    }
}
