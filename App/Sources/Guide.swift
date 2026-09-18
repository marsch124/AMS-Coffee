import Foundation

/// The app's own story. Lives here so the main screen, the guide and the
/// tests all read one list and can never drift apart.
struct Release: Identifiable {
    var id: String { version }
    let version: String
    let date: String
    let headline: String
    let lines: [String]
}

enum Guide {

    static let appVersion = "2.2"

    /// Newest first. Every release adds an entry — never edits an old one.
    static let releases: [Release] = [
        Release(version: "2.2", date: "2026-09-18",
                headline: "A stopwatch on the brew",
                lines: [
                    "Time it, right on the brew. Start when the water starts, Stop when it stops, and the time writes itself into the log — so the seconds you keep are the seconds that happened, not the ones you remembered afterwards.",
                    "The clock is worked out from the moment you started, never by counting. Lock the phone mid-pour or take a call: come back and it is still right.",
                    "On a pour-over or filter there is a Bloom done button, so the bloom is timed separately without you doing arithmetic.",
                    "On an AeroPress or French press, stopping the clock fills in the steep in minutes, to the nearest half.",
                    "Cold brew gets no stopwatch. It steeps overnight.",
                    "Carry on picks up where you left off; Start over is the calm red one, last as always.",
                ]),
        Release(version: "2.1", date: "2026-09-18",
                headline: "Readable, upright, quieter",
                lines: [
                    "Every panel stands upright. The slight tilt is gone for good.",
                    "Nothing in the app is smaller than 15pt, and the faint grey text that was hard to read has been replaced throughout — in dark mode as well as light.",
                    "Remove is one calm red, sits last on the screen, and never shouts. Keep is always the easy way out.",
                    "A brew can carry a photo now — the crema, the bed, the cup.",
                    "Six ways of making coffee, six different marks. Pour-over and filter no longer look identical, and nor do AeroPress and French press.",
                    "Add a bag and Pull a shot moved to the bottom of their lists, where a thumb is. A list should open with what is in it.",
                ]),
        Release(version: "2.0", date: "2026-09-17",
                headline: "Tidied up",
                lines: [
                    "Four places instead of five, and only four: Today, Beans, Brews, Settings.",
                    "The Money screen is gone. No totals, no cost per cup. This app is about drinking coffee, not accounting.",
                    "Your machine, grinder and the rest are now Your kit, in Settings, where you set them up once.",
                    "How this works, the version history, your cups, the Sink and export all moved into Settings, off the morning screen.",
                    "Photos: of a bag, and of a receipt. Taken with the camera or chosen from your pictures.",
                    "A cup now counts its photos and proves they are still there — a cup missing a picture is not a whole cup.",
                    "Every stock symbol is gone. Every mark in the app is drawn here, and everything is bigger.",
                    "The steam at the top of every screen is gone.",
                ]),
        Release(version: "1.1", date: "2026-09-17",
                headline: "Every way of making it",
                lines: [
                    "Pour-over, AeroPress, French press, Moka, cold brew and filter all work now — each with only its own dials, its own colour and its own sensible starting numbers.",
                    "‍The coach learned every method: it says steep it longer for a French press and grind finer for a pour-over, and it knows the usual time window for each one.",
                    "A bag remembers a separate recipe per method, so its pour-over recipe never turns up when you are pulling a shot.",
                    "Money: machines, grinders, accessories and subscriptions, with price, shop, date and warranty — plus a warning when a warranty is about to run out.",
                    "Spent this year, split into beans and gear, and cost per cup both with and without the gear. Your bags are counted automatically — never type a bag in twice.",
                    "Filter the brew list by method with one tap.",
                    "The data file now opens tolerantly: a file or a cup written by an older version still opens, and always will.",
                    "Cups count purchases too, and prove that count like everything else.",
                ]),
        Release(version: "1.0", date: "2026-09-17",
                headline: "First cup",
                lines: [
                    "Bags of beans, with grams left counting themselves down as you pull shots.",
                    "Espresso dial-in: grind, dose, yield, time, temperature — ratio and flow work themselves out.",
                    "‍The coach reads the shot you just rated and tells you the one thing to change.",
                    "The Cup System: quick, daily and keepsake cups, each one proved by opening it again.",
                    "The Sink — rinsed things wait 30 days instead of vanishing.",
                    "The phone and the Mac read the same shelf in iCloud Drive.",
                    "This version history, right on the main screen.",
                ]),
    ]

    static var current: Release { releases[0] }

    // MARK: How it works

    struct Chapter: Identifiable {
        var id: String { title }
        let title: String
        let body: String
    }

    static let chapters: [Chapter] = [
        Chapter(title: "The idea",
                body: """
                AMS Coffee remembers what you bought, what it tasted like, and \
                exactly how you made the good ones. Nothing here needs typing a \
                sentence — it is sliders, stars and big buttons.
                """),
        Chapter(title: "Bags of beans",
                body: """
                Add a bag when you buy it: roaster, name, weight, price. Tap the \
                flavours you taste, give it stars, and stamp it Buy again or \
                Never again.

                Every brew you log takes its dose off the bag, so the bag always \
                shows how many grams are left. No weighing the whole bag again.

                The bag also shows which ways you have made it — — and \
                keeps a separate recipe for each one.
                """),
        Chapter(title: "Making coffee",
                body: """
                Press Pull a shot for espresso, or pick another way underneath: \
                pour-over · AeroPress · French press · Moka · \
                cold brew · filter.

                Each one shows only its own dials. Espresso asks for grams out \
                and seconds; a pour-over asks for water in, bloom and pours; a \
                French press just asks how long it steeped; cold brew asks for \
                hours. Every one arrives pre-filled — from your last good brew \
                on that bag with that method, or from a sensible starting point \
                if there is nothing to copy. Most days you change nothing and \
                press save.

                Then say how it tasted with two sliders — sour ↔ bitter and \
                thin ↔ syrupy — and pick a light: .
                """),
        Chapter(title: "The coach",
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
        Chapter(title: "Your kit",
                body: """
                Machines, grinders, scales, tampers, filters. What it is, where \
                it came from, a photo of the receipt, and when the warranty runs \
                out — the app tells you when one has under two months left.

                It lives in Settings because you set your kit up once and then \
                get on with the coffee. Nothing here is added up: there are no \
                totals and no cost per cup. If you want to note what something \
                cost you can, on one quiet line, and the app will never mention \
                it again.
                """),
        Chapter(title: "Photos",
                body: """
                A bag can have a photo, and so can a receipt. Take one with the \
                camera — that is the useful one, standing at the machine — or \
                choose a picture you already have. Tap a photo to fill the screen \
                with it.

                Photos are kept as files beside your coffee, not inside it, and \
                shrunk so a year of bags still syncs in a moment.

                A photo is only ever deleted when nothing refers to it at all: \
                not a bag, not something in the Sink, and not a single cup on the \
                shelf. Pour back a cup from a month ago and its pictures are \
                still there.
                """),
        Chapter(title: "The Cup System",
                body: """
                Every save is poured into a cup, and the cups sit on a shelf you \
                can look at.

                Quick cup — after every change, silently. Last 10 kept.
                Daily cup — once a day. Last 7 kept.
                Keepsake cup — when you press Save a cup and name it. Kept forever.

                Three rules make it safe:

                1. Each cup proves itself. The app opens the cup again, reads \
                what is inside and counts it — bags, brews, kit and photos. Only \
                then does it get a green . A cup that cannot be opened says so, \
                in orange.

                2. A cup never shrinks silently. If a new cup would hold less \
                than the last one, it is refused and the old cup stays. The shelf \
                tells you it happened. A good backup can never be replaced by an \
                empty one.

                3. Restoring takes a safety cup first. Pouring a cup back shows \
                you what will change before it does anything, and saves where \
                you are now as Before restore.
                """),
        Chapter(title: "Why old cups still open",
                body: """
                The app reads its own files forgivingly. Anything it does not \
                recognise is simply left at its normal value, and anything \
                missing is filled in.

                That means a cup poured by version 1.0 still opens in 1.1, and a \
                cup poured today will still open in a version that has not been \
                written yet. New features can never lock you out of your own \
                history.
                """),
        Chapter(title: "The Sink",
                body: """
                Nothing is deleted. Rinsed bags, brews and purchases go to the \
                Sink and sit there for 30 days. One tap puts them back. After 30 \
                days they are gone for good — and by then they are in a dozen \
                cups anyway.
                """),
        Chapter(title: "Phone and Mac",
                body: """
                Both read one file in your iCloud Drive, so there is no syncing \
                to think about. When both devices changed something, the newer \
                change wins, per bag, per brew and per purchase — never the whole \
                file. A bag you rinsed on the phone stays rinsed; it cannot come \
                back from the Mac.

                No iCloud account signed in? The app quietly keeps everything on \
                that device and says so at the bottom of the main screen.
                """),
        Chapter(title: "Settings",
                body: """
                Everything you touch once lives here, off the morning screen: \
                where your coffee is kept, your cups, your kit, the Sink, a copy \
                of everything to export, this guide, and the version history.

                The version history is the whole story of the app, newest at the \
                top, one line per thing that changed. It is never tidied up or \
                shortened.
                """),
        Chapter(title: "Coming next",
                body: """
                A brew timer that counts while you pour. Charts of how a bag's \
                scores moved as you dialled it in. The Mac app.
                """),
    ]
}
