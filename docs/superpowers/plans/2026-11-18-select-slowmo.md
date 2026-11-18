# Select-Mode Slow Motion Implementation Plan

**Goal:** Sustained slow-mo while Tab held + pulse on card pick, via a unified time-scale controller that doesn't conflict with hitstop. All 13 suites green.

**Architecture:** In `main.gd` add `select_slow_active`, `select_pulse_until`, `hitstop_factor` state
and `_apply_time_scale()` computing min of active factors. Rewrite `hitstop()` to set its factor
and call the controller. Hook Tab transition and card-pick in `_unhandled_input`.

**Tech Stack:** Godot 4.7 GDScript.
**Spec:** `docs/superpowers/specs/2026-11-18-select-slowmo-design.md`

### Task 1: Implement controller + hooks
- [ ] Step 1: Add state vars + `_apply_time_scale()`; rewrite `hitstop()`
- [ ] Step 2: Hook Tab held transition + card-pick pulse in `_unhandled_input`; reset on wave start/clear
- [ ] Step 3: Add focused test `tests/test_step14_slowmo.gd`; run all 14 suites; commit
