#!/usr/bin/env python3
"""Build the web versions of every game in games.json.

For each game: copy carts/<slug>.p8 to docs/<slug>/, give it a label (the cart
"cover" picture PICO-8 needs before it will export HTML) if it has none, then
export docs/<slug>/index.html + index.js and the sprite sheet as sprites.png.

The label is a screenshot of the game's first screen, rendered headless: the
cart's own code runs with _init / a few _update calls / _draw, and the screen
is read back with pget and printed with printh.

usage: uv run tools/build.py   (or python3 tools/build.py)
"""
import json, os, shutil, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PICO8 = os.environ.get('PICO8', '/Applications/PICO-8.app/Contents/MacOS/pico8')

DUMP = '''
-- appended by tools/build.py: render one frame and print it
if _init then _init() end
for i=1,%d do
 if _update60 then _update60() elseif _update then _update() end
end
if _draw then _draw() end
local hx="0123456789abcdef"
printh("--label--")
for y=0,127 do
 local s=""
 for x=0,127 do local c=pget(x,y)%%16 s..=sub(hx,c+1,c+1) end
 printh(s)
end
'''


def run(args, cwd, timeout=40):
    # pico8 sometimes keeps running after -x; the timeout stops it
    try:
        r = subprocess.run([PICO8] + args, cwd=cwd, capture_output=True,
                           text=True, timeout=timeout)
        return r.stdout + r.stderr
    except subprocess.TimeoutExpired as e:
        return (e.stdout or b'').decode() if isinstance(e.stdout, bytes) else (e.stdout or '')


def sections(src):
    return [l for l in src.split('\n') if l.startswith('__') and l.endswith('__')]


def add_label(src, frames, tmp):
    lua_start = src.index('__lua__\n') + len('__lua__\n')
    nxt = [src.index(s + '\n', lua_start) for s in sections(src) if s != '__lua__' and src.find(s + '\n', lua_start) > 0]
    lua_end = min(nxt) if nxt else len(src)
    probe = src[:lua_end].rstrip('\n') + '\n' + DUMP % frames + src[lua_end:]
    p = os.path.join(tmp, 'probe.p8')
    open(p, 'w').write(probe)
    out = run(['-x', p], tmp)
    if '--label--' not in out:
        raise SystemExit('label render failed:\n' + out[-2000:])
    rows = out.split('--label--')[1].split()[:128]
    assert len(rows) == 128 and all(len(r) == 128 for r in rows), out[-500:]
    label = '__label__\n' + '\n'.join(rows) + '\n\n'
    # PICO-8 keeps __label__ after __gfx__/__gff__ and before __map__/__sfx__
    for after in ('__map__', '__sfx__', '__music__'):
        i = src.find('\n' + after + '\n')
        if i >= 0:
            return src[:i+1] + label + src[i+1:]
    return src.rstrip('\n') + '\n' + label


def main():
    games = json.load(open(os.path.join(ROOT, 'games.json')))
    only = sys.argv[1:]
    for g in games:
        if only and g['slug'] not in only:
            continue
        if not g.get('playable', True):
            continue
        slug = g['slug']
        out = os.path.join(ROOT, 'docs', slug)
        os.makedirs(out, exist_ok=True)
        src = open(os.path.join(ROOT, 'carts', slug + '.p8')).read()
        with tempfile.TemporaryDirectory() as tmp:
            if '__label__' not in sections(src):
                src = add_label(src, g.get('label_frames', 30), tmp)
            cart = os.path.join(tmp, slug + '.p8')
            open(cart, 'w').write(src)
            log = run([cart, '-export', 'index.html'], tmp)
            log += run([cart, '-export', 'sprites.png'], tmp)
            for f in ('index.html', 'index.js', 'sprites.png'):
                if not os.path.exists(os.path.join(tmp, f)):
                    raise SystemExit('%s: export of %s failed\n%s' % (slug, f, log))
                shutil.copy(os.path.join(tmp, f), os.path.join(out, f))
            shutil.copy(cart, os.path.join(out, slug + '.p8'))
        print('built', slug)


if __name__ == '__main__':
    main()
