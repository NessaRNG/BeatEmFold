# Urban Arena & Parallax Environment Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menghasilkan aset grafis lingkungan (background, midground, ground lane, neon props) bergaya pixel art retro untuk arena pertarungan Beat 'Em Fold, memvalidasi kualitas raster (alpha, palette, dimensi), dan mengintegrasikannya ke engine Godot 4.

**Architecture:** Menggunakan pipeline generator/raster authoring berbasis Python Pillow untuk menghasilkan texture pixel art kohesif beresolusi integer (1280x720 layer stack). Menghasilkan aset layer: Skyline (latar jauh), Midground Wall (tembok gang), Ground Lane (aspal basah + trotoar pembatas lane y430-y600), dan Neon/Props. Memvalidasi dengan tool `asset_report.py` dan mengonfigurasi `stage_bg.gd` agar memuat tekstur baru secara mulus.

**Tech Stack:** Python 3 (Pillow), Godot 4 (GDScript, Texture2D, Sprite2D, Nearest Filtering), Shell / Git.

**Spec:** `docs/superpowers/specs/2026-11-14-urban-arena-assets-design.md`

## Global Constraints
- Resolusi target viewport: 1280x720.
- Gameplay lane vertikal wajib sesuai: `Player.LANE_TOP = 430.0` dan `Player.LANE_BOTTOM = 600.0`.
- Format file: PNG 32-bit RGBA (atau 24-bit RGB untuk sky layer penuh), filter texture Nearest di Godot (pixel art crisp).
- Skrip unit / validation report wajib exit 0 tanpa error.

---

### Task 1: Pipeline Script & Asset Generation Setup
**Files:**
- Create: `tools/generate_environment_assets.py`
- Test: Verifikasi eksekusi generator menghasilkan file-file PNG di `assets/backgrounds/`.

- [ ] **Step 1: Tulis generator script dengan Pillow untuk membuat layer lingkungan**
- [ ] **Step 2: Jalankan skrip generator untuk merender layer:**
  - `assets/backgrounds/alley_skyline.png` (1280x360)
  - `assets/backgrounds/alley_wall_midground.png` (1280x320)
  - `assets/backgrounds/alley_ground_lane.png` (1280x320)
  - `assets/backgrounds/alley_neon_props.png` (Props atlas)
- [ ] **Step 3: Commit aset mentah awal**

---

### Task 2: Quality Assurance & Manifest Verification
**Files:**
- Modify: `assets/backgrounds/` (hasil QA)
- Create: `assets/backgrounds/asset-manifest.json`
- Test: Jalankan `.agents/skills/create-game-assets/scripts/asset_report.py` pada semua file PNG.

- [ ] **Step 1: Jalankan asset_report.py untuk memvalidasi dimensi, color count, dan transparansi alpha**
- [ ] **Step 2: Buat contact preview sheet untuk inspeksi visual keselarasan palet**
- [ ] **Step 3: Catat manifest dan license/provenance record**
- [ ] **Step 4: Commit aset terverifikasi**

---

### Task 3: Integrasi Engine Godot & StageBg Refactor
**Files:**
- Modify: `scripts/stage_bg.gd`
- Modify: `scripts/main.gd` (sinkronisasi ground / lane jika diperlukan)
- Test: `tests/test_step3.gd` / verifikasi node tree dan rendering panggung.

- [ ] **Step 1: Update `scripts/stage_bg.gd` untuk me-render layer background texture baru pada Theme Alley**
- [ ] **Step 2: Pastikan z-index dan posisi ground lane presisi dengan bounding box Player (LANE_TOP 430, LANE_BOTTOM 600)**
- [ ] **Step 3: Uji integritas kode dan kompatibilitas scene**
- [ ] **Step 4: Commit integrasi engine**
