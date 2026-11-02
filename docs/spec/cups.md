# The Cup System, and the Sink

His phrase, from the very first message (17 Sep 2026): *"an absolute happy
place, so we also need a cup system so that everything is kept safe."*

`Cups.swift`, `CupsView.swift`, `Store.swift`.

## Three kinds of cup

| Kind | Kept |
| --- | --- |
| quick | the newest 10 |
| daily | the newest 7 |
| keepsake | forever |

A cup records `beanCount`, `shotCount`, `purchaseCount`, `photoCount`, when it
was poured, and whether it is `tested`.

## Three rules, each one a scar from another app

1. **Each cup proves itself.** After writing, the cup is read back, decoded,
   its records counted, and the photo files it refers to checked to exist —
   *then* it gets its green tick (`cup-tested-<index>`). "The write returned no
   error" is not proof.
2. **A cup never shrinks silently.** `CupPolicy.mayPour` refuses a cup holding
   less than the newest one, and `CupPolicy.refusal` says why. This comes
   straight from a real data loss in another app, where a blind backup
   overwrote itself with an empty snapshot.
3. **Restoring takes a safety cup first**, and previews the delta
   (`restore-preview`) before anything is replaced.

## The Sink

Nothing is ever hard-deleted under him. Removing a bag, a brew or a kit item
sets `rinsedAt`; the record stays, listed in the Sink, restorable
(`sink-bean-restore-<i>`, `sink-shot-restore-<i>`,
`sink-purchase-restore-<i>`), and is only purged after **30 days**.

Tombstones are also what make deletion survive syncing: a merge is per record
by `modifiedAt`, so without them the Mac would cheerfully resurrect what the
phone rinsed.

## Photos

Photos are files beside the JSON, referenced by id and downscaled to 1600 px
at quality 0.7 on the way in. `tidyPhotos()` purges a photo only when nothing
refers to it — not the live data, not the Sink, and not **any** cup. A photo
still inside a keepsake cup is never collected.
