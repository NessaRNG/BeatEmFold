# Chibi Brawler Character Sprites & Polished Retro Environment Spec

## 1. Intent & Goal
Mengganti representasi visual karakter prosedural runtime dan background dengan set aset pixel art bertema **Retro 8-bit / Neo-NES Chibi Brawler** (proporsi ala Kunio-kun / River City Ransom, outline hitam tegas 1-px, mata ekspresif) serta background lingkungan perkotaan yang polished sesuai referensi visual:
- Dinding bata merah-oranye bertekstur kusam dengan plester semen bawah mengelupas dan pipa/railing metal.
- Trotoar blok paving abu-abu bersekat rapi dengan tanaman liar kecil dan curb aspal jalan.
- Avatar portrait kotak retro dan HP bar gaya arcade klasik.

## 2. Karakter Visual System (Grid 48x48)
- **Anatomi**: Chibi brawler proporsional (kepala bervolume, badan tegap, tangan tinju siap combo).
- **Outline**: 1-px solid black (`#000000`) melingkupi karakter.
- **Rambut**: Hitam shaggy bervolume (`#181822`, highlight `#2e2e42`).
- **Muka/Kulit**: Peachy skin tone (`#f4ab89`, bayangan `#cf7b5c`), mata putih dengan pupil biru/hitam tegas (`#38b6ff`, `#000000`).
- **Pakaian**: Kaos kutang putih (`#ffffff`, shade `#c5c8d6`), celana brawler gelap (`#252834`, shade `#171822`), sepatu hitam (`#0f0f14`).
- **Animasi**:
  1. `idle`: 2 frame nafas/bobbing.
  2. `walk`: 4 frame langkah brawler maju.
  3. `jab`: Frame pukulan lurus cepat.
  4. `hook`: Frame ayunan samping bertenaga.
  5. `upper`: Frame pukulan uppercut ke atas.
  6. `hit`: Frame reaksi terbentur/terpukul mundur.
- **Variasi Musuh (Palet Shift Kohesif)**:
  - Punk / Striker: Kaos hijau lumut (`#387346`), rambut punk/mohawk oranye (`#d9572b`).
  - Dasher: Topi cap merah (`#c92a2a`), jaket toska (`#2a9d8f`).
  - Boss: Jas setelan hitam rapi + kacamata hitam + kemeja putih.

## 3. Environment Polished System
1. **`assets/backgrounds/brick_alley_env.png`** (1280x720 layer):
   - Bagian atas: Tembok bata merah-oranye (`#a63d24`, `#bf4d28`, `#782512`) dengan mortar gelap.
   - Bagian tengah bawah dinding: Plester semen abu-krem (`#9c9483`, `#6e6657`) dengan tekstur retakan dan lubang aus.
   - Pipa/railing metal hitam-abu (`#353842`, highlight `#616675`) menancap di dinding.
   - Bagian trotoar (`y ~ 380 - 460`): Blok paving slab abu-abu persegi dengan tanaman liar rumput hijau (`#3fa34d`) tumbuh di sela sambungan.
   - Bagian jalan aspal (`y ~ 460 - 720`): Aspal gelap bertitik kerikil, batas lane pertempuran yang jelas.

4. **HUD Portrait Avatar (`assets/ui/portrait_brawler.png`)**:
   - Frame kotak 32x32 retro dengan latar biru/hitam menampilkan wajah close-up chibi brawler sesuai referensi.
