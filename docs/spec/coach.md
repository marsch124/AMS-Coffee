# The coach

`Coach.swift`. One thing to change, never a lecture, and never a scolding — a
green brew outside the window is still a green brew.

## What it knows per method

`idealRatio` (dose to water or yield), `idealSeconds` (see
[brews.md](brews.md)), and each method's own vocabulary: `fasterWord` and
`slowerWord`, so espresso hears *grind finer* where a French press hears
*steep it longer*. That is the knob you actually turn.

## How it decides, in order

**Taste leads; time only explains why.**

1. **Bitter** → the method's faster word. If it also ran long, the time is
   given as the reason.
2. **Sour** → the method's slower word, with the same treatment.
3. **Thin and over-watered** (ratio above the window) → less water, with a
   target in grams.
4. **Thin** → more coffee: two grams more on the same water.
5. **Strong and under-watered** → more water, with a target.
6. **Slow but nothing tasted wrong** → the faster word, explicitly optional:
   *"Nothing tasted wrong, so change this one thing only if you want it
   brighter."*
7. **Quick** → the slower word, with the usual window quoted.
8. Otherwise → *"Change one thing only. Nudge the grind by one click and see
   which way it moves."*

Thresholds: sour below −0.15, bitter above +0.15, thin below −0.2, strong
above +0.3 — deliberately not symmetric, because a brew reads as too strong
later than it reads as too thin.

The advice appears on the brew (`shot-advice`) and, after saving, on Today
(`home-advice`).

## Asking outright (2.4)

`Coach.Complaint` — `sour`, `bitter`, `thin`, `strong`, `lovely` — and
`Coach.fix(_ shot:_ complaint:)`.

The answer goes through **the same `advise(for:)`** as a logged brew: the
complaint is written onto a copy of the brew and the coach is asked as usual.
Two sets of rules would be two sets of rules to keep in step.

- Both taste sliders on the copy are **zeroed first**, so only the thing he
  complained about is considered.
- 🚨 **The light is set to amber on the copy.** `advise(for:)` answers "keep it
  exactly here" for any green brew *before* it looks at the taste, so asking
  "too bitter" about a brew marked green used to be told to change nothing.
  Complaining about a brew plainly means it was not green. Found by using the
  app in 2.4, not by a test; `testComplainingAboutAGreenBrewStillGetsAChange`
  guards it now.
- The complaint is written as ±0.5 — comfortably past every threshold above.
- Every other number stays as it was, so the answer still talks about his real
  grind, dose and time.
- **`lovely` returns "Change nothing"** and does not invent a change: *"That is
  the recipe. It is already what this bag offers you next time."*

See [today.md](today.md) for the card.
