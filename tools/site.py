#!/usr/bin/env python3
"""Write docs/index.html (the GitHub Pages landing page) and a label.png cover
for each built game. Run after tools/build.py."""
import html, json, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BLOG = 'https://andyreagan.com/2026-11-09-pico8-on-the-arcade.html'
games = json.load(open(os.path.join(ROOT, 'games.json')))

cards = []
for g in games:
    slug, t = g['slug'], html.escape(g['title'])
    blurb = html.escape(g['blurb'])
    if g.get('playable', True):
        d = os.path.join(ROOT, 'docs', slug)
        subprocess.run([sys.executable, os.path.join(ROOT, 'tools', 'label_png.py'),
                        os.path.join(d, slug + '.p8'), os.path.join(d, 'label.png')], check=True)
        ctl = '<p class="ctl">%s</p>' % html.escape(g['controls']) if g.get('controls') else ''
        cards.append(f'''<a class="card" href="{slug}/">
  <img src="{slug}/label.png" alt="{t}">
  <h2>{t} <small>{g["year"]}</small></h2>
  <p>{blurb}</p>{ctl}
</a>''')
    else:
        cards.append(f'''<a class="card notes" href="https://github.com/andyreagan/pico-8/blob/main/carts/{slug}.p8">
  <h2>{t} <small>{g["year"]}</small></h2>
  <p>{blurb}</p>
</a>''')

page = f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Our PICO-8 games</title>
<style>
 body {{ background:#1d2b53; color:#fff1e8; font-family: ui-monospace, Menlo, monospace; margin:0; padding:24px; }}
 header {{ max-width:960px; margin:0 auto 24px; }}
 h1 {{ color:#ffec27; margin:0 0 8px; }}
 a {{ color:#29adff; }}
 .grid {{ max-width:960px; margin:0 auto; display:grid; grid-template-columns:repeat(auto-fill,minmax(260px,1fr)); gap:20px; }}
 .card {{ background:#000; border:3px solid #5f574f; border-radius:6px; padding:12px; color:#fff1e8; text-decoration:none; }}
 .card:hover {{ border-color:#ff77a8; }}
 .card img {{ width:100%; image-rendering:pixelated; display:block; }}
 .card h2 {{ font-size:18px; color:#ffa300; margin:10px 0 6px; }}
 .card small {{ color:#83769c; font-size:12px; }}
 .card p {{ margin:4px 0; font-size:14px; line-height:1.4; }}
 .card .ctl {{ color:#c2c3c7; font-size:12px; }}
 .notes {{ border-style:dashed; }}
</style>
</head>
<body>
<header>
<h1>Our PICO-8 games</h1>
<p>Games my kids and I made in <a href="https://www.lexaloffle.com/pico8.php">PICO-8</a>.
The kids draw the sprites, make the sounds and come up with the game, and
since 2026 Claude Code writes most of the code.
Click a game to play it in the browser (keyboard: arrows, z and x).</p>
<p>We also play them on our arcade cabinet: <a href="{BLOG}">PICO-8 on the arcade with the joysticks working</a>.
Source: <a href="https://github.com/andyreagan/pico-8">github.com/andyreagan/pico-8</a>.</p>
</header>
<div class="grid">
{chr(10).join(cards)}
</div>
</body>
</html>
'''
open(os.path.join(ROOT, 'docs', 'index.html'), 'w').write(page)
print('wrote docs/index.html')
