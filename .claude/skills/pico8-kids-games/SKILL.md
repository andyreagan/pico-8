---
name: pico8-kids-games
description: Turn a kid's game idea plus the sprites and sounds they drew in PICO-8 into a playable PICO-8 game. Use when asked to make a new game in this repo, turn an untitled_N.p8 cart into a game, add a character or level, or publish a game to the web page / arcade.
---

# Making PICO-8 games with the kids

How the games in this repo were made. The kids own the **ideas, art and
sounds**; Claude writes the code and fills in whatever art is missing. Keep
it that way: the most fun part for them is seeing *their* drawings move.

## 1. Start from the kids' words

The prompt is the design doc. Real examples:

> the bad guys name is maldrid, an evil wizard. rainbow platforms. the main
> character is a princess named princess lucille. the princess tries to
> collect doggies for points. she has power to get away, a magic wand that
> can make the bad guy go away. there is a tent that is the safety lair, pink
> tent. a red orb for the bad guy safety.

> untitled_3 is a world explorer game. The main guy, the blue guy in sprite
> 001, picks up the axe and the sword (sprites 7 and 9). The sword and axe are
> hidden. ... The turtle (sprite 3) is evil and you try to catch the bunny
> (sprite 5). You need to use both of the weapons to kill the evil turtles.

- Every noun in the prompt should be in the game, named as the kid named it
  (lowercase is fine, it's PICO-8). Names go on the title screen and in
  messages ("maldrid got you!").
- Every rule in the prompt becomes a mechanic, even odd ones. Example: "the
  snail sticks to things and hides in its shell, if it hides while stuck it
  falls off" → wall/ceiling sticking, a shell that blocks damage, and hiding
  while stuck drops you.
- Fill gaps with the smallest sensible choice (lives = 3, z = jump/talk,
  x = action), then say what you chose.
- Each game gets a title screen with the name, a one-line goal, and the
  controls, e.g. `arrows move  z jump  x wand`.

## 2. Read the cart before writing anything

Carts live in `~/Library/Application Support/pico-8/carts/` (the kids save
there) and are copied into `carts/<slug>.p8` here.

- Parse `__gfx__` (128 hex chars per row, one hex digit per pixel) and render
  the sprite sheet to a PNG at 6-8x to look at it; also look at `__map__` if
  they drew one. Identify each drawing by its pixel bounding box, not by
  8x8 sprite number: kids' drawings straddle sprite cells, so use
  `sspr(x,y,w,h,...)` with exact boxes (e.g. guy `sspr(11,0,9,16)`).
- Note which way each character faces; flip with the `flip_x` arg.
- Two drawings of the same character = animation frames (the two cheetahs
  alternate for running). Align them to the bottom edge.
- Listen to `__sfx__`: the kids' sounds are numbered in the order they made
  them ("the second sound" = sfx 1). Use their sounds for the matching events
  and loop music with `__music__` (flag byte: 1 loop start, 2 loop end,
  4 stop) when asked.
- Back up the cart before editing (`cp x.p8 x.p8.bak` in a scratch dir).

## 3. Missing art

When the game needs things the kids didn't draw (tiles, villagers, a fort),
draw them as ASCII grids in a small Python script and merge them into
`__gfx__`:

- Only write into empty (all `0`) areas; `assert` before every pixel so you
  never overwrite their art.
- Keep the style: chunky, bright, PICO-8 palette. Render a PNG preview of the
  whole sheet and look at it before building.
- **Color 0 (black) is transparent** for `spr`/`sspr`. Use navy (1) for black
  outlines or eyes, or the pixels vanish.
- gfx rows 64-127 share memory with map rows 32-63: if the lower half of the
  sheet is used, keep the map to rows 0-31.
- Sprite flags (`__gff__`, 2 lines × 256 hex) mark solid tiles (flag 0).

## 4. Code shape that has worked

- One `state` var: `title` → `play` → `win`/`over`, z to continue.
- Platformers: either one-way platforms from rectangles (land only if the old
  bottom was above the top) or solid map tiles with 1-pixel stepping
  (`move(e)` tries x then y a pixel at a time). Gravity ~0.25, variable jump
  height (release early = add extra gravity).
- Top-down: collide with the feet box only, and for the kids' freehand map
  art use per-pixel checks (`sget` != background color) so bushes and stumps
  block exactly where they're drawn.
- Safety zones (fort, tent, orb, houses) are just rectangles the enemy AI
  checks: enemy can't hurt you inside, and wanders off.
- Enemies: simple chase with a speed that ramps with level; give the player
  a breather (invulnerable flash for 60 frames after a hit).
- Lowercase only in code strings (uppercase renders as the puny font).
  P8SCII glyphs: `\135` heart, `\142` O button, `\151` X button.
- Keep text lines ≤ 32 chars (≤ 25 next to a portrait).

## 5. Test headless before handing it over

The kids will find bugs fast; find them first.

- Syntax: extract `__lua__`, rewrite PICO-8 shorthand (`!=` → `~=`,
  `a+=b` → `a=a+b`) and run `luac -p`. P8SCII glyphs make luac complain
  about `<\226>`; those are fine.
- Run it in real PICO-8 without a window:
  `perl -e 'alarm 30; exec @ARGV' /Applications/PICO-8.app/Contents/MacOS/pico8 -x harness.p8`
  where `harness.p8` is the cart with the game code plus a test at the end
  that overrides `btn`/`btnp` from a keys table, calls `_init`/`_update`/
  `_draw` in a loop and `printh`s what happened. A harness needs the real
  `__gfx__`/`__gff__`/`__map__` sections if the game reads them.
- Play it with a bot: walk the level, jump every gap with every character,
  reach the goal, die and respawn, open every door. Several real bugs were
  found this way (a bot let go of jump too early; the cheetah jumped *over*
  the diamond; the snail couldn't clear a gap; a straight-line chaser got
  stuck on a stump).
- Make gaps and stepping stones generous (2 tiles), it's for kids.

## 6. Publish

- Add the game to `games.json`, copy the cart to `carts/<slug>.p8`, then
  `python3 tools/build.py <slug> && python3 tools/site.py`. The build renders
  a label if the cart has none (HTML export refuses without one).
- Arcade (RetroPie): copy the cart to `arcade:/home/pi/RetroPie/roms/pico8/`,
  add a `<game>` name in
  `/opt/retropie/configs/all/emulationstation/gamelists/pico8/gamelist.xml`,
  restart EmulationStation. Panel buttons: a = 🅾️ (z), b = ❎ (x),
  start = pause, select+start = quit. See
  https://andyreagan.com/2026-11-09-pico8-on-the-arcade.html.
- Public repo: keep the kids' first names out of new carts and copy (Abel is
  already public), unless Andy says otherwise.
