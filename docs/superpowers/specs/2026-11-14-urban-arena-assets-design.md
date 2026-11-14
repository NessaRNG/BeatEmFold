# Beat 'Em Fold: Urban Arena & Parallax Environment Asset Spec

## 1. Intent & Goal
Menggantikan elemen background prosedural / ColorRect primitif pada stage arena pertarungan dengan set aset visual lingkungan pixel art yang proper, kohesif, dan siap pakai di Godot 4 (resolusi target 1280x720, viewport integer scaling).

## 2. Visual Direction & Style Guide
- **Tema**: *Neon Dark Alley & Urban Street Beat 'Em Up* (retro arcade 90s ala Streets of Rage / Final Fight berpadu estetika cyberpunk noir).
- **Format**: Pixel art 2D presisi, crisp nearest-neighbor filtering, tanpa mipmap blur.
- **Palette Roles**:
  - Sky / Background Jauh: Deep night navy/purple (`#0d0b18`, `#19142b`, `#281e42`).
  - Skyline Silhouettes & Neon: Cyan (`#00f0ff`), Magenta (`#ff007f`), Amber/Gold (`#ffb703`).
  - Midground Architecture: Dark brick, metal pipes, industrial grey/brown (`#242636`, `#3a3d52`, `#594a3e`).
  - Gameplay Lane (Foreground/Ground): Wet asphalt, sidewalk curb, puddle reflections (`#181824`, `#222433`, `#2f3247`), garis batas visual yang jelas agar tidak bentrok dengan karakter dan bayangan (shadow).

## 3. Asset Deliverables
1. **`assets/backgrounds/alley_skyline.png`** (1280x360)
   - Langit malam gradien pixel dengan siluet gedung bertingkat, antena, dan aksen lampu jendela/neon redup.
2. **`assets/backgrounds/alley_wall_midground.png`** (1280x300)
   - Tembok bata gang perkotaan, pipa ventilasi, tangga darurat (fire escape), dan poster robek.
3. **`assets/backgrounds/alley_neon_signs.png`** (Sprite sheet / atlas props)
   - Neon sign "K.O. BAR", "HOTEL", "LUCKY 7" / Card suit symbols (Hearts, Spades, Clubs, Diamonds) glowing street art.
4. **`assets/backgrounds/alley_ground_lane.png`** (1280x280)
   - Aspal basah dengan trotoar curb di atas (`y ~ 430`), refleksi neon halus di genangan air, dan batas bawah lane gameplay (`y ~ 600-630`).
5. **`assets/backgrounds/alley_props.png`** (Dumpster metal, street lamp post dengan cone light transparan, tumpukan kardus).

## 4. Integration & Engine Requirements
- Disimpan di folder `assets/backgrounds/`.
- File `.import` Godot 4 dikonfigurasi dengan filter `Nearest` (Lossless, no mipmaps, sRGB).
- Terintegrasi dengan modul `StageBg` (`scripts/stage_bg.gd` / `scripts/main.gd`) mempertahankan kompatibilitas layer gameplay (`Player.LANE_TOP = 430`, `Player.LANE_BOTTOM = 600`).
- Validasi visual dengan `asset_report.py` dan contact preview sheet.
