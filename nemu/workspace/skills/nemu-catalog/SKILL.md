# Skill: nemu-catalog — Manajemen Katalog Toko

## Deskripsi
Skill ini memungkinkan agen mengakses, membaca, dan merespons pertanyaan tentang
katalog produk toko secara real-time dari Nemu AI database.

## Kapan Digunakan
- Pembeli tanya "ada [produk] gak?"
- Pembeli minta info harga, stok, ukuran, warna
- Pembeli minta rekomendasi produk
- Penjual minta laporan katalog
- Penjual ingin update stok/harga via chat

---

## API Endpoints (Nemu AI)

Base URL: `https://nemu-ai.com/api/agent`
Auth: `Authorization: Bearer {{AGENT_API_KEY}}`
Seller ID: `{{SELLER_ID}}`

### Ambil semua produk
```
GET /products?seller_id={{SELLER_ID}}&status=active
```
Response: array produk dengan id, name, price, stock, description, images, category, variants

### Cari produk
```
GET /products/search?seller_id={{SELLER_ID}}&q={query}
```

### Detail produk
```
GET /products/{product_id}
```

### Update stok (agen berwenang)
```
PATCH /products/{product_id}
Body: {"stock": N}
```
Hanya diizinkan jika `agent_can_update_stock = true` di config.

### Update harga (perlu approval penjual)
```
PATCH /products/{product_id}
Body: {"price": N, "requires_approval": true}
```

---

## Format Respons ke Pembeli

### Produk ditemukan, stok ada:
```
Ada kak! [Nama Produk] harganya Rp [X.XXX]. 
Stok masih [N] unit. Mau pesan sekarang? 😊
```

### Produk ditemukan, stok habis:
```
Maaf kak, [Nama Produk] lagi kosong stoknya 😔
Mau aku notifiin kalau sudah restok?
```

### Produk tidak ada di katalog:
```
Hmm, kayaknya kami belum jual [nama produk] kak.
Ini produk-produk yang ada: [3-5 rekomendasi relevan]
```

### Beberapa variant tersedia:
```
[Nama Produk] tersedia dalam beberapa pilihan kak:
• [Variant 1] - Rp [X] (stok: [N])
• [Variant 2] - Rp [X] (stok: [N])
Yang mana mau dipilih? 😊
```

---

## AI Product Description Generator

Saat penjual upload produk baru dengan deskripsi kosong atau pendek,
generate deskripsi lengkap dari nama + foto menggunakan template ini:

```
Tulis deskripsi produk untuk [nama produk] di toko fashion Indonesia.
Gaya: persuasif, natural, SEO-friendly.
Sertakan: material/bahan, keunggulan, cara pakai/cocok untuk apa, ukuran/variasi.
Panjang: 100-150 kata. Bahasa Indonesia. Tidak perlu emoji di deskripsi.
```

---

## Rekomendasi Cerdas

Kalau pembeli minta rekomendasi atau tampak bingung, gunakan logika:
1. Cek riwayat chat (jika ada) untuk preferensi
2. Cek produk best-seller toko (order count tertinggi)
3. Sesuaikan dengan konteks (misal: "untuk hadiah" → cari yang bisa di-gift wrap)
4. Maksimal 3 rekomendasi, jangan overwhelming
