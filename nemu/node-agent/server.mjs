import express from "express";

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const MINIMAX_KEY = process.env.MINIMAX_API_KEY || "";
const STORE_NAME = process.env.STORE_NAME || "Toko Demo Nemu";
const STORE_SLUG = process.env.STORE_SLUG || "toko-demo-nemu";

const CATALOG = `Produk ${STORE_NAME}: Kaos Polos Rp85rb (S-XXL, 5 warna), Kemeja Batik Pria Rp185rb (M-XXL, 3 motif), Hijab Voal Rp65rb (5 warna), Celana Chino Rp145rb (28-36, 4 warna), Earphone TWS BT Rp195rb, Powerbank 10000mAh Rp175rb, Sambal Homemade Rp35rb, Kopi Arabica Flores Rp89rb, Lampu LED Rattan Rp75rb, Tote Bag Canvas Rp55rb. Bayar: transfer/QRIS/GoPay/OVO/COD Jabodetabek.`;

async function askMinimax(userMsg) {
  if (!MINIMAX_KEY) return "Maaf kak, agent sedang offline 🙏";
  const messages = [
    { role: "user", content: `Kamu adalah agen AI untuk ${STORE_NAME} di Nemu AI. Bicara Bahasa Indonesia santai, pakai "kak", maks 3 kalimat. Katalog: ${CATALOG}\n\nPembeli: ${userMsg}` }
  ];
  const res = await fetch("https://api.minimax.io/v1/chat/completions", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${MINIMAX_KEY}` },
    body: JSON.stringify({ model: "MiniMax-Text-01", messages, max_tokens: 300, temperature: 0.7 }),
  });
  const data = await res.json();
  return data.choices?.[0]?.message?.content || "Maaf kak, ada kendala teknis 🙏";
}

app.get("/health", (req, res) => res.json({
  status: "ok", paired: false,
  runtime: { components: { gateway: { status: "ok" } }, uptime_seconds: Math.round(process.uptime()) },
  agent: "nemu-node-agent", store: STORE_NAME,
}));

app.post("/webhook", async (req, res) => {
  const { from, name, text, message } = req.body;
  const msg = text || message || "";
  if (!msg) return res.status(400).json({ error: "No message" });
  console.log(`📩 ${name||from}: ${msg}`);
  try {
    const reply = await askMinimax(msg);
    console.log(`🤖 ${reply}`);
    res.json({ status: "ok", reply, from, store: STORE_NAME });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Agent error" });
  }
});

app.get("/whatsapp", (req, res) => {
  if (req.query["hub.mode"] === "subscribe") return res.send(req.query["hub.challenge"]);
  res.sendStatus(403);
});

app.listen(PORT, () => console.log(`🚀 Nemu Agent on :${PORT} | ${STORE_NAME}`));
