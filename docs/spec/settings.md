# Settings

`SettingsView.swift`, `KitView.swift`. Everything touched once lives here, so
the morning screen stays a morning screen.

| Section | Identifier | What it is |
| --- | --- | --- |
| Where the data lives | `settings-where` | iCloud Drive or this device, named plainly |
| The Cup System | `settings-cups` | pour, test, restore; `cups-*` identifiers |
| Your kit | `settings-kit` | equipment, with warranty warnings — and no totals |
| The Sink | — | rinsed things, restorable for 30 days |
| Export / Import | `settings-export`, `settings-import`, `settings-share` | the whole lot as one file |
| How it works | `settings-guide-toggle` → `settings-guide-list` | the guide below |
| What's new | `settings-version-toggle` → `settings-version-list` | every version, newest first |

The version number is shown in the app.

## How it works

`Guide.chapters` in `Guide.swift` — one source for the whole guide, so it
cannot drift from the app. Chapters: The idea · Bags of beans · Making coffee ·
The coach · Your kit · Photos · The Cup System · Why old cups still open · The
Sink · Phone and Mac · Settings · Coming next.

## What's new

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
