# Field notes

Things I learned running AI agents against real codebases, written down while I still remembered why they mattered.

I'm a CTO, not a researcher. Everything here came out of production — an outage, a bill I didn't expect, a green checkmark that turned out to be a lie. Where the work is public I link the pull request. Where it isn't, I rebuild the lesson as the smallest thing that shows it, and the code here is a reconstruction, never a paste.

The rule I hold myself to: **skip the diary, capture the map.** Nobody needs to know what my Tuesday was like. They need the thing that will save them the Tuesday.

## Notes

<!-- newest first; one line each -->

- **[A cached page kept asking for files I'd already shipped away](notes/the-cached-page-outlived-its-files.md)** — every deploy quietly locked a few users out of the sign-in page, and the culprit was our own cache serving a page whose files no longer existed.
- **[My benchmark was measuring itself wrong](notes/my-benchmark-was-measuring-itself-wrong.md)** — I published a negative result against my own work, then found the negative result was an artifact of my measuring tool.
- **[The health check caused the outage it was built to detect](notes/the-health-check-caused-the-outage.md)** — nine agents went dark at once, and the thing that took them down was the monitor I'd added to notice if they ever went down.

## Why this exists

Most of what gets written about AI agents is a demo that worked. Demos that work teach you almost nothing. The interesting information is in the failures, the bills, and the moments when the measuring instrument turned out to be broken.

So this is the other half of the ledger. It is not advice, and it is deliberately not a course. It's just what happened, what it cost, and what I do differently now.

If a note is wrong, [open an issue](https://github.com/kurenn/field-notes/issues) and tell me. I'd rather be corrected in public than confident in private.

## Elsewhere

- **The tools** these notes come from: [roundhouse](https://github.com/kurenn/roundhouse), [rails-audit](https://github.com/kurenn/rails-audit), [boorails](https://github.com/kurenn/boorails), [dev-loop](https://github.com/kurenn/dev-loop)
- **The long-form stuff**: [kurenn.dev](https://kurenn.dev)
- Abraham Kuri — CTO at Coba (YC S23), author of *APIs on Rails* (2014). Rails since 2010.
