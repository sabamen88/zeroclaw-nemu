# Skill: paysponge — Agent Wallet (USDC on Base)

## Deskripsi
Skill untuk mengoperasikan dompet USDC agen via PaySponge.
Digunakan untuk menerima pembayaran dari agen lain (agent-to-agent commerce),
membayar layanan API via x402, dan melacak saldo dompet toko.

**Catatan:** Ini adalah dompet AGEN, bukan dompet penjual manusia.
Untuk pembayaran dari pembeli manusia, tetap gunakan Xendit/QRIS Nemu AI.

## Konfigurasi

```toml
[skills.paysponge]
api_key = "{{PAYSPONGE_API_KEY}}"
agent_id = "{{PAYSPONGE_AGENT_ID}}"
wallet_address = "{{WALLET_ADDRESS}}"  # Base/EVM
network = "base"  # mainnet
```

## API Reference

Base URL: `https://api.wallet.paysponge.com`
Auth: `Authorization: Bearer {{PAYSPONGE_API_KEY}}`

### Cek Saldo
```
GET /v1/balance
```
Response: `{"usdc": "12.50", "address": "0x...", "network": "base"}`

### Transfer USDC
```
POST /v1/transfer
Body: {
  "to": "0x... atau agent_id",
  "amount": "5.00",
  "currency": "USDC",
  "memo": "Pembayaran layanan X"
}
```

### Riwayat Transaksi
```
GET /v1/transactions?limit=10
```

### x402 Auto-Pay (untuk akses layanan berbayar)
PaySponge menangani x402 otomatis. Agen bisa akses endpoint yang require payment:
```
GET https://api.nemu-ai.com/mcp/search?q=sepatu+kulit
# Jika endpoint butuh x402 payment, PaySponge bayar otomatis dari saldo
```

---

## Kapan Menggunakan Dompet Ini

### 1. Menerima pembayaran dari agen pembeli
Saat agen pembeli (dari platform lain) beli produk via Nemu MCP:
- Agen pembeli kirim USDC ke alamat toko
- Agen toko konfirmasi penerimaan dan proses pesanan
- Catat di wallet_events database

### 2. Membayar layanan AI
- Biaya embedding, image generation, atau tool call berbayar
- PaySponge bayar otomatis via x402 jika saldo cukup

### 3. Laporan ke Penjual
Saat penjual tanya saldo wallet:
```
💰 Saldo Wallet Agen Toko {{STORE_NAME}}:
USDC: {{BALANCE}} (≈ Rp {{IDR_EQUIVALENT}})
Alamat: {{WALLET_ADDRESS}}
Jaringan: Base (Ethereum L2)

Untuk withdraw ke rupiah, hubungi Nemu AI support.
```

---

## Keamanan

- **Private key** tidak pernah keluar dari sistem PaySponge
- Agen hanya bisa transfer dengan batas harian yang dikonfigurasi
- Setiap transaksi > $10 USDC butuh konfirmasi penjual
- Alert otomatis jika saldo turun drastis

## Batasan Default

- Transfer maksimum per transaksi: $50 USDC
- Transfer maksimum per hari: $200 USDC
- Auto-pay x402: maks $1 USDC per request
- Semua batas ini bisa disesuaikan di dashboard penjual
