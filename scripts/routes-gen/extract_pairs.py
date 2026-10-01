#!/usr/bin/env python3
"""Extract every hash-style redirect_to/url_for/link_to (controller, action) pair
from the app, so the deprecated catch-all route can be replaced by explicit
routes. Writes tmp/legacy_pairs.txt: one 'controller action' per line.
"""
import re, pathlib

ROOT = pathlib.Path('/home/daryl/work/whitehouse3')
pairs = set()

def add(ctrl, action):
    if ctrl and action:
        pairs.add((ctrl, action))

# --- controllers: redirect_to / url_for with hash options -------------------
ctrl_re = re.compile(r"['\"]?(?:controller|:controller)\s*=>?\s*['\"]?([a-z_]+)")
act_re = re.compile(r"['\"]?(?:action|:action)\s*=>?\s*:?['\"]?([a-z_0-9]+)")

for f in sorted((ROOT / 'app/controllers').glob('*_controller.rb')):
    own = f.name.replace('_controller.rb', '')
    src = f.read_text()
    for m in re.finditer(r"(?:redirect_to|url_for|link_to|render)\s*\(?([^\n]*?)\)?\s*(?:if|unless|$|\n)", src):
        seg = m.group(1)
        if 'action' not in seg and ':action' not in seg:
            continue
        a = act_re.search(seg)
        c = ctrl_re.search(seg)
        if a:
            add(c.group(1) if c else own, a.group(1))
        elif c:
            add(c.group(1), 'index')

# --- views: link_to/url_for/form_tag/form_for with hash options -------------
for f in sorted((ROOT / 'app/views').rglob('*.erb')):
    src = f.read_text()
    for line in src.splitlines():
        if re.search(r"(:action\s*=>|action:\s|:action\s*=>)", line) and re.search(r"(:controller\s*=>|controller:\s)", line) is None:
            # action-only in a view: record with a marker so we can inspect them
            for m in act_re.finditer(line):
                pairs.add(('?', m.group(1)))
        if re.search(r"(:controller\s*=>|controller:\s*)", line):
            cs = ctrl_re.findall(line)
            as_ = act_re.findall(line)
            for c in cs:
                if as_:
                    for a in as_:
                        add(c, a)
                else:
                    add(c, 'index')

lines = sorted(f"{c} {a}" for c, a in pairs)
out = ROOT / 'tmp/legacy_pairs.txt'
out.write_text("\n".join(lines) + "\n")
print(f"{len(lines)} pairs written; '?' = action-only view sites")
print(f"action-only sites: {sum(1 for l in lines if l.startswith('? '))}")
print("\n".join(l for l in lines if l.startswith('? '))[:400])
