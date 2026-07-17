# A cached page kept asking for files I'd already shipped away.

> Users loaded a sign-in page that looked broken and whose button did nothing. Every dashboard stayed green. The only signal was people quietly failing to get in.

**Date:** 2026-07-17
**Receipt:** reconstructed — the original is in a private repo

## What happened

Every time we deployed, a few people got locked out of the sign-in page. Not by an attacker — by our own cache.

To them, the page loaded. It just looked *off* — unstyled — and the button that starts sign-in did nothing. Click, nothing. Click again, nothing. A hard refresh usually fixed it. "Usually fixes it" is a bad place to leave the front door of an app.

It was nearly invisible to us. No error we watched. No alert. Healthy by every metric we had. The only symptom was one person, alone, failing to sign in — a failure that lives entirely on their screen and never travels back to us. They don't file a ticket. They assume it's them, and they leave.

## Why it happened

Modern apps fingerprint their static files: the stylesheet isn't `app.css`, it's `app-a1b2c3.css`, where the hash changes on every deploy. That lets browsers cache those files forever, safely — a new build makes a new filename, so there is never a stale-*file* problem.

Never a stale-file problem. The stale-*page* problem is the one that bites.

Because if you also let the browser cache the HTML page that names those files, here is the sequence:

1. Someone loads the page. Their browser keeps a copy — sometimes a full frozen snapshot in the back/forward cache, restored later with no network request at all.
2. You deploy. The build re-fingerprints the assets. The old filenames no longer exist.
3. The cached page asks for `app-a1b2c3.css` and the script that wires up the button. Both come back 404.

The page renders naked, and the small program that makes the button *do* something never loads. The button is right there. It just isn't connected to anything.

And a 404 on a retired asset is not an error anyone monitors — it is expected background noise. So nothing pages you. The system is "up." The user is locked out.

## The smallest thing that shows it

```
# The page's HTML — and the browser cached this whole document:
<link rel="stylesheet" href="/assets/app-a1b2c3.css">
<script type="module" src="/assets/widget-9f8e7d.js"></script>

# After a deploy the build re-fingerprints. The old names are gone.
# The cached HTML still asks for them:
GET /assets/app-a1b2c3.css    -> 404   # page renders unstyled
GET /assets/widget-9f8e7d.js  -> 404   # the button's behavior never boots

# The fix, on the pages that must never be served stale — one header:
Cache-Control: no-store        # also disables the back/forward cache
```

## What I do differently now

Any page that has to be correct the instant it loads — anything with a login, a token, a one-time action — gets `Cache-Control: no-store`. Never cache the HTML whose asset references can rotate out from under it.

Two rules I keep from this:

- **Caching is a promise you make to the browser, and the browser has no idea you just shipped.** Fingerprinted assets solve stale files. They do nothing for a stale page that still points at them.
- **"Loads" and "works" are different claims.** A page can do the first and not the second, and your monitoring will happily report the first as success. Go looking for the failures that only your users can see — those are the ones doing the real damage.
