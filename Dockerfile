# ─── Stage 1: Build Flutter Web ───────────────────────────────────────────────
# Use the official Flutter image (has Flutter + Dart SDK pre-installed)
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Run as root (required for system-level operations on Render)
USER root

WORKDIR /app

# Copy the entire project
COPY . .

# Build Flutter web app
RUN flutter pub get
RUN flutter build web --release --no-sound-null-safety 2>/dev/null || flutter build web --release

# ─── Stage 2: Dart Backend Runtime ────────────────────────────────────────────
FROM dart:stable AS runtime

WORKDIR /app

# Copy the full source from the build stage
COPY --from=build-env /app /app

# Get backend dependencies and compile the server binary
RUN dart pub get
RUN dart compile exe bin/genkit_server.dart -o bin/server

# Copy the Flutter web build into the public directory
RUN mkdir -p public && cp -r build/web/. public/

# Render provides PORT environment variable
EXPOSE 3100

CMD ["./bin/server"]
