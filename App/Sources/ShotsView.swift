import SwiftUI

struct ShotsView: View {
    @EnvironmentObject private var store: CoffeeStore
    @State private var editing: Shot?
    @State private var adding = false

    var body: some View {
        Screen(emoji: "🎛", title: "Shots") {
            Button {
                adding = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 24, weight: .black))
                    Text("Log a shot")
                    Spacer()
                }
            }
            .buttonStyle(SquashyButton(tint: Candy.bubblegum))
            .accessibilityIdentifier("shots-add")

            // What v1.1 brings. Shown so nothing feels missing by accident.
            WobbleCard(tint: Candy.grape, tilt: 0.6) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🌀 Ways to make it")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                    FlowRow(spacing: 8) {
                        ForEach(BrewMethod.allCases) { method in
                            HStack(spacing: 4) {
                                Image(systemName: method.symbol)
                                Text(method.title)
                                if !method.isLive { Text("soon").opacity(0.7) }
                            }
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(method.isLive ? .white : Candy.cocoa.opacity(0.6))
                            .padding(.vertical, 7).padding(.horizontal, 11)
                            .background(Capsule().fill(method.isLive
                                                       ? Candy.forSeed(method.rawValue)
                                                       : Color.white.opacity(0.6)))
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
        .accessibilityIdentifier("shots-methods")

            if store.data.liveShots.isEmpty {
                WobbleCard(tint: Candy.mango, tilt: -0.6) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🎛 No shots yet")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                        Text("Log the next one you pull. Grind, grams in, grams out, seconds — then two sliders for how it tasted.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                }
                .accessibilityElement(children: .contain)
        .accessibilityIdentifier("shots-empty")
            }

            ForEach(Array(sortedShots.enumerated()), id: \.element.id) { index, shot in
                Button { editing = shot } label: {
                    ShotCard(shot: shot, tilt: index.isMultiple(of: 2) ? 0.8 : -0.8)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("shot-row-\(index)")
                .poppyAppear(Double(index) * 0.03)
            }
        }
        .sheet(isPresented: $adding) { ShotEditor(shot: store.draftShot(beanID: nil)) }
        .sheet(item: $editing) { ShotEditor(shot: $0) }
    }

    private var sortedShots: [Shot] {
        store.data.liveShots.sorted { $0.date > $1.date }
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
                        Text(shot.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(shot.ratioText)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(tint)
                }
                HStack(spacing: 6) {
                    Chip(text: "grind \(Coach.trim(shot.grind))", tint: Candy.blueberry)
                    Chip(text: "\(Coach.trim(shot.doseGrams))→\(Coach.trim(shot.yieldGrams)) g", tint: Candy.grape)
                    Chip(text: "\(Coach.trim(shot.seconds)) s", tint: Candy.sky)
                }
                if !shot.note.isEmpty {
                    Text(shot.note)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
            }
        }
    }
}

// MARK: - The dial-in sheet

struct ShotEditor: View {
    @EnvironmentObject private var store: CoffeeStore
    @Environment(\.dismiss) private var dismiss
    @State var shot: Shot
    @State private var confirmRinse = false

    private var isNew: Bool { store.data.shots.allSatisfy { $0.id != shot.id } }
    private var advice: Advice { Coach.advise(for: shot) }

    var body: some View {
        ZStack {
            CoffeeBackground()
            Screen(emoji: "🎛", title: isNew ? "Pull a shot" : "The shot") {

                // Which bag.
                WobbleCard(tint: Candy.mint, tilt: -0.5) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🫘 Which bag?")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                        if store.data.liveBeans.isEmpty {
                            Text("No bags yet — log the shot anyway and attach a bag later.")
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

                // The numbers.
                WobbleCard(tint: Candy.blueberry, tilt: 0.5) {
                    VStack(alignment: .leading, spacing: 2) {
                        NumberDial(label: "Grind setting", unit: "", value: $shot.grind,
                                   step: 0.5, range: 0...100, tint: Candy.blueberry,
                                   identifier: "shot-grind")
                        NumberDial(label: "Dose in", unit: "g", value: $shot.doseGrams,
                                   step: 0.5, range: 0...60, tint: Candy.grape,
                                   identifier: "shot-dose")
                        NumberDial(label: "Yield out", unit: "g", value: $shot.yieldGrams,
                                   step: 1, range: 0...200, tint: Candy.bubblegum,
                                   identifier: "shot-yield")
                        NumberDial(label: "Time", unit: "s", value: $shot.seconds,
                                   step: 1, range: 0...180, tint: Candy.sky,
                                   identifier: "shot-seconds")
                        NumberDial(label: "Water", unit: "°C", value: $shot.tempC,
                                   step: 1, range: 70...100, tint: Candy.apricot,
                                   identifier: "shot-temp")
                        NumberDial(label: "Pre-infusion", unit: "s", value: $shot.preInfusionSeconds,
                                   step: 1, range: 0...60, tint: Candy.mint,
                                   identifier: "shot-preinfusion")
                    }
                }

                // Works itself out while you type.
                WobbleCard(tint: Candy.mango, tilt: -0.7) {
                    HStack {
                        BigNumber(value: shot.ratioText, caption: "ratio", tint: Candy.mango)
                        BigNumber(value: shot.flowGramsPerSecond.map { String(format: "%.1f", $0) } ?? "—",
                                  caption: "g per second", tint: Candy.apricot)
                    }
                    .accessibilityIdentifier("shot-computed")
                }

                // How it tasted.
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

                // The coach, live, before you even save.
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
                StickyBar(saveTitle: "Save the shot", tint: Candy.bubblegum,
                          saveIdentifier: "shot-save", closeIdentifier: "shot-close",
                          save: { store.upsert(shot); dismiss() },
                          close: { dismiss() })
            }
        }
        .alert("Rinse this shot?", isPresented: $confirmRinse) {
            Button("Rinse it", role: .destructive) {
                store.rinse(shot)
                dismiss()
            }
            Button("Keep it", role: .cancel) { }
        } message: {
            Text("It waits 30 days in the Sink.")
        }
    }
}
