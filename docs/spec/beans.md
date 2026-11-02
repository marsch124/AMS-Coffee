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

## The editor

Every field, then **Save** and **Cancel**; Remove is one calm red, last, and
asks first (`bag-rinse-confirm`). Roast date is behind a switch
(`bag-has-roastdate` → `bag-roastdate`) so a bag without one stays clean.
Flavours are tapped words (`flavour-<name>`), never emoji. Verdict is
`bag-verdict`. A photo of the bag can be taken or chosen.
