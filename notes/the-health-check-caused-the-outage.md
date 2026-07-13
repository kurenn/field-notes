# The health check caused the outage it was built to detect

> Nine agents went dark at once. The thing that took them down was the monitor I'd added to notice if they ever went down.

**Date:** 2026-06-19
**Receipt:** reconstructed — the original is in a private repo. The shape is exact; the code is rebuilt.

## What happened

I run a fleet of nine agents. They sit in Slack, each one scoped to a different part of the business, and they're supervised by a process manager that restarts anything that dies.

That supervisor was already there. It worked. But I wanted something more specific — I wanted to know if an agent was still *running* but had stopped *doing anything*. Alive but wedged. So I wrote a small watchdog: every sixty seconds, look at an internal counter that the platform advances as it works. If the counter hasn't moved in five minutes, that agent is stuck. Restart it.

It ran quietly for weeks.

Then one morning all nine agents were gone from Slack at once. The processes were alive. The logs were frozen. Nothing had been deployed.

The counter I was watching was internal to the platform, and it turned out it didn't resume advancing after a restart — it only advanced on a code path that a fresh process didn't hit right away. So after one ordinary, unremarkable restart, the counter sat still. My watchdog looked at all nine agents, saw a stale counter on every one of them, concluded that the entire fleet was wedged, and killed them.

Which caused a restart. Which left the counter stale. Which made the watchdog kill them again.

The monitoring *was* the incident.

## Why it happened

I built a watchdog on a signal I did not own.

That's the whole thing. The counter was an internal implementation detail of somebody else's system. I never agreed a contract with it. Nobody promised me it would keep advancing, or that it would resume after a restart, or that it meant "healthy" at all — I just noticed it moved when things were working and decided that was good enough.

And the failure mode of a watchdog is uniquely nasty, because a watchdog has a **kill switch**. A dashboard built on a bad signal shows you a wrong number. A watchdog built on a bad signal reaches out and breaks production. It has the authority to act, and none of the judgment to know when not to.

The deeper mistake was that I added it at all. The supervisor already restarted dead processes and had done so, correctly, for months. I bolted a second, dumber supervisor on top of a system that already had a good one — and the new one could fight the old one.

## The smallest thing that shows it

```python
# The watchdog. It looks reasonable. That's the problem.

def check(agent):
    ticks = read_internal_counter(agent)      # <- a signal I do not own
    if now() - ticks.last_moved > 300:
        restart(agent)                        # <- and it has a kill switch

# What I never asked:
#   Does this counter advance for every reason the agent is healthy?
#   Does it resume after a restart?
#   Who promised me either of those things?
#
# Answers: no, no, and nobody.
```

## What I do differently now

**Assume the platform already does this.** Before writing any supervisor, watchdog, retry loop or health check, go and find out what the thing you're running on already provides. Mine already had a supervisor. It was better than mine. I just hadn't read far enough to know that.

**Never build a kill switch on a signal you don't own.** If you didn't define the signal, and nobody has promised you what it means, it is an observation, not a contract. Observations belong on dashboards. Contracts get to restart things.

**Be most suspicious of any component that can restart or reshape what the platform already runs.** Those are the ones that turn a bad assumption into an outage instead of a wrong graph.

And the general version, which I've now watched play out three separate times in different disguises: **the instrument is part of the system.** A monitor that can act is not a neutral observer of production. It *is* production. Test it like it is.
