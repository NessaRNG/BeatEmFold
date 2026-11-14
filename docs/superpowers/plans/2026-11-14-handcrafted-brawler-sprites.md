# Handcrafted Fluid Brawler Sprites Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mengganti total sprite karakter kaku dengan handcrafted brawler spritesheet (2048x96, frame 128x96) yang digambar tangan frame-by-frame, dan memastikan seluruh 12 suite smoke test Godot lulus 100%.

**Architecture:**
1. Download dan splice frame brawler luwes (Player, Enemy, Boss) ke `assets/sprites/handcrafted_player_sheet.png`, `assets/sprites/handcrafted_enemy_sheet.png`, `assets/sprites/handcrafted_boss_sheet.png`.
2. Update `scripts/char_sprites.gd` untuk frame 128x96.
3. Sesuaikan offset sprite di `scripts/player.gd` dan `scripts/dummy.gd` agar kaki menjejak tanah secara natural.
4. Scan asset di Godot headless, jalankan 12 suite test, dan commit.

**Tech Stack:** Python Pillow, Godot 4.7 GDScript, AnimatedSprite2D.

**Spec:** `docs/superpowers/specs/2026-11-14-handcrafted-brawler-sprites-spec.md`

## Global Constraints
- Sheet 2048x96, 16 frames @ 128x96.
- Nama animasi: `idle`, `walk`, `jab`, `hook`, `upper`.
- Kaki karakter harus sejajar di y = 0.

---

### Task 1: Update CharSprites.gd and Character Positioning
**Files:**
- Modify: `scripts/char_sprites.gd`
- Modify: `scripts/player.gd`
- Modify: `scripts/dummy.gd`
- Test: Jalankan 12 suite smoke test Godot

- [ ] **Step 1: Update `scripts/char_sprites.gd` ke frame 128x96 dan file `handcrafted_*_sheet.png`**
- [ ] **Step 2: Update offset sprite di `scripts/player.gd` dan `scripts/dummy.gd`**
- [ ] **Step 3: Jalankan Godot editor scan untuk import aset baru**
- [ ] **Step 4: Jalankan 12 smoke test dan pastikan PASS 100%**
- [ ] **Step 5: Commit perubahan**
