#!/bin/bash
# Put the online carts the kids have launched into Splore's favourites on the
# arcade. Reads PICO-8's play log there; safe to rerun (only adds).
# usage: tools/arcade_favourites.sh
ssh arcade 'pkill -f "[p]ico8_dyn -v"; cd ~/.lexaloffle/pico-8 && python3 - <<PY
import os, re
seen, rows = set(), []
for line in open("activity_log.txt", errors="replace"):
    m = re.search(r"/pico-8/(bbs/\S+\.p8\.png)", line)
    if not m or m.group(1) in seen or not os.path.exists(m.group(1)):
        continue
    p = m.group(1); seen.add(p)
    stem = os.path.basename(p)[:-len(".p8.png")]
    title = stem
    # metadata sits in temp-<id>.nfo next to the cart (id without the -N revision)
    for cand in (stem, re.sub(r"-\d+$", "", stem)):
        nfo = os.path.join(os.path.dirname(p), "temp-%s.nfo" % cand)
        if os.path.exists(nfo):
            for l in open(nfo, errors="replace"):
                if l.startswith("title:"):
                    title = l[6:].strip()
    rows.append("|%-20s |%-20s |%-6d |%-16s |%-20s |%s\n" % ("", "", 0, "", p, title))
# lines already in the file win (PICO-8 fills in their metadata over time)
old = {}
if os.path.exists("favourites.txt"):
    for l in open("favourites.txt", errors="replace"):
        f = l.split("|")
        if len(f) >= 7:
            old[f[5].strip()] = l if l.endswith("\n") else l + "\n"
out = list(old.values()) + [r for r in rows if r.split("|")[5].strip() not in old]
open("favourites.txt", "w").write("".join(out))
print("".join(out))
PY'
