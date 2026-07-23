# A timeout never tells you whether it happened.

> The same network timeout means "reconnect and retry" on a read, and "you might have already done it — don't do it again" on a write. We handled both the same way once. Only one of them was safe.

**Date:** 2026-07-23
**Receipt:** reconstructed — the original is in a private repo

## What happened

Our service depends on an external provider. One afternoon the provider got slow for a few seconds — an ordinary network blip — and the same timeout surfaced on two very different screens.

One was read-only: it fetched a quote to display. The other *submitted an Order* — a real, state-changing request to the provider.

Both screens failed the same way, because both had the same missing error handling. Fixing the read-only one was easy: catch the timeout, show "reconnecting," try again. Obvious.

Then we went to add the exact same "just retry" to the submit path, and stopped cold.

## Why it happened

A timeout is not an answer. It's the *absence* of one. "I didn't hear back in time" is equally consistent with two opposite realities:

- The request never reached the provider. Nothing happened. Safe to retry.
- The request reached the provider, the Order was placed, and only the *confirmation* got lost on the way back. Everything happened. Retrying places a second Order.

From inside your own process, those two are indistinguishable. A timeout gives you no way to tell them apart.

So "retry on timeout" is only safe under one of two conditions: the operation is **idempotent** (doing it twice is the same as doing it once), or you can **independently check** whether it already happened before trying again. On a read, both hold for free — reading twice costs nothing. On a state-changing write, neither is free; you have to build it.

The correct response to the *identical* error was opposite on the two paths — and the thing that decided it was never the error. It was what was at stake when it hit.

## The smallest thing that shows it

```
# Read path — retry freely. Reading twice is free.
def fetch_quote
  provider.quote
rescue Timeout
  retry                     # fine
end

# Write path — the SAME rescue is a bug.
def submit(order)
  provider.place(order)
rescue Timeout
  retry                     # may place the order twice: the first try might have succeeded
end

# Write path, done right — make it answerable, not a guess:
def submit(order)
  provider.place(order, idempotency_key: order.id)   # provider dedupes, OR
rescue Timeout
  return if provider.already_placed?(order.id)       # check before you retry
  retry
end
```

## What I do differently now

Before I add "retry on timeout" anywhere, I ask one question: what happens if the thing I'm retrying already succeeded? If the answer is "we do it twice," a bare retry is a bug, and the operation owes me either an idempotency key or a way to check its own status first.

Two rules I keep:

- **A timeout is the absence of an answer, not the answer "no."** Treating "I didn't hear back" as "it didn't happen" is the single most common way software does the same thing twice.
- **Classify failures by what's at stake, not by their type.** The same exception on a read and on a write are different bugs with opposite fixes. Handling them identically is how the safe-looking one quietly becomes the dangerous one.
