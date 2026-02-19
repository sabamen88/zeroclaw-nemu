#!/bin/sh
set -e

WORKSPACE="/zeroclaw-data/workspace"
CONFIG="/zeroclaw-data/.zeroclaw/config.toml"

mkdir -p "$WORKSPACE/skills/nemu-catalog"
mkdir -p "$WORKSPACE/skills/nemu-orders"
mkdir -p "$WORKSPACE/skills/nemu-buyers"
mkdir -p "$WORKSPACE/skills/paysponge"
mkdir -p "/zeroclaw-data/.zeroclaw"

# Copy Nemu workspace files (baked into image)
cp /nemu-workspace/SOUL.md "$WORKSPACE/SOUL.md"
cp /nemu-workspace/HEARTBEAT.md "$WORKSPACE/HEARTBEAT.md"
cp /nemu-workspace/skills/nemu-catalog/SKILL.md "$WORKSPACE/skills/nemu-catalog/SKILL.md"
cp /nemu-workspace/skills/nemu-orders/SKILL.md "$WORKSPACE/skills/nemu-orders/SKILL.md"
cp /nemu-workspace/skills/nemu-buyers/SKILL.md "$WORKSPACE/skills/nemu-buyers/SKILL.md"
cp /nemu-workspace/skills/paysponge/SKILL.md "$WORKSPACE/skills/paysponge/SKILL.md"

# Substitute seller placeholders with env vars (or demo defaults)
SELLER_NAME="${SELLER_NAME:-Toko Demo Nemu}"
STORE_NAME="${STORE_NAME:-Toko Demo Nemu}"
STORE_SLUG="${STORE_SLUG:-toko-demo-nemu}"
STORE_CATEGORY="${STORE_CATEGORY:-Fashion & Pakaian}"
STORE_DESCRIPTION="${STORE_DESCRIPTION:-Toko online terpercaya di Nemu AI}"
INVITE_CODE="${INVITE_CODE:-NEMU2025}"
IS_FOUNDING_SELLER="${IS_FOUNDING_SELLER:-true}"
WALLET_ADDRESS="${WALLET_ADDRESS:-0x0000000000000000000000000000000000000000}"
ACTIVE_HOURS="${ACTIVE_HOURS:-08:00-22:00}"

sed -i \
  -e "s/{{SELLER_NAME}}/$SELLER_NAME/g" \
  -e "s/{{STORE_NAME}}/$STORE_NAME/g" \
  -e "s/{{STORE_SLUG}}/$STORE_SLUG/g" \
  -e "s/{{STORE_CATEGORY}}/$STORE_CATEGORY/g" \
  -e "s/{{STORE_DESCRIPTION}}/$STORE_DESCRIPTION/g" \
  -e "s/{{INVITE_CODE}}/$INVITE_CODE/g" \
  -e "s/{{IS_FOUNDING_SELLER}}/$IS_FOUNDING_SELLER/g" \
  -e "s/{{WALLET_ADDRESS}}/$WALLET_ADDRESS/g" \
  -e "s/{{ACTIVE_HOURS}}/$ACTIVE_HOURS/g" \
  -e "s|{{STORE_LINK}}|https://nemu-ai.com/toko/$STORE_SLUG|g" \
  "$WORKSPACE/SOUL.md" "$WORKSPACE/HEARTBEAT.md"

# Generate config.toml from env vars
GATEWAY_PORT="${PORT:-3000}"
MEMORY_BACKEND="${NEON_DATABASE_URL:+postgres}"
MEMORY_BACKEND="${MEMORY_BACKEND:-sqlite}"

cat > "$CONFIG" <<EOF
api_key = "${MINIMAX_API_KEY:-}"
default_provider = "minimax"
default_model = "MiniMax-Text-01"
default_temperature = 0.7

workspace_dir = "$WORKSPACE"

[gateway]
port = $GATEWAY_PORT
host = "[::]"
allow_public_bind = true
require_pairing = false

[memory]
backend = "$MEMORY_BACKEND"
auto_save = true

[heartbeat]
enabled = true
interval_minutes = 30

[secrets]
encrypt = false

[autonomy]
level = "supervised"
workspace_only = true

[runtime]
kind = "native"
EOF

# Append PostgreSQL config if Neon URL is set
if [ -n "${NEON_DATABASE_URL:-}" ]; then
cat >> "$CONFIG" <<EOF

[storage.provider.config]
provider = "postgres"
db_url = "$NEON_DATABASE_URL"
schema = "zeroclaw_nemu"
table = "memories"
connect_timeout_secs = 15
EOF
fi

echo "ZeroClaw Nemu Agent starting..."
echo "Provider: minimax | Model: MiniMax-Text-01"
echo "Store: $STORE_NAME | Workspace: $WORKSPACE"

exec zeroclaw gateway
