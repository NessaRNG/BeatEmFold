# Beat 'Em Fold - GDD (sementara)

## 1. Ringkasan
- Genre: Beat 'em up / Action-Deckbuilder
- Platform: PC / Konsol (full gamepad)
- Engine: Godot 4, 2D, solo dev
- Inti: Beat em up tempo cepat + rakit poker hand real-time tanpa stop waktu
- USP: Pukul = draw. Harus agresif bahkan saat sekarat (Aggressive Healing).

## 2. Core Loop
1. Bertarung (tarik kartu): Basic Attack sukses = draw 1 kartu
2. Manajemen: Buang / pilih kartu real-time tanpa pause
3. Positioning: Giring musuh sesuai bentuk AoE yang mau dieksekusi
4. Eksekusi (Cash-In): Ubah kartu pilihan jadi jurus + auto-lock sesuai rank poker

## 3. Kontrol (keyboard only, revisi terakhir)
- WASD / Panah: Gerak
- J / Klik kiri: Basic Attack / auto-draw
- K / Spasi: Dash (sekali pencet) + i-frame
- Tahan Tab: Mode Pilih Kartu (waktu tetap jalan, masih bisa gerak)
  - 1-6 = toggle slot 1-6
- Lepas Tab + tekan E (Enter juga bisa): Cash-In kartu yang dipilih
- Tap E tanpa pilih manual: Cash-In hand terbaik otomatis (auto-suggest)
- R: Discard cepat (terpilih / 1 tertua)
- ESC/P: Pause • T: ulangi • M: menu • 1-6/E: shop • Y/N: tanya tutorial • C: coba lagi (game over) • L: lanjut (pause/shop)

Hand: 6 slot di bawah tengah layar. Cash-In: 2-5 kartu. Hanya kartu dipilih yang kebuang, sisa stay.

## 4. Combat
### 4A. Basic Attack (fixed, bukan random)
- Animasi selalu fixed: jab-jab-finisher. Nilai kartu hanya nambah angka + stagger, TIDAK ganti animasi.
- As = crit + guard break, bukan launcher random.

### 4B. Eksekusi & Lock-On (by rank)
- Pair / Two Pair: lock single / double di depan
- Three of a Kind: cone 90 derajat depan
- Straight: piercing garis lurus
- Flush / Full House: 360 derajat sekeliling
- Royal Flush: screen nuke sinematik (long-term, kemungkinan hampir 0 di awal - butuh Joker/support)

Cash-In konsumsi kartu dipilih saja. Kasih i-frame 0.3 detik + magnet musuh kecil biar berasa ultimate.

### 4C. Bertahan & Hukuman
- Dash di tombol, ada i-frame singkat
- Kena hit: hilang HP saja, kartu di tangan TIDAK reset/hancur
- Musuh striker: dekati -> windup kuning 0.6s -> pukul 8. Max 1 penyerang (token), sisanya tahan jarak + strafe. Boss ikut ngejar pelan (60).

## 5. Suit System (saat Cash-In)
- Hearts: Heal / lifesteal (skala dengan rank kombo)
- Spades: damage mentah + armor pierce
- Clubs: stun / knockback masif
- Diamonds: shield sementara / gandakan drop uang

## 6. Sistem Balatro (diadopsi sebagian)
- Damage = Chips x Mult (bukan flat)
- Joker = equipment pasif, target 12-15 buah dulu (contoh: +Mult saat HP rendah, Spade +Chips, retrigger Pair, discard = shield)
- Hand/Discard per wave: misal 4 Hand + 3 Discard per wave. Jab gratis damage kecil buat stall.
- Struktur run: Fight (Small Blind) -> Shop -> Elite (Large Blind) -> Shop -> Boss (debuff ala Boss Blind, cth: Hati di-debuff, Straight disabled)
- Shop: beli Joker / upgrade level hand (Planet) / tambah-hapus kartu. Deck run: 20-25 kartu build sendiri, bukan 52 random.

## 7. UI
- HP di kiri/kanan atas standar
- 6 slot kartu bawah tengah, transparan tapi jelas
- Indikator: "PAIR READY!", "FLUSH READY!" di atas kartu saat seleksi valid

## Open Question
- Royal Flush terlalu langka di sistem FIFO real-time -> butuh pity/Joker khusus atau biarkan sebagai jackpot?
