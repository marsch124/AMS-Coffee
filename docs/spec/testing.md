# Testing

Every change gets a test that finds its control **by accessibility
identifier, never by the words on it**, and every test is seen failing before
it is believed. The suite runs in CI on every push, and a red run blocks the
release.

As of 2.9: **140 checks of the rules** (`Tests/`) and **22 of the screens**
(`UITests/`).

## What the rule tests guard

| Area | Examples |
| --- | --- |
| Tolerant decoding | a verbatim 1.0 file and a verbatim 1.0 cup still open; garbage is still rejected |
| Cup policy | a shrunken cup is refused; a cup counts and proves bags, brews and kit |
| Merging | per record by `modifiedAt`; tombstones survive |
| The coach | every branch, and every starter recipe lands inside its own window |
| Brew methods | each method's dials; only pour-over and filter bloom; only AeroPress and French press steep in minutes |
| The timer | all four bands of `TimerStanding`, both boundaries, and the proportional lead |
| Freshness | the four stages, the singular "1 day", no date, a date in the future |
| Running out | the three warnings, silence above them, a weightless bag, and the dose coming from the bag's own recipe |
| Dial-in chart (2.5) | one bag + one method, oldest first, Sink left out; opens on the last method; grind finer/coarser; nothing moved; time inside, short of and past the window; cold brew's clock is its steep; taste in words; one brew is not a trend |
| Search (2.5) | empty matches all; bag, roaster, origin, method and note; every word must match; accents and case ignored; a brew with no bag; newest first; the Sink skipped; works with the method filter |
| Label (2.6) | roaster, origin and roast date from words; five date shapes; best-before ignored; future and ancient dates ignored; Swedish spellings; no guessed roaster; never offered for a filled field; **real Vision reading of a drawn picture** |
| Kit care (2.6) | grams since bought, every method; machine counts espresso only; due at the limit; done restarts the count and keeps the date; defaults; rinsed kit and brews; an older file opens |
| Backup file (2.6) | a safe file name; proved by read-back; a short or garbage file is not proved; opening previews, takes a safety cup and replaces |
| Same again, search (2.6) | the newest green brew only; a new brew, untasted; light words; month, year, today, yesterday; several words together |
| Dials (2.6) | a four-digit number is written without a thousands space on a Swedish phone, and the box is wide enough |
| Label name and process (2.7) | process in three languages, two together, whole words only, never from a tasting-notes line, but read from a spec line that opens with it; name only when one line is plainly left, or one is clearly taller; weights, whole bean, profile words, addresses and dates are never names; shouted names read naturally; never offered for a filled field |
| Roast level, from the label (2.8) | roast level in three languages and the Swedish compounds; never from a flavour or body word; a roast line is never the name; only for an empty box; the mark shows while the box holds what the label gave and goes once it is changed; a roast date only on the same day |
| Card details and roast search (2.9, `Release29Tests`) | the card line joins origin, process and roast and skips what is empty, none at all when all are empty; *Light* reads *Light roast* and one that already says roast stays as typed; search finds roast in English, Swedish and German; a hand-typed roast answers in all languages; *roast* finds any bag with a roast; whole word only (*dark* not medium-dark, *medium* not medium-dark, *light* not medium-light), *medium dark* as one level; every word still has to match (*kenya light*) |
| Last backup file (2.7) | plain words from today to months; the date travels in the file and an old file still opens; phone and Mac keep the later; only a proved save sets it and a restore never winds it back |
| Asking outright | sour and bitter disagree; lovely changes nothing; the old taste cannot steer a new question; every method answers every complaint |

## Tests that have earned their keep

- `testOpeningABackupPreviewsThenTakesASafetyCup` (2.6) would have failed on
  the old restore: it merged with the file on disk, so a restore kept
  everything newer and put almost nothing back. Restore now writes without
  merging.

- `testEveryStarterLandsInsideItsOwnWindow` caught the cold-brew default
  recipe sitting outside the window the coach judges cold brew by — the app
  would have argued with its own defaults.
- `testEveryTimedMethodHasSomewhereForTheClockToLand` went red and found that
  AeroPress and French press have no Total-time dial. That turned out to be
  correct — their clock lands in Steep — so the test was rewritten to state
  the real rule. An over-strict invariant that fails is still a finding.
- `testANewBrewSaysWhereItsNumbersCameFrom` (2.4) caught the new
  "where the numbers came from" line being placed inside the part of the
  screen that only exists once you own a bag, so a very first brew would have
  had no explanation.

## Traps in testing this app

- 🚨 **Never `app.descendants(matching: .any)[id]`.** It walks the whole tree
  on every call and turned a 20-second suite into a six-minute hang. Use
  `app.buttons[id]` / `app.otherElements[id]` / `app.staticTexts[id]`.
- 🚨 **Naming a screen container steals its children's identifiers.** A control
  inside a `safeAreaInset` inherits its ancestor's id — the tree once showed a
  button labelled "Pull a shot" answering to `screen-shots`. This is a real
  VoiceOver bug, not only a test problem. Never put an
  `.accessibilityIdentifier` on a whole screen.
- A container needs `.accessibilityElement(children: .contain)` before its own
  identifier can be found.
- A control below the fold exists but is not hittable. Scroll with
  `scrollView.swipeUp()`, never a raw coordinate drag — a drag can land in a
  text field, raise the keyboard and hide the Save bar.
- 🚨 **CI's Xcode is older than the Mac's.** Long arithmetic expressions that
  compile locally can fail there with "unable to type-check this expression in
  reasonable time". Annotate values `Double` and keep one constant per line in
  trig loops.
- 🚨 **The simulators are shared between conversations.** Another session
  driving a different app on the same device will take the foreground
  mid-check. Confirm which app is in front before believing a screenshot.
