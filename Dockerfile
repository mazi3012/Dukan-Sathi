# ─── Render: Dart Backend Only ────────────────────────────────────────────────
# Vercel handles the Flutter web frontend separately.
# This Dockerfile ONLY builds the Dart API server.
FROM dart:stable

WORKDIR /app

# Copy workspace files
COPY . .

# Get dependencies using pure Dart in the server subdirectory
RUN cd server && dart pub get

# Compile the server binary
RUN cd server && dart compile exe bin/genkit_server.dart -o bin/server

# Expose the port (Render provides PORT env var)
EXPOSE 3100

CMD ["./server/bin/server"]
