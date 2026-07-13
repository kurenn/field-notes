# Sanitizing a note

Most of what I learn happens inside private code — a cross-border payments company and the agent fleet that runs it. Publishing from there is a one-way door, so this is the process, and it is not optional.

## The one rule that makes the rest easy

**Never paste. Reconstruct.**

Do not copy code out of a private repo and scrub it. Scrubbing is a game you eventually lose — you remove the API key and leave the table name, you rename the class and leave the comment above it, you catch the customer name and miss it in the test fixture.

Instead: close the private file, and rebuild the smallest possible thing that demonstrates the lesson, from scratch, in a neutral domain.

This is safer, and it is also **better content**. Nobody wants forty lines of Coba's internals. They want the eight lines that show the idea. The sanitized version was always going to be the stronger one — sanitizing just forces you to find it.

If a lesson cannot survive being rebuilt in a neutral domain, it was probably a fact about our business rather than a lesson about agents, and it doesn't belong here anyway.

## What never leaves

- Credentials of any kind. Keys, tokens, connection strings, webhook secrets, session IDs.
- Anything about a customer. Names, amounts, emails, phone numbers, account or transaction identifiers — including in test fixtures, including if you think it's fake.
- Money-path logic. Ledger rules, KYC decisioning, fraud heuristics, limits, fee logic. If it touches money moving, it stays in.
- Internal topology. Hostnames, private IPs, queue names, bucket names, Fly app names, Slack channel and user IDs.
- Colleagues, by name, without asking them first.
- Anything under NDA, and anything about a client engagement.
- **My own machine.** Absolute paths like `/Users/abrahamkuri/...` — this is not hypothetical; I shipped my laptop path inside a published plugin in the boorails 2.0.0 release and had to go fix it.

## What's fine

- The shape of a mistake. "Our health check restarted the thing it was checking."
- Costs and token counts, as long as they don't reveal volume or customer scale.
- Public library and model behavior. Anything already in someone's docs.
- Anything already in a public repo of mine — link the PR, it's the strongest receipt there is.
- Neutral reconstructions: `Widget`, `Order`, `Report`. Boring on purpose.

## The checklist

Before publishing, read the note back **as a competitor** and then **as a regulator**. Then:

- [ ] No code was pasted from a private repo — every snippet was rebuilt from scratch.
- [ ] The domain is neutral. Nothing names or implies the business.
- [ ] No credential, identifier, hostname, or path survives. Run `bin/check-note.sh`.
- [ ] It would be fine on the front page of Hacker News with my name on it, because one day it might be.
- [ ] The lesson is still true after all of the above. If sanitizing broke it, don't publish it — fix it or drop it.

`bin/check-note.sh` is a backstop, not a substitute for reading the thing. It catches the obvious. You are responsible for the rest.
