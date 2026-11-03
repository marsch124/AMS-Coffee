import SwiftUI
import UniformTypeIdentifiers

struct CupsView: View {
    @EnvironmentObject private var store: CoffeeStore
    @State private var keepsakeName = ""
    @State private var naming = false
    @State private var restoring: Cup?

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

            BackupButtons(prefix: "cups")

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
            RestoreSheet(title: cup.name.isEmpty ? cup.kind.title : cup.name,
                         when: cup.pouredAt,
                         contents: cup.contentsLine,
                         preview: store.preview(of: cup) ?? "could not be read",
                         safetyName: "Before restore") {
                _ = store.restore(cup)
                restoring = nil
            } cancel: {
                restoring = nil
            }
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
    let title: String
    let when: Date?
    let contents: String
    let preview: String
    let safetyName: String
    let pour: () -> Void
    let cancel: () -> Void

    var body: some View {
        ZStack {
            CoffeeBackground()
            Screen(title: "Pour it back?") { CupMark(size: 38) } content: {
                WobbleCard(tint: Candy.grape) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(title)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(Candy.ink)
                        if let when {
                            Text(when.formatted(date: .complete, time: .shortened))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Candy.inkSoft)
                        }
                        Chip(text: contents, tint: Candy.grape) { BoxMark(size: 18) }
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
                    Text("Where you are now is saved first, as a keepsake cup called “\(safetyName)”. Nothing is lost either way.")
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

// MARK: - A backup file you name and place (2.6)

/// Save a backup file · Open a backup — the same pair in Settings and on
/// the cups shelf.
struct BackupButtons: View {
    @EnvironmentObject private var store: CoffeeStore
    let prefix: String
    @State private var saving = false
    @State private var opening = false
    @State private var incoming: IncomingBackup?
    @State private var unreadable = false

    struct IncomingBackup: Identifiable {
        let id = UUID()
        let name: String
        let data: CoffeeData
    }

    var body: some View {
        FlowRow(spacing: 10) {
            Button { saving = true } label: {
                HStack(spacing: 10) { TrayArrowMark(size: 24, out: true); Text("Save a backup file") }
            }
            .buttonStyle(SquashyButton(tint: Candy.sky))
            .accessibilityIdentifier("\(prefix)-backup")

            Button { opening = true } label: {
                HStack(spacing: 10) { TrayArrowMark(size: 24, out: false); Text("Open a backup") }
            }
            .buttonStyle(SquashyButton(tint: Candy.blueberry))
            .accessibilityIdentifier("\(prefix)-open-backup")
        }
        .sheet(isPresented: $saving) { BackupSheet() }
        .fileImporter(isPresented: $opening, allowedContentTypes: [.json, .data]) { result in
            guard case .success(let url) = result else { return }
            if let data = BackupFile.read(url) {
                incoming = IncomingBackup(name: url.deletingPathExtension().lastPathComponent,
                                          data: data)
            } else {
                unreadable = true
            }
        }
        .sheet(item: $incoming) { file in
            RestoreSheet(title: file.name,
                         when: nil,
                         contents: Cup.counting(file.data).contentsLine,
                         preview: store.preview(of: file.data),
                         safetyName: "Before opening a backup") {
                store.restore(from: file.data, safetyName: "Before opening a backup")
                incoming = nil
            } cancel: {
                incoming = nil
            }
        }
        .alert("That is not a Coffee backup", isPresented: $unreadable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("It could not be read as one. Nothing was changed.")
        }
    }
}

/// Name it, choose where it goes, and watch it prove itself.
struct BackupSheet: View {
    @EnvironmentObject private var store: CoffeeStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = BackupFile.suggestedName()
    @State private var exporting = false
    @State private var document: BackupDocument?
    @State private var snapshot = CoffeeData()
    @State private var proved: Bool?
    @State private var note = ""
    @State private var savedAs = ""

    var body: some View {
        ZStack {
            CoffeeBackground()
            Screen(title: "A backup file") { TrayArrowMark(size: 38, out: true) } content: {
                WobbleCard(tint: Candy.sky) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Every bag, brew and piece of kit in one file. Name it, then choose where it goes — Files, iCloud Drive, or a USB stick on the Mac.")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                        FatField(label: "Call it", text: $name,
                                 tint: Candy.sky, identifier: "backup-name")
                        Text("Photos stay with the app; the file holds everything else.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Candy.inkSoft)
                    }
                }

                if let proved {
                    WobbleCard(tint: proved ? Candy.mint : Candy.apricot) {
                        HStack(alignment: .top, spacing: 12) {
                            if proved {
                                TickMark(size: 30, weight: 6).foregroundStyle(Candy.mint)
                            } else {
                                WarningMark(size: 28)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(proved ? "Saved and proved" : "Not proved")
                                    .font(.system(size: 19, weight: .black, design: .rounded))
                                if !savedAs.isEmpty {
                                    Text(savedAs)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(Candy.inkSoft)
                                }
                                Text(note)
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(proved ? "backup-proved" : "backup-unproven")
                }
            } bar: {
                StickyBar(saveTitle: proved == true ? "Done" : "Choose where",
                          tint: Candy.sky,
                          saveIdentifier: "backup-save", closeIdentifier: "backup-close",
                          save: save, close: { dismiss() })
            }
        }
        .fileExporter(isPresented: $exporting, document: document, contentType: .json,
                      defaultFilename: fileStem) { result in
            switch result {
            case .success(let url):
                prove(url)
            case .failure:
                proved = false
                note = "It was not saved. Nothing changed."
            }
        }
    }

    private var fileStem: String {
        (BackupFile.fileName(for: name) as NSString).deletingPathExtension
    }

    private func save() {
        if proved == true { dismiss(); return }
        snapshot = store.data
        guard let bytes = try? BackupFile.encode(snapshot) else {
            proved = false
            note = "The file could not be made. Nothing changed."
            return
        }
        // A screen test cannot drive the system's place picker, so under
        // test the file goes straight to a scratch folder — and is proved
        // by exactly the same read-back.
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(BackupFile.fileName(for: name))
            try? bytes.write(to: url)
            prove(url)
            return
        }
        document = BackupDocument(bytes: bytes)
        exporting = true
    }

    private func prove(_ url: URL) {
        let proof = BackupFile.prove(url, expecting: snapshot)
        savedAs = url.lastPathComponent
        proved = proof.passed
        note = proof.note
    }
}
