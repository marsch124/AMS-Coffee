# ☕ AMS Coffee

A native app for iPhone **and** Mac (one SwiftUI target, XcodeGen project) that
remembers what coffee you bought, what it tasted like, and exactly how you made
the good ones.

**Live version: 1.1** — see the Version history pill on the app's main screen.

---

## What it does

| | |
|---|---|
| 🫘 **Bags** | Roaster, bean, origin, process, weight, price, roast date. Tap the flavours you taste, give it stars, stamp it *Buy again* or *Never again*. The grams-left bar counts itself down as you brew, and the card shows which methods you have used that bag for. |
| 🎛 **Brews** | Seven methods, each showing **only its own dials**: ☕️ espresso · 🌀 pour-over · 🪗 AeroPress · 🫙 French press · 🔥 Moka · 🧊 cold brew · 🫗 filter. Ratio computes itself from grams out (espresso) or water in (everything else). Taste goes in as two sliders plus 🔴 🟡 🟢. Filter the list by method with one tap. |
| 🧑‍🏫 **The coach** | **One** change per brew, in that method's own language: *grind finer* on a pour-over, *steep it shorter* on a French press. It knows each method's usual ratio and time window. Green means keep it exactly here, and that brew becomes the bag's recipe for that method. |
| 🛒 **Money** | Machines, grinders, accessories, subscriptions: price, shop, date, warranty — with a warning when a warranty has under two months left. Spend this year split into beans and gear, and cost per cup both with and without the gear. **Bags are counted automatically from the bags, so nothing is entered twice.** |
| 🏺 **Cups** | The safety system. See below. |
| 🚰 **The Sink** | Rinsed bags, brews and purchases wait 30 days instead of vanishing. |
| 📜 **Version history** | Folded onto the main screen, unfolds in place. Never tidied up. |
| 📖 **How this works** | Eleven short chapters, in the app, kept current with every release. |

Adding a method is a `BrewMethod` case plus its `fields` and `starter()` — the
editor, the cards, the coach and the per-bag recipes all follow from that.

---

## 🏺 The Cup System

Every save is poured into a cup. Cups sit on a shelf you can look at.

- 🥤 **Quick cup** — after every change, silently. Last 10 kept.
- ☕️ **Daily cup** — once a day. Last 7 kept.
- 🏺 **Keepsake cup** — when you press *Save a cup*. Kept forever.

Three rules, each one a lesson from a real data loss in another app:

1. **Each cup proves itself.** `CupCupboard.test(_:)` reads the file back,
   decodes it and counts the records — bags, brews *and* purchases. Only a
   match earns the green ✓. "The write returned no error" is not proof.
2. **A cup never shrinks silently.** `CupPolicy.mayPour` refuses a cup holding
   less than the newest cup on the shelf, and raises a warning the main screen
   shows. A good backup can never be overwritten by an empty one.
3. **Restoring takes a safety cup first.** Pouring a cup back previews the
   change (`+2 bags · −14 brews`) and saves the present as *Before restore*.

Pruning never takes a keepsake, never takes the newest cup of a kind, and only
runs after the new cup has passed its test.

---

## 🛟 Why old files still open

Every record decodes with `decodeIfPresent` and a default. A missing key is
filled in; a key from a newer version is ignored. So a file or a cup written by
1.0 opens in 1.1, and one written today will open in a version that has not been
written yet. `OldFileTests` pins this down with a verbatim 1.0 file and a
verbatim 1.0 cup — **new features can never lock you out of your own history.**

Corrupt input is still rejected rather than guessed at.

---

## Phone and Mac

Both devices read **one file** in the app's iCloud Drive container, so there is
no sync to think about. Writes are coordinated (`NSFileCoordinator`) and merged
**per record** by `modifiedAt` — never whole-file — so neither device can
flatten the other's work. Rinses are tombstones, so a bag deleted on the phone
cannot come back from the Mac. No iCloud account? It falls back to local storage
and the main screen says *This device*.

Atomic writes go through `Data.writeAtomically(to:)`: write a neighbour file,
then swap it in.

---

## Building it

```bash
tools/build.sh          # builds for the iPhone 17 Pro simulator
tools/build.sh test     # builds and runs the whole suite
```

Two traps the script handles:

- Anything under `~/Documents` collects macOS extended attributes and
  `codesign` refuses them — *"resource fork, Finder information, or similar
  detritus not allowed"*. The script clears them, skipping `.git` (whose
  objects are read-only).
- Derived data must land **outside** `~/Documents` for the same reason.

Icons are drawn by `tools/make-icons.py`. It writes a labelled contact sheet of
every candidate, and `python3 tools/make-icons.py C` installs one of them.

---

## Tests

Unit tests cover the places where a silent bug costs data or trust: cup policy,
cup proving, the per-record merge, tolerant decoding of old files, grams left,
ratios per method, money totals, and every branch of the coach for every method
(including a sweep asserting it always has something usable to say).

UI tests run in CI on **every push** (`.github/workflows/tests.yml`) and find
every control by its **accessibility identifier**, never by the words on it. The
`Tab` enum's raw values are those identifiers, which is why `shots` is still
`tab-shots` even though the tab now reads *Brews*.

The suite grows by one or two per release, never in a heap:

| | |
|---|---|
| 1.0 | `testLoggingAShotPutsItInTheList`, `testSavingACupProvesItself` |
| 1.1 | `testEachMethodShowsOnlyItsOwnDials`, `testAddingAPurchaseReachesTheTotals` |

**A red run means the build is not fit to install.**

---

## Version history

Kept in `App/Sources/Guide.swift` as the single source — the main screen, the
in-app guide and `VersionHistoryTests` all read that one list, so the version on
screen and the newest entry can never drift apart.
