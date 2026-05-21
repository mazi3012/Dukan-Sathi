# ─── Render: Dart Backend Only (Multi-Stage) ─────────────────────────────────
# Stage 1: Build the server binary
FROM dart:stable AS build

WORKDIR /app
COPY server/ server/
RUN cd server && dart pub get
RUN cd server && dart compile exe bin/genkit_server.dart -o bin/server

# Stage 2: Minimal runtime image (~15MB vs ~800MB)
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server/bin/server /app/server/bin/server

WORKDIR /app
EXPOSE 3100

CMD ["./server/bin/server"]
