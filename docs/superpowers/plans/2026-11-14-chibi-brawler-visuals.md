# Chibi Brawler Characters & Polished Environment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menghasilkan sprite sheet karakter chibi brawler (Player & variasi Musuh) serta environment bata/trotoar polished sesuai referensi visual, memvalidasi aset dengan QA tool, dan mengintegrasikannya ke Godot 4.

**Architecture:** 
1. Buat skrip generator berbasis Python/Pillow `tools/generate_chibi_brawler_assets.py` untuk merender sprite sheet modular (48x48 per frame) dan background environment beresolusi integer.
2. Validasi kualitas piksel, palet warna, dan alpha dengan `asset_report.py`.
3. Buat module loader sprite `scripts/char_sprites.gd` untuk menyajikan `SpriteFrames` animasi (idle, walk, jab, hook, upper, hit) ke `Player` dan musuh.
4. Integrasikan background bata retro polished ke `scripts/stage_bg.gd` dan avatar portrait ke HUD `scripts/main.gd`.

**Tech Stack:** Python 3 (Pillow), Godot 4 (GDScript, AnimatedSprite2D, SpriteFrames, TextureRect).

**Spec:** `docs/superpowers/specs/2026-11-14-chibi-brawler-visuals-design.md`

## Global Constraints
- Grid karakter: 48x48 pixel per frame, outline 1-px tegas.
- Animasi player wajib mencakup: `idle` (2 frame), `walk` (2-4 frame), `jab`, `hook`, `upper`, `hit`.
- Gameplay lane tetap presisi (`Player.LANE_TOP = 430`, `Player.LANE_BOTTOM = 600`).
- Semua skrip verifikasi QA wajib lulus (exit code 0).

---

### Task 1: Generate Chibi Brawler Spritesheets & Polished Brick Environment
**Files:**
- Create: `tools/generate_chibi_brawler_assets.py`
- Output: `assets/sprites/chibi_player_sheet.png` (288x48)
- Output: `assets/sprites/chibi_enemy_sheet.png` (288x48)
- Output: `assets/sprites/chibi_boss_sheet.png` (288x48)
- Output: `assets/backgrounds/brick_alley_polished.png` (1280x720)
- Output: `assets/ui/portrait_player.png` (48x48)

- [ ] **Step 1: Tulis generator Python `tools/generate_chibi_brawler_assets.py`**
- [ ] **Step 2: Eksekusi generator dan verifikasi file PNG terbuat**
- [ ] **Step 3: Commit skrip generator dan file aset mentah**

---

### Task 2: Raster Quality Assurance & Asset Manifest
**Files:**
- Modify: `assets/backgrounds/asset-manifest.json`
- Test: Jalankan `asset_report.py` pada semua file sprite sheet dan background baru.

- [ ] **Step 1: Jalankan `asset_report.py` untuk menguji transparansi, dimensi, dan warna**
- [ ] **Step 2: Generate contact sheet preview untuk verifikasi tampilan**
- [ ] **Step 3: Update manifest aset**
- [ ] **Step 4: Commit hasil QA**

---

### Task 3: Godot Engine Integration (Player, Enemy, StageBg, and HUD)
**Files:**
- Create: `scripts/char_sprites.gd`
- Modify: `scripts/player.gd` (sambungkan ke SpriteFrames Chibi)
- Modify: `scripts/stage_bg.gd` (terapkan background bata/trotoar polished)
- Modify: `scripts/main.gd` (tambahkan avatar portrait retro di sebelah HP bar)
- Test: Verifikasi node tree dan eksekusi scene tanpa crash.

- [ ] **Step 1: Buat helper `scripts/char_sprites.gd` yang membagi sprite sheet menjadi SpriteFrames**
- [ ] **Step 2: Update `scripts/player.gd` dan prefab musuh agar menggunakan CharSprites**
- [ ] **Step 3: Update `scripts/stage_bg.gd` untuk menampilkan background bata/trotoar polished**
- [ ] **Step 4: Update HUD di `scripts/main.gd` dengan icon portrait chibi brawler**
- [ ] **Step 5: Commit integrasi engine**
