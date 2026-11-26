# Settings

`SettingsView.swift`, `KitView.swift`. Everything touched once lives here, so
the morning screen stays a morning screen.

| Section | Identifier | What it is |
| --- | --- | --- |
| Where the data lives | `settings-where` | iCloud Drive or this device, named plainly |
| The Cup System | `settings-cups` | pour, test, restore; `cups-*` identifiers |
| Your kit | `settings-kit` | equipment, with warranty warnings — and no totals |
| The Sink | — | rinsed things, restorable for 30 days |
| A backup file (2.6) | `settings-backup`, `settings-open-backup` | named, placed anywhere, proved by reading it back — see [cups.md](cups.md#the-backup-file-26-backupfileswift-backupbuttons-in-cupsviewswift) |
| Last backup file (2.7) | `settings-last-backup` | one quiet line under the backup buttons: *Last backup file: 3 days ago*, or *No backup file saved yet*. Only a **proved** save counts. Never a warning or a reminder |
| How this works | `settings-guide-toggle` → `settings-guide-list` | the guide below |
| Version history | `settings-version-toggle` → `settings-version-list` | every version, newest first |

The version number is shown in the app (the Version history pill reads *v2.10 · headline*). The two pills are named in the app *How this works* (subtitle: *14 short chapters*) and *Version history*; some older notes call them "How it works" and "What's new".

## How this works (the guide)

`Guide.chapters` in `Guide.swift` — one source for the whole guide, so it
cannot drift from the app. Chapters (14, as of 2.10): The idea · Bags of beans · Making coffee ·
Finding a brew · The coach · Your kit · Photos · The Cup System · Why old cups still open · The
Sink · Phone and Mac · Settings · **Signs in this app (2.10)** · Coming next.

**Signs in this app** lists every mark and colour that carries a meaning, one
line each — **31 lines** in 2.10: the four tab colours (Today pink, Beans green,
Brews blue, Settings purple); the brew light (green lovely, yellow drinkable,
pink tipped out); a bag's verdict (filled star, thumb down, question mark),
its rating stars and grams-left bar; the four freshness words (resting, at its
best, fading, past it) and the running-out chip; on Today *In the hopper*, the
four numbers, the orange kit *Done* line, the coach card and the *What should I
change?* chips; the timer's four colours; the dial-in line colours (grind,
dose, time, taste); cups (green tick, warning mark, purple keepsake); kit (*due*
/ *fine*, warranty shield); *from the label*; and the red remove word. It is
written from the code (`Candy`, `LightMark`, `VerdictMark`, `TabMark`,
`Candy.forFreshness`, `Candy.forRunningOut`, `Candy.forStanding`). **A new mark
or colour in a release adds a line here in the same release.**

## Version history

`Guide.releases`, newest first. `Guide.appVersion` must equal
`Guide.current.version`, and a test asserts it.

**Every release adds an entry and never edits an old one**, and every release
updates the chapters for each part that changed — and these spec files, in the
same commit.

## Your kit

Equipment, grinders, scales and the rest, each with a kind
(`kit-kind-<rawValue>`), a shop, a date (`kit-date`), an optional warranty
date (`kit-has-warranty` → `kit-warranty`), a receipt photo and notes.

A **Warranty running out** card (`kit-warranties`) appears above the list when
any live item's warranty falls within the next **60 days**, soonest first, each
line naming the item and the date. An expired warranty is not listed — there is
nothing left to act on.

**No totals, no spend split, no cost per cup.** The Money tab was deleted in
2.0 at his request.

A grinder's card carries *Burrs fine* / *Burrs due*, a machine's *Backflush
fine* / *Backflush due* (apricot when due).

## Looking after it (2.6)

`KitCare.swift`. Only a **grinder** (task *burrs*) and a **machine** (task
*backflush*) are looked after; every other kind shows nothing.

- **Counted, never typed.** A grinder adds up the `doseGrams` of every live
  brew of **every** method; a machine counts live **espresso** brews only.
  Both count brews dated after `since` = the latest `careDone` date, or the
  start of the day in `date` (when it arrived). Rinsed brews and rinsed kit
  never count. With two grinders, each counts every brew.
- **How often:** `burrEveryKg` (default **5 kg**, dial 1–100 in steps of 1) and
  `backflushEveryShots` (default **50**, dial 5–500 in steps of 5), identifier
  `kit-care-every`. Due when the count reaches the number.
- **The card** in the editor (`kit-care`): *Looking after it*, what is
  counted, the line (`kit-care-line`, *"0.6 of 1 kg since 1 Oct"*, apricot and
  prefixed *Backflush due ·* when due), the dial, **Burrs done today** /
  **Backflushed today** (`kit-care-done`, kept on Save), and *Last done 1 Oct
  2026 · 3 times in all* (`kit-care-last`). Every date is kept in `careDone`.
- Dates read *1 Oct* in the app's English, with the year only when it is not
  this year.
