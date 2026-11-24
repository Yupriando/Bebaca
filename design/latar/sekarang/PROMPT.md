# Bahan generate latar Bebaca

File di folder ini adalah latar yang dipakai aplikasi sekarang. Tombol dan kartunya tidak ikut, sementara ukuran dan namanya sudah final. Unggah sebagai gambar referensi (image-to-image), pakai prompt di bawah, lalu simpan hasilnya ke `../hasil/` dengan nama yang sama.

`latar_utama.png` dan `latar_dongeng.png` saat ini sama persis. Pakai prompt yang berbeda supaya hasilnya berbeda.

## Pengaturan

- Mode: image-to-image atau gambar referensi. Gambar referensi menentukan susunan (letak bukit, jalan, pohon), sedangkan prompt menentukan gaya. Arah slidernya beda di tiap aplikasi:
  - Adobe Firefly, Referensi struktur (Structure reference): Strength sekitar 60–80. Makin ke kanan, makin mirip susunan aslinya.
  - Leonardo, Image Guidance lalu Image to Image: mulai dari strength 0,35 untuk latar dan 0,50 untuk peta. Makin besar, makin mirip gambar asli, termasuk gaya datarnya. Kalau hasilnya masih datar, turunkan 0,05. Kalau susunan atau jalan peta bergeser, naikkan 0,05. Kalau opsi Image to Image tidak muncul untuk model yang dipilih, pakai Content Reference: Mid untuk latar, High untuk peta.
  - Stable Diffusion, tab img2img: Denoising strength sekitar 0,55–0,7. Di sini makin besar justru makin berubah.
  - ChatGPT atau Gemini: tidak ada slider. Unggah gambar, tempel prompt, lalu tambahkan "keep the exact same layout and composition".
- Rasio hasil harus sama dengan file referensi, supaya susunannya tidak tertarik atau bergeser. Ukuran hasil boleh lebih kecil, nanti kusesuaikan ke ukuran akhir. Kalau aplikasinya bisa mengatur ukuran sendiri (custom), pakai angka ini:
  - Latar (2560 × 1440): 1536 × 864
  - Peta Unit 1, 2, 4, 6 (1640 × 1914): 1040 × 1216
  - Peta Unit 3 (1640 × 1706): 1104 × 1152
  - Peta Unit 5, 7, 8 (1640 × 2122): 960 × 1240
  - Peta Unit 9 (1640 × 1290): 1216 × 960

  Kalau ukuran custom tidak tersedia, kabari aku supaya kubuatkan versi peta dengan rasio standar.
- Peta: jalan harus tetap di posisi yang sama, karena titik pelajaran diletakkan aplikasi di atas jalan itu. Kalau jalannya bergeser, kabari aku, nanti jalan buatan aplikasi tetap kupasang di atasnya.
- Pakai gaya yang sama untuk semua file. Tempel kalimat gaya di bawah ke setiap prompt.
- Pastikan generator yang dipakai mengizinkan pemakaian komersial, karena aplikasinya dijual.

## Kalimat gaya (tempel di akhir setiap prompt)

```
children's picture book illustration, hand-painted gouache and colored pencil texture, visible paper grain, slightly imperfect hand-drawn lines, limited soft palette, matte flat colors, no glossy gradients, no glow, no sparkles, no text, no letters, no numbers, no logos
```

## Prompt per file

**latar_utama.png**
```
calm bright morning sky over a gentle Indonesian countryside, a few hand-drawn clouds near the top edge and on the right, low rice-field hills and coconut palms along the bottom edge, large plain soft blue area in the middle and on the left
```

**latar_belajar.png**
```
very calm pale sky-blue backdrop, soft grass strip along the bottom edge, a few small plants in the bottom right corner, large empty plain center
```

**latar_dongeng.png** (bagian kanan tengah harus terang dan polos karena teks cerita ada di situ)
```
soft warm evening sky fading to light cream in the center, distant village rooftops and small lanterns along the bottom edge, a few hand-drawn stars only in the top corners, large plain light area in the center and on the right
```

**latar_pembuka.png** (bagian tengah harus gelap karena tulisannya putih)
```
deep blue night sky over a sleepy Indonesian village, warm window lights along the bottom, a soft round moon near the top, darker plain area in the center, sparse small hand-drawn stars
```

**latar_masuk.png**
```
cheerful sunny morning landscape, layered green rice-field hills across the bottom third, small stilt houses and a kite far away on the right, pale sky with hand-drawn clouds, plain light area on the left side
```

**latar_terkunci.png** (opsional; belum ada file referensi karena sekarang putih polos, jadi buat dari teks dengan rasio 16:9)
```
quiet bedtime scene, dim blue room with a crescent moon in a window on the right, a sleeping cat on a blanket in the bottom left corner, large plain soft area in the center
```

**peta_unit_1.png … peta_unit_9.png** (ganti `[TEMA]`)
```
top-down storybook map, keep the winding sandy path exactly where it is in the reference image, [TEMA] on the left and right sides, plain open ground along the path, nothing tall on the path
```

| Unit | Tema |
|------|------|
| 1 | flower garden |
| 2 | fruit orchard |
| 3 | rice fields and a small village |
| 4 | sandy beach with palm trees |
| 5 | forest |
| 6 | river with a wooden bridge |
| 7 | mountain foothills |
| 8 | small town market |
| 9 | reading garden with benches and little book stalls |
