# Announcer Scope — Design

## Intent
The yellow center announcer (`combat_label`) appears constantly because every cash-in fires
`"HAND! X DMG → N TARGET"` / `"MISS…"` and error text. Make it appear only at meaningful moments.

## Decisions (approved)
- REMOVE `_show_combat_text` from `_on_cash_resolved` (DMG/MISS spam) and `_on_cash_failed` (error).
  Damage feedback remains via floating numbers, shake, flash, FX, SFX, callout scale.
- KEEP per-wave banner in `_enter_stage` (`wave_banner`) and `"WAVE CLEAR!"` in `_wave_clear_cine`.
- ADD a distinct area-transition announcement when the tier changes ALLEY→ROOFTOP→CLUB:
  e.g. `"ENTERING ROOFTOP — WAVE 15"`. Shown at the wave where tier changes.

## Area transition logic
`tier_of(idx) = loop/5 % 3` (main.gd:_start_wave computes `block`, stage theme = `block % 3`).
Area changes whenever `tier_of(idx) != tier_of(idx - 1)`. Need a WaveManager static helper
`tier_of(idx)` (check if exists) or compute locally. Show a different-styled announcer for the
area change (bigger, gold, longer hold) vs the normal wave banner.

## Constraints / test contracts
- Do not break `wave_banner` / `wave_title` (test_step9 "WAVE 4", test_step6 "WAVE 2").
- Do not touch damage/target logic.
- combat_label text color: set gold for area announce; normal banner keeps existing color.
- All 15 suites green.
