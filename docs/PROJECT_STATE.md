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

## Next Recommended Work
- Persist sessions across restarts (Redis or database)
- Add explicit session timeout eviction strategy
- Add structured logging for Telegram inbound/outbound events
- Add integration test for chat + tool routing
