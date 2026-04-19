# Project State and Session Handoff

Last updated: 2026-04-19

## Current Phase
- Phase 2: Completed
- Phase 3: Implemented in `bin/telegram_bot.dart`
  - Per-user chat sessions are stored in memory (`activeSessions`)
  - Default shop context is embedded in system prompt (`shop_001`)
  - Tool usage is intent-routed to avoid multi-tool request errors
- Phase 4.5: Implemented
  - Supabase-backed `browseCatalogTool` and `businessInsightsTool` are active
  - `draft_invoices` RLS policies allow anon insert/select for operational writes and analytics reads
  - Genkit dashboard upgraded for no-code usage (settings panel, action explorer, quick prompts, trace view)

## Architecture Diagram

```mermaid
flowchart LR
  U[Telegram User] --> B[@Sathiaibeta_bot]
  B --> T[telegram_bot.dart Listener]
  T --> S{activeSessions\nMap<int, Chat>}
  S --> C[Chat Session]
  C --> G[Genkit Runtime]
  G --> M[Google GenAI Model]
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

## Unified Environment
Use `.env` with:

```env
MODEL_ID=gemini-3.1-flash-lite-preview
GOOGLE_API_KEY=<your-google-genai-api-key>
TELEGRAM_BOT_TOKEN=<your-telegram-bot-token>
```

Notes:
- `MODEL_ID` is unified across the app (flows + listener + status output)
- `GEMINI_API_KEY` can be used instead of `GOOGLE_API_KEY`

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
MODEL_ID=gemini-3.1-flash-lite-preview \
GOOGLE_API_KEY=<your-google-genai-api-key> \
/tmp/dart-sdk/bin/dart run bin/telegram_bot.dart
```

## Operations Runbook

### 1) Start All Services
```bash
cd /workspaces/dukansathi-new
/tmp/dart-sdk/bin/dart run bin/genkit_ui.dart
```

In a second terminal:
```bash
cd /workspaces/dukansathi-new
TELEGRAM_BOT_TOKEN=<token> \
MODEL_ID=gemini-3.1-flash-lite-preview \
GOOGLE_API_KEY=<your-google-genai-api-key> \
/tmp/dart-sdk/bin/dart run bin/telegram_bot.dart
```

### 2) One-Line Health Checks
```bash
curl -sS http://localhost:4000 | head -5
curl -sS http://localhost:4000/api/listActions
ps aux | grep "bin/telegram_bot.dart" | grep -v grep
curl -s "https://api.telegram.org/bot<token>/getMe"
```

### 3) Restart Services
```bash
pkill -f "bin/genkit_ui.dart" || true
cd /workspaces/dukansathi-new && /tmp/dart-sdk/bin/dart run bin/genkit_ui.dart
```

In a second terminal:
```bash
pkill -f "bin/telegram_bot.dart" || true
cd /workspaces/dukansathi-new && \
TELEGRAM_BOT_TOKEN=<token> \
MODEL_ID=gemini-3.1-flash-lite-preview \
GOOGLE_API_KEY=<your-google-genai-api-key> \
/tmp/dart-sdk/bin/dart run bin/telegram_bot.dart
```

### 4) Stop Services
```bash
pkill -f "bin/genkit_ui.dart" || true
pkill -f "bin/telegram_bot.dart" || true
```

### 5) Fast Troubleshooting
```bash
echo "$GOOGLE_API_KEY"
/tmp/dart-sdk/bin/dart analyze /workspaces/dukansathi-new/bin/telegram_bot.dart
lsof -i -P -n 2>/dev/null | grep LISTEN | grep -E ":4000|:3100"
```

## Next Recommended Work
- Persist sessions across restarts (Redis or database)
- Add session timeout eviction
- Add structured logging for Telegram inbound/outbound events
- Add integration tests for chat + tool routing
