# Project State and Session Handoff

Last updated: 2026-04-19

## Current Phase
- Phase 2: Completed
- Phase 3: In progress and implemented in `bin/telegram_bot.dart`
  - Per-user chat sessions are kept in memory via `activeSessions`
  - Default shop context is embedded in system prompt (`shop_001`)
  - Tool usage is intent-routed to avoid Vertex multi-tool request errors

## Architecture Diagram

```mermaid
flowchart LR
  U[Telegram User] --> B[@Sathiaibeta_bot]
  B --> T[telegram_bot.dart Listener]
  T --> S{activeSessions\nMap<int, Chat>}
  S --> C[Chat Session]
  C --> G[Genkit Runtime]
  G --> M[Vertex AI Model]
  C --> I[checkInventory Tool]
  C --> D[createDraftInvoice Tool]
  I --> R1[Inventory Result]
  D --> R2[Draft Invoice Result]
  R1 --> T
  R2 --> T
  T --> B
  B --> U
```

## Runtime Components
- UI Server: `bin/genkit_ui.dart` on port `4000`
- API Server: `bin/genkit_server.dart` on port `3100`
- Telegram Listener: `bin/telegram_bot.dart`

## Environment Requirements
Use `.env` with:

```env
GCLOUD_PROJECT=peppy-avatar-429012-q2
GCLOUD_LOCATION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/tmp/dukansathi-vertex-sa.json
TELEGRAM_BOT_TOKEN=<your-telegram-bot-token>
```

## Known Constraints and Applied Fixes
- Vertex rejected requests with multiple tools in one generate call.
  - Fix: Telegram chat selects only one tool by intent per message.
- `gemini-3.1-flash-lite-preview` can be unavailable for the project.
  - Fix: Telegram chat falls back to `gemini-2.5-flash`.
- Missing ADC credentials caused metadata server errors.
  - Fix: runtime now validates local credentials path early.

## Start Commands

### Genkit UI (port 4000)
```bash
cd /workspaces/dukansathi-new
/tmp/dart-sdk/bin/dart run bin/genkit_ui.dart
```

### Telegram Listener
```bash
cd /workspaces/dukansathi-new
TELEGRAM_BOT_TOKEN=<token> \
GCLOUD_PROJECT=peppy-avatar-429012-q2 \
GOOGLE_APPLICATION_CREDENTIALS=/tmp/dukansathi-vertex-sa.json \
/tmp/dart-sdk/bin/dart run bin/telegram_bot.dart
```

## Verification Checklist
- `curl http://localhost:4000` returns HTML
- Telegram bot process is running
- Bot replies to inventory and billing prompts
- `dart analyze bin/telegram_bot.dart` reports no issues

## Operations Runbook

### 1) Start All Services
```bash
cd /workspaces/dukansathi-new

# Start Genkit UI (port 4000)
/tmp/dart-sdk/bin/dart run bin/genkit_ui.dart
```

In a second terminal:
```bash
cd /workspaces/dukansathi-new

# Start Telegram listener
TELEGRAM_BOT_TOKEN=<token> \
GCLOUD_PROJECT=peppy-avatar-429012-q2 \
GOOGLE_APPLICATION_CREDENTIALS=/tmp/dukansathi-vertex-sa.json \
/tmp/dart-sdk/bin/dart run bin/telegram_bot.dart
```

### 2) One-Line Health Checks
```bash
# UI endpoint
curl -sS http://localhost:4000 | head -5

# UI actions endpoint
curl -sS http://localhost:4000/api/listActions

# Telegram bot process
ps aux | grep "bin/telegram_bot.dart" | grep -v grep

# Telegram bot token validity
curl -s "https://api.telegram.org/bot<token>/getMe"
```

### 3) Restart Services
```bash
# Restart UI
pkill -f "bin/genkit_ui.dart" || true
cd /workspaces/dukansathi-new && /tmp/dart-sdk/bin/dart run bin/genkit_ui.dart
```

In a second terminal:
```bash
# Restart Telegram listener
pkill -f "bin/telegram_bot.dart" || true
cd /workspaces/dukansathi-new && \
TELEGRAM_BOT_TOKEN=<token> \
GCLOUD_PROJECT=peppy-avatar-429012-q2 \
GOOGLE_APPLICATION_CREDENTIALS=/tmp/dukansathi-vertex-sa.json \
/tmp/dart-sdk/bin/dart run bin/telegram_bot.dart
```

### 4) Stop Services
```bash
pkill -f "bin/genkit_ui.dart" || true
pkill -f "bin/telegram_bot.dart" || true
```

### 5) Fast Troubleshooting
```bash
# Missing credentials file
ls -la /tmp/dukansathi-vertex-sa.json

# Analyzer check
/tmp/dart-sdk/bin/dart analyze /workspaces/dukansathi-new/bin/telegram_bot.dart

# Check bound ports
lsof -i -P -n 2>/dev/null | grep LISTEN | grep -E ":4000|:3100"
```

## Next Recommended Work
- Persist sessions across restarts (Redis or database)
- Add explicit session timeout eviction strategy
- Add structured logging for Telegram inbound/outbound events
- Add integration test for chat + tool routing
