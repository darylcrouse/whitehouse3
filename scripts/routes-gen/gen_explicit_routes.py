#!/usr/bin/env python3
"""Regenerate the explicit legacy route block that replaces the deprecated
:controller/:action catch-all.

Sources:
  1. tmp/all_actions.json  - every controller's own public actions (runner introspection)
  2. tmp/legacy_pairs.txt  - every hash-style (controller, action) pair in code
  3. issues nav specials   - slug-based issue sub-pages, both legacy shapes
"""
import json, re, pathlib

ROOT = pathlib.Path('/home/daryl/work/whitehouse3')
valid = re.compile(r'^[a-z_0-9]+$')

enum = json.loads((ROOT / 'tmp/all_actions.json').read_text())
code_pairs = []
for line in (ROOT / 'tmp/legacy_pairs.txt').read_text().splitlines():
    if line.startswith('? ') or not line.strip():
        continue
    c, a = line.split()
    code_pairs.append((c, a))

lines = []
lines.append("  # ---------------------------------------------------------------------")
lines.append("  # Explicit replacements for the retired Rails-2 :controller/:action")
lines.append("  # catch-all. Generated from every controller action + every hash-style")
lines.append("  # (controller, action) URL-generation site in the app, so both generation")
lines.append("  # (redirect_to/url_for/link_to hashes) and serving keep working without")
lines.append("  # the dynamic segments removed in Rails 8.1.")
lines.append("")

ISSUES_SLUG_ACTIONS = [
    'yours', 'yours_finished', 'yours_created', 'network', 'obama', 'not_obama',
    'obama_opposed', 'rising', 'falling', 'controversial', 'random', 'newest',
    'finished', 'twitter', 'points', 'documents', 'discussions',
]
lines.append("  # Tag-scoped issue sub-pages, in both legacy shapes:")
lines.append("  #   /issues/<action>/<slug>  (what hash url_for used to generate)")
lines.append("  #   /issues/<slug>/<action>  (slug-first, matches the resources block above)")
for a in ISSUES_SLUG_ACTIONS:
    lines.append(f'  get "issues/{a}/:slug",   to: "issues#{a}"')
lines.append("")
for a in ISSUES_SLUG_ACTIONS:
    lines.append(f'  get "issues/:slug/{a}",   to: "issues#{a}"')
lines.append("")

pairs = set()
for c in sorted(enum):
    for a in enum[c]:
        if valid.match(a):
            pairs.add((c, a))
for c, a in code_pairs:
    if valid.match(a):
        pairs.add((c, a))

lines.append("  # Full controller#action pair table (the catch-all's dispatch surface).")
seen = set()
for c, a in sorted(pairs):
    if (c, a) in seen:
        continue
    seen.add((c, a))
    lines.append(f'  match "{c}/{a}(/:id)(.:format)", to: "{c}#{a}", via: %i[get post]')

lines.append("")
lines.append("  # Bare controller paths (-> index), which the catch-all served with its")
lines.append("  # default action.")
for c in sorted(enum):
    if 'index' in enum[c]:
        lines.append(f'  match "{c}(/:id)(.:format)", to: "{c}#index", via: %i[get post]')

lines.append("")
(ROOT / 'tmp/legacy_routes_snippet.rb').write_text("\n".join(lines) + "\n")
print(f"snippet: {len(lines)} lines, {len(seen)} pairs")
