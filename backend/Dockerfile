# Dependencies are cached in their own layer so day-to-day code edits rebuild
# in seconds instead of recompiling the whole crate graph.
FROM rust:1.98-slim-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        pkg-config libssl-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs \
    && cargo build --release \
    && rm -rf src

COPY src ./src
COPY migrations ./migrations
# The crate is a library plus a thin binary; touch both so neither is
# mistaken for the cached placeholder.
RUN touch src/main.rs src/lib.rs && cargo build --release


FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --create-home --uid 10001 kitaza

WORKDIR /app
COPY --from=builder /build/target/release/kitaza-server /usr/local/bin/kitaza-server
COPY --from=builder /build/migrations ./migrations

USER kitaza
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl --fail http://localhost:8080/health || exit 1

CMD ["kitaza-server"]
