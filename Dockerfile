# ─── Stage 1: Build ──────────────────────────────────────────────────────────
FROM dart:stable AS build
WORKDIR /app
COPY server/ server/
RUN cd server && dart pub get
RUN cd server && dart compile exe bin/genkit_server.dart -o bin/server

# ─── Stage 2: Minimal runtime ────────────────────────────────────────────────
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/server/bin/server /app/server/bin/server
WORKDIR /app
EXPOSE 3100
CMD ["./server/bin/server"]
