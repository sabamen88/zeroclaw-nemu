# Skill: nemu-catalog — Katalog Produk Toko

## Deskripsi
Skill ini memungkinkan agen menjawab pertanyaan pembeli tentang produk toko.
Untuk demo MVP, katalog sudah di-embed di SOUL.md. Untuk produksi, gunakan Nemu Dashboard API.

## Kapan Digunakan
- Pembeli tanya stok, harga, ukuran, warna
- Pembeli minta rekomendasi produk
- Penjual minta laporan katalog

---

## Mode Demo (Aktif Sekarang)

Katalog produk tersedia di SOUL.md bagian "Katalog Produk".
Gunakan data tersebut untuk menjawab pembeli secara langsung — tidak perlu API call.

---

## Mode Produksi (Nemu Dashboard API)

Base URL: `https://nemu-dashboard-ki58epz0w-sabastian-karyadis-projects.vercel.app/api`

### Ambil semua produk aktif
```
GET /products
```

### Response format
```json
[{"id":"...","name":"...","price":"85000","stock":50,"category":"Fashion","images":["..."],"variants":[...]}]
```

---

## Format Respons ke Pembeli

### Produk tersedia:
```
Ada kak! [Nama] harganya Rp [X]. Stok [N] unit. Mau ukuran/warna apa? 😊
```

### Stok habis:
```
Maaf kak, [Nama] lagi kosong stoknya 😔 Mau dinotifiin kalau restok?
```

### Tidak ada di katalog:
```
Hmm, [nama] belum ada kak. Mungkin cocok: [2-3 alternatif relevan]
```

### Multi-varian:
```
[Nama] tersedia dalam:
• [Variant 1] — Rp [X]
• [Variant 2] — Rp [X]
Mana yang dipilih kak? 😊
```

---

## Rekomendasi Cerdas

1. Cek riwayat chat untuk preferensi pembeli
2. Rekomendasikan produk dengan stok tinggi
3. Sesuaikan konteks (hadiah, untuk diri sendiri, dll)
4. Maksimal 3 rekomendasi, jangan overwhelming
