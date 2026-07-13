# My benchmark was measuring itself wrong

> I published a negative result against my own work. Then I found out the negative result was an artifact of my measuring tool. The second mistake is the more interesting one.

**Date:** 2026-06-09
**Receipt:** [claude-prototype](https://github.com/kurenn/claude-prototype) — the correction banner sits on top of the original results file, and the wrong conclusion is still visible underneath it.

## What happened

I had a tool that generated web prototypes, and it was loading a large instruction file into context on every single run. Expensive. So I refactored it: keep a small core always loaded, move the detail into reference files that get pulled in only when needed.

It worked. Context cost dropped by 73%.

But cheaper is only good if it isn't also worse, so I built a test to check. I generated prototypes with the old version and the new one, then had a separate model compare them blind — it didn't know which was which — and score them on ten different dimensions.

The verdict came back: the new version was worse.

And the losses weren't random. They clustered. Mobile layouts were clipping. Buttons were getting pushed off the edge of the screen. Which made *perfect* sense, because the mobile guardrails were exactly the kind of "don't forget this" rule the refactor had moved out of always-loaded context and into a file that might never get read.

A coherent story, a plausible mechanism, and my own data. So I published it — wrote up the regression, against my own refactor, in my own repo.

Then I went to fix it, and I couldn't reproduce the clipping by hand.

Headless Chrome has a minimum window width of around 500 pixels. I had been asking it for 390 pixels — a phone — and it had quietly given me a 500-pixel layout and handed back the leftmost 390 pixels of it. Cropped.

Every mobile screenshot I had judged was a crop of a desktop-ish layout. The clipping was real in the image and had never existed on the page.

The refactor had been fine the whole time.

## Why it happened

The failure wasn't that my instrument was broken. Instruments break constantly.

The failure was that **the broken instrument told me a story that made sense.**

If the tool had returned garbage — black screenshots, obvious nonsense — I'd have caught it in a minute. Instead it returned a *plausible* result, one with a mechanism I could explain, one that confirmed a risk I already believed in. I had written down beforehand that progressive disclosure might weaken the guardrails. Then my broken tool showed me exactly that, and I didn't check it, because it was what I expected to see.

I have thought about this a lot since. The dangerous measurement error isn't the one that produces an absurd number. It's the one that produces a number you were already half-expecting.

## The smallest thing that shows it

```bash
# What I asked for:
render --window-size=390,844      # an iPhone

# What I got:
#   viewport: 500px  (Chrome's headless floor — silently applied)
#   image:    the leftmost 390px of it
#
# The screenshot looked exactly like a clipped mobile layout,
# because it WAS a clipped layout. Just not the page's fault.
```

The fix, in the tool that checks the tool:

```bash
# Don't ask the window to be small. Tell the page it IS a phone.
override_device_metrics(width=390, height=844, mobile=true)

# And then verify the thing you actually care about, rather than eyeballing it:
assert document.scrollWidth == document.clientWidth   # no horizontal overflow
```

## What I do differently now

**When the measurement confirms what you expected, that is the moment to check the instrument.** Not when it surprises you — surprise already makes you suspicious. Agreement is what puts you to sleep.

**Reproduce the finding by hand before you publish it.** One manual check would have caught this in five minutes. I skipped it because the data was so tidy.

**Assert on a number, not on a picture.** "Does this screenshot look clipped to a judge" is a question with a hundred ways to go wrong. `scrollWidth == clientWidth` has one answer and it is not a matter of opinion. Where a proxy metric can be replaced by a fact, replace it.

**Leave the wrong conclusion visible.** I put a dated correction on top of the results file rather than quietly deleting the bad analysis. Anyone can still scroll down and read what I originally, confidently, got wrong. That costs me nothing and it's the only version of this that's worth anything.

And the general rule, which I've now watched play out in three different disguises: **the instrument is part of the system.** Your benchmark, your monitor, your test harness — none of them are neutral observers standing outside your work. They're inside it, they can fail, and when they fail they will tell you a story you're inclined to believe.
