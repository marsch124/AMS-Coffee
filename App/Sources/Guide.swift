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

    static let appVersion = "2.9"

    /// Newest first. Every release adds an entry — never edits an old one.
    static let releases: [Release] = [
        Release(version: "2.9", date: "2026-11-03",
                headline: "The roast on the bag card, and search by roast",
                lines: [
                    "NEW — a bag in the Beans list now shows one quiet line under its name: where it is from, how it was processed and how it was roasted, for example \"Colombia · Anaerobic natural · Medium-light roast\". Before, the card showed none of these.",
                    "The line is in the bag's own colour, in bold. Each part is only there when you have filled it in, and a bag with none of the three has no line at all, so nothing is left empty or looks odd.",
                    "A roast of \"Light\" reads \"Light roast\" on the card. A roast that already says roast — \"Light roast\", \"Ljusrost\", \"Helle Röstung\" — is shown exactly as you typed it.",
                    "NEW — the Brews search now finds a brew by its bag's roast. Type light, medium, dark, medium-light or medium-dark. It also understands Swedish (ljusrost, mellanrost, mörkrost, ljus, mellan, mörk, mellanljus, mellanmörk) and German (hell, helle, mittel, mittlere, dunkel, dunkle, with or without Röstung).",
                    "The word roast itself (or rost, or Röstung) finds every brew whose bag has a roast filled in.",
                    "A roast you typed by hand in any of these languages answers to all of them: a bag with \"Ljusrost\" is found by \"light\", and a bag with \"Light\" by \"ljusrost\" or \"helle\".",
                    "The roast must match as a whole word, on purpose. \"dark\" does not find medium-dark bags, \"medium\" does not find medium-dark, and \"light\" does not find medium-light. Medium-dark is its own step on the scale, and the bag says so; if \"dark\" also brought back medium-dark bags, the truly dark ones would be buried. To find those, type \"medium dark\" or \"medium-dark\" — two words count as the one level.",
                    "As always, every word you type still has to turn up somewhere, so \"kenya light\" finds the light-roast Kenyan brews.",
                    "CHANGED — the \"Nothing matches\" hint now also says that search looks at the bag's roast.",
                    "Tests: 140 checks of the rules and 22 of the screens — 7 new rule checks and 2 new screen checks (the roast line on the card, and finding a brew by its bag's roast), each seen failing before the feature existed.",
                ]),
        Release(version: "2.8", date: "2026-11-03",
                headline: "The roast from the label, and a mark on what it filled",
                lines: [
                    "NEW — Reading the label now also offers the roast: Light, Medium-light, Medium, Medium-dark or Dark, with its own Use button, next to the name, roaster, origin, process and roast date.",
                    "It understands English, Swedish and German — Ljusrost and helle Röstung become Light, Mellanrost and mittlere Röstung become Medium, Mörkrost and dunkle Röstung become Dark — and always writes it in plain English.",
                    "Light, medium and dark are also words for flavours and body, so the roast is only read from a line that talks about roasting (\"Light roast\", \"Roast: medium\", \"Ljusrost\") or where the word stands alone. \"Dark chocolate\" or \"light and juicy\" are never taken for a roast.",
                    "NEW — A Roast box on the bag. The app could already keep a bag's roast, but there was nowhere to type it. Now there is one, under Process, so you can fill it in yourself too.",
                    "NEW — \"from the label\". When you tap Use, the box it fills says \"from the label\" in small pink letters beside its title, so you can see at a glance what came off the photo and give it a quick look. The roast date gets the same mark beside the date.",
                    "Change the box by hand and the mark goes away — from then on it is yours. Boxes you typed yourself never get the mark. The mark is only there while you are adding the bag; it is not saved with it.",
                    "CHANGED — when the label gives nothing useful, the quiet line now also mentions the roast.",
                    "Tests: 133 checks of the rules and 20 of the screens — 6 new rule checks and 1 new screen check, each seen failing before the feature existed.",
                ]),
        Release(version: "2.7", date: "2026-11-03",
                headline: "Name and process from the label",
                lines: [
                    "NEW — Reading the label now also offers the bean's name and its process. Take or choose a photo of a new bag and, next to the roaster, origin and roast date, you may now see Name of the bean and Process, each with its own Use button.",
                    "The process is understood in English, Swedish and German and always written in plain English: Tvättad and gewaschen become Washed, naturlig and Natur become Natural, honung becomes Honey, and you also get Anaerobic, Wet-hulled and Carbonic maceration. Two together read as one, such as Anaerobic natural.",
                    "A flavour is never mistaken for a process. If the label says \"Notes: honey, peach\", or lists flavours one after another, that line is left alone (a line like \"Tvättad · SL28 · SL34\" that starts with the process is still read) — so a honey-sweet washed coffee is not called Honey.",
                    "The name is offered carefully, because a wrong guess is worse than none. Everything that is clearly something else is set aside first: the roaster, the country, any date, the process, the weight, Whole bean, tasting notes, web addresses and words like Espresso or Filter on their own. If exactly one line is left, that is the name. If several are left, the name is only offered when one stands clearly taller on the bag than all the others. Otherwise nothing is offered and you type it as before.",
                    "A name written in capitals is shown the way you would write it — KIAMAINA AA becomes Kiamaina AA, keeping grades like AA and varieties like SL28 as they are.",
                    "As always, nothing is filled in behind your back: the name and process are only offered while their boxes are empty, and typing in a box makes its suggestion go away.",
                    "NEW — Settings now says when you last saved a backup file, in one quiet line under the backup buttons: \"Last backup file: 3 days ago\" (or today, yesterday, a few weeks or months ago). Before the first one it simply says \"No backup file saved yet\". It is never a warning and never nags.",
                    "Only a backup file that proved itself counts — saved, opened again and counted. A save that was cancelled or came back wrong changes nothing.",
                    "The date travels with your coffee, so the phone and the Mac both show the same line, and the later save wins. Opening an older backup or pouring back a cup never turns it back to an earlier date.",
                    "CHANGED — when the label gives nothing useful, the quiet line now reads \"Nothing on this label I could read as a name, roaster, origin, process or roast date.\"",
                    "Tests: 127 checks of the rules and 19 of the screens — 12 new rule checks and 2 new screen checks, each seen failing before the feature existed.",
                ]),
        Release(version: "2.6", date: "2026-11-03",
                headline: "Read the bag, look after the kit, keep a file",
                lines: [
                    "NEW — Read the label. Take or choose a photo of a new bag and the app reads the words on it, right on the phone — no internet, nothing sent anywhere. Underneath the photo it offers what it found: the roaster, the origin and the roast date, each on its own row with a Use button.",
                    "Nothing is ever filled in behind your back. A suggestion only appears for a box that is still empty, and it never replaces something you typed. Start typing the roaster yourself and the roaster suggestion simply goes away.",
                    "It understands the usual ways a roast date is written — 2026-10-20, 20.10.2026, 20/10/26, 20 Oct 2026, October 20, 2026 — and never mistakes a best-before date for one. It knows about forty coffee countries in English, Swedish and German spellings, so Kenia becomes Kenya. It only suggests a roaster when the label says so (Roasters, Rosteri, Coffee Co…), rather than guessing from the biggest letters.",
                    "If it cannot read anything useful it says so in one quiet line, and you type it in as before.",
                    "NEW — Looking after your kit. A grinder now counts how much coffee has gone through it, and a machine counts its espresso shots — both worked out from the brews you log, nothing to type. Open the grinder or machine in Your kit to see \"0.6 of 5 kg since 1 Oct\" or \"12 of 50 shots since 1 Oct\".",
                    "You choose how often each is due: the burrs every 5 kg and a backflush every 50 shots to start with, both easy to change. One tap marks it done today, and every date is kept — the card says when it was last done and how many times in all.",
                    "When something is due, one quiet line appears on Today — \"Lever machine — backflush due · 22 of 20 shots since 1 Oct\" — with a Done button. Nothing due, no line. The kit list also says Burrs fine or Backflush due on each card.",
                    "NEW — A backup file you name and place. In Settings (and on the cups shelf), Save a backup file asks for a name, then lets you choose where it goes: Files, iCloud Drive, or a USB stick on the Mac.",
                    "The file proves itself exactly the way a cup does: once it is saved, the app opens it again from where it landed, reads it and counts the bags, brews and kit inside. Only then does it say Saved and proved with a green tick. If it came back different, it says so in orange instead.",
                    "Open a backup reads a file, shows what is in it and what would change — \"+2 bags · same brews\" — and keeps where you are now as a keepsake cup called Before opening a backup before it does anything. A file that is not a Coffee backup is refused and nothing changes.",
                    "NEW — Same again from here. Open a bag and, under How you dialled it in, a button starts a new brew with the numbers from your best green brew of that method on that bag, and says which one it is. No green brew yet, no button.",
                    "NEW — Search finds more. The Brews search now also knows a brew's light — green or lovely, amber or drinkable, red or tipped — and when it was made: the month (October or Oct), the year, today and yesterday. Words still combine, so \"kenya green october\" finds exactly that.",
                    "CHANGED — Export, Import and Share are replaced by Save a backup file and Open a backup. Import used to mix a file into what you had without showing anything first; opening a backup now previews it, keeps a safety cup, and then puts things exactly as they were in the file.",
                    "FIXED — pouring a cup back did not really put things back. It mixed the cup with what was already saved, and anything changed since the cup was poured stayed as it was. It now puts things exactly as they were in the cup, after keeping Before restore as always.",
                    "FIXED — a bag of 1000 g or more showed its weight cut off as \"1 0…\". Numbers no longer get a thousands space, and the box is wider where a number can run into the thousands. Found by looking at a full shelf, not by a test; there is a test for it now.",
                    "FIXED — on the Mac, Escape now works as Cancel on every screen where you change something, as it always should have. Before, only the search box listened to it.",
                    "CHANGED — the search box hint is shorter, so it is no longer cut off on the phone: \"Search: bag, note, green, Oct\".",
                    "Tests: 115 checks of the rules and 17 of the screens — 25 new rule checks (including the phone really reading the words off a picture) and 5 new screen checks, each seen failing before the feature existed.",
                ]),
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

                Under the bag's name, in the bag's own colour, one quiet line \
                says where it is from, how it was processed and how it was \
                roasted — "Colombia · Anaerobic natural · Medium-light roast". \
                Each part only shows if you filled it in, and a bag with none \
                of them has no line. A roast of "Light" reads "Light roast"; \
                one that already says roast is shown as you typed it.

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

                Once a brew of that method has been green, Same again from \
                here sits under the chart: one tap starts a new brew with the \
                numbers of your best green one, and it says which brew that is.

                Reading the label: take or choose a photo of a new bag and \
                the phone reads it — no internet. It offers the name of the \
                bean, the roaster, the origin, the process, the roast and the \
                roast date it found, each with a Use button. A box filled this \
                way says "from the label" beside its title until you change \
                it, so you can see what came off the photo. The process is always in \
                plain English, even from a Swedish or German bag, and a \
                flavour like honey is never taken for one. The name is only \
                offered when one line is plainly the name — otherwise it \
                offers nothing rather than guess. \
                It only offers what would fill an empty box, never replaces \
                something you typed, and never takes a best-before date for a \
                roast date. If it finds nothing it says so quietly.
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

                It also knows a brew's light — green or lovely, amber or \
                drinkable, red or tipped — and when it was made: the month \
                (October or Oct), the year, today and yesterday. So "kenya \
                green october" finds the lovely Kenyan brews of October.

                And its bag's roast: light, medium, dark, medium-light or \
                medium-dark — also in Swedish (ljusrost, mellanrost, \
                mörkrost) and German (helle, mittlere, dunkle Röstung). A roast \
                you typed in one language is found in all of them, and the word \
                roast finds every bag with a roast filled in. The roast matches \
                as a whole word: "dark" finds dark bags, not medium-dark ones — \
                for those type "medium dark". So "kenya light" finds the \
                light-roast Kenyan brews.
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

                A grinder counts the coffee that has gone through it and a \
                machine counts its espresso shots, both from the brews you \
                log. Set how often the burrs and the backflush are due — 5 kg \
                and 50 shots to start with — and tap done when you have done \
                it; every date is kept. When one is due, a quiet line with a \
                Done button appears on Today, and only then.
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
                you are now as Before restore. Then it puts things exactly as \
                they were in the cup.

                A backup file works the same way. Save a backup file, give it \
                a name, and choose where it goes — Files, iCloud Drive, a USB \
                stick on the Mac. The app then opens the file again from \
                there and counts what is inside before it shows the green \
                tick. Open a backup shows what would change and keeps Before \
                opening a backup first. Photos stay with the app; the file \
                holds everything else.

                Under the backup buttons in Settings one quiet line says when \
                you last saved a backup file that proved itself — "Last \
                backup file: 3 days ago" — or that there is none yet. The \
                phone and the Mac show the same date.
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
                where your coffee is kept, your cups, your kit, the Sink, a \
                backup file you name and place, this guide, and the version \
                history.

                The version history is the whole story of the app, newest at the \
                top, one line per thing that changed. It is never tidied up or \
                shortened.
                """),
        Chapter(title: "Coming next",
                body: """
                Everything from the list you picked in September is now in, \
                and the label reader now knows the name, process and roast too. \
                Next: a proper look at the Mac app as a Mac app — windows, \
                keyboard, and the backup file on a USB stick.
                """),
    ]
}
