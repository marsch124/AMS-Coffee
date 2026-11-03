# Bags of beans

`BagsView.swift`. The list of bags, newest-useful first, with **Add a bag** at
the bottom (`bags-add`) — his rule: a list should open with what is in it.

Empty state: `bags-empty`.

## The card (`BagCard`, identifier `bag-row-<index>`)

Photo if there is one · roaster upper-cased · name · a grams-left bar · then
chips. `index` exists on the card only so its chips can carry distinct
identifiers.

### The details line (2.9, `bag-details-<index>`)

One quiet line under the name: **origin · process · roast**, e.g.
*Colombia · Anaerobic natural · Medium-light roast*. 17 pt bold, in the bag's
own colour. Before 2.9 the card showed neither origin nor process.

- `Bean.cardDetails` joins the parts that are filled in with ` · `; each part
  is trimmed and skipped when empty. Nothing filled in → **no line at all**
  (no `bag-details-<index>` element).
- `Bean.roastCardText` writes the roast: *Light* → *Light roast*. A roast that
  already says roast (*Light roast*, *Ljusrost*, *Helle Röstung*) stays as
  typed.
- Test: `testABagCardShowsItsRoast` (screen test 21) finds
  `bag-details-<index>` by identifier.

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

Every field — roaster (`bag-roaster`), name (`bag-name`), origin
(`bag-origin`), process (`bag-process`) and, from 2.8, roast
(`bag-roastlevel`, *Roast (light, medium, dark…)*, stored in the long-existing
`Bean.roastLevel` that had no box before) — then **Save** and **Cancel**; Remove is one calm red, last, and
asks first (`bag-rinse-confirm`). Roast date is behind a switch
(`bag-has-roastdate` → `bag-roastdate`) so a bag without one stays clean.
Flavours are tapped words (`flavour-<name>`), never emoji. Verdict is
`bag-verdict`. A photo of the bag can be taken or chosen.

## Reading the label (2.6, `LabelReader.swift`)

When a **new** photo is taken or chosen in the bag editor (`PhotoRow`'s
`onNewPhoto`), the full-size picture is read **on the device** with Vision
(`VNRecognizeTextRequest`, accurate, language detected, the photo's own
orientation respected). No internet. Only a photo that was just taken or
chosen is read — opening a bag with a photo reads nothing.

- While reading: *Reading the label…* (`bag-label-reading`).
- Nothing usable: one quiet line, *Nothing on this label I could read as a
  name, roaster, origin, process, roast or roast date.* (`bag-label-nothing`).
- Otherwise *From the label — tap to use* (`bag-label-suggestions`) with one
  full-width row per suggestion and a **Use** pill:
  `bag-label-suggest-name` (2.7), `-roaster`, `-origin`, `-process` (2.7),
  `-roastlevel` (2.8), `-roastdate`.
- **Never overwrites.** `LabelSuggestion.offered(for:hasRoastDate:)` offers a
  name, roaster, origin, process or roast only while that field is blank (spaces count as blank),
  and a roast date only while the switch is off. Typing in a field makes its
  row disappear; tapping Use fills it (the date also turns the switch on).

The rules (pure, tested):
- **Roaster** only when a line says it is one: *roaster(s)*, *roastery*,
  *roasting co*, *rosteri*, *rösterei*, *coffee co*, *coffee company*,
  *torrefazione*, *brûlerie*. An all-capitals line is put in title case.
  Nothing is guessed from big letters.
- **Origin**: 40 coffee countries, matched as whole words in English, Swedish
  or German spellings (*Kenia* → Kenya, *Etiopien* → Ethiopia, *Sumatra* →
  Indonesia), returned in English.
- **Roast date**: *2026-10-20*, *20.10.2026*, *20/10/26*, *20 Oct 2026*,
  *October 20, 2026* — day before month when ambiguous, as in Sweden. A line
  with *best*, *bäst*, *use by*, *exp*, *bbe*, *mhd*, *haltbar* is never read;
  a date after tomorrow or over a year back is not believed; a line saying
  *roast* / *rost(ad)* wins over a bare date.
- **Process** (2.7): whole words only, in English, Swedish or German, returned
  in plain English — *washed / fully washed / tvättad / gewaschen / lavado* →
  Washed; *natural / naturlig / naturell / natur* → Natural; *honey / honung /
  honig* → Honey; *anaerobic / anaerob / anaerobisk* → Anaerobic;
  *wet-hulled / wet hulled / giling basah* → Wet-hulled; *carbonic maceration*
  → Carbonic maceration. Two together read as one: *Anaerobic natural*. A
  line that names tasting notes (*notes*, *tasting*, *smak*, *aroma*,
  *geschmack*, *noter*) or lists three or more words between commas or dots
  is skipped, so *honey* as a flavour is never read as the process — except
  a spec line whose **first** item is nothing but a process (*Tvättad · SL28
  · SL34*, *Natural, Heirloom, 2100 masl*); one opening with *Honey* must
  also carry a number (a variety or altitude), which a flavour list does not.
  *Naturally* and *unwashed* are not matches.
- **Name** (2.7) — careful, because a wrong guess is worse than none. Every
  line is struck out that is the roaster line, names a country, holds a date,
  names a process, is a tasting-notes line, holds a weight (*250 g*, *1 kg*,
  *12 oz*), is a web or mail address, says *whole bean / ground / hela bönor /
  malet / ganze Bohne / gemahlen*, says *net*, *weight*, *vikt*, *best*,
  *altitude*, *masl*, *variety*, *producer*, *region* and the like, or is only
  a profile word (*Espresso*, *Filter*, *Omni*, *Coffee*, *Kaffe*,
  *Single origin*, *Light/Medium/Dark roast*). What is left must be 3–40
  characters with at least three letters and at most six words. Then: **one
  line left → that is the name**; several → the tallest wins only when it
  stands at least 1.3 times taller than every other; otherwise **nothing**. An
  all-capitals name is put in title case, with grades (*AA*, *AB*, *PB*) and
  words with digits (*SL28*) kept as they are; a name in mixed case is kept
  exactly.
- **Roast level** (2.8): *Light*, *Medium-light*, *Medium*, *Medium-dark*,
  *Dark*, from English, Swedish or German (*ljusrost*, *helle Röstung* →
  Light; *mellanrost*, *mittlere Röstung* → Medium; *mörkrost*, *dunkle
  Röstung* → Dark; *medium light*, *medium dark*). Because light, medium and
  dark are also flavour and body words, a level counts only on a line that
  speaks of roasting (*roast*, *rost*, *Röstung*, *level*, or a Swedish
  compound like *ljusrost*) or when it stands alone on its line; tasting-notes
  lines are skipped. *Dark chocolate* and *light and juicy* give nothing. A
  roast line is never the name.
- **From the label** (2.8): tapping Use records the value in `LabelFills`
  (in `LabelReader.swift`). While a box still holds exactly that value
  (spaces ignored), `FatField(fromLabel:)` shows *from the label* in 15 pt
  bubblegum beside its title — `bag-name-from-label`, `bag-roaster-…`,
  `bag-origin-…`, `bag-process-…`, `bag-roastlevel-from-label`; a roast date
  shows `bag-roastdate-from-label` beside the date while it is the same day.
  Editing the box removes the mark. It lives only in the editor and is not
  stored.
- Under `-uiTesting`, the words come from the `LABEL_LINES` environment value
  (separated by `|`) when a new bag opens.

## Same again from here (2.6)

At the bottom of *How you dialled it in*, for the method shown:
**Same again from here** (`dialin-same-again`), full colour, with *Your green
espresso from 1 Nov: grind 13.5 · 18 g · 30 s* underneath. It opens a new
brew carrying that brew's recipe (`Shot.again(from:)`: same bag and numbers,
amber, no note, no photo). It is there only when `CoffeeData.bestGreen` finds a
green brew of this method on this bag — the newest green one — so it shows
even when the chart itself is still waiting for a second brew.
