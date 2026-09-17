# ☕ AMS Coffee

A native app for iPhone **and** Mac (one SwiftUI target, XcodeGen project) that
remembers what coffee you bought, what it tasted like, and exactly how you made
the good ones.

**Live version: 1.0** — see the Version history pill on the app's main screen.

---

## What it does

| | |
|---|---|
| 🫘 **Bags** | Roaster, bean, origin, process, weight, price, roast date. Tap the flavours you taste, give it stars, stamp it *Buy again* or *Never again*. The grams-left bar counts itself down as you pull shots. |
| 🎛 **Dial-in** | Grind, dose in, yield out, seconds, water temperature, pre-infusion. Ratio and flow rate compute themselves. Taste goes in as two sliders — sour ↔ bitter, thin ↔ syrupy — plus 🔴 🟡 🟢. |
| 🧑‍🏫 **The coach** | Reads the shot and gives **one** change: sour and fast → finer; bitter and slow → coarser; green → keep it exactly here, and that shot becomes the bag's recipe next time. |
| 🏺 **Cups** | The safety system. See below. |
| 🚰 **The Sink** | Rinsed bags and shots wait 30 days instead of vanishing. |
| 📜 **Version history** | Folded onto the main screen, unfolds in place. Never tidied up. |
| 📖 **How this works** | Nine short chapters, in the app, kept current with every release. |

Espresso ships in 1.0. Pour-over, AeroPress, French press, Moka, cold brew and
filter are in the model already (`BrewMethod`) and get their own fields and
screens in 1.1 — no data migration needed. Purchases and photos follow.

---

## 🏺 The Cup System

Every save is poured into a cup. Cups sit on a shelf you can look at.

- 🥤 **Quick cup** — after every change, silently. Last 10 kept.
- ☕️ **Daily cup** — once a day. Last 7 kept.
- 🏺 **Keepsake cup** — when you press *Save a cup*. Kept forever.

Three rules, each one a lesson from a real data loss in another app:

1. **Each cup proves itself.** `CupCupboard.test(_:)` reads the file back,
   decodes it and counts the records. Only a match earns the green ✓. "The
   write returned no error" is not proof of anything.
2. **A cup never shrinks silently.** `CupPolicy.mayPour` refuses a cup holding
   less than the newest cup on the shelf, and the shelf raises a warning the
   main screen shows. A good backup can never be overwritten by an empty one.
3. **Restoring takes a safety cup first.** Pouring a cup back previews the
   change (`+2 bags · −14 shots`) and saves the present as *Before restore*.

Pruning never takes a keepsake, never takes the newest cup of a kind, and only
runs after the new cup has passed its test.

---

## Phone and Mac

Both devices read **one file** in the app's iCloud Drive container, so there is
no sync to think about. Writes are coordinated (`NSFileCoordinator`) and merged
**per record** by `modifiedAt` — never whole-file — so neither device can
flatten the other's work. Rinses are tombstones, so a bag deleted on the phone
cannot come back to life from the Mac. No iCloud account? It falls back to local
storage and the main screen says *This device*.

Atomic writes go through `Data.writeAtomically(to:)`: write a neighbour file,
then swap it in.

---

## Building it

```bash
tools/build.sh          # builds for the iPhone 17 Pro simulator
tools/build.sh test     # builds and runs the whole suite
```

Two traps the script handles for you:

- Anything under `~/Documents` collects macOS extended attributes, and
  `codesign` refuses them — *"resource fork, Finder information, or similar
  detritus not allowed"*. The script runs `xattr -cr .` first.
- Derived data must land **outside** `~/Documents` for the same reason.

The icon is drawn by `tools/make-icon.py` (flat calm background, hand-drawn
white glyph, nothing glowing).

---

## Tests

Unit tests cover the parts where a silent bug costs data or trust: cup policy,
cup proving, the per-record merge, grams left, ratio, and every branch of the
coach.

UI tests run in CI on **every push** (`.github/workflows/tests.yml`) and find
every control by its **accessibility identifier**, never by the words on it — so
rewording a button can never turn the suite red. Two to begin with, one added at
a time:

1. `testLoggingAShotPutsItInTheList`
2. `testSavingACupProvesItself`

**A red run means the build is not fit to install.**

---

## Version history

Kept in `App/Sources/Guide.swift` as the single source — the main screen, the
in-app guide and `VersionHistoryTests` all read that one list, so the version on
screen and the newest entry can never drift apart.
