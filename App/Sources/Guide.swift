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

    static let appVersion = "2.5"

    /// Newest first. Every release adds an entry — never edits an old one.
    static let releases: [Release] = [
        Release(version: "2.5", date: "2026-11-02",
                headline: "See where a bag is heading, and find any brew",
                lines: [
                    "NEW — How you dialled it in. Open a bag and, once you have made it twice the same way, there is a small chart for each number that matters: grind, dose, time and taste. The oldest brew is on the left, the newest on the right, and every dot is coloured by the light you gave that brew — green, amber or red — so you can see at a glance which way you were walking and where it started tasting good.",
                    "Each line also says it in words: \"15 → 13.5 · finer\", \"18 g all along\", \"21 s → 28 s · in the window\", \"sour → balanced\". Above the lines: how many brews, how many were green, and how the last one went.",
                    "The time line has a shaded strip for the coach's own window, and the taste line a strip for balanced, so where you want to be is always on the chart — even if no brew has landed there yet. The time is judged by exactly the same window the coach and the timer use, so the three can never tell different stories.",
                    "A bag made more than one way shows one chip per method above the chart; it opens on the way you made it most recently. Each method is its own line, because a pour-over and an espresso are dialled in on completely different numbers.",
                    "With only one brew, the bag says the line starts with the next one, rather than drawing a lonely dot. A bag never brewed shows no chart at all.",
                    "NEW — Search every brew. At the top of Brews there is now one search box. Type any part of the bag's name, the roaster, the origin, the process, the way you made it, or something you wrote in a note, and the list shows only the brews that match, newest first, with how many were found.",
                    "Type more than one word to narrow it down: \"kenya pour\" finds pour-overs of a Kenyan bag. Every word has to turn up somewhere. Capitals and accents never matter, so \"cafe\" finds Café.",
                    "Search works together with the method chips: pick Pour-over and search for a roaster, and you get only that roaster's pour-overs. When nothing matches it says so and tells you what it looked at. The small cross, or Escape on the Mac, clears it.",
                    "Brews waiting in the Sink are never found — only what is really on your list.",
                    "FIXED — a bag with its chips and its stars in one row — grams left, days off roast, running out, five stars — was wider than the phone, and pushed the whole Beans screen off both sides — the tabs at the bottom included. The chips now wrap onto a second line. Found by looking at the new chart on a full bag, not by a test.",
                    "CHANGED — the guide's \"Coming next\" was still promising the brew timer, which arrived in 2.2. It now says what is actually next.",
                    "Tests: 90 checks of the rules and 12 of the screens — 18 new rule checks for the chart and the search, and two new screen checks that build a bag, brew it twice and find the chart, and that search two brews and find only the right one. Both were seen failing before the features existed.",
                ]),
        Release(version: "2.4", date: "2026-11-02",
                headline: "Ask it what to change, and know what you are repeating",
                lines: [
                    "NEW — What should I change? On the morning screen, under the coach's line, you can now just say what was wrong: too sour, too bitter, too thin, too strong, or it was lovely. You get one concrete change straight away, worked out from the brew you actually made — no need to fill in a whole new brew first.",
                    "The answer comes from exactly the same coach as always, so it can never contradict the advice on a logged brew. Tap the same choice again to put the answer away.",
                    "\"It was lovely\" does not invent a change. It says change nothing, because that is already the recipe the bag offers you next time.",
                    "NEW — every new brew now says where its numbers came from: \"Same again: your best espresso on this bag, 20 Sep\". The app has always copied your best brew into a new one, but there was no way to tell your own recipe from a generic starting point. Now there is. With no bag chosen, or a bag you have never brewed, it says so plainly instead.",
                    "NEW — bags warn you before they run out. A bag shows \"2 more brews\", then \"1 more brew\", then \"not enough for another\" — on the bag itself and on the bag in the hopper. It counts using that bag's own recipe, so a 30 g filter recipe empties it twice as fast as an 18 g espresso, and it says nothing at all while there is plenty.",
                    "A bag with no weight entered is never counted down and never claims to be empty.",
                    "FIXED — the guide said the bag \"shows which ways you have made it — — and keeps a separate recipe\". A word had been missing there since version 2.0.",
                    "FIXED — asking \"too bitter\" about a brew you had marked green used to answer \"keep it exactly here\". The coach stops at a green light before it ever looks at the taste, and complaining about a brew plainly means it was not green. Found by using it, not by a test; there is a test for it now.",
                    "Tests: 72 checks of the rules and 10 of the screens. The new \"where the numbers came from\" line was caught by its own test first: it had been put inside the part of the screen that only appears once you own a bag, so your very first brew would have got no explanation at all.",
                ]),
        Release(version: "2.3", date: "2026-09-20",
                headline: "The timer knows where it is going",
                lines: [
                    "The clock now aims at something. It says what to aim for, and the number itself changes colour as you pour: plain while it settles, amber when you are nearly there, green inside the window, and a calm red once you have gone past.",
                    "It buzzes at the two moments you would otherwise have to watch for — when you reach the window, and when you have run past it. Another, firmer buzz marks the end of the pre-infusion.",
                    "The window is the coach's own, so the timer and the advice can never tell you two different stories.",
                    "Every bag now shows its days off roast, and the colour drifts as it ages: resting for the first few days, at its best for three weeks, then fading, then past it. A bag with no roast date says nothing rather than guessing.",
                ]),
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

                When a bag is nearly finished it says so: 2 more brews, then 1 \
                more brew, then not enough for another. It works that out from \
                that bag's own recipe, so a filter bag you use 30 g at a time \
                runs down twice as fast as an espresso bag at 18 g. While there \
                is plenty it says nothing — a warning that is always on is not a \
                warning. A bag with no weight entered is never counted down.

                A bag also shows its days off roast, and the colour drifts as it \
                ages: resting for the first few days, at its best for about three \
                weeks, then fading, then past it. A bag with no roast date says \
                nothing rather than guessing.

                The bag also shows which ways you have made it, and keeps a \
                separate recipe for each one.

                Open a bag you have made at least twice the same way and it \
                shows how you dialled it in: one small line each for grind, \
                dose, time and taste, oldest brew on the left and newest on the \
                right, every dot coloured by its light. Each line says where it \
                went in words — "15 → 13.5 · finer", "sour → balanced". The \
                time line has a shaded strip for the coach's window and the \
                taste line one for balanced, so you can see whether you are \
                walking towards them. Made it more than one way? Tap a method \
                above the chart to see that one.
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

                A new brew tells you which of the two it did: "Same again: your \
                best espresso on this bag, 20 Sep", or that nothing is logged for \
                this bag yet. So you always know whether these are your numbers \
                or the book's.

                Time it right there. Press Start when the water starts and Stop \
                when it stops, and the time writes itself in. The number says \
                what to aim for and changes colour as you pour — plain, then \
                amber when you are nearly there, green inside the window, calm \
                red once past it — and buzzes when you reach the window, when you \
                run past it, and when the pre-infusion ends.

                Then say how it tasted with two sliders — sour ↔ bitter and \
                thin ↔ syrupy — and pick a light: green for lovely, amber for \
                fine, red for pour it away.
                """),
        Chapter(title: "Finding a brew",
                body: """
                At the top of Brews there is one search box. Type part of a \
                bag's name, a roaster, an origin, a process, a way of making \
                it, or anything you wrote in a note, and the list shows just \
                the brews that match, newest first.

                Several words narrow it down — each one has to turn up \
                somewhere, so "kenya pour" finds the pour-overs of a Kenyan \
                bag. Capitals and accents never matter. It works together \
                with the method chips underneath, and the cross clears it \
                (Escape on the Mac). Brews in the Sink are left out.
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

                You can also just ask. On the morning screen, say what was \
                wrong — too sour, too bitter, too thin, too strong — and it \
                answers on the spot about the brew you just made, without you \
                filling anything in. "It was lovely" answers change nothing.

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
                Read a bag's label from a photo to fill in the roaster, origin \
                and roast date. Looking after your kit — when the burrs and the \
                backflush are due. A backup file you name and put wherever you \
                like.
                """),
    ]
}
