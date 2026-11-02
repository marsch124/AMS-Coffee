# Bags of beans

`BagsView.swift`. The list of bags, newest-useful first, with **Add a bag** at
the bottom (`bags-add`) — his rule: a list should open with what is in it.

Empty state: `bags-empty`.

## The card (`BagCard`, identifier `bag-row-<index>`)

Photo if there is one · roaster upper-cased · name · a grams-left bar · then
chips. `index` exists on the card only so its chips can carry distinct
identifiers.

### Chips

| Chip | Identifier | Example |
| --- | --- | --- |
| Grams left | — | `214 g left` |
| Days off roast | `bag-freshness-<index>` | `11 days · at its best` |
| Running out | `bag-running-out-<index>` | `1 more brew` |

The chips and the stars sit in a **`FlowRow`, which wraps** (2.5). They used to
sit in an `HStack`; a `Chip` is `fixedSize` horizontally, so grams left + days
off roast + five stars were wider than an iPhone 17 Pro and pushed the whole
Beans screen — tab bar included — off both sides.

## Days off roast (2.3)

`Bean.daysOffRoast`, `Bean.freshness`, `Bean.freshnessText` in `Model.swift`.

Whole days between the start of the roast day and the start of today.

| Days | Freshness | Word | Colour |
| --- | --- | --- | --- |
| 0–3 | `.resting` | resting | sky |
| 4–21 | `.best` | at its best | mint |
| 22–42 | `.fading` | fading | mango |
| 43+ | `.old` | past it | apricot |

The chip reads `12 days · at its best`, and `1 day · resting` in the singular.

**Edge cases**

- **No roast date → no chip.** Saying nothing beats guessing.
- **A roast date in the future → no chip.** That is somebody mis-tapping the
  date wheel; `-3 days · resting` would be worse than silence.

## Running out (2.4)

`CoffeeData.brewsLeft(for:method:)` and `runningOutText(for:method:)` in
`Shelf.swift`.

| Brews left | Chip | Colour |
| --- | --- | --- |
| 0 | `not enough for another` | Danger |
| 1 | `1 more brew` | apricot |
| 2 | `2 more brews` | mango |
| 3 or more | *(nothing)* | — |

The dose comes from **that bag's own recipe** (`nextDose`), not a fixed
number: a bag used for filter at 30 g a time runs down twice as fast as an
espresso bag at 18 g. A bag with **no weight entered** returns nil from both
and is never counted down.

Quiet until it matters — a warning that is always on is not a warning.

### Why

Idea 12 of the 20, picked 20 Sep 2026: *"Warn me before the bag runs out."*

## How you dialled it in (2.5, `DialInCard` in `DialIn.swift`)

A card in the bag editor, after *What does it taste like?* and before Remove,
on an existing bag only. Nothing at all for a bag with no live brews.

- **Which brews:** this bag, one method, live only (the Sink is left out),
  **oldest first** — `DialIn.brews(in:beanID:method:)`.
- **Which method:** the one used most recently with this bag
  (`DialIn.defaultMethod`). With more than one method, a chip per method
  (`dialin-method-<rawValue>`) switches; the chosen one is ink-coloured.
- **One brew:** no chart — *One espresso so far. Make another with this bag and
  the line starts here.* (`bag-dialin-waiting`).
- **Two or more:** the chart (`bag-dialin`). First a summary line,
  *"3 brews · 1 green · the last one green"*, then four lines
  (`dialin-grind`, `dialin-dose`, `dialin-time`, `dialin-taste`) — every method
  has all four. Each line: its name, a sentence comparing the first brew with
  the newest, and a drawn sparkline 44 pt high.

| Line | Value | Sentence | Colour |
| --- | --- | --- | --- |
| Grind | `grind` | `15 → 13.5 · finer` (lower = finer) / `15 all along` | blueberry |
| Dose | `doseGrams` | `18 → 18.5 g` / `18 g all along` | grape |
| Time | `totalSeconds` (steep hours on cold brew) | `21 s → 28 s · in the window`, `· short of 25–32 s`, `· past 25–32 s` | sky |
| Taste | `sourBitter` (−1 sour … +1 bitter) | `sour → balanced` / `balanced all along` | bubblegum |

Time is shown in the unit of the method's window — seconds, minutes (to the
half) or hours (to the half) — and judged against `idealSeconds`, the same
window the coach and the timer use. Taste words: under 0.15 either way
*balanced*; under 0.45 *a little sour/bitter*; beyond, *sour/bitter*.

**The sparkline** (`Sparkline`): brews evenly spaced left to right (by order,
not by date, so a busy weekend does not squash the line). The vertical range
is the values stretched to include the band, so *where you want to be* is
always on the chart. Bands: the coach's window on Time, −0.15…0.15 on Taste,
none on Grind and Dose. Each dot is coloured by the brew's light (mint /
mango / bubblegum). The drawing is hidden from VoiceOver; the sentence is what
it reads. Every value in the drawing is typed `Double` and each step kept short
— CI's older compiler gives up on long expressions.

### Why

Idea 1 of the 20, picked 20 Sep 2026: *"The dial-in chart — show how my numbers
for a bag moved over time so I can see where it is heading."*

## The editor

Every field, then **Save** and **Cancel**; Remove is one calm red, last, and
asks first (`bag-rinse-confirm`). Roast date is behind a switch
(`bag-has-roastdate` → `bag-roastdate`) so a bag without one stays clean.
Flavours are tapped words (`flavour-<name>`), never emoji. Verdict is
`bag-verdict`. A photo of the bag can be taken or chosen.
