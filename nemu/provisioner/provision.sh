#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Nemu AI — ZeroClaw Seller Agent Provisioner
# Spins up a new ZeroClaw agent for a seller in ~30 seconds
#
# Usage:
#   ./provision.sh <seller_id>
#
# Environment vars required (set in .env or pass via env):
#   NEMU_API_BASE        — e.g. https://nemu-ai.com/api
#   NEMU_PROVISION_KEY   — internal API key for agent provisioning
#   MINIMAX_API_KEY      — MiniMax M2.5 API key (shared across sellers)
#   NEON_DATABASE_URL    — Neon PostgreSQL connection string
#   WA_ACCESS_TOKEN      — WhatsApp Business Cloud API access token
#   WA_PHONE_NUMBER_ID   — Phone number ID from Meta Developer Console
#   ZEROCLAW_BIN         — Path to zeroclaw binary (default: zeroclaw)
#   AGENTS_BASE_DIR      — Where to store agent workspaces (default: /opt/nemu/agents)
#   GATEWAY_PORT_START   — Starting port for agent gateways (default: 4000)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SELLER_ID="${1:-}"
if [[ -z "$SELLER_ID" ]]; then
  echo "❌ Usage: $0 <seller_id>" >&2
  exit 1
fi

# ─── Config ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEMU_DIR="$(dirname "$SCRIPT_DIR")"
ZEROCLAW_BIN="${ZEROCLAW_BIN:-zeroclaw}"
AGENTS_BASE_DIR="${AGENTS_BASE_DIR:-/opt/nemu/agents}"
GATEWAY_PORT_START="${GATEWAY_PORT_START:-4000}"
NEMU_API_BASE="${NEMU_API_BASE:-https://nemu-ai.com/api}"

echo "🦀 Provisioning ZeroClaw agent for seller: $SELLER_ID"

# ─── Step 1: Fetch Seller Info from Nemu API ─────────────────────────────────
echo "📡 Fetching seller info..."
SELLER_JSON=$(curl -sf \
  -H "Authorization: Bearer ${NEMU_PROVISION_KEY}" \
  "${NEMU_API_BASE}/agent/seller/${SELLER_ID}")

SELLER_NAME=$(echo "$SELLER_JSON" | jq -r '.storeName')
STORE_NAME=$(echo "$SELLER_JSON" | jq -r '.storeName')
STORE_SLUG=$(echo "$SELLER_JSON" | jq -r '.storeSlug')
STORE_CATEGORY=$(echo "$SELLER_JSON" | jq -r '.category')
STORE_DESCRIPTION=$(echo "$SELLER_JSON" | jq -r '.description')
INVITE_CODE=$(echo "$SELLER_JSON" | jq -r '.inviteCode')
IS_FOUNDING_SELLER=$(echo "$SELLER_JSON" | jq -r '.isFoundingSeller')
SELLER_PHONE=$(echo "$SELLER_JSON" | jq -r '.whatsappPhone // ""')
NEMU_AGENT_API_KEY=$(echo "$SELLER_JSON" | jq -r '.agentApiKey')
PAYSPONGE_AGENT_ID=$(echo "$SELLER_JSON" | jq -r '.payspongAgentId // ""')
PAYSPONGE_API_KEY=$(echo "$SELLER_JSON" | jq -r '.payspongeApiKey // ""')
WALLET_ADDRESS=$(echo "$SELLER_JSON" | jq -r '.walletAddress // ""')

echo "✅ Seller: $STORE_NAME ($SELLER_ID)"

# ─── Step 2: Allocate Port ───────────────────────────────────────────────────
# Find next available port
GATEWAY_PORT=$GATEWAY_PORT_START
while lsof -Pi ":$GATEWAY_PORT" -sTCP:LISTEN -t >/dev/null 2>&1; do
  GATEWAY_PORT=$((GATEWAY_PORT + 1))
done
echo "🔌 Assigned gateway port: $GATEWAY_PORT"

# ─── Step 3: Create Agent Workspace ──────────────────────────────────────────
WORKSPACE_DIR="${AGENTS_BASE_DIR}/${SELLER_ID}"
mkdir -p "$WORKSPACE_DIR/workspace/skills"

echo "📁 Creating workspace at $WORKSPACE_DIR"

# Copy skills
cp -r "${NEMU_DIR}/workspace/skills/"* "${WORKSPACE_DIR}/workspace/skills/"

# Render SOUL.md with seller data
sed \
  -e "s/{{SELLER_NAME}}/${SELLER_NAME}/g" \
  -e "s/{{STORE_NAME}}/${STORE_NAME}/g" \
  -e "s/{{STORE_SLUG}}/${STORE_SLUG}/g" \
  -e "s/{{STORE_CATEGORY}}/${STORE_CATEGORY}/g" \
  -e "s|{{STORE_DESCRIPTION}}|${STORE_DESCRIPTION}|g" \
  -e "s/{{INVITE_CODE}}/${INVITE_CODE}/g" \
  -e "s/{{IS_FOUNDING_SELLER}}/${IS_FOUNDING_SELLER}/g" \
  -e "s/{{WALLET_ADDRESS}}/${WALLET_ADDRESS}/g" \
  -e "s|{{STORE_LINK}}|https://nemu-ai.com/toko/${STORE_SLUG}|g" \
  "${NEMU_DIR}/workspace/SOUL.md" > "${WORKSPACE_DIR}/workspace/SOUL.md"

cp "${NEMU_DIR}/workspace/HEARTBEAT.md" "${WORKSPACE_DIR}/workspace/HEARTBEAT.md"
# Render HEARTBEAT.md
sed -i "s/{{SELLER_NAME}}/${SELLER_NAME}/g" "${WORKSPACE_DIR}/workspace/HEARTBEAT.md"
sed -i "s/{{STORE_NAME}}/${STORE_NAME}/g" "${WORKSPACE_DIR}/workspace/HEARTBEAT.md"

# ─── Step 4: Generate Config ──────────────────────────────────────────────────
WA_VERIFY_TOKEN=$(openssl rand -hex 16)

sed \
  -e "s/{{MINIMAX_API_KEY}}/${MINIMAX_API_KEY}/g" \
  -e "s|{{NEON_DATABASE_URL}}|${NEON_DATABASE_URL}|g" \
  -e "s/{{SELLER_ID}}/${SELLER_ID}/g" \
  -e "s/{{GATEWAY_PORT}}/${GATEWAY_PORT}/g" \
  -e "s/{{WA_ACCESS_TOKEN}}/${WA_ACCESS_TOKEN}/g" \
  -e "s/{{WA_PHONE_NUMBER_ID}}/${WA_PHONE_NUMBER_ID}/g" \
  -e "s/{{WA_VERIFY_TOKEN}}/${WA_VERIFY_TOKEN}/g" \
  -e "s/{{SELLER_PHONE}}/${SELLER_PHONE}/g" \
  -e "s/{{NEMU_AGENT_API_KEY}}/${NEMU_AGENT_API_KEY}/g" \
  -e "s/{{PAYSPONGE_API_KEY}}/${PAYSPONGE_API_KEY}/g" \
  -e "s/{{PAYSPONGE_AGENT_ID}}/${PAYSPONGE_AGENT_ID}/g" \
  -e "s/{{WALLET_ADDRESS}}/${WALLET_ADDRESS}/g" \
  -e "s/{{AGENT_CAN_UPDATE_STOCK}}/false/g" \
  "${NEMU_DIR}/config.toml.template" > "${WORKSPACE_DIR}/config.toml"

echo "⚙️  Config generated"

# ─── Step 5: Install Zeroclaw (if not present) ────────────────────────────────
if ! command -v "$ZEROCLAW_BIN" &>/dev/null; then
  echo "📦 Installing ZeroClaw..."
  curl -LsSf https://raw.githubusercontent.com/sabamen88/zeroclaw-nemu/main/scripts/install.sh | bash
fi

# ─── Step 6: Launch Agent as Systemd Service ─────────────────────────────────
SERVICE_NAME="nemu-agent-${SELLER_ID}"

cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=Nemu AI Seller Agent — ${STORE_NAME} (${SELLER_ID})
After=network.target

[Service]
Type=simple
User=nemu
WorkingDirectory=${WORKSPACE_DIR}
Environment=ZEROCLAW_CONFIG=${WORKSPACE_DIR}/config.toml
Environment=ZEROCLAW_WORKSPACE=${WORKSPACE_DIR}/workspace
ExecStart=${ZEROCLAW_BIN} daemon
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

echo "🚀 Agent service started: $SERVICE_NAME"

# ─── Step 7: Register with Nemu Dashboard ────────────────────────────────────
curl -sf -X PATCH \
  -H "Authorization: Bearer ${NEMU_PROVISION_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"agentStatus\": \"active\",
    \"agentPort\": $GATEWAY_PORT,
    \"agentServerId\": \"$(hostname)\"
  }" \
  "${NEMU_API_BASE}/agent/seller/${SELLER_ID}/status"

echo ""
echo "✅ Done! Agent for ${STORE_NAME} is running on port ${GATEWAY_PORT}"
echo "   Webhook URL: http://localhost:${GATEWAY_PORT}/whatsapp"
echo "   Dashboard:   https://nemu-ai.com/dashboard"
