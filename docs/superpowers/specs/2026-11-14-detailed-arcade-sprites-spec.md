# Detailed Arcade Brawler (Neo-Geo/CPS2 Style) Sprites Spec

## 1. Intent & Goal
Mengganti representasi visual karakter dari chibi/SD (kepala besar 48x48) menjadi **Detailed Proportional Arcade Brawler** (standar Neo-Geo / Capcom CPS2 arcade seperti *Streets of Rage*, *Final Fight*, *Street Fighter III*):
1. **Grid & Dimensi**:
   - Frame karakter berukuran **64×64 pixel**.
   - 16 frame per karakter dalam sheet berukuran **1024×64** (idle 4 frame, walk 6 frame, jab 2 frame, hook 2 frame, upper 2 frame).
2. **Anatomi & Proporsi Manusiawi (Atletis & Berotot)**:
   - Proporsi 6–7 head ratio (bukan kepala besar chibi).
   - Kepala proporsional dengan rambut berlayer detail, mata tajam, dan rahang tegas.
   - Bahu lebar, dada dan deltoid berotot (terdefinisi dengan shading 3 nada).
   - Tangan dengan sarung tinju/wrap atau kepalan berotot.
   - Celana jeans/street brawler dengan lipatan kain realistis dan boot bertali tebal.
3. **Karakter & Varian Warna**:
   - **Player**: Kaos kutang putih/abu-abu, celana denim biru gelap, sarung tangan merah/hitam, rambut cokelat/hitam tajam.
   - **Enemy (Striker/Punk)**: Jaket kulit hijau/rompi denim, celana kargo gelap, rambut spike/punk mohawk.
   - **Boss**: Setelan jas mafia hitam proporsional, kemeja putih berdasi, kacamata hitam, rambut perak.

## 2. Integrasi Engine Godot 4
- `scripts/char_sprites.gd`:
  - `frame_w = 64`, `frame_h = 64`.
  - Sheet dipotong Rect2(i * 64, 0, 64, 64).
  - Sprite offset disesuaikan: `position = Vector2(0, -32)` agar pas dengan shadow dan feet origin.
- Shadow & Feet Alignment:
  - Posisi kaki sejajar tanah `y = 0` sehingga collider 34x52 di `scripts/player.gd` dan collision musuh tetap presisi di lane y-axis.
