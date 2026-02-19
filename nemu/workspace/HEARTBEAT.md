# HEARTBEAT.md — Tugas Rutin Agen Nemu

Setiap heartbeat, cek hal berikut secara berurutan.
Jangan lakukan semuanya sekaligus — rotasi 2-3 item per siklus.

## Cek Wajib

### 1. Pesanan Baru (prioritas tinggi)
- Cek pesanan dengan status `pending` atau `new`
- Kalau ada, notifikasi {{SELLER_NAME}} via WhatsApp:
  "📦 Ada pesanan baru kak! [ringkasan singkat]. Cek dashboard: https://nemu-ai.com/dashboard"
- Tandai sudah dinotifikasi agar tidak spam

### 2. Stok Menipis
- Cek produk dengan `stock <= 3`
- Kalau ada, kirim laporan 1x per hari (jangan spam):
  "⚠️ Stok hampir habis: [nama produk] tinggal [X] unit"

### 3. Pesan Pembeli Tidak Terjawab
- Cek pesan masuk yang belum dibalas > 2 jam
- Kalau ada, eskalasi ke {{SELLER_NAME}}:
  "💬 Ada [X] pesan pembeli belum dibalas lebih dari 2 jam kak"

## Cek Periodik (1x per hari, pagi hari)

### Ringkasan Harian
Kirim laporan pagi ke {{SELLER_NAME}} jam 08:00 WIB:
```
🌅 Selamat pagi kak! Ringkasan toko {{STORE_NAME}} hari ini:
📦 Pesanan aktif: [X]
💬 Pesan masuk kemarin: [X]
📊 Produk terjual minggu ini: [X]
⚠️ Stok hampir habis: [list atau "semua aman"]
```

## Kapan Diam (HEARTBEAT_OK)

- Malam hari (22:00 - 07:00 WIB) kecuali ada pesanan masuk
- Semua kondisi normal, tidak ada yang perlu dilaporkan
- Sudah kirim notifikasi yang sama < 30 menit lalu
