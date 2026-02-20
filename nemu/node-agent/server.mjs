import express from "express";
import { createParser } from "eventsource-parser";

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const MINIMAX_KEY = process.env.MINIMAX_API_KEY || "";
const STORE_NAME = process.env.STORE_NAME || "Toko Demo Nemu";
const STORE_SLUG = process.env.STORE_SLUG || "toko-demo-nemu";
const INVITE_CODE = process.env.INVITE_CODE || "NEMU2025";

const CATALOG = `
Produk tersedia di ${STORE_NAME}:

FASHION:
- Kaos Polos Premium Unisex — Rp 85.000 | Stok: 50 | Ukuran: S/M/L/XL/XXL | Warna: Putih/Hitam/Abu-abu/Navy/Merah
- Kemeja Batik Modern Pria — Rp 185.000 | Stok: 30 | Ukuran: M/L/XL/XXL | Motif: Kawung/Parang/Mega Mendung
- Hijab Segi Empat Voal — Rp 65.000 | Stok: 100 | Warna: Krem/Dusty Pink/Sage/Cokelat Muda/Putih Tulang
- Celana Chino Slim Fit — Rp 145.000 | Stok: 40 | Ukuran: 28/30/32/34/36 | Warna: Khaki/Navy/Olive/Hitam

ELEKTRONIK:
- Earphone TWS Bluetooth 5.0 — Rp 195.000 | Stok: 25 | Warna: Putih/Hitam/Pink
- Powerbank 10000mAh Fast Charging — Rp 175.000 | Stok: 35 | Warna: Hitam/Putih/Biru

MAKANAN:
- Sambal Homemade Pedas Manis 250gr — Rp 35.000 | Stok: 20 | Level: Sedang/Pedas/Extra Pedas
- Kopi Arabica Flores Single Origin 200gr — Rp 89.000 | Stok: 15 | Jenis: Whole Bean/Medium Grind/Fine Grind

RUMAH & AKSESORI:
- Lampu LED Aesthetic Rattan — Rp 75.000 | Stok: 45 | Ukuran: Small 15cm/Medium 25cm/Large 35cm
- Tote Bag Canvas Sablon Custom — Rp 55.000 | Stok: 60 | Warna: Natural/Hitam/Navy

Kebijakan: COD Jabodetabek, transfer bank, QRIS, GoPay, OVO. Pengiriman JNE/J&T/SiCepat.
`;

const SYSTEM_PROMPT = `Kamu adalah agen AI untuk toko ${STORE_NAME} di Nemu AI — marketplace generasi baru Indonesia.
Tugas: bantu pembeli dengan pertanyaan produk, harga, stok, dan pesanan.
Bicara Bahasa Indonesia, santai, pakai "kak", maksimal 3-4 kalimat per balasan.
${CATALOG}
Kalau tidak ada produk yang diminta, rekomendasikan alternatif yang relevan.`;

async function askMinimax(message, history = []) {
  const messages = [
    { role: "user", content: SYSTEM_PROMPT + "\n\nPembeli: " + message },
  ];
  // Append history if any
  for (const h of history.slice(-6)) {
    messages.push(h);
  }

  const res = await fetch("https://api.minimax.io/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${MINIMAX_KEY}`,
    },
    body: JSON.stringify({
      model: "MiniMax-Text-01",
      messages,
      max_tokens: 300,
      temperature: 0.7,
    }),
  });

  const data = await res.json();
  return data.choices?.[0]?.message?.content || "Maaf kak, ada kendala teknis. Coba lagi ya 🙏";
}

// Health check — ZeroClaw-compatible format
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    paired: false,
    runtime: {
      components: { gateway: { status: "ok", restart_count: 0 } },
      pid: process.pid,
      uptime_seconds: Math.round(process.uptime()),
      updated_at: new Date().toISOString(),
    },
    agent: "nemu-node-agent",
    store: STORE_NAME,
  });
});

// Webhook — receive buyer messages
app.post("/webhook", async (req, res) => {
  const { type, from, name, text, message } = req.body;
  const userMsg = text || message || "";

  if (!userMsg) {
    return res.status(400).json({ error: "No message text provided" });
  }

  console.log(`📩 From ${name || from}: ${userMsg}`);

  try {
    const reply = await askMinimax(userMsg);
    console.log(`🤖 Reply: ${reply}`);
    res.json({ status: "ok", reply, from, store: STORE_NAME });
  } catch (e) {
    console.error("MiniMax error:", e);
    res.status(500).json({ error: "Agent error", message: e.message });
  }
});

// WhatsApp webhook verify
app.get("/whatsapp", (req, res) => {
  const mode = req.query["hub.mode"];
  const token = req.query["hub.verify_token"];
  const challenge = req.query["hub.challenge"];
  if (mode === "subscribe") return res.send(challenge);
  res.sendStatus(403);
});

app.listen(PORT, () => {
  console.log(`🚀 Nemu Agent running on port ${PORT}`);
  console.log(`🏪 Store: ${STORE_NAME} (${STORE_SLUG})`);
  console.log(`🤖 Model: MiniMax-Text-01`);
});
