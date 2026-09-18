import SwiftUI

/// Everything you set up once and then forget: the guide, the story of the
/// app, the safety net, your kit, and the way out for your data.
struct SettingsView: View {
    @EnvironmentObject private var store: CoffeeStore
    @State private var showGuide = false
    @State private var showHistory = false
    @State private var exportURL: URL?
    @State private var importing = false

    var body: some View {
        Screen(title: "Settings") { CogMark(size: 38) } content: {

            // Where the data is, in one plain sentence.
            WobbleCard(tint: Candy.sky) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Where your coffee lives")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                    Text(store.syncPlace == "iCloud Drive"
                         ? "In your iCloud Drive, so this phone and your Mac read the very same shelf."
                         : "On this device only. Sign in to iCloud and both your phone and your Mac will read the same shelf.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    Chip(text: store.syncPlace, tint: Candy.sky) { CloudMark(size: 18) }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("settings-where")
            }

            BigLink(title: "Your cups",
                    subtitle: "\(store.shelf.cups.count) kept · \(store.shelf.cups.filter(\.tested).count) proved",
                    tint: Candy.grape, identifier: "settings-cups") {
                JarMark(size: 38)
            } content: {
                CupsView()
            }

            BigLink(title: "Your kit",
                    subtitle: kitLine,
                    tint: Candy.apricot, identifier: "settings-kit") {
                CaseMark(size: 38)
            } content: {
                KitView()
            }

            BigLink(title: "The Sink",
                    subtitle: store.sinkCount == 0
                        ? "Nothing waiting"
                        : "\(store.sinkCount) waiting, 30 days to change your mind",
                    tint: Candy.mint, identifier: "settings-sink") {
                TapMark(size: 38)
            } content: {
                SinkView()
            }

            // Out and in.
            WobbleCard(tint: Candy.blueberry) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("A copy of everything")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                    Text("Every bag, every brew, every cup, in one file you can keep anywhere.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                    FlowRow(spacing: 10) {
                        Button { exportURL = store.exportFile() } label: {
                            HStack(spacing: 10) { TrayArrowMark(size: 24, out: true); Text("Export") }
                        }
                        .buttonStyle(SquashyButton(tint: Candy.sky))
                        .accessibilityIdentifier("settings-export")

                        Button { importing = true } label: {
                            HStack(spacing: 10) { TrayArrowMark(size: 24, out: false); Text("Import") }
                        }
                        .buttonStyle(SquashyButton(tint: Candy.blueberry))
                        .accessibilityIdentifier("settings-import")
                    }
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Text("Share the file you just made")
                                .font(.system(size: 19, weight: .heavy, design: .rounded))
                                .foregroundStyle(Candy.blueberry)
                        }
                        .accessibilityIdentifier("settings-share")
                    }
                }
            }

            FoldPill(title: "How this works",
                     subtitle: "\(Guide.chapters.count) short chapters",
                     tint: Candy.mint, isOpen: $showGuide,
                     identifier: "settings-guide") {
                BookMark(size: 38)
            } content: {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Guide.chapters) { chapter in
                        VStack(alignment: .leading, spacing: 7) {
                            Text(chapter.title)
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(Candy.mint)
                            Text(chapter.body)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .accessibilityIdentifier("settings-guide-list")
            }

            FoldPill(title: "Version history",
                     subtitle: "v\(Guide.appVersion) · \(Guide.current.headline)",
                     tint: Candy.grape, isOpen: $showHistory,
                     identifier: "settings-version") {
                ScrollMark(size: 38)
            } content: {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Guide.releases) { release in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 9) {
                                Text("v\(release.version)")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(Candy.grape)
                                Text(release.headline)
                                    .font(.system(size: 19, weight: .bold, design: .rounded))
                                Spacer()
                                Text(release.date)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(Candy.inkSoft)
                            }
                            ForEach(Array(release.lines.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .accessibilityIdentifier("settings-version-list")
            }
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: [.json, .data]) { result in
            if case .success(let url) = result { store.importFile(url) }
        }
    }

    private var kitLine: String {
        let n = store.data.livePurchases.count
        return n == 0 ? "Your machine, grinder, the rest" : "\(n) thing\(n == 1 ? "" : "s")"
    }
}

/// A fat row that opens something. Emoji big enough to aim at.
struct BigLink<Mark: View, Content: View>: View {
    let mark: Mark
    let title: String
    let subtitle: String
    let tint: Color
    let identifier: String
    @ViewBuilder var content: Content
    @State private var open = false

    init(title: String, subtitle: String, tint: Color, identifier: String,
         @ViewBuilder mark: () -> Mark, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.identifier = identifier
        self.mark = mark()
        self.content = content()
    }

    var body: some View {
        Button { open = true } label: {
            HStack(spacing: 15) {
                mark
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(tint)
                    Text(subtitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Candy.inkSoft)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                ChevronMark(size: 26, weight: 5)
                    .rotationEffect(.degrees(-90))
                    .foregroundStyle(tint)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Candy.card)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(tint.opacity(0.55), lineWidth: 3))
                .shadow(color: tint.opacity(0.28), radius: 0, x: 0, y: 5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .sheet(isPresented: $open) { content }
    }
}
