import SwiftUI

struct ShotsView: View {
    @EnvironmentObject private var store: CoffeeStore
    @State private var editing: Shot?
    @State private var newMethod: BrewMethod?
    @State private var filter: BrewMethod?

    var body: some View {
        Screen(title: "Brews") { DialMark(size: 38) } content: {
            // Every method, and every one of them works now.
            WobbleCard(tint: Candy.grape) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Or make it another way")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                    FlowRow(spacing: 8) {
                        ForEach(BrewMethod.allCases.filter { $0 != .espresso }) { method in
                            Button {
                                newMethod = method
                            } label: {
                                HStack(spacing: 8) {
                                    MethodMark(method: method, size: 24)
                                    Text(method.title)
                                }
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
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
                        Chip(text: "All", tint: filter == nil ? Candy.ink : Candy.blueberry)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("filter-all")

                    ForEach(usedMethods) { method in
                        Button { filter = (filter == method) ? nil : method } label: {
                            Chip(text: "\(count(method))",
                                 tint: filter == method ? Candy.ink : method.tint) {
                                MethodMark(method: method, size: 20)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("filter-\(method.rawValue)")
                    }
                }
            }

            if store.data.liveShots.isEmpty {
                WobbleCard(tint: Candy.mango) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nothing brewed yet")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                        Text("Log the next one you make. The numbers for each method arrive already filled in, so most days you change nothing and press save.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("shots-empty")
            }

            ForEach(Array(shown.enumerated()), id: \.element.id) { index, shot in
                Button { editing = shot } label: {
                    ShotCard(shot: shot, )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("shot-row-\(index)")
                .poppyAppear(Double(index) * 0.03)
            }
        } bar: {
            AddBar(title: "Pull a shot", tint: Candy.bubblegum, identifier: "shots-add") {
                newMethod = .espresso
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

    private var tint: Color {
        switch shot.light {
        case .green: return Candy.mint
        case .amber: return Candy.mango
        case .red:   return Candy.bubblegum
        }
    }

    var body: some View {
        WobbleCard(tint: tint) {
            VStack(alignment: .leading, spacing: 10) {
                if let photoID = shot.photoID {
                    PhotoImage(data: store.photo(photoID), corner: 18)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
                HStack {
                    LightMark(light: shot.light, size: 30)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(store.data.bean(shot.beanID)?.displayName ?? "No bag")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.ink)
                        Text("\(shot.method.title) · \(shot.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
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
                        .font(.system(size: 17, weight: .medium, design: .rounded))
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
            Screen(title: isNew ? shot.method.title
                                : "The \(shot.method.title.lowercased())") {
                MethodMark(method: shot.method, size: 38)
            } content: {

                WobbleCard(tint: Candy.mint) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Which bag?")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                        if store.data.liveBeans.isEmpty {
                            Text("No bags yet — log the brew anyway and attach a bag later.")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundStyle(Candy.inkSoft)
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

                if shot.method.worthTiming {
                    WobbleCard(tint: Candy.mint) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time it")
                                .font(.system(size: 19, weight: .black, design: .rounded))
                            BrewTimer(seconds: $shot.seconds,
                                      bloomSeconds: shot.method.hasBloom ? $shot.bloomSeconds : nil,
                                      steepMinutes: shot.method.steepsInMinutes ? $shot.steepMinutes : nil)
                            Text(shot.method.hasBloom
                                 ? "Start when the water hits, tap Bloom done when you carry on pouring, and Stop at the end. The numbers below fill themselves in."
                                 : "Start when it starts, Stop when it stops. The time below fills itself in.")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(Candy.inkSoft)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("shot-timer")
                    }
                }

                // Only the dials this method actually uses.
                WobbleCard(tint: tint) {
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
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                            }
                            .tint(tint)
                            .accessibilityIdentifier("shot-inverted")
                        }
                    }
                }

                WobbleCard(tint: Candy.mango) {
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

                WobbleCard(tint: Candy.grape) {
                    PhotoRow(title: "A photo of it",
                             hint: "The crema, the bed, the cup",
                             photoID: $shot.photoID,
                             identifier: "shot-photo")
                }

                WobbleCard(tint: Candy.bubblegum) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("How was it?")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                        TasteSlider(leftWord: "Sour", rightWord: "Bitter",
                                    value: $shot.sourBitter, tint: Candy.bubblegum,
                                    identifier: "shot-sourbitter")
                        TasteSlider(leftWord: "Thin", rightWord: "Syrupy",
                                    value: $shot.thinSyrupy, tint: Candy.grape,
                                    identifier: "shot-thinsyrupy")
                        LightPicker(light: $shot.light)
                        FatField(label: "Note (optional)", text: $shot.note,
                                 tint: Candy.bubblegum, identifier: "shot-note")
                    }
                }

                WobbleCard(tint: Candy.sky) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next time")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                        Text(advice.headline)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.sky)
                        Text(advice.detail)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("shot-advice")
                }

                if !isNew {
                    DangerButton(title: "Remove", identifier: "shot-rinse") {
                        confirmRinse = true
                    }
                }
            } bar: {
                StickyBar(saveTitle: isNew ? "Save it" : "Save the changes",
                          tint: Candy.bubblegum,
                          saveIdentifier: "shot-save", closeIdentifier: "shot-close",
                          save: { store.upsert(shot); dismiss() },
                          close: { dismiss() })
            }
        }
        .alert("Remove this brew?", isPresented: $confirmRinse) {
            Button("Remove", role: .destructive) {
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
