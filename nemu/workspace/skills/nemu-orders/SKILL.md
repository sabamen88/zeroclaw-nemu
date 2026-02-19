# Skill: nemu-orders — Manajemen Pesanan

## Deskripsi
Skill untuk memantau, melaporkan, dan merespons pesanan masuk di toko Nemu AI.
Agen dapat membaca status pesanan, notifikasi penjual, dan membantu pembeli cek status.

## API Endpoints

Base URL: `https://nemu-ai.com/api/agent`
Auth: `Authorization: Bearer {{AGENT_API_KEY}}`

### Ambil pesanan terbaru
```
GET /orders?seller_id={{SELLER_ID}}&limit=10&sort=newest
```

### Pesanan per status
```
GET /orders?seller_id={{SELLER_ID}}&status=pending|processing|shipped|delivered|cancelled
```

### Detail pesanan
```
GET /orders/{order_id}
```
Response: id, buyer_name, buyer_phone, items, total, status, created_at, shipping_address

### Update status pesanan (jika agen berwenang)
```
PATCH /orders/{order_id}/status
Body: {"status": "processing", "note": "sedang disiapkan"}
```

---

## Notifikasi Pesanan Baru

Saat ada pesanan baru masuk (trigger dari webhook atau heartbeat):

**Ke Penjual:**
```
🛍️ Pesanan Baru! #{{ORDER_ID}}
👤 Pembeli: {{BUYER_NAME}}
📦 Produk: {{ITEMS_SUMMARY}}
💰 Total: Rp {{TOTAL}}
📍 Kirim ke: {{CITY}}

Cek & konfirmasi: https://nemu-ai.com/dashboard/orders/{{ORDER_ID}}
```

**Auto-reply ke Pembeli (opsional, jika dikonfigurasi):**
```
Halo kak {{BUYER_NAME}}! 👋
Pesanan kamu #{{ORDER_ID}} sudah kami terima ya.
Total: Rp {{TOTAL}}
Kami akan proses dalam 1x24 jam kerja. Nanti kami kabari kalau sudah dikirim 📦
```

---

## Cek Status Pesanan (dari Pembeli)

Saat pembeli tanya status pesanannya:

1. Minta nomor pesanan atau konfirmasi nama
2. Cari di API
3. Balas sesuai status:

| Status | Balasan |
|--------|---------|
| `pending` | "Pesanan kamu #[ID] sudah masuk kak, sedang menunggu konfirmasi penjual 🕐" |
| `processing` | "Pesanan #[ID] sedang disiapkan kak! Biasanya 1-2 hari kerja sebelum dikirim 📦" |
| `shipped` | "Pesanan #[ID] sudah dikirim kak! Nomor resi: [resi] via [ekspedisi]" |
| `delivered` | "Pesanan #[ID] sudah terkirim kak 🎉 Semoga suka! Ada yang bisa dibantu lagi?" |
| `cancelled` | "Pesanan #[ID] dibatalkan. Untuk info lebih lanjut, hubungi kami ya kak 🙏" |

---

## Laporan Penjualan Harian

Format laporan untuk penjual (dikirim via heartbeat pagi):

```
📊 Ringkasan Pesanan {{DATE}}:
• Pesanan baru: {{NEW_COUNT}}
• Sedang diproses: {{PROCESSING_COUNT}}  
• Dikirim hari ini: {{SHIPPED_COUNT}}
• Total pendapatan hari ini: Rp {{DAILY_REVENUE}}

📦 Perlu tindakan (pending): {{PENDING_LIST}}
```

---

## Alert Otomatis

- **Pesanan pending > 6 jam** tanpa konfirmasi → alert ke penjual
- **Pesanan bernilai > Rp 500.000** → notifikasi segera (prioritas tinggi)
- **5+ pesanan dalam 1 jam** → alert "toko sedang ramai" + pantau stok
