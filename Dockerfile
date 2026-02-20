# Nemu AI — ZeroClaw Seller Agent (Render-compatible build)

# ── Stage 1: Build ZeroClaw binary ───────────────────────────
FROM rust:1.93-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y pkg-config libssl-dev && \
    rm -rf /var/lib/apt/lists/*

COPY Cargo.toml Cargo.lock rust-toolchain.toml ./
COPY crates/robot-kit/Cargo.toml crates/robot-kit/Cargo.toml

RUN mkdir -p src benches crates/robot-kit/src && \
    echo "fn main() {}" > src/main.rs && \
    echo "fn main() {}" > benches/agent_benchmarks.rs && \
    echo "pub fn placeholder() {}" > crates/robot-kit/src/lib.rs

RUN cargo build --release --locked

RUN rm -rf src benches crates/robot-kit/src

COPY src/ src/
COPY benches/ benches/
COPY crates/ crates/
COPY firmware/ firmware/

RUN cargo build --release --locked && \
    cp target/release/zeroclaw /app/zeroclaw && \
    strip /app/zeroclaw

# ── Stage 2: Nemu Runtime ─────────────────────────────────────
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/zeroclaw /usr/local/bin/zeroclaw
COPY nemu/workspace/ /nemu-workspace/
COPY nemu/docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /zeroclaw-data/.zeroclaw /zeroclaw-data/workspace && \
    chmod -R 777 /zeroclaw-data

ENV ZEROCLAW_WORKSPACE=/zeroclaw-data/workspace
ENV HOME=/zeroclaw-data

EXPOSE 3000
ENTRYPOINT ["/entrypoint.sh"]
