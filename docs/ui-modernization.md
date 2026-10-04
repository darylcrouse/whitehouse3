# The White House 2 — UI Modernization Plan

**Status:** draft v0.4 · 2026-10-03 · for Daryl's review
**Repo:** `darylcrouse/whitehouse3` @ `rails8-modernization` (engine: Rails 8.0.5.1 / Ruby 3.3)
**Design direction:** the **WhiteHouse 3 concept** in `wh3-concept/` (Daryl's exports) — supersedes the blue home-concept in §6. See `wh3-concept/README.md` (design system + how to browse) and `wh3-concept/feature-map.md` (every concept feature → codebase asset → gap).

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
- **Top / Controversial / Rising** as the ranking system (with the charts) — WH3 adds Common ground alongside them.
- The voice — *"The word is out:"*, *"the more clout we have to make our agenda happen"*.
- The section grouping: Economy, Health Care, Energy, … (WH3 reuses it as priority categories).
- The site's deep blue heritage — carried into WH3's navy family (`#0f2a45`/`#1b3c5a`), so the brand still feels like this app, one register deeper and with a gold accent.

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

## 6. Design direction — the WhiteHouse 3 concept

The **WhiteHouse 3 concept** (`wh3-concept/`) is the adopted direction, superseding the earlier blue home-concept (kept at `ui/home-concept.html` only as an alternative — it is no longer the target). The concept arrives as 8 complete page designs + shared header/footer, all browsable (see `wh3-concept/README.md`).

What it changes vs. the former direction:

- **A real brand system**: Cormorant SC display serif + Montserrat UI sans; navy `#0f2a45`/`#1b3c5a` + gold `#a88f61` on cream `#f1f0ee`. (The old blue `#13499b` retires with the old concept.)
- **The product story is upgraded, not just restyled**: common-ground ranking, a response clock, opinion maps, civic credit, video takes, citizens' assemblies, a budget sandbox, a transparency page. Half of this maps onto machinery the legacy app already runs — `wh3-concept/feature-map.md` is the full mapping and is the implementation brief.
- **The 2009 keep-list survives**: endorse/oppose rhythm, Top/Rising/Controversial, the section structure, the voice — all carried forward in WH3's own language.
- **Fluid layout, mobile-aware**: 1240px container with wrapping flex rows; every control ≥44px.

## 7. Page-by-page plan (revised to the WH3 concept)

Two tracks, in order:

**Track 1 — reskin on existing mechanics** (every page presentable; no schema changes)
1. ✅ **Design tokens + overlay stylesheet** — `wh3.css` + `Wh3Theme.apply!` (commit `1dbc44b`): fonts self-hosted, palette via ColorScheme, header band + footer, buttons/links/forms/focus states.
2. ✅ **Home (agenda)** — WH3 hero panel, ranked rows with endorse/oppose split, momentum counts; admin stance/credits land as labels on existing data.
3. ✅ **Auth/join** — MojoAuth flow styled in the WH3 visual language (`/login`, sidebar card).
4. ✅ **Priority page** — tab strip, vote-button states, share/rank polish (commit `1dbc44b`).
5. ✅ **Lists / profile / misc** — consistency sweep done across `/priorities/*`, `/users`, `/about`.
6. ⬜ **Mobile + accessibility pass** — basic responsiveness verified (390px no-overflow); dedicated a11y pass (contrast audit, targets, alt text) still open.

Verified for Track 1: `rails test` 247/394 0F 0E; zeitwerk OK; 14 pages 200; zero horizontal overflow at 1440 + 390; sub-nav active states correct on all listing pages. Screenshots in `docs/wh3-concept/live/`. Remaining nits: hero input placeholder clips at 390px; "ADMIN AGENDA" label alignment on first home group.

**Track 2 — new mechanics** (per `feature-map.md`, small → flagship → rest)
1. 🟡 Common-ground score — ✅ **done** (commit `45a4409`): voting-pattern opinion groups, cached score, tab + badge, designed demo spread, tests. Remaining in this item: scope filters (state first) + propose-with-duplicate-check.
2. Flagship choice: **response clock** (self-contained, most differentiating) vs **video takes** (requires Ziggeo) vs **opinion map**. Recommend response clock first.
3. Assemblies, budget sandbox, Congress.gov bills, transparency/open-data page, local layer, verification.

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
4. Appetite: **Track 1 slice-by-slice as time allows** — home first? And for Track 2, is the **response clock** the right flagship, or does **video takes** (Ziggeo) matter more to you?
5. The concept is "WhiteHouse 3" branding — do we take that name/wordmark into the app (title, logo, copy), or keep "White House 2" until a public relaunch decision is made?

## 10. Recently fixed (context for the audit)

- `b1637ef` — priority short-URL link text restored; footer "set priorities for **the government**".
- `7bd4e57` — ColorScheme attachment/column collision fixed (scheme CSS + admin color picker).
- `58620c0` — sitewide markup-unescaping (blurb helper + translation shim) — the "visible HTML source text" fix.
- `f8dbfe9` — MojoAuth passwordless login.
- `17f6ef6` — `Liquid error: internal` eliminated (liquid_methods restored + boot-order fix).
- `c528f37` — auth plumbing (Rails-8 mailer, dev mail capture, signup status fix).
