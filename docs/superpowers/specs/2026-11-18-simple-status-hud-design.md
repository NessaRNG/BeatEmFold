# Simplify Player Status HUD — Design

## Intent
Remove unused/redundant elements from the player status HUD, keeping only what is genuinely used.
Pure UI change. No gameplay logic change.

## Decisions (approved)
- Remove `combo_label` ("JAB: -") — minor info, not needed.
- Remove `deck_label` ("TANGAN/DECK/$/SKOR/CASH/BUANG") — redundant: CASH/BUANG already shown as
  pips, TANGAN visible from card slots, $ only used in shop, SKOR shown on game over.
- Keep: portrait frame, player HP label, HP bar (bg/delay/fill), wave label, cash/discard pips,
  SEAL badge+text, boss bar, help label, mode label, combat label.

## Constraints / test contracts
- `test_step10`: `hud_panel.visible`, `seal_badge.visible`, `seal_text` contains "STRAIGHT".
- `test_step8`: `hp_bar_fill.size.x` = 280 full / 140 at 50%.
- Remove the update sites for combo_label/deck_label too (functions that set their .text), and
  the `_refresh_counters` calls that fed deck_label — but keep budget logic (hands/discards)
  that pips still use.
- All 13 smoke suites green.
