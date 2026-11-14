# Modern Arcade Brawler Visuals & Fluid UI Spec

## 1. Intent & Goal
Merombak visual game *Beat 'Em Fold* dari presentasi kaku ("seperti slide PPT") menjadi **Modern Arcade Brawler (*Streets of Rage 4* / *TMNT: Shredder's Revenge*)**:
1. Karakter memiliki animasi multi-frame yang fluid dan dinamis (idle 4-frame, run 6-frame, combo jab-hook-upper masing-masing punya fase windup, snap, dan slash trail).
2. Efek visual combat tebal: Slash arc lengkungan angin pukulan semi-transparan, partikel debu pijakan (*dust puff*) saat lari dan dash, serta hitspark yang punchy.
3. UI juice arcade:
   - Dual-layer HP bar dengan bar merah/putih *delay lerp* yang menyusut perlahan setelah damage diterima.
   - Damage float numbers elastis (*pop-in scale bounce* dengan random spread arc, bukan sekadar naik lurus).
   - Card Hand slot kartu poker di HUD dengan transisi masuk melayang (*slide-up bounce*), efek seleksi terangkat (*raise & glow*), dan feedback combo counter pop.

## 2. Character Animation System (Grid 48x48, 768x48 Sheet)
- **Idle (Frames 0-3)**: 4 frames nafas dinamis, bahu naik-turun, lutut relaks, dan rambut bergoyang subtle.
- **Walk / Run (Frames 4-9)**: 6 frames langkah brawler bertenaga, ayunan tangan bergantian, pergelangan kaki mengangkat natural, dan bobbing tubuh.
- **Jab (Frames 10-11)**: Frame ancang-ancang cepat -> ekstensi tinju lurus dengan efek garis kecepatan (speedlines).
- **Hook (Frames 12-13)**: Frame putaran pinggang -> ayunan tinju samping melengkung lebar bertenaga.
- **Upper (Frames 14-15)**: Frame kompresi jongkok -> lonjakan uppercut vertikal ke atas.
- **Hit (Frame 16 or flinch variant)**: Frame reaksi benturan dengan kepala menoleh ke belakang dan tubuh condong.
- **Penerapan Multi-Karakter**:
  - Player: Kaos kutang putih, celana brawler gelap, rambut hitam shaggy, mata biru.
  - Enemy (Striker/Punk): Kaos hijau lumut, rambut mohawk oranye/merah, mata merah.
  - Boss: Jas mafia hitam rapi, kacamata hitam, rambut perak.

## 3. Combat FX System
- **Slash / Swing Arc (`PunchSlashFX`)**: Node/sprite yang muncul otomatis saat player atau musuh melancarkan `jab`, `hook`, atau `upper`, mengikuti arah hadap (`facing`), lalu memudar cepat (0.12s).
- **Dust Puff FX (`DustPuff`)**: Partikel debu pijakan halus saat player melakukan dash atau melangkah cepat.
- **Elastic Pop Damage Text**: Floating numbers yang muncul saat `take_damage()` diberi pivot tengah, scale-up elastis (`Vector2(1.6, 1.6) -> Vector2.ONE`), sedikit rotasi acak (-0.15 s/d 0.15 rad), dan melayang melengkung.

## 4. Arcade UI Polish System
- **Dual-Layer Health Bar**:
  - Layer 1: Background gelap (`Color(0, 0, 0, 0.8)`).
  - Layer 2: Delay bar merah/oranye (`Color("ff5555")`) yang menyusut tertunda via tween cubic ease-out.
  - Layer 3: Fill bar hijau utama (`Color("55d66b")`) yang berubah instan mengikuti fraksi HP.
- **Card Hand Interaction Polish (`HandUI`)**:
  - Kartu baru yang di-deal/draw meluncur masuk dari bawah dengan tween cubic bounce.
  - Kartu yang dipilih (selected) naik ke atas -14px dengan border neon bercahaya tebal dan scale pop 1.05.
- **Combo Counter HUD**:
  - Label combo membesar (*punch scale 1.3*) setiap kali stage jab bertambah.
