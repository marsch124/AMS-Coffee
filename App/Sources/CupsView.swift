import SwiftUI
import UniformTypeIdentifiers

struct CupsView: View {
    @EnvironmentObject private var store: CoffeeStore
    @State private var keepsakeName = ""
    @State private var naming = false
    @State private var restoring: Cup?
    @State private var exportURL: URL?
    @State private var importing = false

    var body: some View {
        Screen(title: "Cups") { JarMark(size: 38) } content: {

            WobbleCard(tint: Candy.mint) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Everything is kept safe in cups")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    Text("Every save is poured into a cup, and every cup proves itself by being opened again and counted. A cup holding less than the last one is refused, not written over.")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                    HStack(spacing: 8) {
                        Chip(text: "\(tested) proved", tint: Candy.mint) { TickMark(size: 18) }
                        if untested > 0 {
                            Chip(text: "\(untested) unproven", tint: Candy.apricot) {
                                WarningMark(size: 18)
                            }
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cups-intro")

            if let warning = store.shelf.warning {
                WobbleCard(tint: Candy.apricot) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(warning)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Button("Got it") { store.dismissWarning() }
                            .buttonStyle(SquashyButton(tint: Candy.apricot))
                            .accessibilityIdentifier("cups-dismiss-warning")
                    }
                }
                .accessibilityIdentifier("cups-warning")
            }

            Button {
                keepsakeName = ""
                naming = true
            } label: {
                HStack(spacing: 10) {
                    JarMark(size: 30)
                    Text("Save a cup")
                    Spacer()
                }
            }
            .buttonStyle(SquashyButton(tint: Candy.grape))
            .accessibilityIdentifier("cups-save-keepsake")

            HStack(spacing: 10) {
                Button {
                    exportURL = store.exportFile()
                } label: {
                    HStack(spacing: 10) { TrayArrowMark(size: 24, out: true); Text("Export") }
                }
                .buttonStyle(SquashyButton(tint: Candy.sky))
                .accessibilityIdentifier("cups-export")

                Button {
                    importing = true
                } label: {
                    HStack(spacing: 10) { TrayArrowMark(size: 24, out: false); Text("Import") }
                }
                .buttonStyle(SquashyButton(tint: Candy.blueberry))
                .accessibilityIdentifier("cups-import")
            }

            if let url = exportURL {
                ShareLink(item: url) {
                    Text("Share the file you just made")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                }
                .accessibilityIdentifier("cups-share")
            }

            ForEach(Array(cups.enumerated()), id: \.element.id) { index, cup in
                CupRow(cup: cup, index: index) { restoring = cup }
                    .poppyAppear(Double(index) * 0.03)
            }

            if cups.isEmpty {
                WobbleCard(tint: Candy.mango) {
                    Text("The shelf fills itself the moment you save anything.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                }
                .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cups-empty")
            }
        }
        .sheet(isPresented: $naming) {
            KeepsakeSheet(name: $keepsakeName) {
                store.saveKeepsake(named: keepsakeName)
                naming = false
            } cancel: {
                naming = false
            }
        }
        .sheet(item: $restoring) { cup in
            RestoreSheet(cup: cup, preview: store.preview(of: cup) ?? "could not be read") {
                _ = store.restore(cup)
                restoring = nil
            } cancel: {
                restoring = nil
            }
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: [.json, .data]) { result in
            if case .success(let url) = result { store.importFile(url) }
        }
    }

    private var cups: [Cup] { store.shelf.cups.sorted { $0.pouredAt > $1.pouredAt } }
    private var tested: Int { store.shelf.cups.filter(\.tested).count }
    private var untested: Int { store.shelf.cups.filter { !$0.tested }.count }
}

struct CupRow: View {
    @EnvironmentObject private var store: CoffeeStore
    let cup: Cup
    let index: Int
    let restore: () -> Void

    private var tint: Color {
        cup.tested ? (cup.kind == .keepsake ? Candy.grape : Candy.mint) : Candy.apricot
    }

    var body: some View {
        WobbleCard(tint: tint, ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    CupKindMark(kind: cup.kind, size: 34).foregroundStyle(tint)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(cup.name.isEmpty ? cup.kind.title : cup.name)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.ink)
                        Text(cup.pouredAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                    }
                    Spacer()
                    Group {
                        if cup.tested {
                            TickMark(size: 30, weight: 6).foregroundStyle(Candy.mint)
                        } else {
                            WarningMark(size: 28).font(.system(size: 28))
                        }
                    }
                        .accessibilityIdentifier("cup-tested-\(index)")
                }

                Chip(text: cup.contentsLine, tint: tint) { BoxMark(size: 18) }

                Text(cup.testedNote)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(cup.tested ? Candy.inkSoft : Candy.apricot)

                HStack(spacing: 10) {
                    Button("Pour it back", action: restore)
                        .buttonStyle(SquashyButton(tint: Candy.grape))
                        .accessibilityIdentifier("cup-restore-\(index)")
                    Button("Test again") { store.retest(cup) }
                        .buttonStyle(SquashyButton(tint: Candy.sky))
                        .accessibilityIdentifier("cup-retest-\(index)")
                }
                .font(.system(size: 17))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("cup-row-\(index)")
    }
}

// MARK: - Naming a keepsake

struct KeepsakeSheet: View {
    @Binding var name: String
    let pour: () -> Void
    let cancel: () -> Void

    var body: some View {
        ZStack {
            CoffeeBackground()
            Screen(title: "Name this cup") { JarMark(size: 38) } content: {
                WobbleCard(tint: Candy.grape) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Keepsake cups are kept forever — the shelf never tips one out.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                        FatField(label: "Call it something", text: $name,
                                 tint: Candy.grape, identifier: "cups-keepsake-name")
                        Text("Leave it blank and it will just be called Keepsake.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                    }
                }
            } bar: {
                StickyBar(saveTitle: "Pour it", tint: Candy.grape,
                          saveIdentifier: "cups-keepsake-confirm",
                          closeIdentifier: "cups-keepsake-cancel",
                          save: pour, close: cancel)
            }
        }
    }
}

// MARK: - Pouring a cup back in

struct RestoreSheet: View {
    let cup: Cup
    let preview: String
    let pour: () -> Void
    let cancel: () -> Void

    var body: some View {
        ZStack {
            CoffeeBackground()
            Screen(title: "Pour it back?") { CupMark(size: 38) } content: {
                WobbleCard(tint: Candy.grape) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(cup.name.isEmpty ? cup.kind.title : cup.name)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.ink)
                        Text(cup.pouredAt.formatted(date: .complete, time: .shortened))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                        Chip(text: cup.contentsLine, tint: Candy.grape) { BoxMark(size: 18) }
                    }
                }

                WobbleCard(tint: Candy.sky) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What changes")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                        Text(preview)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.sky)
                            .accessibilityIdentifier("restore-preview")
                    }
                }

                WobbleCard(tint: Candy.mint) {
                    Text("Where you are now is saved first, as a keepsake cup called “Before restore”. Nothing is lost either way.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                }
            } bar: {
                StickyBar(saveTitle: "Pour it back", tint: Candy.grape,
                          saveIdentifier: "cups-restore-confirm",
                          closeIdentifier: "cups-restore-cancel",
                          save: pour, close: cancel)
            }
        }
    }
}
