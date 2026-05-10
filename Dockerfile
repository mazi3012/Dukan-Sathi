# ─── Render: Dart Backend Only ────────────────────────────────────────────────
# Vercel handles the Flutter web frontend separately.
# This Dockerfile ONLY builds the Dart API server.
FROM dart:stable

WORKDIR /app

# Copy the server-only pubspec (no Flutter SDK deps)
COPY pubspec_server.yaml pubspec.yaml

# Copy source code
COPY lib/ lib/
COPY bin/ bin/

# Get dependencies using pure Dart (no Flutter SDK needed)
RUN dart pub get

# Compile the server binary
RUN dart compile exe bin/genkit_server.dart -o bin/server

# Expose the port (Render provides PORT env var)
EXPOSE 3100

CMD ["./bin/server"]
