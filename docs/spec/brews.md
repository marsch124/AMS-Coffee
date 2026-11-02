# Brews

`ShotsView.swift`. The list of brews, newest first, with **Pull a shot** at the
bottom (`shots-add`). Empty state: `shots-empty`.

Above the list: "Or make it another way" (`shots-methods`) — one button per
method, `method-<rawValue>` — and a filter row, `filter-all` plus
`filter-<rawValue>` with a count per method.

Each row is `shot-row-<index>`: the bag, the method, the date, then pills for
grind, dose→yield and time, and the coach's note.

## The seven methods

`BrewMethod` in `Model.swift`. Each one declares its own dials, so no screen
ever asks for something the method does not have.

| Method | Dials | Window (`idealSeconds`) |
| --- | --- | --- |
| `espresso` | grind, dose, yield, seconds, temp, pre-infusion | 25–32 s |
| `v60` (Pour-over) | grind, dose, water, temp, bloom water, bloom time, pours, seconds | 150–210 s |
| `filter` | as pour-over | 240–360 s |
| `aeropress` | grind, dose, water, temp, steep minutes, plunge | 90–180 s |
| `frenchPress` | grind, dose, water, temp, steep minutes | 210–270 s |
| `moka` | grind, dose, water, seconds | 180–300 s |
| `coldBrew` | grind, dose, water, steep hours | 12–18 h |

Derived properties: `isWeighedByWaterIn` (everything but espresso),
`hasInvertedSwitch` (AeroPress only), `worthTiming` (everything but cold
brew), `hasBloom` (pour-over and filter), `steepsInMinutes` (AeroPress and
French press).

`starter()` gives each method a sensible recipe when the bag has no history.

## The editor (`ShotEditor`)

In order: **Which bag?** → **Time it** → the dials → the computed figures →
a photo → **How was it?** → the coach → Save/Cancel, with Remove last.

### Where the numbers came from (2.4)

`shot-starting-from`, shown only on a **new** brew:

- With history: `Same again: your best espresso on this bag, 20 Sep.`
  ("best" when that brew was green, otherwise "last".)
- Without: `Nothing logged for this bag yet — starting from the usual espresso.`

`CoffeeStore.draftShot(beanID:method:)` has copied the bag's best brew into
every new brew since version 1.0; until 2.4 there was no way to tell your own
recipe from a generic starting point.

**It sits outside the "has bags" branch of the screen.** It was first written
inside it, which meant a very first brew — before any bag exists — got no
explanation at all. `testANewBrewSaysWhereItsNumbersCameFrom` caught that
before release.

### Why

Idea 2 of the 20, picked 20 Sep 2026: *"Same again."*

## The timer (`BrewTimer.swift`, 2.2–2.3)

Card identifier `shot-timer`, shown when `method.worthTiming`. Cold brew has
no stopwatch: it steeps overnight.

- The clock is worked out from a **start `Date`**, never by counting ticks.
  Lock the phone mid-pour or take a call: the time is still right, because
  nothing was being counted. `TimelineView(.periodic(by: 0.2))` only redraws.
- **Stopping is what commits the time.** On stop, `seconds` is written; for a
  method that `steepsInMinutes`, the steep is also written in minutes to the
  nearest half.
- Buttons: `timer-start` / `timer-stop` (the same button, relabelled Start →
  Stop → Carry on), `timer-bloom` ("Bloom done", pour-over and filter only,
  and only while running), `timer-reset` ("Start over", calm red, last).
- `timer-aim` reads `aim 25–32 s`, or in minutes for the long methods.
- `timer-display` carries the elapsed seconds as its accessibility value.

### Where it stands — `TimerStanding`

Pulled **out of the view** on purpose: a rule you can only check by watching a
screenshot for thirty seconds is a rule nobody checks.

```
lead = max(5, window.lowerBound * 0.15)
elapsed > upper              → .past     "past it"   Danger
elapsed >= lower             → .there    "there"     mint
elapsed >= lower - lead      → .nearly   "nearly"    mango
otherwise                    → .settling  (no word)  Ink
```

So an espresso warns 5 seconds early and a filter 36 seconds early. Nothing is
said while it settles — the number alone is the message.

### The buzzes (iPhone only, `#if os(iOS)`)

Watched on their own clock in a `Task`, never from inside the view body — a
view body must not set state, and a haptic fired there would fire again on
every redraw. Each mark fires **once**: end of pre-infusion (rigid impact),
reaching the window (success), running past it (warning). Taps you make
yourself get a light knock.

## How was it?

Two sliders — sour ↔ bitter and thin ↔ syrupy — and a light:
`light-green`, `light-amber`, `light-red`. Green means keep it exactly here,
and that brew becomes the recipe the bag offers next time for that method.
