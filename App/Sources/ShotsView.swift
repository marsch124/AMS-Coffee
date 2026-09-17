import SwiftUI

struct ShotsView: View {
    @EnvironmentObject private var store: CoffeeStore
    @State private var editing: Shot?
    @State private var newMethod: BrewMethod?
    @State private var filter: BrewMethod?

    var body: some View {
        Screen(emoji: "🎛", title: "Brews") {
            Button {
                newMethod = .espresso
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "cup.and.saucer.fill").font(.system(size: 24, weight: .black))
                    Text("Pull a shot")
                    Spacer()
                }
            }
            .buttonStyle(SquashyButton(tint: Candy.bubblegum))
            .accessibilityIdentifier("shots-add")

            // Every method, and every one of them works now.
            WobbleCard(tint: Candy.grape, tilt: 0.6) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("🌀 Or make it another way")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                    FlowRow(spacing: 8) {
                        ForEach(BrewMethod.allCases.filter { $0 != .espresso }) { method in
                            Button {
                                newMethod = method
                            } label: {
                                HStack(spacing: 5) {
                                    Text(method.emoji)
                                    Text(method.title)
                                }
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.vertical, 9)
                                .padding(.horizontal, 13)
                                .background(Capsule().fill(method.tint))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("method-\(method.rawValue)")
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("shots-methods")
            }

            if !usedMethods.isEmpty {
                FlowRow(spacing: 8) {
                    Button { filter = nil } label: {
                        Chip(text: "All", tint: filter == nil ? Candy.cocoa : Candy.blueberry)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("filter-all")

                    ForEach(usedMethods) { method in
                        Button { filter = (filter == method) ? nil : method } label: {
                            Chip(text: "\(method.emoji) \(count(method))",
                                 tint: filter == method ? Candy.cocoa : method.tint)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("filter-\(method.rawValue)")
                    }
                }
            }

            if store.data.liveShots.isEmpty {
                WobbleCard(tint: Candy.mango, tilt: -0.6) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🎛 Nothing brewed yet")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                        Text("Log the next one you make. The numbers for each method arrive already filled in, so most days you change nothing and press save.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("shots-empty")
            }

            ForEach(Array(shown.enumerated()), id: \.element.id) { index, shot in
                Button { editing = shot } label: {
                    ShotCard(shot: shot, tilt: index.isMultiple(of: 2) ? 0.8 : -0.8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("shot-row-\(index)")
                .poppyAppear(Double(index) * 0.03)
            }
        }
        .sheet(item: $newMethod) { method in
            ShotEditor(shot: store.draftShot(beanID: nil, method: method))
        }
        .sheet(item: $editing) { ShotEditor(shot: $0) }
    }

    private var sorted: [Shot] { store.data.liveShots.sorted { $0.date > $1.date } }
    private var shown: [Shot] {
        guard let filter else { return sorted }
        return sorted.filter { $0.method == filter }
    }
    private var usedMethods: [BrewMethod] {
        let used = Set(store.data.liveShots.map(\.method))
        return BrewMethod.allCases.filter { used.contains($0) }
    }
    private func count(_ method: BrewMethod) -> Int {
        store.data.liveShots.filter { $0.method == method }.count
    }
}

struct ShotCard: View {
    @EnvironmentObject private var store: CoffeeStore
    let shot: Shot
    var tilt: Double

    private var tint: Color {
        switch shot.light {
        case .green: return Candy.mint
        case .amber: return Candy.mango
        case .red:   return Candy.bubblegum
        }
    }

    var body: some View {
        WobbleCard(tint: tint, tilt: tilt) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(shot.light.emoji).font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(store.data.bean(shot.beanID)?.displayName ?? "No bag")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.cocoa)
                        Text("\(shot.method.emoji) \(shot.method.title) · \(shot.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(shot.ratioText)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(tint)
                }
                FlowRow(spacing: 6) {
                    Chip(text: "grind \(Coach.trim(shot.grind))", tint: Candy.blueberry)
                    Chip(text: shot.method.isWeighedByWaterIn
                         ? "\(Coach.trim(shot.doseGrams)) g + \(Coach.trim(shot.waterGrams)) g"
                         : "\(Coach.trim(shot.doseGrams))→\(Coach.trim(shot.yieldGrams)) g",
                         tint: Candy.grape)
                    Chip(text: shot.timeText, tint: Candy.sky)
                }
                if !shot.note.isEmpty {
                    Text(shot.note)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
            }
        }
    }
}

// MARK: - The brew editor

struct ShotEditor: View {
    @EnvironmentObject private var store: CoffeeStore
    @Environment(\.dismiss) private var dismiss
    @State var shot: Shot
    @State private var confirmRinse = false

    private var isNew: Bool { store.data.shots.allSatisfy { $0.id != shot.id } }
    private var advice: Advice { Coach.advise(for: shot) }
    private var tint: Color { shot.method.tint }

    var body: some View {
        ZStack {
            CoffeeBackground()
            Screen(emoji: shot.method.emoji,
                   title: isNew ? shot.method.title : "The \(shot.method.title.lowercased())") {

                WobbleCard(tint: Candy.mint, tilt: -0.5) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🫘 Which bag?")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                        if store.data.liveBeans.isEmpty {
                            Text("No bags yet — log the brew anyway and attach a bag later.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("", selection: $shot.beanID) {
                                Text("No bag").tag(UUID?.none)
                                ForEach(store.data.liveBeans) { bean in
                                    Text(bean.displayName).tag(Optional(bean.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Candy.mint)
                            .accessibilityIdentifier("shot-bean")
                        }
                    }
                }

                // Only the dials this method actually uses.
                WobbleCard(tint: tint, tilt: 0.5) {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(shot.method.fields) { field in
                            NumberDial(label: field.label,
                                       unit: field.unit,
                                       value: binding(field),
                                       step: field.step,
                                       range: field.range,
                                       tint: field.tint,
                                       identifier: field.identifier)
                        }
                        if shot.method.hasInvertedSwitch {
                            Toggle(isOn: $shot.inverted) {
                                Text("Upside down")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                            }
                            .tint(tint)
                            .accessibilityIdentifier("shot-inverted")
                        }
                    }
                }

                WobbleCard(tint: Candy.mango, tilt: -0.7) {
                    HStack {
                        BigNumber(value: shot.ratioText, caption: "ratio", tint: Candy.mango)
                        if shot.method == .espresso {
                            BigNumber(value: shot.flowGramsPerSecond.map { String(format: "%.1f", $0) } ?? "—",
                                      caption: "g per second", tint: Candy.apricot)
                        } else {
                            BigNumber(value: shot.timeText, caption: "brew time", tint: Candy.apricot)
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("shot-computed")
                }

                WobbleCard(tint: Candy.bubblegum, tilt: 0.6) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("👅 How was it?")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                        TasteSlider(leftEmoji: "🍋", leftWord: "Sour",
                                    rightEmoji: "🫒", rightWord: "Bitter",
                                    value: $shot.sourBitter, tint: Candy.bubblegum,
                                    identifier: "shot-sourbitter")
                        TasteSlider(leftEmoji: "💧", leftWord: "Thin",
                                    rightEmoji: "🍯", rightWord: "Syrupy",
                                    value: $shot.thinSyrupy, tint: Candy.grape,
                                    identifier: "shot-thinsyrupy")
                        LightPicker(light: $shot.light)
                        FatField(label: "Note (optional)", text: $shot.note,
                                 tint: Candy.bubblegum, identifier: "shot-note")
                    }
                }

                WobbleCard(tint: Candy.sky, tilt: -0.5) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🧑‍🏫 Next time")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text("\(advice.emoji) \(advice.headline)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.sky)
                        Text(advice.detail)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("shot-advice")
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
                    .accessibilityIdentifier("shot-rinse")
                }
            } bar: {
                StickyBar(saveTitle: isNew ? "Save it" : "Save the changes",
                          tint: Candy.bubblegum,
                          saveIdentifier: "shot-save", closeIdentifier: "shot-close",
                          save: { store.upsert(shot); dismiss() },
                          close: { dismiss() })
            }
        }
        .alert("Rinse this brew?", isPresented: $confirmRinse) {
            Button("Rinse it", role: .destructive) {
                store.rinse(shot)
                dismiss()
            }
            Button("Keep it", role: .cancel) { }
        } message: {
            Text("It waits 30 days in the Sink.")
        }
    }

    private func binding(_ field: BrewField) -> Binding<Double> {
        switch field {
        case .grind:         return $shot.grind
        case .dose:          return $shot.doseGrams
        case .yield:         return $shot.yieldGrams
        case .water:         return $shot.waterGrams
        case .seconds:       return $shot.seconds
        case .temp:          return $shot.tempC
        case .preInfusion:   return $shot.preInfusionSeconds
        case .bloomWater:    return $shot.bloomGrams
        case .bloomSeconds:  return $shot.bloomSeconds
        case .pours:         return $shot.pours
        case .steepMinutes:  return $shot.steepMinutes
        case .steepHours:    return $shot.steepHours
        case .plungeSeconds: return $shot.plungeSeconds
        }
    }
}
