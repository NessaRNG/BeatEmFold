# UI Polish Design — neon arcade, full sweep

## Intent
Make every surface of the UI look and read better, keeping the existing neon arcade identity.
No gameplay changes. This is a direct continuation of the approved "Polish menyeluruh" choice.

## Findings from actual screenshots (menu / fight / shop)
1. **HP bar rendered in world space**: `hp_bar_bg/delay/fill` are `add_child`-ed to `self`
   (Node2D main) while labels live in `ui_root` (CanvasLayer). Result: green bar floats over
   the brick wall, detached from "PLAYER HP" text and camera-shifted. Fix: parent them to
   `ui_root` like the rest of the HUD.
2. **HUD text cramped/overflowing**: wave/combo/deck lines at 24px spacing with a very long
   deck line ("HAND 3/8 | DECK 21 | CASH 4/4 | BUANG 3/3 | $10 | SHOP 0") that overflows.
3. **Cards small & plain**: 64×90 slots, tiny pips, weak selected state.
4. **Shop dim**: card panels near-transparent, power-up row overlaps the "K.O. BAR" sign.
5. **Menu bare**: title + 2 buttons, no framing or identity.

## Goals
- Everything readable: larger fonts, stronger contrast, no overlap/overflow.
- Cohesive layered panels (framed HUD, solid shop cards, glowing selected cards, framed menu).
- Fix the HP-bar parent bug.

## Non-goals / constraints
- Keep all names/text/smoke-test contracts: `hud_panel.visible`, `menu_title`, `menu_best`
  contains "TERBAIK", `menu_mulai` begins "(M)", `seal_text` contains "STRAIGHT",
  `over_score` contains "SKOR", `hp_bar_fill.size.x == 280` full / `140` at 50%,
  `shop.rows.size() == 2`, power-up buttons separate from rows.
- No gameplay/timing/animation changes. 29-frame sheets untouched.

## Approach (chosen: full polish, same style)
- `ui_theme.gd`: bump base/button font sizes, stronger label outline, add `panel_framed()`
  with border + subtle inner shadow for cohesion.
- `main.gd`: reparent HP bars to `ui_root`; restyle HUD panel; space out wave/combo/deck;
  shorten deck line; larger help text; framed menu + bigger title/buttons.
- `hand_ui.gd`: bigger slots (78×106), rank in corner, suit symbol, glowing selected state,
  larger best-hand label.
- `shop_ui.gd`: smaller card height so power-up row fits; solid/brighter card panels;
  larger readable text; power-up row recentered below shop cards with clear gap.

## Validation
- Screenshot menu/fight/shop after change and visually compare.
- Run all 13 smoke suites; all green.
