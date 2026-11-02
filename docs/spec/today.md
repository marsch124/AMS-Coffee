# Today

`HomeView.swift`. The morning screen: one big button, what you have drunk,
what you are drinking, and the one thing to change next time. Nothing else.

Title "AMS Coffee" with a hand-drawn `CupMark`.

## What is on it, in order

| Element | Identifier | When it appears |
| --- | --- | --- |
| Shelf warning card | `home-warning` | only when the shelf has a warning; "Got it" is `home-dismiss-warning` |
| **Pull a shot** | `home-pull-shot` | always — the one big button, full colour, never grey |
| The numbers | `home-numbers` | always — today · brews · bags · lovely |
| What the coach said | `home-advice` | only when a brew has been saved this session |
| **What should I change?** | `home-ask` | only when at least one brew exists |
| In the hopper | `home-current-bag` | only when a bag exists; taps through to Beans |

## The numbers

Four big numbers, no money among them: brews logged **today**, **brews** in
total, **bags** in total, and **lovely** — the count of brews with a green
light.

## What should I change? (2.4)

Five choices in a wrapping row, each a capsule, identifiers
`ask-sour`, `ask-bitter`, `ask-thin`, `ask-strong`, `ask-lovely`:

> Too sour · Too bitter · Too thin · Too strong · It was lovely

Tapping one shows the answer (`ask-answer`): a headline and one concrete
change. Tapping the **same** choice again clears it, so the card can be put
away.

The answer is `Coach.fix(lastBrew, complaint)` — see [coach.md](coach.md). Two
rules matter here:

- It is always about **the most recent live brew**, named in the card
  ("About the espresso you just made.").
- The complaint he picked is the **only** taste considered. Both sliders on the
  copy are zeroed first, so a brew already logged as very bitter cannot colour
  the answer to a question about body.

### Why

Idea 7 of the 20 he was offered on 18 Sep 2026, picked on 20 Sep. The coach
already gave this advice, but only after a whole brew had been filled in and
tasted. This asks the question directly.

## In the hopper

The bag of the most recent brew, else the newest bag. Shows its photo, its
name, and up to three chips:

- grams left — `214 g left`
- days off roast — `home-freshness`, e.g. `11 days · at its best`
- running out — `home-running-out`, e.g. `2 more brews`

Both of the last two are absent when they have nothing to say. See
[beans.md](beans.md).

## iPhone and Mac

Identical. The Mac gets Mac text sizes from the same type styles. **Nothing on
this screen is pinned to a safe-area inset**, because a control inside a
`safeAreaInset` inherits its ancestor's accessibility identifier — see
[testing.md](testing.md).
