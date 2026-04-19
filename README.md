# Dukan Sathi Pro - Genkit Backend

AI retail backend built with Dart, Genkit, Google GenAI SDK, Supabase, and Telegram integration.

## Current Status

- Phase 4.5 completed: Supabase-backed tools + RLS policies + catalog + analytics.
- Live state and runbook: [docs/PROJECT_STATE.md](docs/PROJECT_STATE.md)

## Quick Start

1. Install dependencies

```bash
dart pub get
```

2. Create `.env` (never commit this file)

```env
MODEL_ID=gemini-3.1-flash-lite-preview
GOOGLE_API_KEY=<your-google-genai-api-key>
TELEGRAM_BOT_TOKEN=<your-telegram-bot-token>
SUPABASE_URL=<your-supabase-url>
SUPABASE_ANON_KEY=<your-supabase-anon-key>
```

3. Run Genkit dashboard

```bash
dart run bin/genkit_ui.dart
```

4. Run Telegram bot

```bash
dart run bin/telegram_bot.dart
```

## Runtime Components

- `bin/genkit_ui.dart`: No-code dashboard and flow playground.
- `bin/genkit_server.dart`: JSON API server.
- `bin/telegram_bot.dart`: Telegram listener with tool-intent routing.
- `lib/runtime/genkit_runtime.dart`: Google GenAI runtime + unified `MODEL_ID`.

## Tools

- `checkInventory`: Price/stock lookup from Supabase `products`.
- `browseCatalogTool`: Lists available products, optional category filter.
- `createDraftInvoice`: Creates draft invoices in `draft_invoices`.
- `businessInsightsTool`: Revenue and invoice count analytics.

## Supabase Schema & Security

Migrations in `supabase/migrations/` include:

- `init_core_schema`: `products`, `draft_invoices`
- `add_products_read_policy`: base RLS policies
- `fix_invoice_policies`: explicit anonymous `INSERT`/`SELECT` policies for `draft_invoices`

Apply migrations:

```bash
npx -y supabase@latest db push
```

## API Test

```bash
curl -X POST http://localhost:4000/api/runAction \
  -H "Content-Type: application/json" \
  -d '{"key":"/flow/retailAssistantFlow","input":"What item do you sell?"}'
```

## Security

- `.env` is gitignored.
- `.secrets/` is gitignored.
- Supabase local secret variants are gitignored in `supabase/.gitignore`.
- Do not commit tokens, API keys, or credential JSON files.

## Troubleshooting

- Port conflict on dashboard:

```bash
PORT=4010 dart run bin/genkit_ui.dart
```

- Check running listeners:

```bash
ps aux | grep "bin/telegram_bot.dart" | grep -v grep
```