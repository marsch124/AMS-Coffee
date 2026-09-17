import Foundation

/// The app's own story. Lives here so the main screen, the guide and the
/// tests all read one list and can never drift apart.
struct Release: Identifiable {
    var id: String { version }
    let version: String
    let date: String
    let headline: String
    let emoji: String
    let lines: [String]
}

enum Guide {

    static let appVersion = "1.1"

    /// Newest first. Every release adds an entry — never edits an old one.
    static let releases: [Release] = [
        Release(version: "1.1", date: "2026-09-17",
                headline: "Every way of making it", emoji: "🌀",
                lines: [
                    "🌀 Pour-over, AeroPress, French press, Moka, cold brew and filter all work now — each with only its own dials, its own colour and its own sensible starting numbers.",
                    "🧑‍🏫 The coach learned every method: it says steep it longer for a French press and grind finer for a pour-over, and it knows the usual time window for each one.",
                    "🫘 A bag remembers a separate recipe per method, so its pour-over recipe never turns up when you are pulling a shot.",
                    "🛒 Money: machines, grinders, accessories and subscriptions, with price, shop, date and warranty — plus a warning when a warranty is about to run out.",
                    "💰 Spent this year, split into beans and gear, and cost per cup both with and without the gear. Your bags are counted automatically — never type a bag in twice.",
                    "🎛 Filter the brew list by method with one tap.",
                    "🛟 The data file now opens tolerantly: a file or a cup written by an older version still opens, and always will.",
                    "🏺 Cups count purchases too, and prove that count like everything else.",
                ]),
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

                Every brew you log takes its dose off the bag, so the bag always \
                shows how many grams are left. No weighing the whole bag again.

                The bag also shows which ways you have made it — ☕️ 🌀 🫙 — and \
                keeps a separate recipe for each one.
                """),
        Chapter(emoji: "🎛", title: "Making coffee",
                body: """
                Press Pull a shot for espresso, or pick another way underneath: \
                🌀 pour-over · 🪗 AeroPress · 🫙 French press · 🔥 Moka · \
                🧊 cold brew · 🫗 filter.

                Each one shows only its own dials. Espresso asks for grams out \
                and seconds; a pour-over asks for water in, bloom and pours; a \
                French press just asks how long it steeped; cold brew asks for \
                hours. Every one arrives pre-filled — from your last good brew \
                on that bag with that method, or from a sensible starting point \
                if there is nothing to copy. Most days you change nothing and \
                press save.

                Then say how it tasted with two sliders — sour ↔ bitter and \
                thin ↔ syrupy — and pick a light: 🔴 🟡 🟢.
                """),
        Chapter(emoji: "🧑‍🏫", title: "The coach",
                body: """
                As soon as you change anything, the coach tells you one thing to \
                change next time.

                It speaks each method's own language. On espresso, sour and fast \
                means grind finer. On a French press or cold brew it says steep \
                it longer or shorter, because that is the knob you actually turn. \
                It knows roughly how long each method should take, so it can tell \
                you that four minutes is slow for a pour-over.

                Green means keep it exactly here — and that brew becomes the \
                recipe the bag offers you next time for that method.

                One change at a time. That is the whole trick.
                """),
        Chapter(emoji: "🛒", title: "Money",
                body: """
                Machines, grinders, scales, tampers, filters, subscriptions — \
                what it was, where from, what it cost, and when the warranty \
                runs out. The app warns you when a warranty has under two \
                months left.

                Your bags of beans are counted automatically from the bags \
                themselves, so you never enter a bag twice.

                Spent this year is split into beans and gear. Cost per cup comes \
                two ways: beans only, which is what this morning actually cost, \
                and with the gear folded in, which is the number that stings.
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
                what is inside and counts it — bags, brews and purchases. Only \
                then does it get a green ✓. A cup that cannot be opened says so, \
                in orange.

                2. A cup never shrinks silently. If a new cup would hold less \
                than the last one, it is refused and the old cup stays. The shelf \
                tells you it happened. A good backup can never be replaced by an \
                empty one.

                3. Restoring takes a safety cup first. Pouring a cup back shows \
                you what will change before it does anything, and saves where \
                you are now as Before restore.
                """),
        Chapter(emoji: "🛟", title: "Why old cups still open",
                body: """
                The app reads its own files forgivingly. Anything it does not \
                recognise is simply left at its normal value, and anything \
                missing is filled in.

                That means a cup poured by version 1.0 still opens in 1.1, and a \
                cup poured today will still open in a version that has not been \
                written yet. New features can never lock you out of your own \
                history.
                """),
        Chapter(emoji: "🚰", title: "The Sink",
                body: """
                Nothing is deleted. Rinsed bags, brews and purchases go to the \
                Sink and sit there for 30 days. One tap puts them back. After 30 \
                days they are gone for good — and by then they are in a dozen \
                cups anyway.
                """),
        Chapter(emoji: "☁️", title: "Phone and Mac",
                body: """
                Both read one file in your iCloud Drive, so there is no syncing \
                to think about. When both devices changed something, the newer \
                change wins, per bag, per brew and per purchase — never the whole \
                file. A bag you rinsed on the phone stays rinsed; it cannot come \
                back from the Mac.

                No iCloud account signed in? The app quietly keeps everything on \
                that device and says so at the bottom of the main screen.
                """),
        Chapter(emoji: "📜", title: "Version history",
                body: """
                The pill on the main screen. Tap it and the whole story unfolds, \
                newest at the top, one line per thing that changed. It is never \
                tidied up or shortened.
                """),
        Chapter(emoji: "🌱", title: "Coming next",
                body: """
                Photos of the bags and of receipts. A brew timer that counts \
                while you pour. Charts of how a bag's scores moved as you dialled \
                it in.
                """),
    ]
}
