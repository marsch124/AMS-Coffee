import Foundation

/// The app's own story. Lives here so the main screen, the guide and the
/// tests all read the same single list.
struct Release: Identifiable {
    var id: String { version }
    let version: String
    let date: String
    let headline: String
    let emoji: String
    let lines: [String]
}

enum Guide {

    static let appVersion = "1.0"

    /// Newest first. Every release adds an entry here — never edits an old one.
    static let releases: [Release] = [
        Release(version: "1.0", date: "2026-09-17",
                headline: "First cup", emoji: "🎉",
                lines: [
                    "🫘 Bags of beans, with grams left counting themselves down as you pull shots.",
                    "🎛 Espresso dial-in: grind, dose, yield, time, temperature — ratio and flow work themselves out.",
                    "🧑‍🏫 The coach reads the shot you just rated and tells you the one thing to change.",
                    "🏺 The Cup System: quick, daily and keepsake cups, each one proved by opening it again.",
                    "🚰 The Sink — rinsed things wait 30 days instead of vanishing.",
                    "☁️ The phone and the Mac read the same shelf in iCloud Drive.",
                    "📜 This version history, right on the main screen.",
                ]),
    ]

    static var current: Release { releases[0] }

    // MARK: How it works

    struct Chapter: Identifiable {
        var id: String { title }
        let emoji: String
        let title: String
        let body: String
    }

    static let chapters: [Chapter] = [
        Chapter(emoji: "☕️", title: "The idea",
                body: """
                AMS Coffee remembers what you bought, what it tasted like, and \
                exactly how you made the good ones. Nothing here needs typing a \
                sentence — it is sliders, stars and big buttons.
                """),
        Chapter(emoji: "🫘", title: "Bags of beans",
                body: """
                Add a bag when you buy it: roaster, name, weight, price. Tap the \
                flavours you taste, give it stars, and stamp it Buy again or \
                Never again.

                Every shot you log takes its dose off the bag, so the bag always \
                shows how many grams are left. No weighing the whole bag again.
                """),
        Chapter(emoji: "🎛", title: "Dialling in a shot",
                body: """
                Press Pull a shot. It arrives pre-filled with the last good \
                recipe for that bag, so most days you change nothing and press \
                save.

                Type what actually happened — grind, grams in, grams out, \
                seconds. The ratio and the flow rate work themselves out while \
                you type. Then say how it tasted with two sliders: sour ↔ bitter \
                and thin ↔ syrupy, and pick a light: 🔴 🟡 🟢.
                """),
        Chapter(emoji: "🧑‍🏫", title: "The coach",
                body: """
                As soon as you save, the coach tells you one thing to change. \
                Sour and fast means grind finer. Bitter and slow means coarser. \
                Green means keep it exactly here — and that shot becomes the \
                recipe the bag offers you next time.

                One change at a time. That is the whole trick to dialling in.
                """),
        Chapter(emoji: "🏺", title: "The Cup System",
                body: """
                Every save is poured into a cup, and the cups sit on a shelf you \
                can look at.

                🥤 Quick cup — after every change, silently. Last 10 kept.
                ☕️ Daily cup — once a day. Last 7 kept.
                🏺 Keepsake cup — when you press Save a cup and name it. Kept forever.

                Three rules make it safe:

                1. Each cup proves itself. The app opens the cup again, reads \
                what is inside and counts it. Only then does it get a green ✓. \
                A cup that cannot be opened says so, in orange.

                2. A cup never shrinks silently. If a new cup would hold less \
                than the last one, it is refused and the old cup stays. The \
                shelf tells you it happened. A good backup can never be replaced \
                by an empty one.

                3. Restoring takes a safety cup first. Pouring a cup back shows \
                you what will change before it does anything, and saves where \
                you are now as Before restore.
                """),
        Chapter(emoji: "🚰", title: "The Sink",
                body: """
                Nothing is deleted. Rinsed bags and shots go to the Sink and sit \
                there for 30 days. One tap puts them back. After 30 days they \
                are gone for good — and by then they are in a dozen cups anyway.
                """),
        Chapter(emoji: "☁️", title: "Phone and Mac",
                body: """
                Both read one file in your iCloud Drive, so there is no syncing \
                to think about. When both devices changed something, the newer \
                change wins, per bag and per shot — never the whole file. A bag \
                you rinsed on the phone stays rinsed; it cannot come back from \
                the Mac.

                No iCloud account signed in? The app quietly keeps everything on \
                that device and says so at the bottom of the main screen.
                """),
        Chapter(emoji: "📜", title: "Version history",
                body: """
                The pill on the main screen. Tap it and the whole story unfolds, \
                newest at the top, one line per thing that changed. It is never \
                tidied up or shortened.
                """),
        Chapter(emoji: "🌀", title: "Coming next",
                body: """
                Pour-over, AeroPress, French press, Moka, cold brew and filter — \
                each with its own fields, colour and icon. Purchases with receipt \
                photos, spend-this-year and cost per cup. Photos of the bags.
                """),
    ]
}
