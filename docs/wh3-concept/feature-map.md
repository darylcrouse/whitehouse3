# WhiteHouse 3 — feature map

How each feature in the concept maps to the legacy Rails 8 codebase, and what is
genuinely new build. Ordered by the concept's own information architecture.

**Legend:** ✅ already exists (reuse) · 🟡 partly exists (extend) · 🔴 new build

---

## Core mechanics

| Concept feature | Legacy asset | Status | Gap |
|---|---|---|---|
| ENDORSE / OPPOSE | `endorsements.value` (+1/-1), `up_endorsements_count` / `down_endorsements_count` | ✅ | None — this IS the app's core mechanic. Keep. |
| Common-ground score (0–100, weakest group) | No equivalent. Raw material: endorser/opposer/undecided splits; `points.endorser_score` / `opposer_score` / `neutral_score` | 🔴 | Define opinion groups, compute "support in least-supportive group". New derived metric + cached column. Model exists in design ("We group members by how they vote, never by party"). |
| Momentum ("Up 2 this week") | `position_7days_change`, `position_24hr_change`, `position_1hr_change` | ✅ | Already computed for Top/Rising/Controversial. Surface it. |
| Admin stance ("Admin stance: Supports / Opposes / No stance") | `priorities.obama_value` (1/0/-1) + all the `obama_*` scopes and activity views | 🟡 | Column + UI exist; **relabel** to administration stance and replace "compare with Obama" with "compare with administration / your senators / your representative" (design's 2008→now table, row "Compare"). |
| Talking points with "Helpful" ratings | `points` / `point_qualities` / `points_count`, `up_points_count`, `neutral_points_count` | ✅ | The briefing-room mechanic already exists. Restyle + "3 sources" attribution (sources = new light field). |
| Civic credit ("earned, never bought") | `capitals` + `CapitalPointHelpfulEveryone/Opposers/Endorsers/Undeclareds` subclasses | ✅ | Strikingly close: legacy already awards credit when *different viewpoints* rate your point helpful. Design's rule (credit ≠ vote weight, not transferable) matches legacy (`capitals_count` can't be spent on votes). Polish UI: credit history feed (activity views exist). |
| Delegation ("hand your vote to someone you trust") | No equivalent (`followings` is user→user following) | 🔴 | New `delegations` table (user, delegate, issue/tag, active), one-hop cap (per design changelog v3.3), own vote overrides. Small, self-contained. |
| Verification (one real person, one account) | No equivalent. Auth now MojoAuth (email OTP); `users` has no verification field | 🔴 | New verification flow: 3 methods (state ID scan / mailed code / in person), store *status only* (ID image deleted per privacy promise). MojoAuth handles login; this is a separate layer. Public name = existing `login`/`name` vs legal name = new private fields. |

## Agenda & home

| Concept feature | Legacy asset | Status | Gap |
|---|---|---|---|
| Hero question + #1 common-ground card | `homepage` model, press block, charts (`priority_chart`, `branch_endorsement_chart`) | 🟡 | Restyle; new ranked-by-common-ground card. |
| Agenda list with tabs Top / **Common ground** / Rising / Controversial / New | Existing rankings: `score` (top), `trending_score` (rising), `controversial_score` | 🟡 | Add common-ground sort. "New" = `created_at` sort. All cheap. |
| Scope filter: whole country / my state / my congressional district | `users.state`, `users.zip`; `legislators` (state, district); `constituents`; `branches` | 🟡 | State filter easy (users already have state). District needs zip→district lookup (available via legislators/`govtrack` data or a gem). |
| "52 video takes" count on rows | No video anywhere in app | 🔴 | Video takes = new subsystem (see below). |
| Propose-a-priority box with duplicate check + 60-char limit | Priority create flow exists; duplicate machinery: `changes` table (merge proposals with yes/no votes), `is_mergeable` on users | 🟡 | Add char limit + automatic duplicate suggestion (string similarity now; ML later). `changes` already models the merge vote. |

## Priority page

| Concept feature | Legacy asset | Status | Gap |
|---|---|---|---|
| Response clock (days since crossing the line, per-official reply status) | No equivalent | 🔴 | New: `response_requests` (priority, official, sent_at, replied_at, reply body, form-letter flag) + threshold config ("20,000 endorsements + CG ≥ 70, rises with membership" — design rule; v3.4 changelog). Renders from `constituents` join to know *which* officials have endorsing constituents. |
| Opinion map ("Who agrees, and on what") | `Relationship*` models (cross-priority overlap), `Priority#undecideds`, endorser/opposer/neutral splits | 🟡 | Data for opinion groups exists in spirit; needs clustering (start: 3 groups by voting pattern via existing relationship graph; later: Pol.is-style). Statements with per-group percentages = new `statements` + `statement_votes` tables. |
| Bills in Congress ("Where this stands in real legislation") | `legislators` table (had `govtrack_id`); no bills table | 🔴 | Congress.gov public API integration (v3 API, api.data.gov key). New `bills` + `priority_bills` link table; import job; status timeline (Introduced→Committee→Passed…). Replaces nothing — complements. "See how your officials voted" = roll-call votes, later phase. |
| Debate with "Steelman the other side" button | No AI anywhere | 🔴 | AI feature — pairs with the plain-language summaries idea. Start as curated (the briefing room's FOR/AGAINST talking points already exist), then AI draft + human review. |
| "3 sources" per argument | No sources model | 🔴 | Light: `sources` JSON on points, or new table. "Every claim needs a source" is a house rule — worth a real field. |

## New subsystems (not in legacy at all)

| Concept feature | Design file | Notes |
|---|---|---|
| **Video takes (Ziggeo)** — 90-sec for/against, auto-captions, transcripts, profanity mask | Home + Priority | Design explicitly: "RECORDING AND PLAYBACK POWERED BY ZIGGEO". New `video_takes` table + Ziggeo embed config. Captions/transcript storage. Ties into accessibility (ASL + captions idea). |
| **Citizens' assembly** — monthly balanced panel, 7-day program, published recommendations | Assembly | New: `assemblies`, `panelists` (stratified random draw: region, age, opinion group), `recommendations`. Stipend/childcare/ASL logistics are operational, not code-first. |
| **Budget sandbox** — $100 across real categories vs actual spending, locked interest | Budget | New: `budget_categories` (CBO data: category, actual share), `budget_submissions` (user allocations, JSON), member-average view. "Submit to add to average" + profile summary. |
| **Trust & transparency page** — ranking method, change log, integrity report, open data exports | Transparency | New page; mostly *publishing* what we compute: change log table, integrity stats (dupes removed, campaigns caught, summaries corrected, paid boosts = 0), CSV/JSON export endpoints, public API docs. Requires audit trail tables. |
| **Open data / public API** — weekly agenda snapshot CSV, anonymized votes JSON | Transparency + footer | New export endpoints + anonymization (votes tied to anonymous IDs). |
| **Local layer** — chapters + town-hall RSVPs | Design footer/comparison table ("local chapters, town-hall RSVPs") | `branches` exist (legacy "branches" = groups). Extend: chapter pages, RSVP events. District pages build on the district filter work above. |
| **Accessibility** — captions everywhere, ASL interpreted sessions, SMS voting, Spanish | Assembly (ASL), video takes (captions) | Partially in design (captions + ASL for assemblies). SMS/ES not in the exports — keep on the roadmap list; cheap wins: `Language` already supports en/de; add es; caption-first video design is already there. |

---

## What this means for sequencing

The concept is **one long arc from "restyle" to "new subsystems"**. Slices that are
nearly free because the engine already runs them:

1. **Slice 1 — the reskin (no new mechanics):** apply the WH3 design system to
   existing pages: header/footer bands, type scale (Cormorant SC + Montserrat),
   navy/gold palette, agenda rows with ENDORSE/OPPOSE + counts + momentum (already
   computed), common-ground column stubbed from existing endorse ratios, briefing
   room = existing points, civic credit = existing capitals, profile = existing
   user stats. This alone turns the 2009 look into the concept's look.
2. **Slice 2 — small new mechanics on existing tables:** common-ground score
   (computed), admin-stance relabel, scope filters (state first), propose-with-
   duplicate-check, sources field on points.
3. **Slice 3 — one flagship new subsystem:** pick from {response clock,
   opinion map, video takes}. Response clock is the most self-contained and the
   most differentiating ("silence becomes the story").
4. **Slice 4+ — the rest:** assemblies, budget sandbox, bills/Congress.gov,
   transparency/API, local layer, verification.

## Decisions the design has already made (vs the 10-idea brainstorm)

Daryl's 10 ideas list proposed quadratic voting; the design **deliberately did not
adopt it** — civic credit "can't add weight to your votes" (profile) and delegated
votes are capped at one hop with self-override (transparency changelog). The design
chose soft influence (credit unlocks *featuring a priority*, not vote weight). Keep
that; it is the concept's philosophy.
