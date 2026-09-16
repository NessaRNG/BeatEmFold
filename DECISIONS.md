# Keputusan Desain - Beat 'Em Fold

Tanggal update: 2026-09-15

## Final
1. Taktis, bukan full arcade refleks. Real-time jalan terus, tanpa time-stop.
2. 2D side-view, 1 lane dulu (musuh dari kiri-kanan). Max 1v2 di layar untuk MVP.
3. Solo dev, Godot 4. Struktur: CardData (Resource) -> Deck -> HandManager -> CombatManager (PlayerTurn/Resolve versi real-time) -> PokerEvaluator (fungsi murni).
4. Hand size 6, Cash-In 2-5 kartu pilihan. Hanya yang dipilih yang kebuang.
5. Seleksi: tahan Tab + angka 1-6 toggle slot. Gerak tetap jalan. Tap Cash-In = auto best-hand.
6. Basic attack animasi fixed. Kartu = angka, bukan penentu animasi.
7. Dash = K/Spasi, bukan double-tap arah. Gerak = WASD/Panah.
8. Punishment: kena hit hilang HP saja, kartu aman.
9. Deck run 20-25 kartu (custom build), bukan 52 full random.
10. Damage pakai Chips x Mult ala Balatro.
11. Joker 12-15 dulu sebagai resource pasif (on_play_hand, on_discard, on_hit).
12. Map: buang Room Synthesis CoM, ganti linear node-based (Fight-Shop-Elite-Boss).

## Cash-In MVP (Step 3, 2026-09-15)
13. Cash-In 2-5 kartu; seleksi <2 = auto best-hand. Whiff (<2 kartu di tangan) tidak makan kartu; miss (tanpa target) tetap consume.
14. Damage = (base_chips_hand + jumlah chips kartu scoring) x mult. Base: High 5x1, Pair 10x2, Two Pair 20x2, Three 30x3, Straight 30x4, Flush 35x4, Full House 40x4, Four 60x7, Straight Flush 100x8.
15. Suit dominan kartu scoring (seri = kartu pertama): Hearts heal=mult, Spades dmg x1.5, Clubs stagger 0.6s + heavy, Diamonds shield 1.5s.
16. AoE: Pair/single-lock depan, Two Pair/double depan, Three-Four/cone 90°, Straight/garis piercing, Flush-FullHouse-SF/360°. Tiap cash-in: i-frame 0.3s + magnet 40px.
17. Seleksi by identitas kartu (tahan FIFO/draw): tahan Tab + 1-6 toggle, E/Enter cash-in, R buang. Cash-in min-2 else auto, jab lock saat pilih, gerak + dash tetap jalan.
18. Teknis: suit/hand-type pakai int const (bukan enum) — enum antar-script tidak resolve di build ini. Test -s pakai preload + pola WaitForExit (fallback main scene bikin hang bila script gagal load).

## Wave/Shop/Boss MVP (Step 4, 2026-09-15)
19. Run: Wave 1 (3 dummy HP 30) -> Shop -> Wave 2 Boss (HP 150). Jatah per wave: 4 Cash-In + 3 Discard; jab unlimited (stall). Kill $4, boss $20.
20. Shop: 3 Joker (Bloodlust $6: +2 Mult saat HP<50%; Spade Drill $6: spades +30 Chips; Parry $5: discard = shield 1s) + Planet $5 (+10 Chips +1 Mult/level utk best-hand saat itu) + tambah kartu acak $3 + hapus terlemah $3. Klik / tombol 1-6, E lanjut.
21. Boss Blind: Straight di-seal (jadi 5+chips flat, tanpa suit bonus). Boss slam 15 dmg tiap 3s (telegraph kuning 0.5s). Kalah/menang: T = ulangi.

## Post-MVP 1: Striker AI (2026-09-15)
22. Musuh wave 1 aktif mukul: chase 120 -> hold ring 220 (strafe) -> windup 0.6s kuning -> strike 8 (range 62+15). Token max 1 penyerang, mati/windup-selesai melepas token. Kaki diam saat windup = bisa di-dodge (dash/jalan). Boss: chase 60 + slam seperti biasa.

## Post-MVP 2: Elite wave (2026-09-15)
23. Run 3 wave config-driven: Fight (3 striker) -> Shop -> Elite (2 Brute: HP 60, pukul 12, windup 0.7, bounty $8, badan besar merah tua) -> Shop -> Boss. Bounty per-musuh via money_value (striker $4, brute $8, boss $20).

## Post-MVP 3: Varian + Feel (2026-09-15)
24. Varian: Dasher (HP 20, speed 200, windup 0.35, dmg 6, lunge 50 — anti-jalan-kaki, mesti dash), Fury (HP 40, double-hit 6x2 gap 0.25, token dipegang selama dua hit), Slammer (HP 70, mini-slam 10/110m/2.5s, tanpa melee, nempel sampai slam_range). Wave: 2 striker+1 dasher -> Brute+Fury+Slammer -> Boss.
25. Feel: hit-stop (jab 0.03, kill 0.1, cash-in 0.09, kena-hit 0.06; anti-stack), screenshake trauma (jab 0.12, kill 0.25, cash 0.5, kena 0.6) via Camera2D, float damage number, burst partikel CPU, jab-step +10. SFX ditunda (tanpa aset audio).

## Post-MVP 4: Aset Kenney CC0 (2026-09-15)
26. Kartu pakai Playing Cards Pack (face 64px + back utk slot kosong, filter nearest). SFX: Impact (punch), Interface (klik/confirm/error/open), Casino (slide/place/shuffle/chips). Fighter tetap geometris (kohesif + readable). Lisensi: assets/LICENSE-kenney.txt. Tanpa BGM dulu.

## Post-MVP 5: Visual pass (2026-09-15)
27. Karakter: Queen (player: idle/walk/jab-hook-upper/hit/death) + Fistbot (musuh: idle/walk/jab/hit) via AnimatedSprite2D + CharSprites factory; tint per varian, shadow, flip hadap. Hitspark sprite tiap kena. Background stage_bg (redup 0.62) + fg strip. HUD: HP bar player (hijau-kuning-merah) + bar boss. Kredit: assets/LICENSE-oga.txt (Chewbatrij, CC0). [Diganti Post-MVP 6.]

## Post-MVP 6: Back alley + preman (2026-09-16)
28. Art direction final: gang malam + preman pixel prosedural (kohesif penuh). Aset karakter CC0 yg pas tidak ada — Pixel Puncher ditolak (gaya kartun-vektor + karakter mirip Sonic, clash dgn kartu pixel). ThugFactory: 7 look (player bandana+rante emas, hoodie, cap, mohawk, vest+shades, leather, suit+rante+shades boss), pose idle/walk1-2/jab/hook/upper (player), mati = roboh (rotasi). AlleyBg seed-7: langit gradien, gedung+jendela, bulan, tembok bata, dinding samping, neon K.O. BAR flicker, poster, pipa, dumpster, lampu+cone, aspal basah + pantulan. HUD: panel gelap top-left.

## Post-MVP 7: UI cakep (2026-09-16)
29. Tema neon: font Kenney Pixel (judul) + Mini (body), CC0. Button dark + border neon (hover pink, pressed kuning, disabled abu). Slot = Panel berbingkai + hint angka 1-6. Pip hijau (cash) + biru (buang). Combat text emas + pop scale + outline. Semua label HUD di ui_root (1 tema). Shop otomatis ikut tema.

## Post-MVP 8: Shop cakep (2026-09-16)
30. K.O. SHOP fullscreen: 6 kartu sejajar kiri-ke-kanan (ikon monogram, nama, deskripsi 2-baris, harga hijau), uang kanan-atas, LANJUT hijau bawah-tengah. Klik/1-6, E lanjut.

## Post-MVP 9: Endless (2026-09-16)
31. Run tanpa menang: fight/elite/boss berulang + shop tiap clear. Scaling per loop: HP +40% (boss +50%), dmg +1 (boss slam +2), musuh +1-2 (cap 5/4), bounty +, penyerang 1->3. Seal boss rotasi STRAIGHT/FLUSH/PAIR. Skor = bounty x3 + 25/wave; best tersimpan user://.

## Post-MVP 10: Menu + pause (2026-09-16)
32. Main menu (judul neon, TERBAIK, MULAI/KELUAR, kontrol, ENTER mulai; HUD sembunyi). Pause fisik (tree.paused): ESC/P/Start toggle, overlay + LANJUTKAN/MENU, T ulangi, M menu. PauseKeys node ALWAYS; T/M/Enter dijaga state. T-restart skip menu (static flag).

## Post-MVP 11: Layar game over (2026-09-16)
33. K.O.! + SKOR/TERBAIK + COBA LAGI (T, hijau) + MENU UTAMA (M). ENTER juga retry. M boleh dari pause/game over (tidak di fight).

## Post-MVP 15: Menu rapi (2026-09-16)
39. Skema kontrol dihapus dari menu (tutorial yang ajarkan). Komposisi: judul + divider neon + tagline + TERBAIK + MULAI + KELUAR + tag versi + hint ENTER.

## Post-MVP 12: Tutorial (2026-09-16)
34. 7 langkah di arena aman (samsack respawn): gerak >120px, 3 jab kena, 5 kartu, pilih 2, cash-in, dash, bunuh. Jatah 99 selama tutorial, L lewati, selesai -> wave 0. MULAI selalu tanya dulu: YA (Y) tutorial / LANGSUNG MAIN (N/ENTER) — tanpa section terpisah.

## Post-MVP 16: Sine wave (2026-09-16)
35. Mob terakhir -> slow-mo 0.25 (1s) + "WAVE CLEAR!" + player jalan keluar kanan -> shop. Shop tutup -> spawn + player jalan masuk dari kiri (AI mati + invuln, nyala saat tiba) + banner. Pause-safe (shop nunggu unpause).

## Post-MVP 17: Full keyboard (2026-09-16)
46. KeyButton: tiap tombol punya shortcut 1 huruf + hint "(M)" di label. M/K menu, Y/N ask, L/M pause, T/M game over, 1-6/E shop (sudah ada). Tanpa mouse bisa main penuh. Guard anti double-aktivasi se-frame (tombol + PauseKeys).

## Post-MVP 21: Ikon shop (2026-09-16)
47. Board Game Icons Kenney CC0 di tile item shop. assets/icons/.

## Post-MVP 19: Balancing pass 1 (2026-09-16, diukur via tests/balance_report.gd)
41. Hearts = lifesteal damage/8 (pair ~5, flush jackpot ~38) — Aggressive Healing jadi nyata.
42. Spades tier: 2 spades x1.25, 3+ x1.5 (sebelumnya tie-break selalu x1.5).
43. Planet: +8 Chips/lv, +1 Mult tiap 2 lv (sebelumnya +10/+1 tiap lv — meledak: Lv2 pair 264).
44. Dasher windup 0.35 -> 0.40. Harga shop +25%/loop.

## Post-MVP 20: Keyboard only (2026-09-16)
45. Gamepad dilepas total (input map bersih, kode RB/LB/joy dibuang). Kontrol: WASD/Panah, J/klik, K/Spasi, Tab+1-6, E, R, ESC/P/T/M/Y/N/C/L. GDD §3 ditulis ulang.

## Post-MVP 18: Animasi UI (2026-09-16)
48. UiAnim: fade/pop/rise + stagger delay. Menu entrance stagger, ask pop, shop kartu stagger (buka saja), pause pop (pause-proof), game over slam, tutorial rise + punch tiap langkah, slot kartu pop saat draw baru.

## Post-MVP 23: Badge sealed (2026-09-16)
49. Badge merah kanan-atas "SEALED: <kombo>" saat boss seal aktif, sembunyi jika tidak. Nama seal publik di WaveManager.

## Post-MVP 13: Keterbacaan (2026-09-16)
36. Fighter dibesar (player 1.35x, musuh 1.15x varian), lane diterangi (alpha 0.88->0.55), ring cyan di bawah player. Build lama di editor ("WAVE 1/3") = sesi basi, restart editor.
37. Arena: musuh diklem X 40-1240 seperti player (kabur kena knockback/chase).

## Post-MVP 14: Overlay bocor (2026-09-16)
38. menu_dim (82% gelap) ketinggalan nyala saat MULAI (flow ask tidak sembunyikan) -> seluruh game gelap. Fix: _press_mulai sembunyikan semua node menu. Audit: pause/shop/over buka-tutup sendiri, aman.

## Ditolak / Ditunda
- Double-tap dash: ditolak, tidak responsif saat dikepung.
- Basic attack random (2-5=jab, J/Q/K=heavy): ditolak, hancurkan game feel.
- Full 52 kartu random: ditolak untuk MVP.
- 150 Joker ala Balatro: ditunda, mulai 12-15.
- Screen-nuke Royal Flush sinematik: ditunda sampai prototype fun.
