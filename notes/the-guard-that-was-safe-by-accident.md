# My guard against doing a job twice worked — by accident.

> A job claimed each order so it could never run twice, and released the claim to retry on failure. One reachable path would have released a claim *after* the work was already done — and run it again. Every test was green.

**Date:** 2026-07-20
**Receipt:** reconstructed — the original is in a private repo

## What happened

I had a job that processes an Order, and it must never process the same one twice. The guard was simple and, I thought, airtight: before doing anything, the job atomically claims the order — flips it from `pending` to `processing`. Two workers race, one wins, the other sees it's already claimed and backs off. A clean fence.

The wrinkle is failure. If the job claims an order and then crashes, that order is stuck in `processing` forever. So there's a release: on an error, if the work hadn't actually happened yet, put the claim back to `pending` so it can be retried.

"If the work hadn't actually happened yet" is the whole ballgame. Release too eagerly — after the work is done — and you run it again.

Every test passed. Then a reviewer asked the one question I hadn't: is that release *always* safe, on every path that can reach it?

It wasn't.

## Why it happened

The release decided "did the work happen?" by looking for a `Completion` row tagged with the order's id. No tagged Completion → not done yet → safe to release.

But two different handlers could do the work, reached through a shared router. One tagged its `Completion` with the order id. The other didn't — it wrote a `Completion` with no order id at all.

So for any order that went through the second handler, the check would look for a tagged `Completion`, find none, and conclude "not done" — *even after the work had finished and its effects were irreversible.* Release → retry → done twice.

Here's the part that took the wind out of me: it was safe **today** only because of coincidences. The second handler happened not to be reached by the paths under test. The router happened to send the tested cases to the safe handler. Three unrelated facts in three unrelated files lined up, and that alignment was the only thing standing between me and running the job twice. Nobody had asserted any of them. Nobody knew they were load-bearing.

A safety property that holds only because of coincidences in unrelated code is not a safety property. It's luck with good posture.

## The smallest thing that shows it

```
# The guard: only release a claim if the work never happened.
def release_if_unstarted(order)
  return if Completion.exists?(order_id: order.id)   # already done — don't retry
  order.update!(state: "pending")                    # safe to retry
end

# Handler A tags its Completion. The check works.
Completion.create!(order_id: order.id, ...)

# Handler B — reachable through the same router — does NOT.
Completion.create!(...)                              # no order_id

# For any order through Handler B, Completion.exists?(order_id:) is false
# even after the work finished. release -> retry -> processed twice.
```

The fix was one line: refuse to run the release at all on a handler that can't prove its own completion — `raise unless handler.tags_completions?` — so the unsafe path fails loudly instead of silently doing the work twice.

## What I do differently now

When a piece of code is safe *because* of an assumption about code somewhere else, I make that assumption an assertion — in the code, next to the thing that depends on it. If the release is only safe when the completion check is reliable, the release should refuse to run when it can't verify the check is reliable. Don't document the coincidence. Fail on its absence.

Two things I keep from this:

- **"It works" and "it works for a reason" are different claims,** and only the second survives a refactor. A test proves the first. It cannot prove the second — a test exercises the paths you thought of, and the danger lives on the one you didn't.
- **A safety property that leans on faraway code needs a guard *at* the dependency,** not a comment hoping the faraway code never changes. The coincidence that saves you today is one unrelated PR away from being the incident.
