# Power-Up Panel UI Polish — Design

## Intent
Make the shop's power-up pick section neat and readable, keeping the approved "dedicated framed
panel inside the shop" placement. Pure UI change; no gameplay/logic change.

## Problems observed in screenshot
- No frame/container: title + 3 cards float over the brick wall and overlap the "K.O. BAR" neon.
- Tiny cramped text (name + desc + stack in one 210×74 box), low contrast.
- "Lanjut" button not visually prominent / lost among the layout.
- No category identity (TINJU/GERAK/AFINITAS/FINISHER) or visible stack count.

## Design
- `powerup_frame: Panel` using `UiTheme.panel_framed()` — solid dark bg, purple border, header.
  Title "PILIH 1 POWER-UP (GRATIS)" big inside the frame top.
- 3 power-up cards inside frame at 224×112 each, color-coded border by category:
  TINJU=#ff6b5a, GERAK=#5ad9ff, AFINITAS=#7bff9e, FINISHER=#ffd94d.
  Each card shows: key hint [7]/[8]/[9], category badge, name (big), desc (body), stack badge
  "xN" when already owned. Picked card shows green ✓ DIPILIH, others dim/disabled.
- Note line under cards inside frame.
- "Lanjut" continue button moved to the very bottom, wide and bright green.

## Constraints / test contracts
- `shop.rows.size() == 2` (test_step4) — power-up nodes stay separate from rows.
- `pick_powerup(i)`, card node "Name" (test_step13) preserved.
- Keys 7/8/9 still work (main.gd unchanged).
- All 13 smoke suites green.
