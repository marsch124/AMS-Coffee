# What is stored

One JSON file, `coffee.json`, holding a `CoffeeData`. It lives in the app's
iCloud Drive container when iCloud is available and in the app's own folder
when it is not; Settings always shows which (`settings-where`). Photos are
separate files beside it, referenced by id.

## Tolerant decoding — the rule that governs every record

Every record has a **hand-written `init(from:)` using `decodeIfPresent` plus a
default**, and an explicit memberwise `init`. A missing key is filled in, an
unknown key is ignored, and only genuine garbage is rejected.

This is why a file or a cup written by version 1.0 still opens today, and why
one written today will still open in a version nobody has written yet.
`OldFileTests` holds a verbatim 1.0 file and a verbatim 1.0 cup and asserts
they still open.

## `CoffeeData` — the whole file

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `schema` | Int | 2 (1 when missing) | |
| `beans`, `shots`, `purchases` | arrays | `[]` | |
| `savedAt` | Date | now | |
| `lastBackupFileAt` (2.7) | Date? | nil | when a backup file was last saved **and proved**; merging keeps the later, a restore never winds it back — see [cups.md](cups.md) |

## `Bean` — a bag of beans

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `id` | UUID | new | |
| `roaster` | String | `""` | shown upper-cased on the card |
| `name` | String | `""` | |
| `origin`, `process`, `roastLevel` | String | `""` | `roastLevel` gets a box in the editor from 2.8 |
| `roastDate` | Date? | nil | drives freshness — see [beans.md](beans.md) |
| `bagWeightGrams` | Double | 250 | 0 means "not entered": never counted down |
| `priceSEK` | Double | 0 | stored, never totalled or shown as a total |
| `rating` | Int | 0 | 0–5 stars |
| `verdict` | Verdict | `.undecided` | `buyAgain`, `never`, `undecided` |
| `flavours` | [Flavour] | `[]` | words only, no emoji |
| `notes` | String | `""` | |
| `photoID` | String? | nil | the photo is a file; this is only its name |
| `createdAt`, `modifiedAt` | Date | now | `modifiedAt` drives the merge |
| `rinsedAt` | Date? | nil | the Sink: a tombstone, not a deletion |

`displayName` falls back from name → roaster → "New bag".

## `Shot` — one brew

Carries every field any method might need; each method shows only its own
(`BrewMethod.fields`). Key fields: `method`, `beanID`, `date`, `grind`,
`doseGrams`, `yieldGrams`, `waterGrams`, `seconds`, `tempC`,
`preInfusionSeconds`, `bloomGrams`, `bloomSeconds`, `pours`, `steepMinutes`,
`steepHours`, `plungeSeconds`, `inverted`, `basket`, `photoID`,
`sourBitter` (−1 sour … +1 bitter), `thinSyrupy` (−1 thin … +1 syrupy),
`light` (`TrafficLight`: green, amber, red), `notes`, `rinsedAt`.

## `Purchase` — something for your kit

`kind` (`PurchaseKind`, default `.accessory`), `what`, `shop`, `priceSEK`,
`date`, `warrantyUntil` (a **date**, not a number of months), `notes`,
`photoID` (the receipt), `burrEveryKg` (default 5), `backflushEveryShots`
(default 50), `careDone` (every date the burrs or backflush were done, default
empty) — the last three added in 2.6 and decoded tolerantly — `createdAt`,
`modifiedAt`, `rinsedAt`.
`displayName` falls back to the kind's own title when `what` is empty.

Shown as **Your kit** in Settings, with warranty warnings — and with no totals
of any sort.

`CoffeeData.warrantiesRunningOut` lists live kit whose `warrantyUntil` falls
between today and **60 days** from today, soonest first. A warranty already
expired is not listed: there is nothing left to act on.

## Derived figures (`Shelf.swift`, on `CoffeeData`)

- `gramsUsed(beanID:)` — the sum of every live brew's dose for that bag.
- `gramsLeft(for:)` — `bagWeightGrams − gramsUsed`, floored at 0.
- `bestShot(beanID:method:)` — the newest **green** brew for that bag and
  method, else simply the newest. This is the recipe a bag offers next time.
- `nextDose(beanID:method:)` — that recipe's dose, else the method's starter
  dose.
- `brewsLeft(for:method:)` — `floor(gramsLeft / nextDose)`, or **nil** when
  the bag has no weight.
- `runningOutText(for:method:)` — see [beans.md](beans.md).
- `methodsUsed(beanID:)` — which ways this bag has actually been made.

## Syncing between iPhone and Mac

Writes go through `NSFileCoordinator`, and a merge is **per record by
`modifiedAt`**, never whole-file. Deletes travel as tombstones (`rinsedAt`),
so the Mac can never resurrect what the phone rinsed. See [cups.md](cups.md).
