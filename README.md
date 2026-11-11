# Our PICO-8 games

Games my kids and I made in [PICO-8](https://www.lexaloffle.com/pico8.php).
The kids draw the sprites, make the sounds and come up with the gameplay, and
since 2026 [Claude Code](https://claude.com/claude-code) writes most of the code.

## ▶️ Play

**https://andyreagan.github.io/pico-8/**

| Game | | Play |
|---|---|---|
| Dave Digger Bot | Dig for diamonds, throw chickens at the bots | [play](https://andyreagan.github.io/pico-8/dave-digger-bot/) |
| Bunny Quest | Find the axe and sword, beat the turtles, catch the bunny | [play](https://andyreagan.github.io/pico-8/bunny-quest/) |
| Super Animals | Five animals with powers race the boss to the ultra diamond | [play](https://andyreagan.github.io/pico-8/super-animals/) |
| Super Animals 2 | Super Animals for two players at once | [play](https://andyreagan.github.io/pico-8/super-animals-2/) |
| Princess Lucille | Collect doggies, zap Maldrid the evil wizard | [play](https://andyreagan.github.io/pico-8/princess-lucille/) |
| Rainbow Unicorn | Rainbow blocks, coins, a robber and a fort | [play](https://andyreagan.github.io/pico-8/rainbow-unicorn/) |
| Apple Guy vs the Duck | Poison apples and diamond robots | [play](https://andyreagan.github.io/pico-8/apple-guy/) |
| Animal Power, Cat Mario, Save the Children | Our first games (2025), before Claude | [all games](https://andyreagan.github.io/pico-8/) |

Keyboard: arrows to move, **z** and **x** for the two buttons.

We also play these on our RetroPie arcade cabinet, with the joysticks mapped
properly this time: [PICO-8 on the arcade with the joysticks working](https://andyreagan.com/2026-11-09-pico8-on-the-arcade.html).
The first game is written up in [Dave Digger Bot](https://andyreagan.com/2026-06-21-abel-wrote-a-game.html).

## Layout

- `carts/<slug>.p8` — the source carts (open in PICO-8 to play or tinker)
- `games.json` — titles, blurbs and controls
- `docs/` — the GitHub Pages site (web exports, built by the tools below)
- `tools/build.py` — exports each cart to `docs/<slug>/index.html`; carts with
  no label get one rendered headless from the game's first screen
- `tools/site.py` — writes `docs/index.html` and the cover images
- `tools/label_png.py` — a cart's label as a PNG
- `.claude/skills/pico8-kids-games/` — how we make the games with Claude:
  the workflow, the PICO-8 gotchas, and how the kids' art, sounds and ideas
  get turned into a game

## Building

Needs PICO-8 installed (set `PICO8=/path/to/pico8` if it isn't at
`/Applications/PICO-8.app`).

```sh
python3 tools/build.py          # all games (or: tools/build.py bunny-quest)
python3 tools/site.py
```

`dave-digger-bot` used to live in its own repo,
[andyreagan/dave-digger-bot](https://github.com/andyreagan/dave-digger-bot) (archived).
