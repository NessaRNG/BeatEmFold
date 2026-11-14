# Modern Arcade Brawler Visuals & Fluid UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merombak seluruh sistem animasi sprite karakter menjadi 16-frame fluid arcade brawler (idle 4 frame, walk 6 frame, jab/hook/upper ber-slash trail), menambahkan efek visual combat (swing arc & dust puff), serta memoles seluruh UI dengan game feel arcade (dual-layer HP lag-bar, elastic bouncing floating damage, dan card hand slide-up & selection lift).

**Architecture:**
1. Upgrade `tools/generate_chibi_brawler_assets.py` untuk merender 16-frame sprite sheets (768x48) per karakter, serta tekstur slash arc efek pukulan.
2. Update `scripts/char_sprites.gd` agar memetakan 16 frames ke animasi `idle`, `walk`, `jab`, `hook`, `upper`, `hit` dengan frame-rate halus (8-14 FPS).
3. Integrasikan visual FX swing arc pukulan dan dust puff di `scripts/player.gd` dan `scripts/dummy.gd`.
4. Rombak `_spawn_float` pada `scripts/dummy.gd` agar menghasilkan animasi damage number elastis dengan pivot tengah, pop scale, dan random trajectory.
5. Upgrade UI di `scripts/main.gd` dengan dual-layer lag-bar HP dan combo counter punch tween, serta di `scripts/hand_ui.gd` dengan animasi card selection lift dan draw bounce.
6. Verifikasi seluruh 12 suite smoke test Godot (`test_step1.gd` s/d `test_step12.gd`) tetap passed 100%.

**Tech Stack:** Python 3 (Pillow), Godot 4.7 (GDScript, AnimatedSprite2D, SpriteFrames, Tween, CPUParticles2D, Control).

**Spec:** `docs/superpowers/specs/2026-11-14-modern-arcade-brawler-spec.md`

## Global Constraints
- Grid karakter: 48x48 pixel per frame, ukuran spritesheet 768x48 (16 frames).
- Kompatibilitas API: Nama animasi `idle`, `walk`, `jab`, `hook`, `upper`, `hit`, dan method statis `spark_anims()` wajib tetap ada dan berfungsi.
- Ukuran bar `hp_bar_fill.size.x` wajib tetap merefleksikan `280.0 * frac` agar pengujian `test_step8.gd` dan `test_step4.gd` tetap valid.
- Selector kartu hand (index 1-6) dan label float `Label.text == "-5"` wajib kompatibel dengan `test_step2.gd`, `test_step3.gd`, dan `test_step7.gd`.

---

### Task 1: Generate Fluid 16-Frame Modern Brawler Sprites & FX Sheets
**Files:**
- Modify: `tools/generate_chibi_brawler_assets.py`
- Output: `assets/sprites/chibi_player_sheet.png` (768x48)
- Output: `assets/sprites/chibi_enemy_sheet.png` (768x48)
- Output: `assets/sprites/chibi_boss_sheet.png` (768x48)
- Output: `assets/sprites/slash_arc_fx.png` (96x48: 2 frames)

- [ ] **Step 1: Update generator Python untuk menggambar 16 frames per karakter dan slash arc**
- [ ] **Step 2: Jalankan generator dan verifikasi file PNG terbuat**
- [ ] **Step 3: Validasi dimensi dan transparansi dengan asset_report.py**

---

### Task 2: Update CharSprites Loader for 16-Frame Animation
**Files:**
- Modify: `scripts/char_sprites.gd`
- Test: Jalankan `test_step8.gd` untuk verifikasi animasi player dan musuh

- [ ] **Step 1: Implementasikan mapping 16-frame ke `SpriteFrames` di `scripts/char_sprites.gd`**
- [ ] **Step 2: Pastikan `spark_anims()` dan `spark_frames()` tetap utuh**
- [ ] **Step 3: Jalankan `tests/test_step8.gd` untuk verifikasi animasi idle, walk, jab, hook, upper**

---

### Task 3: Combat FX (Slash Arc, Dust Puff, and Elastic Damage Pop)
**Files:**
- Modify: `scripts/player.gd` (munculkan slash arc saat pukul, dust puff saat dash/gerak)
- Modify: `scripts/dummy.gd` (upgrade `_spawn_float` dengan elastic scale pop + random drift)
- Test: Jalankan `tests/test_step1.gd` dan `tests/test_step7.gd`

- [ ] **Step 1: Tambahkan slash arc sprite effect di `scripts/player.gd`**
- [ ] **Step 2: Upgrade `_spawn_float` di `scripts/dummy.gd` dengan tween scale pop dan rotation drift**
- [ ] **Step 3: Jalankan `tests/test_step1.gd` dan `tests/test_step7.gd`**

---

### Task 4: Modern Arcade HUD Polish (Dual-Layer HP Bar & Dynamic Card Hand)
**Files:**
- Modify: `scripts/main.gd` (tambahkan delay red bar `hp_bar_delay`, combo counter punch tween)
- Modify: `scripts/hand_ui.gd` (efek card selection lift y = -14px, glow stylebox, dan smooth entry)
- Test: Jalankan `tests/test_step2.gd`, `tests/test_step3.gd`, `tests/test_step10.gd`

- [ ] **Step 1: Tambahkan `hp_bar_delay` di `scripts/main.gd` dengan tween lerp delay**
- [ ] **Step 2: Tambahkan combo pop scale tween di `_on_combo()` di `scripts/main.gd`**
- [ ] **Step 3: Implementasikan selection lift & visual glow di `scripts/hand_ui.gd`**
- [ ] **Step 4: Jalankan seluruh suite test Godot untuk konfirmasi tidak ada regresi**
