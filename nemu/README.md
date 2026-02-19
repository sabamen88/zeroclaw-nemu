# Nemu AI — ZeroClaw Seller Agent Layer

This directory contains everything needed to turn a ZeroClaw instance into a
Nemu AI seller agent. The core ZeroClaw binary handles runtime, channels,
memory, and security. This layer provides the Nemu-specific intelligence.

## Architecture

```
zeroclaw binary (Rust, <5MB RAM, <10ms startup)
└── nemu/ (this layer)
    ├── workspace/
    │   ├── SOUL.md           ← Agent personality & rules (Bahasa Indonesia)
    │   ├── HEARTBEAT.md      ← Proactive tasks (order alerts, daily summaries)
    │   └── skills/
    │       ├── nemu-catalog/ ← Real-time catalog, search, AI descriptions
    │       ├── nemu-orders/  ← Order management & notifications
    │       ├── nemu-buyers/  ← WhatsApp buyer Q&A & conversion
    │       └── paysponge/    ← Agent USDC wallet (agent-to-agent commerce)
    ├── config.toml.template  ← ZeroClaw config (MiniMax M2.5 + WhatsApp + Neon)
    └── provisioner/
        └── provision.sh      ← Spin up new seller agent in ~30 seconds
```

## What Each Seller Agent Does

- **Answers WhatsApp buyer messages** automatically from catalog (24/7)
- **Notifies seller** of new orders, low stock, unanswered messages
- **Sends daily summaries** (pesanan, revenue, pesan masuk)
- **Escalates** complex requests (complaints, negotiation) to human seller
- **Generates AI product descriptions** from name + photo
- **Holds a USDC wallet** for agent-to-agent commerce via PaySponge

## Provisioning a New Seller

```bash
export NEMU_API_BASE=https://nemu-ai.com/api
export NEMU_PROVISION_KEY=...
export MINIMAX_API_KEY=...
export NEON_DATABASE_URL=...
export WA_ACCESS_TOKEN=...
export WA_PHONE_NUMBER_ID=...

cd nemu/provisioner
./provision.sh <seller_id>
```

This will:
1. Fetch seller info from Nemu API
2. Render `SOUL.md` and `config.toml` with seller-specific data
3. Start ZeroClaw as a systemd service
4. Register the agent with the Nemu dashboard

## Scale

| VPS | RAM | Sellers |
|-----|-----|---------|
| $12/mo | 2GB | ~400 sellers |
| $24/mo | 4GB | ~800 sellers |
| $48/mo | 8GB | ~1,600 sellers |

ZeroClaw uses <5MB RAM per agent. A $12 VPS comfortably runs 400 Nemu sellers.

## Model

- **LLM:** MiniMax M2.5 (OpenAI-compatible, strong Bahasa Indonesia, ~10x cheaper than GPT-4)
- **Memory:** Neon PostgreSQL (per-seller schema, scales to zero)
- **WhatsApp:** Meta Business Cloud API (required at scale)
- **Wallet:** PaySponge USDC on Base (for agent-to-agent transactions)

## Contributing

Improvements to skills (Markdown files) don't require Rust knowledge.
See upstream [ZeroClaw docs](https://github.com/zeroclaw-labs/zeroclaw) for binary changes.
