# ─── Render: Dart Backend Only ────────────────────────────────────────────────
# Vercel handles the Flutter web frontend separately.
# This Dockerfile ONLY builds the Dart API server.
FROM dart:stable

WORKDIR /app

# Copy project files
COPY pubspec.yaml pubspec.lock ./
COPY lib/ lib/
COPY bin/ bin/

# Get dependencies (dart pub, not flutter pub)
# Override flutter SDK dependency for server-only build
RUN sed -i '/flutter_test/,/sdk: flutter/d' pubspec.yaml && \
    sed -i '/flutter:/,/sdk: flutter/d' pubspec.yaml && \
    sed -i '/uses-material-design/d' pubspec.yaml && \
    sed -i '/flutter:/d' pubspec.yaml

RUN dart pub get

# Compile the server binary
RUN dart compile exe bin/genkit_server.dart -o bin/server

# Expose the port (Render provides PORT env var)
EXPOSE 3100

CMD ["./bin/server"]
