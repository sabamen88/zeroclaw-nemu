# Nemu AI — ZeroClaw Seller Agent
# Builds ZeroClaw with Nemu workspace layer

# ── Stage 1: Build ZeroClaw binary ───────────────────────────
FROM rust:1.92-slim AS builder

WORKDIR /app

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y pkg-config libssl-dev && \
    rm -rf /var/lib/apt/lists/*

COPY Cargo.toml Cargo.lock rust-toolchain.toml ./
COPY crates/robot-kit/Cargo.toml crates/robot-kit/Cargo.toml

RUN mkdir -p src benches crates/robot-kit/src && \
    echo "fn main() {}" > src/main.rs && \
    echo "fn main() {}" > benches/agent_benchmarks.rs && \
    echo "pub fn placeholder() {}" > crates/robot-kit/src/lib.rs

RUN --mount=type=cache,id=nemu-cargo-registry,target=/usr/local/cargo/registry,sharing=locked \
    --mount=type=cache,id=nemu-cargo-git,target=/usr/local/cargo/git,sharing=locked \
    --mount=type=cache,id=nemu-target,target=/app/target,sharing=locked \
    cargo build --release --locked

RUN rm -rf src benches crates/robot-kit/src

COPY src/ src/
COPY benches/ benches/
COPY crates/ crates/
COPY firmware/ firmware/

RUN --mount=type=cache,id=nemu-cargo-registry,target=/usr/local/cargo/registry,sharing=locked \
    --mount=type=cache,id=nemu-cargo-git,target=/usr/local/cargo/git,sharing=locked \
    --mount=type=cache,id=nemu-target,target=/app/target,sharing=locked \
    cargo build --release --locked && \
    cp target/release/zeroclaw /app/zeroclaw && \
    strip /app/zeroclaw

# ── Stage 2: Nemu Runtime ─────────────────────────────────────
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/zeroclaw /usr/local/bin/zeroclaw

# Bake Nemu workspace files into image
COPY nemu/workspace/ /nemu-workspace/

# Entrypoint generates config.toml from env vars at startup
COPY nemu/docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Data directory
RUN mkdir -p /zeroclaw-data/.zeroclaw /zeroclaw-data/workspace && \
    chmod -R 777 /zeroclaw-data

ENV ZEROCLAW_WORKSPACE=/zeroclaw-data/workspace
ENV HOME=/zeroclaw-data

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
