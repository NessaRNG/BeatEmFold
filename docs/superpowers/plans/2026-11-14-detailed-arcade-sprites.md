# Detailed Arcade Brawler Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menghasilkan spritesheet karakter detail proporsional 64x64 (1024x64: Player, Enemy, Boss) ala arcade Neo-Geo/CPS2 dan mengintegrasikannya ke engine Godot 4 tanpa merusak gameplay lane collision.

**Architecture:**
1. Upgrade skrip generator Python `tools/generate_chibi_brawler_assets.py` menjadi `tools/generate_detailed_brawler_assets.py` yang menggambar karakter proporsional atletis (64x64 per frame, 16 frames).
2. Generate spritesheet: `assets/sprites/detailed_player_sheet.png`, `assets/sprites/detailed_enemy_sheet.png`, `assets/sprites/detailed_boss_sheet.png`.
3. Update `scripts/char_sprites.gd` untuk me-load spritesheet 64x64 dengan grid region 64x64.
4. Sesuaikan scale dan posisi sprite di `scripts/player.gd` dan `scripts/dummy.gd`.
5. Verifikasi semua 12 test suite Godot (`test_step1.gd` s/d `test_step12.gd`) lulus 100%.

**Tech Stack:** Python 3 (Pillow), Godot 4.7 (GDScript, AnimatedSprite2D, SpriteFrames).

**Spec:** `docs/superpowers/specs/2026-11-14-detailed-arcade-sprites-spec.md`

## Global Constraints
- Grid karakter: 64x64 pixel per frame (1024x64 sheet).
- Semua nama animasi tetap konsisten: `idle`, `walk`, `jab`, `hook`, `upper`, `hit`.
- Origin kaki karakter tepat di dasar sprite sehingga alignment lantai jalanan tetap presisi.

---

### Task 1: Generate 64x64 Detailed Proportional Spritesheets
**Files:**
- Create: `tools/generate_detailed_brawler_assets.py`
- Output: `assets/sprites/detailed_player_sheet.png` (1024x64)
- Output: `assets/sprites/detailed_enemy_sheet.png` (1024x64)
- Output: `assets/sprites/detailed_boss_sheet.png` (1024x64)

- [ ] **Step 1: Tulis generator Python untuk anatomi atletis proporsional 64x64 (16 frames)**
- [ ] **Step 2: Jalankan generator dan verifikasi ketiga sheet berdimensi 1024x64**
- [ ] **Step 3: Uji transparansi dengan asset_report.py**

---

### Task 2: Engine Integration for 64x64 Grid
**Files:**
- Modify: `scripts/char_sprites.gd` (ubah frame size ke 64x64 dan arahkan ke detailed sheet)
- Modify: `scripts/player.gd` (posisi dan scale sprite)
- Modify: `scripts/dummy.gd` (posisi dan scale sprite musuh)
- Test: Jalankan 12 suite smoke test Godot (`test_step1.gd` s/d `test_step12.gd`)

- [ ] **Step 1: Update `scripts/char_sprites.gd` untuk frame 64x64**
- [ ] **Step 2: Update sprite positioning di `scripts/player.gd` dan `scripts/dummy.gd`**
- [ ] **Step 3: Lakukan Godot scan headless `--headless --editor --quit` untuk import PNG**
- [ ] **Step 4: Jalankan seluruh 12 suite test Godot dan pastikan lulus 100%**
- [ ] **Step 5: Commit perubahan**
