# Announcer Scope Implementation Plan

**Goal:** Announcer only on area change (new style), per-wave banner, and WAVE CLEAR. Remove cash-in hit/fail spam. 15 suites green.

**Architecture:** In main.gd: strip `_show_combat_text` from `_on_cash_resolved` / `_on_cash_failed`;
in `_start_wave` compute area change vs previous, pass a flag to `_enter_stage`; add
`_announce_area()` with a gold, larger, longer-hold variant of `_show_combat_text`.

**Spec:** `docs/superpowers/specs/2026-11-18-announcer-scope-design.md`

### Task 1
- [ ] Step 1: Remove cash-in spam calls; add area-change detection + `_announce_area()` in main.gd
- [ ] Step 2: Add test_step16 (area change detection at wave 5/10/15), run 16 suites, commit
