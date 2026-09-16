# Progress - Beat 'Em Fold

## Status: MVP Step 1 SELESAI (bisa jalan di Godot 4.7.2)

Sesi terakhir (2026-09-15):
- GDD awal dari user masuk
- Revisi kontrol ke L1+face select + Left Stick move
- Sepakat hand size 6, cash-in 2-5, buang yang dipilih saja
- Sepakat mix Balatro: Chips x Mult, Joker 12-15, Blind = Stage, Shop antar wave
- MVP Step 1 DONE: project Godot jalan. Player (gerak WASD/panah/stick, jab 3-hit 5/5/9, dash i-frame 0.25s, HP 100) + Dummy (HP 30, stagger/knockback, flash, KO+respawn 2s) + lane 430-600 + HUD + smoke test 7/7 PASS (tests/test_step1.gd).
- File: project.godot, icon.svg, scenes/main.tscn, scripts/player.gd, scripts/dummy.gd, scripts/main.gd
- MVP Step 2 DONE: kartu hidup. Deck starter 24 kartu custom (run Hearts + 3 pair + filler). Buka dengan deal 3, tiap jab KENA = draw 1 (sinyal Player.hit_landed), penuh = FIFO buang tertua. PokerEvaluator murni: PAIR/TWO PAIR/THREE/STRAIGHT (incl. wheel)/FLUSH/FULL HOUSE + bonus HIGH/FOUR/STRAIGHT FLUSH, return kartu pembentuk kombo. UI 6 slot bawah-tengah + indikator "PAIR READY!" + counter HAND/DECK. Test tests/test_step2.gd 21/21 PASS, test_step1 tetap 7/7, main scene headless 8s bersih.
- File baru: scripts/card_data.gd, scripts/deck.gd, scripts/poker_evaluator.gd, scripts/hand_manager.gd, scripts/hand_ui.gd (player.gd + main.gd diupdate)
- MVP Step 3 DONE: Cash-In hidup. CombatManager: full map AoE (Pair single-lock, Two Pair double, Three-Four cone 90°, Straight piercing line, Flush-FullHouse-SF 360°), damage (base+chips)xmult ala Balatro, suit dominan (Hearts heal, Spades x1.5, Clubs stun 0.6s, Diamonds shield 1.5s), i-frame 0.3s + magnet 40px, konsumsi yang dipakai saja. Seleksi: tahan Tab/L1 + 1-6/face toggle (RB cycle 5/6), E/B cash-in (kosong = auto best), R/RB discard, jab lock saat pilih. UI: highlight kuning + preview + combat text + flash. Test tests/test_step3.gd 25/25 PASS; regresi step1 7/7, step2 21/21; main scene headless 8s bersih.
- File baru: scripts/combat_manager.gd, tests/test_step3.gd. Pelajaran: enum antar-script tidak resolve (ganti int const); run -s gagal = fallback main scene = hang (pakai WaitForExit+kill).
- Bugfix UI (2026-09-15): kartu tidak tampil karena Control di bawah Node2D/CanvasLayer tidak dapat viewport rect (size 0, anchor runtuh off-screen). Solusi: semua UI pakai rect eksplisit dari viewport + ikut resize (_fit_ui, HandUI._layout). Terbukti via screenshot render.
- Cara main: buka folder di Godot 4.7 > jalankan main.tscn (F5). J=jab, K/Spasi=dash.

## MVP SELESAI (Step 4, 2026-09-15)
- [x] 4. 1 wave + shop dummy + 1 boss debuff sederhana:
  WaveManager (3 dummy -> clear -> shop -> boss), RunManager (4 Cash + 3 Buang/wave, uang, Planet), JokerManager (Bloodlust/Spade Drill/Parry), ShopUI (klik/1-6, E lanjut), Boss (HP 150, slam 15/3s telegraph, Straight sealed, HP bar), flow menang/kalah + T ulangi.
- File baru: scripts/run_manager.gd, scripts/joker_data.gd, scripts/joker_manager.gd, scripts/wave_manager.gd, scripts/shop_ui.gd, tests/test_step4.gd.
- Test tests/test_step4.gd 24/24 PASS; regresi step1-3 hijau; screenshot render terverifikasi (wave banner, 3 dummy, counter CASH/BUANG/$, PAIR READY!).

## Post-MVP 1: Striker AI (2026-09-15)
- Musuh mukul balik: chase/hold-strafe/windup-0.6s/strike-8, token max 1 penyerang, dodgeable, boss ikut chase pelan. Wave 1 = 3 striker.
- File: scripts/dummy.gd (+AI), scripts/wave_manager.gd (flag), tests/test_step5.gd 13/13 PASS; regresi step1-4 hijau; screenshot render OK.

## Post-MVP 2: Elite wave (2026-09-15)
- Run 3 wave: Fight -> Shop -> Elite (2 Brute HP 60/pukul 12/windup 0.7/bounty $8) -> Shop -> Boss. WaveManager config-driven, bounty via money_value.
- tests/test_step6.gd 15/15 PASS; step4 diupdate (boss wave 2); semua regresi hijau; screenshot WAVE 1/3 OK.

## Post-MVP 3: Varian + Feel (2026-09-15)
- Varian: Dasher (cepat+lunge), Fury (double-hit), Slammer (mini-slam). Wave: 2 striker+1 dasher -> Brute+Fury+Slammer -> Boss.
- Feel: hit-stop, screenshake Camera2D, float damage, burst partikel, jab-step.
- tests/test_step7.gd 16/16 PASS; step6 update komposisi; semua regresi hijau; screenshot OK.

## Post-MVP 4: Aset (2026-09-15)
- Kenney CC0: face kartu + back di slot, 10 SFX (punch/draw/select/cash/buy/shop/fail) via Sfx pool-8 + pitch acak.
- File: assets/cards (56) + assets/sfx (10), scripts/sfx.gd. Semua 7 suite hijau; screenshot kartu tampil.

## Post-MVP 5: Visual (2026-09-15)
- Queen + Fistbot animasi (walk/jab/hook/upper/hit/death), tint varian, shadow, hitspark, stage BG malam, HP bar player+boss.
- tests/test_step8.gd 18/18 PASS; semua 8 suite hijau; screenshot terverifikasi.

## Post-MVP 6: Back alley + preman (2026-09-16)
- ThugFactory (7 look + pose), player+musuh preman, AlleyBg (neon K.O. BAR flicker), panel HUD.
- test_step8 ditulis ulang 18/18 PASS; semua 8 suite hijau; screenshot gang terverifikasi.

## Post-MVP 7: UI (2026-09-16)
- UiTheme + font Kenney, slot berbingkai + hint 1-6, pip cash/buang, combat pop emas, shop ikut tema.
- Semua 8 suite hijau; screenshot UI terverifikasi.

## Post-MVP 8: Shop (2026-09-16)
- K.O. SHOP fullscreen horizontal (6 kartu kiri-ke-kanan, ikon, harga, lanjut hijau). Screenshot shop OK; semua 8 suite hijau.

## Post-MVP 9: Endless (2026-09-16)
- Wave scaling loop + seal rotasi + skor/best save. test_step9 15/15 PASS; semua 9 suite hijau; screenshot OK.

## Post-MVP 10: Menu + pause (2026-09-16)
- Main menu + pause overlay + PauseKeys + flow restart/menu. test_step10 15/15 PASS; semua 10 suite hijau; screenshot menu + gameplay OK.

## Post-MVP 11: Game over (2026-09-16)
- Layar K.O. + retry/menu (klik/T/M/ENTER). test_step10 20/20 PASS; semua 10 suite hijau; screenshot OK.

## Post-MVP 12: Tutorial (2026-09-16)
- 7 langkah terpandu + samsack + skip + lanjut wave 0. MULAI tanya YA/TIDAK (Y/N/ENTER), tanpa section terpisah.
- test_step11 12/12 PASS; semua 11 suite hijau; screenshot OK.

## Post-MVP 13: Keterbacaan (2026-09-16)
- Fighter besar + ring player + lane terang. Semua 11 suite hijau; screenshot OK.

## Post-MVP 14: Overlay bocor (2026-09-16)
- menu_dim ketinggalan nyala (game gelap total). Fix 1 baris + audit. Semua 11 suite hijau; screenshot terang OK.

## Post-MVP 15: Menu rapi (2026-09-16)
- Divider + versi, skema kontrol dihapus. Screenshot menu OK; step10/11 hijau.

## Post-MVP 16: Sine wave (2026-09-16)
- Slow-mo clear + walk-out/in + banner arrival + pause-safe. test_step12 10/10 PASS; semua 12 suite hijau.

## Post-MVP 17: Full keyboard (2026-09-16)
- KeyButton + hint + nav guard. Semua 12 suite hijau; screenshot menu OK.
- Retry = C, lanjut shop = L (E tetap bisa). Audit bentrok aman.
- Label embedded "(C)oba Lagi" (shortcut = huruf pertama; TIDAK jadi L).

## Post-MVP 18: Animasi UI (2026-09-16)
- UiAnim + stagger/pop/rise di menu/ask/shop/pause/over/tutorial/slot. Semua 12 suite hijau; screenshot OK.

## Post-MVP 21: Ikon shop (2026-09-16)
- Board Game Icons Kenney (pedang/spade/shield/stack/card±) di tile. Screenshot + step4/10/12 hijau.

## Post-MVP 23: Badge sealed (2026-09-16)
- Badge SEALED kanan-atas saat boss. Screenshot boss + semua 12 suite hijau.

## Post-MVP 22: Nol warning (2026-09-16)
- Bersihkan 12 warning GDScript (int-division, shadowed, unused). Headless 0 warning; perilaku identik, test hijau.

## Post-MVP 19: Balancing (2026-09-16)
- Lifesteal Hearts, Spades tier, Planet nerf, Dasher 0.40, harga +25%/loop. Semua 12 suite hijau.
- Label embedded "(C)oba Lagi" (shortcut = huruf pertama; TIDAK jadi L).
- Tombol lanjut shop jadi "(E)". Audit bentrok: M/K/E/T/L/Y/N/1-6 aman per konteks.
- Bugfix: guard viewport null di KeyButton (error saat reload scene).

## Next (MVP 2 minggu)
- [x] 1. Gerak + jab 3-hit + 1 dummy musuh (tanpa kartu)
- [x] 2. UI 6 slot + auto-draw on hit + PokerEvaluator (deteksi PAIR, TWO PAIR, THREE, STRAIGHT, FLUSH, FULL HOUSE)
- [x] 3. Cash-In Pair (single lock) + Flush (360 AoE) + i-frame 0.3s
- [ ] 4. 1 wave + shop dummy + 1 boss debuff sederhana

## Cara lanjutkan sesi baru
Buka AI dan prompt: "baca Documents/BeatEmFold/GDD.md, DECISIONS.md, PROGRESS.md, lanjutkan dari sana"
Lalu tiap selesai, minta AI update file PROGRESS.md ini.
