# WhiteHouse 3 — design concept (Daryl's exports)

This directory holds the **WhiteHouse 3 design concept**: a full visual/interaction
design for the modernized site, supplied by Daryl as exported design components
(the "WhiteHouse 3" PDF is the scroll-through of the same design).

It is the **target direction for the UI modernization**. It is *not* production
code — each export is a React-runtime mockup whose inline styles carry the design's
exact values (colors, type, spacing). Implement by replicating those values in
Rails views + a real stylesheet, not by copying the mockup markup.

## Browse it

```bash
# from repo root
cd docs/wh3-concept/site && python3 -m http.server 8736
# open http://127.0.0.1:8736/Main.dc.html
```

Pages: `Main.dc.html` (agenda/home) · `Priority.dc.html` (priority detail) ·
`Join.dc.html` (verify & join) · `Profile.dc.html` (member profile) ·
`Accountability.dc.html` · `Assembly.dc.html` · `Budget.dc.html` ·
`Transparency.dc.html`. Header/footer are shared components.

Full-page screenshots of each are in `screenshots/` for quick reference in the repo UI.

## The design system (extracted values)

| Token | Value |
|---|---|
| Display font | `Cormorant SC`, 'Trajan Pro', Georgia, serif (wordmark, headings) |
| UI font | `Montserrat`, 'Helvetica Neue', Arial, sans-serif |
| Navy (primary) | `#0f2a45` (top band) / `#1b3c5a` (primary ink & buttons) |
| Deep navy inks | `#2c4e6d`, `#34506c`, `#0b1f33` |
| Gold (accent) | `#a88f61` (primary) / `#c6af8a` (light) / `#6f5a36` (dark, on light bg) |
| Cream surface | `#f1f0ee` |
| Body text | `#5f727d` (muted) · `#a9b6c2` (on navy) |
| Borders | `#d9d3c6` |
| Container | 1240px max, 24px gutters |
| Radii | 2px (controls), 6px (cards) |
| Buttons | min-height 44px, uppercase, letter-spacing 0.08em |

## Structure of the concept

- **Top band**: independence disclaimer ("An independent civic concept…").
- **Header**: `WhiteHouse` + gold `3` wordmark; nav: AGENDA / ACCOUNTABILITY /
  ASSEMBLY / BUDGET SANDBOX / HOW IT'S RANKED; profile icon + "Verify and join" CTA.
- **Home**: hero question ("What if the country set its own priorities, in pubic?"),
  #1 common-ground card with left/right split bars, the agenda list with
  ENDORSE/OPPOSE, common-ground scores, momentum ("Up 2 this week"), admin stance,
  briefing room, civic credit explainer, video takes (Ziggeo), "from 2008 to now" table.
- **Priority**: response clock (days since crossing the line, per-official reply
  status), opinion map (voting-pattern groups, agree/split statements), bills in
  Congress (Congress.gov feed), debate with Steelman button + sourced columns.
- **Personas**: verify-once join flow (ID / postcard / in person; privacy promise);
  profile with "me and my officials" table, civic credit history, delegations.

## How it relates to the codebase

`feature-map.md` maps each concept feature to what the legacy Rails app already
has (surprisingly much: `points.endorser_score` etc. already implement
cross-viewpoint "helpful" scoring; `capitals` implement civic credit;
`position_7days_change` implements momentum; `legislators`/`constituents`
implement "your officials"). Read that file before planning implementation.

The old `../ui/home-concept.html` (blue #13499b, different direction) is
**superseded** by this concept; it stays only as an alternative if ever wanted.
