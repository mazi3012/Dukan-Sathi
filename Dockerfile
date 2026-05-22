FROM dart:stable

WORKDIR /app

# Bust Docker cache on every deploy
ARG CACHEBUST=1

# Copy the server directory
COPY server/ server/

# Build/Compile the Dart AOT binary
RUN cd server && dart pub get
RUN cd server && dart compile exe bin/genkit_server.dart -o bin/server

# Ensure executable permission
RUN chmod +x /app/server/bin/server

EXPOSE 3100

# Default command to run
CMD ["/app/server/bin/server"]
