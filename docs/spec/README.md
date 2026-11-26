# AMS Coffee — written specification

Every screen, rule, number and edge case of the app, written **from the code**,
so the app could be rebuilt from this description without guessing.

Updated in the same commit as every release. If a release changes behaviour and
these files do not change, the release is wrong.

> **This repository is public.** Every example here is invented. No real bag,
> roaster, photo or brew of Martin's appears in these files.

| File | Area |
| --- | --- |
| [model.md](model.md) | What is stored: every record, every field, every default |
| [today.md](today.md) | The Today screen |
| [beans.md](beans.md) | Bags of beans: the list, the editor, freshness, running out, the dial-in chart |
| [brews.md](brews.md) | Brews: the list, search, the editor, the seven methods, the timer |
| [coach.md](coach.md) | The coach: windows, advice, and asking outright |
| [cups.md](cups.md) | The Cup System, the Sink, and how data is kept safe |
| [settings.md](settings.md) | Settings, the guide (*How this works*), *Version history*, your kit and looking after it, the backup file |
| [testing.md](testing.md) | What the tests guard, and the traps in testing this app |
| [Picture mode](#picture-mode-210) | Launch words that fill the app with made-up coffee for pictures |

## The shape of the app

One SwiftUI target builds both the iPhone and the Mac app
(`supportedDestinations: [iOS, macOS]` in `project.yml`). Bundle
`com.schabbauer.AMSCoffee`, team `D24ENP83QQ`, built by XcodeGen from
`project.yml` — the `.xcodeproj` is generated and must never be edited by hand.

Four tabs, and only four: **Today · Beans · Brews · Settings**
(`Tab` in `AMSCoffeeApp.swift`, raw values `today`, `bags`, `shots`,
`settings` — the raw values are stable test identifiers and deliberately do
not match the visible labels). Every one-off thing — the guide (*How this works*), the Version history,
the cups, the Sink, your kit, the backup file — lives in Settings, so the
morning screen stays a morning screen.

## House rules this app obeys

Set by Martin, each one learned the hard way (dates in `docs/spec/*.md` and in
`Guide.swift`'s Version history).

- **No money anywhere he has to see it.** No totals, no cost per cup. His
  words, 18 Sep 2026: *"I don't like to talk about money. This is about
  experiencing the coffee and having fun."*
- **No Apple art at all** — no SF Symbols and no emoji. Every mark is drawn by
  hand as a SwiftUI `Path` in `Marks.swift`, `TabMarks.swift` and `Theme.swift`.
  Where a drawing would be worse than a word, the app uses the word.
- **Panels stand upright.** The old `tilt` parameter is deleted, not zeroed.
- **Nothing below 15 pt, and `.secondary` is banned** — this is Coffee's own
  rule, not a general one. Colours come from the asset catalogue with both a
  light and a dark value: `Ink`, `InkSoft`, `Card`, `Field`, `Danger`.
- **Remove and Delete are one calm red, quiet, and last on the screen.**
  Keeping a thing is always the easy way out.
- **Add buttons sit at the bottom** of a list, where a thumb is.
- **Escape is Cancel on the Mac.** `StickyBar`'s round close button carries
  `.keyboardShortcut(.cancelAction)` (2.6), so every editor and sheet closes
  on Escape.

## Picture mode (2.10)

For making pictures for the AMS Apps Overview and the course — **not** for
day-to-day use. `PictureSample.swift`, started from `AMSCoffeeApp.swift`.

**Launch words** (passed to the app on start):

| Word | Effect |
| --- | --- |
| `-pictures` | fills the app with the sample below |
| `-startTab today\|bags\|shots\|settings` | opens on that tab (Today, Beans, Brews, Settings); without it the app opens on Today. Uses the `Tab` raw values |

**The sample** is entirely invented:

- **4 bags:** Hilltop Roastery *Ethiopia Guji*, North Pier Coffee *Colombia
  Huila*, Lantern Roasters *Brazil Cerrado*, Fjord & Fern *Kenya Nyeri AA*.
- **10 brews** over the last week — espresso, V60, AeroPress, French press and
  moka — each with its dial-in values (grind, dose, yield or water, time,
  taste, light).
- **2 kit purchases.**

**What it never touches.** The sample is kept in a **temporary folder** — the
same arrangement the UI tests use — so it never reads or changes the real
coffee file, the real cups or the real photos, and **never touches iCloud**.
Starting the app normally afterwards shows the real coffee untouched.
