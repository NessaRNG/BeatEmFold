# Enemy Distinct Attack Animations & Slash FX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mengimplementasikan variasi animasi serangan unik (`jab`, `hook`, `upper`) dan slash FX merah/oranye untuk masing-masing varian musuh (Striker, Fury/Dasher, Brute/Boss).

**Architecture:**
1. Tambahkan helper `_attack_anim_name()` di `scripts/dummy.gd` berdasarkan tipe tampilan musuh (`look`).
2. Update fase windup AI state 1 & 3 di `scripts/dummy.gd` agar memainkan animasi serangan yang sesuai.
3. Tambahkan fungsi `_spawn_attack_slash()` di `scripts/dummy.gd` yang dipanggil saat `_strike()` atau slam AoE.
4. Verifikasi bahwa seluruh smoke test (`tests/test_step5.gd`, `tests/test_step6.gd`, `tests/test_step7.gd`, dsb.) tetap lulus 100%.

**Tech Stack:** Godot 4.7, GDScript, AnimatedSprite2D, Sprite2D, Tween.

**Spec:** `docs/superpowers/specs/2026-11-14-enemy-attack-animations-spec.md`

## Global Constraints
- `test_step5.gd`, `test_step6.gd`, dan `test_step7.gd` memeriksa AI state transitions (windup -> strike -> recover). Timing `ai_windup` dan `ai_recover` tidak boleh rusak.
- Boss slam AoE dan normal melee attack tetap terpicu sesuai kondisi jangkauan yang sudah ada.

---

### Task 1: Enemy Attack Animation Mapping and Visual Slash FX in Dummy.gd
**Files:**
- Modify: `scripts/dummy.gd`
- Test: Jalankan `tests/test_step5.gd`, `tests/test_step6.gd`, `tests/test_step7.gd`

- [ ] **Step 1: Definisikan mapping animasi serangan berdasarkan `look`**
- [ ] **Step 2: Update AI state 1 & 3 dan `_update_visual()` untuk memutar animasi serangan spesifik**
- [ ] **Step 3: Tambahkan `_spawn_attack_slash()` saat `_strike()` dan `_update_slam()`**
- [ ] **Step 4: Jalankan tes regresi dan commit**
