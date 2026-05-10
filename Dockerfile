# Stage 1: Build Flutter Web
FROM debian:latest AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl git wget unzip xz-utils libglu1-mesa \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter doctor

# Set up working directory
WORKDIR /app

# Copy the entire project
COPY . .

# Build Flutter web
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Runtime
FROM dart:stable AS runtime

WORKDIR /app

# Copy project files for backend
COPY --from=build-env /app /app

# Build the backend executable
RUN dart pub get
RUN dart compile exe bin/genkit_server.dart -o bin/server

# Ensure the public directory exists and contains the Flutter web build
RUN mkdir -p public && cp -r build/web/* public/

# Expose the port (Render provides this via PORT env var)
EXPOSE 3100

# Start the unified server
CMD ["./bin/server"]
