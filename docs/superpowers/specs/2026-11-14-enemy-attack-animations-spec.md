# Enemy Distinct Attack Animations & Slash FX Spec

## 1. Intent & Goal
Memberikan animasi dan efek visual serangan yang khas, fluid, dan terbaca (*telegraphed*) bagi musuh di `Beat 'Em Fold`:
1. **Striker / Punk**: Melakukan pukulan `jab` cepat dengan arc tebasan tajam kemerahan.
2. **Fury / Dasher**: Melakukan serangan `hook` melingkar dengan putaran badan dan arc tebasan melengkung lebar saat lunge maju.
3. **Brute & Boss**: Melakukan serangan `upper` / overhead slam bertenaga tinggi dengan kompresi jongkok saat telegraph dan lonjakan ke atas saat mengeksekusi serangan.
4. **Visual Attack Trail & Telegraph**:
   - Fase `windup` (telegraph): Sprite memutar frame ancang-ancang serangan sesuai tipenya (`jab`, `hook`, atau `upper`) dengan telegraph flash kuning-oranye.
   - Fase `strike`: Memunculkan `slash_arc_fx` musuh (warna crimson / oranye bahaya) tepat di arah pukulan musuh menghadap player.

## 2. Enemy Type to Attack Mapping
- `striker`, `punk` -> `attack_anim = "jab"` (2 frames 10..11)
- `dasher`, `fury` -> `attack_anim = "hook"` (2 frames 12..13)
- `brute`, `boss`, `slammer` -> `attack_anim = "upper"` (2 frames 14..15)

## 3. FX Integration
- `_spawn_enemy_slash(anim_name: String)`:
  - Mengambil tekstur `slash_arc_fx.png`.
  - Frame 0 (horizontal crescent) untuk `jab` & `hook`, Frame 1 (rising arc) untuk `upper`.
  - Warna modulate: `Color(1.0, 0.35, 0.3, 0.9)` (merah/oranye ancaman musuh).
  - Skala disesuaikan dengan `sprite_scale` (Boss & Brute mendapat arc lebih besar).
