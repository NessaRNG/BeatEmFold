# Handcrafted Fluid Brawler Sprites Spec

## 1. Intent & Goal
Mengganti sprite prosedural kaku dengan **Handcrafted Fluid Brawler Sprites** (animasi luwes asli digambar tangan frame-by-frame):
1. **Fluiditas Gerak**:
   - Pose idle bernapas lentur dan kuda-kuda dinamis.
   - Walk cycle melangkah natural dengan bobbing pinggul dan ayunan bahu.
   - Pukulan jab tajam berkecepatan tinggi dengan follow-through.
   - Hook dengan putaran torso dan bahu.
   - Uppercut dengan kompresi beban dan lonjakan vertikal.
2. **Karakter Handcrafted**:
   - **Player**: Brawler atletis heroik dengan celana street brawler dan sarung tinju.
   - **Enemy (Striker, Fury, Dasher, Slammer, Brute)**: Brawler mecha/cyber brawler perkasa dengan animasi ayunan tinju berat.
   - **Boss**: Cyber warlord robot brawler emas dengan aksen crimson bahaya.
3. **Format & Dimensi**:
   - Frame dimensi: **128×96 pixel** (lebar 128 untuk jangkauan pukulan panjang tanpa terpotong, tinggi 96 dengan dasar kaki di y=94).
   - 16 frame per karakter: 4 idle, 6 walk, 2 jab, 2 hook, 2 upper.
   - Sheet: 2048×96 pixel.
4. **Engine Positioning**:
   - Offset sprite: `Vector2(-12, -48)` agar kaki tepat menjejak garis lantai dan selaras dengan shadow ellipse.
