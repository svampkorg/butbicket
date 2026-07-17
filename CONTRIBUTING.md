# Contributing to ButBicket

Thanks for helping out! This is a small colorscheme plugin, so the process is
light. The two things CI checks are **formatting** and the **test harness** —
run both locally before opening a PR and review will go smoothly.

## Project layout

```
colors/                     entrypoints (:colorscheme butbicket[-dark|-light])
lua/butbicket/
  init.lua                  setup(), colorscheme(), terminal colors, group loading
  config.lua                default options + user config merging
  colorscheme.lua           the palette (raw colors + dark/light semantic mapping)
  hl-groups.lua             base + treesitter + LSP highlight groups
  utils.lua                 color mixing/shading helpers
  integrations/             per-plugin highlight tables
lua/lualine/themes/         lualine theme
after/queries/              per-language treesitter query overrides
tests/                      contrast helpers + standalone test runner
scripts/gen-terminals.lua   generates extras/<terminal>/ theme files
extras/                     generated terminal themes (ghostty/kitty/…)
```

If you change the palette or `set_terminal_colors()`, regenerate the terminal
themes and commit them:

```sh
nvim -l scripts/gen-terminals.lua
```

## Development setup

You need [`stylua`](https://github.com/JohnnyMorganz/StyLua) and Neovim >= 0.9
(for `nvim -l`).

```sh
# format
stylua .

# check formatting without writing (what CI runs)
stylua --check .

# run the tests
nvim -l tests/run.lua
```

## Tests

`tests/run.lua` is dependency-free (no plenary/busted) and runs both backgrounds.
It checks:

1. `colorscheme()` loads without error (dark **and** light).
2. Every palette key the highlights depend on is defined (catches the class of
   typo/find-replace bug that silently drops a color).
3. WCAG contrast ratios for foreground colors against the editor background meet
   a floor. **This is the quality gate for the light theme** — if you add or
   change a foreground color, add it to `contrast_pairs` in `tests/run.lua`.

`tests/contrast.lua` exposes `luminance(hex)` and `ratio(fg, bg)` if you want to
grade a candidate color by hand.

## Working on colors

- The palette lives in `lua/butbicket/colorscheme.lua`. Raw colors are defined
  once at the top; the `if vim.o.background == 'light'` branch remaps them and
  sets the semantic aliases for each variant.
- **`hl-groups.lua` references some raw palette keys directly** (`type`,
  `method`, `keyword`, `number`, `variable`, …), so if you touch the light
  branch make sure those keys are remapped there too — otherwise dark values
  bleed into the light theme. The tests guard the important ones.
- Prefer adding a *semantic alias* (e.g. `colorscheme.syntaxFunction`) over
  wiring a raw color into `hl-groups.lua`, so both variants stay in sync.

## Adding a plugin integration

1. Create `lua/butbicket/integrations/<plugin>.lua` exporting
   `M.highlights()` that returns a `{ GroupName = { … } }` table.
2. Register it in the `set_groups` loop in `lua/butbicket/init.lua`.
3. Add it to the `reloadable` list in `init.lua` so it re-evaluates on a
   background toggle.

## Pull requests

- One logical change per PR where possible.
- Run `stylua .` and `nvim -l tests/run.lua` first.
- If you changed colors, a before/after screenshot is very welcome.

## Reviewing PRs (maintainer notes)

- CI must be green (stylua + tests on stable and nightly).
- For color changes, check the contrast output in the test log rather than
  eyeballing alone — especially for the light variant.
- Be generous with "thanks" and specific with requested changes. It's fine to
  ask a contributor to add a test alongside a new foreground color.
