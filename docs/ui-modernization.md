# The White House 2 — UI Modernization Plan

**Status:** draft v0.3 · 2026-10-03 · for Daryl's review
**Repo:** `darylcrouse/whitehouse3` @ `rails8-modernization` (engine: Rails 8.0.5.1 / Ruby 3.3)

---

## 1. Where the app stands today

The engine is done — this plan is only about the **face**:

- Full 2009 test suite revived and green: **245 runs / 390 assertions / 0 failures / 0 errors**.
- **Passwordless login (MojoAuth)** live on `/login` — no more passwords required for new users.
- Sitewide rendering bugs fixed: zero `Liquid error`, zero escaped-markup artifacts, footer/short-URL text repaired (see §10).
- All main pages render 200 with demo seed data (Economy / Health Care / Energy priorities, press block, charts).

The UI itself is still **the authentic 2009 White House 2 look** — the port deliberately kept behavior and appearance parity. That is a fine starting point, not a problem to apologize for; the question now is what to keep, what to modernize, and how far to go.

## 2. Why touch the UI

1. **First impression / credibility.** The engine is current; the skin says 2009 to anyone who looks (11–12px text, underlined blue links, table layout).
2. **Mobile.** The layout is a fixed-width table grid. On a phone it compresses into a cramped desktop page — no breakpoints exist.
3. **Demo-readiness.** For showing the app to anyone, the auth page (which now has a modern MojoAuth card floating above 2009 forms) shows the mismatch most starkly.

## 3. What to preserve (the soul — do NOT modernize these away)

- The question *"What should the government do better?"* — the product IS this question.
- The **ENDORSE / OPPOSE** rhythm — the repeating unit of the whole site.
- **Top / Controversial / Rising** as the ranking system (with the charts).
- The voice — *"The word is out:"*, *"the more clout we have to make our agenda happen"*.
- The section grouping: Economy, Health Care, Energy, …
- The site's own deep blue (**#13499b**) — keep it as the brand accent; it's personal to this app.

## 4. Current-state audit

Screenshots live in `ui/` next to this file (`current-home.png`, `current-login.png`, `current-priority.png`).

**Home** (`/`) — two-tier text nav on a gray band; content in a ~65% column with a 284px sidebar; ranks shown as plain rows; yellow/blue Endorse-Oppose buttons; "ADMIN AGENDA" floats orphaned in whitespace; press logos cramped in a gray box; footer = one dense 11px gray line.

**Login / Signup** (`/login`) — MojoAuth card (modern) sits above two side-by-side legacy forms; legacy inputs render as dark boxes; "Join the network" / "Sign in" yellow buttons; sidebar repeats the pitch.

**Priority detail** (`/priorities/3-invest-in-high-speed-rail`) — byline + badge; strong H1; tab strip rendered as plain text links ("Overview / 2 endorsers / 0 opposers / 1 discussion / News / Action"); a 2-item activity feed with dotted separators and no visible composer; large dead whitespace once the feed ends; Endorse/Oppose + "Post on Facebook" buttons look identical (same yellow); "RANK YDAY WEEK MONTH" text links; press block repeated.

Cross-cutting offenders: tiny type & low-contrast grays; blue underlined links for every action; no hover/focus states; no logo or user menu in the header; no responsive behavior; no cards/dividers — everything is flat text on white.

## 5. Options

| | Scope | Effort | Risk | Gets you |
|---|---|---|---|---|
| **A. Overlay restyle** *(recommended first)* | One new stylesheet layered over the existing one + ~10 small layout tweaks | days | very low — no markup changes, zero behavior change | modern type/color/spacing, header & footer bands, button + link treatment, basic responsiveness |
| **B. Key-journey refresh** | Rewrite the core templates (header/menu partial, home, auth, priority show) in semantic HTML on top of A's design system | 2–4 weeks | medium — touches live templates; tests cover behavior | proper hierarchy, real components, mobile-first on the pages that matter |
| **C. Full redesign** | New design system + view-component layer; everything rewritten | months | high | a genuinely new product skin |

**Recommendation: A now, then B for four journeys (home, auth, priority show, lists), then re-assess.** A alone removes ~80% of the "it looks old" feeling and makes every demo presentable, with near-zero risk to the just-stabilized app.

## 6. Design direction (see the concept)

The concept file `ui/home-concept.html` shows one interpretation you can open in a browser (or ask me to preview it in chat). The moves it makes:

- **Type scale**: 16px base body (up from ~11px), one serif display voice for the wordmark + the big question, sans for UI.
- **Header**: a real brand band — wordmark left, one-row nav, "Sign in" action right; the second nav row becomes filter chips.
- **The question becomes the CTA**: the dark search bar turns into the page's hero — type a priority, submit.
- **Priority rows as cards**: title + ranking chip (Top/Rising/Controversial) + a single segmented **Endorse/Oppose** control with counts; scannable rhythm instead of loose lines.
- **Sidebar rail**: sign-in box, about blurb, press block — collapses below content on mobile.
- **Footer**: lightened from a dense one-liner into a quiet 2-row block.
- **Palette**: white/off-white surface, ink #1a1d21, muted #5b6470, borders #e5e7eb, brand blue **#13499b**, endorse green, oppose red — one accent family, semantic colors only where the mechanic needs them.

## 7. Page-by-page plan (if approved)

1. **Global overlay stylesheet** — header band, type scale, links, buttons, forms, footer, focus states, first responsive breakpoints. (Everything immediately looks 15 years younger; highest ROI, lowest risk.)
2. **Auth pages** — style the legacy forms to sit with the MojoAuth card; consider demoting the legacy password forms visually (MojoAuth is the primary path now).
3. **Home + priority detail** — the two screens people remember.
4. **Lists / profile / about / misc** — consistency sweep.
5. **Mobile + accessibility pass** — real breakpoints, 44px targets, contrast check, alt text.

## 8. How you contribute: video messages

Taste is hard to write in text and easy to point at on a screen. Workflow:

1. Record short clips (phone or screen recording, 2–5 min each, any format).
2. Drop them in **`~/incoming/ui-notes/`** on this machine (or attach them in the Hermes chat).
3. I transcribe each clip, turn it into a requirements checklist, and fold it into this plan — then implement.

Suggested clips (any subset, any order):
- **Walk-through**: open the site and talk through what bugs you / what you'd show someone first.
- **Taste**: 2–3 sites whose *feel* you like, and *why* (authority? clean? playful? — the why matters more than the site).
- **Deal-breakers / requirements**: mobile priority? public relaunch or demo? anything that must stay exactly as-is?
- **The story**: what is this site for now? (That answer changes the design brief more than any color choice.)

## 9. Open questions

1. End use: demo piece, public relaunch, or a base for something else?
2. How important is phone-first for the audience you care about?
3. Keep any 2009 "retro charm" on purpose, or modernize uniformly?
4. Appetite: Option A now (days) — go? — and is Option B's four-journey scope the right next step?

## 10. Recently fixed (context for the audit)

- `b1637ef` — priority short-URL link text restored; footer "set priorities for **the government**".
- `7bd4e57` — ColorScheme attachment/column collision fixed (scheme CSS + admin color picker).
- `58620c0` — sitewide markup-unescaping (blurb helper + translation shim) — the "visible HTML source text" fix.
- `f8dbfe9` — MojoAuth passwordless login.
- `17f6ef6` — `Liquid error: internal` eliminated (liquid_methods restored + boot-order fix).
- `c528f37` — auth plumbing (Rails-8 mailer, dev mail capture, signup status fix).
