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
   (`restore-preview`, *"+2 bags · same brews"*, with a kit count only when it
   differs) before anything is replaced.

`CoffeeStore.restore(from:safetyName:)` is the one place this happens, for a
cup ("Before restore") and for a backup file ("Before opening a backup"). It
writes **without merging** (`saveNow(pourCup:merge: false)`): before 2.6 a
restore merged with the file on disk, so every record changed since the cup
was poured won the merge and pouring a cup back put almost nothing back.

## The backup file (2.6, `BackupFile.swift`, `BackupButtons` in `CupsView.swift`)

The same pair of buttons in Settings (`settings-backup`,
`settings-open-backup`) and on the shelf (`cups-backup`, `cups-open-backup`).
They replace 2.5's Export / Import / Share.

- **Save a backup file** opens a sheet: a name (`backup-name`, starts as
  *AMS Coffee 2026-11-03*), then **Choose where** (`backup-save`) hands the
  file to the system's place picker (`fileExporter`, `.json`) — Files, iCloud
  Drive, a USB stick on the Mac. `BackupFile.fileName(for:)` turns `/ : \`
  into `-`, adds `.json`, and uses today's name when blank.
- **It proves itself like a cup.** `BackupFile.prove` reads the file back from
  where it landed (security-scoped), decodes it and compares bags, brews and
  kit with what was written. Only then: **Saved and proved** with a tick
  (`backup-proved`) and *"Opened and counted: 5 bags · 46 brews · 3 things"*;
  otherwise an orange **Not proved** (`backup-unproven`) saying what came
  back. The button then reads **Done**. Photos are not in the file.
- **Open a backup** picks a file (`.json` or any data). `BackupFile.read`
  refuses anything that is not a Coffee file (it must carry `beans` or
  `shots`) with *"That is not a Coffee backup … Nothing was changed."*
  Otherwise the same `RestoreSheet` as a cup: name, contents, the delta, and
  the promise that *Before opening a backup* is kept first. Pouring it in
  **replaces** what is there (2.5's Import merged silently, with no preview).
- Under `-uiTesting` the file goes straight to the temporary folder instead of
  the place picker, and is proved by the same read-back.

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
