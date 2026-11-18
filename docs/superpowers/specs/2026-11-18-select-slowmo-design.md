# Select-Mode Slow Motion — Design

## Intent
Add game feel: while holding Tab (select mode), time slows for a "thinking" beat; each card pick
adds a brief deeper pulse. Feedback only — no gameplay logic change.

## Decisions (approved)
- While Tab held: sustained slow-mo ~0.45x.
- Each card pick (slot 1-6 while held): pulse ~0.20x for 0.08s layered on top.
- On Tab release: time returns to normal.

## The real problem to solve
`Engine.time_scale` is currently written directly by `hitstop()` (main.gd:813) which sets 0.3 then
unconditionally resets to 1.0. Enemies stay active while Tab is held, so the player can be hit →
hitstop fires and would stomp the select slow-mo. Two writers, no coordination.

## Design: unified time-scale controller
Introduce a single function that computes the effective scale from active sources:
- `select_active: bool` → 0.45 when Tab held.
- `select_pulse_until: float` (msec timestamp) → 0.20 while active.
- `hitstop_active: bool` → hitstop's factor while active.
- Effective = min of all active factors, default 1.0.

`hitstop()` no longer writes `Engine.time_scale = 1.0` directly; it clears its own flag and calls
`_apply_time_scale()`. Tween-based hitstop timer uses `ignore_time_scale=true` already.

## Integration points
- `main.gd`: add `_apply_time_scale()`, call on Tab transition (989-993), on card pick (997),
  and rewrite `hitstop()` (813-820) to use flags. Reset flags in `_start_wave`/`_wave_clear`
  where `Engine.time_scale = 1.0` currently appears.
- No change to player/dummy/card logic.

## Constraints / test contracts
- `test_step7` requires hitstop not stuck and time_scale == 1.0 within 300 frames. Unified
  controller must restore 1.0 when all flags clear.
- Tests call `toggle_select()` directly (no Tab) — those must NOT trigger slow-mo (pulse only in
  main.gd input path), so tests are unaffected.
- All 13 smoke suites green.
