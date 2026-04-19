# Dukan Sathi Pro - Genkit Backend

A headless AI-powered retail assistant backend built with Dart, Genkit, and Vertex AI. This project provides intelligent inventory management, billing, and customer interaction through a Genkit flow architecture.

## Current State

- Live project/session handoff: [docs/PROJECT_STATE.md](docs/PROJECT_STATE.md)
- Includes current architecture diagram, runtime commands, constraints, and Phase 3 session notes.

## 🚀 Quick Start

### Prerequisites
- Dart SDK 3.10.0 or higher
- Google Cloud project with Vertex AI enabled
- Service account credentials (optional, but recommended)

### Installation

1. **Clone and setup dependencies:**
```bash
dart pub get
```

2. **Configure environment variables:**

Create a `.env` file in the project root:
```
GCLOUD_PROJECT=your-gcp-project-id
GCLOUD_LOCATION=us-central1
```

Or set environment variables:
```bash
export GCLOUD_PROJECT="your-gcp-project-id"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
```

3. **Run the development server:**
```bash
dart bin/genkit_dev.dart
```

The Genkit UI will be available at: **http://localhost:4000**

## 📋 Project Structure

```
bin/
├── dukansathi_new.dart      # Main entry point (initializes backend)
├── genkit_dev.dart          # Development server with web UI
├── genkit_ui.dart           # Custom Genkit UI dashboard
├── genkit_server.dart       # Custom HTTP reflection server
├── genkit_ui_server.dart    # Alternative UI server implementation
└── telegram_bot.dart        # Telegram bot integration

lib/
├── bootstrap.dart           # Backend initialization
├── runtime/
│   └── genkit_runtime.dart  # Genkit + Vertex AI configuration
├── flows/
│   └── retail_assistant.dart # Main AI flow for retail operations
├── tools/
│   ├── inventory_tools.dart # Inventory management tools
│   └── billing_tools.dart   # Billing & invoice tools
├── models/
│   ├── cart_item.dart
│   ├── draft_invoice.dart
│   └── product.dart
└── bootstrap.dart           # Initialization module
```

## 🤖 AI Components

### Model
- **Provider:** Vertex AI (Google Cloud)
- **Model:** gemini-2.5-flash
- **Location:** us-central1 (configurable)

### Flow: retailAssistantFlow
An intelligent retail assistant that:
- Understands customer queries about products and inventory
- Routes requests to appropriate tools (checkInventory, createDraftInvoice)
- Generates natural language responses
- Maintains context-aware conversations

**Input:** String (customer message)
**Output:** String (AI response)

### Tools

#### 1. checkInventory
Check product availability and pricing
- Queries product database
- Returns stock levels and prices
- Integrated with Supabase backend

#### 2. createDraftInvoice
Create draft bills/invoices
- Accumulates cart items
- Calculates totals
- Generates invoice data
- Ready for payment processing

## 🔧 Configuration

### Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `GCLOUD_PROJECT` | Google Cloud Project ID | (Required) |
| `GOOGLE_CLOUD_PROJECT` | Alternative GCP Project ID | (Optional) |
| `GCLOUD_LOCATION` | Vertex AI location | us-central1 |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service account JSON | (Optional) |

### Credentials Resolution
The system resolves credentials in this order:
1. Platform environment variables (`GCLOUD_PROJECT`, `GOOGLE_CLOUD_PROJECT`)
2. `.env` file (`GCLOUD_PROJECT`, `GOOGLE_CLOUD_PROJECT`)
3. Service account file path from `GOOGLE_APPLICATION_CREDENTIALS`
4. Project ID extracted from service account JSON

## 📊 Running Different Servers

### Development Server (Recommended)
```bash
dart bin/genkit_dev.dart
```
- Includes Genkit reflection UI
- Port: 4000
- Best for development and testing

### Main Backend (No UI)
```bash
dart bin/dukansathi_new.dart
```
- Initializes backend only
- No HTTP server
- Use for headless operations or integration

### Custom Genkit UI
```bash
dart bin/genkit_ui.dart
```
- Custom HTML dashboard
- Port: 4000
- Flow executor with trace history

### JSON API Server
```bash
dart bin/genkit_server.dart
```
- HTTP REST endpoints
- Port: 3100
- Programmatic flow execution

## 🧪 Testing the System

### Via Web UI
1. Open http://localhost:4000
2. Enter a query in the flow executor
3. Examples:
   - "Check inventory for items"
   - "Create a bill with 5 items"
   - "What products do we have?"

### Via REST API
```bash
curl -X POST http://localhost:4000/api/runAction \
  -H "Content-Type: application/json" \
  -d '{
    "key": "/flow/retailAssistantFlow",
    "input": "Check inventory status"
  }'
```

### Via Telegram (when configured)
Send a message to the configured Telegram bot for instant AI responses.

## 💬 Integration Points

### Telegram Bot
The project includes TeleDart integration for Telegram messaging:
- Bot token configuration (in `.env`)
- Message forwarding to retailAssistantFlow
- Real-time response delivery

### Supabase Backend
Optional Supabase integration for:
- Product database
- Inventory management
- Customer data

## 📚 Dependencies

**Core:** Genkit 0.12.1, Vertex AI plugin 0.2.4
**Database:** Supabase 2.10.6
**Schema:** Schemantic 0.1.1
**Messaging:** TeleDart 0.6.1
**Utilities:** DotEnv 4.2.0, Freezed 3.2.5, JSON Serializable 6.13.1

## 🔐 Security Notes

- Never commit `.env` or credentials to version control
- Service account credentials should be restricted to necessary APIs
- Use environment variables in production
- Rotate credentials regularly

## 📝 Development Workflow

1. **Initialize:**
   ```bash
   dart pub get
   ```

2. **Configure:**
   - Set up `.env` with GCP credentials
   - Configure Supabase if using database features

3. **Run:**
   ```bash
   dart bin/genkit_dev.dart
   ```

4. **Test:**
   - Access UI at http://localhost:4000
   - Test flows and tools
   - Check logs for debugging

5. **Deploy:**
   - Use appropriate server binary (genkit_dev.dart for UI, or headless)
   - Set production environment variables
   - Configure firewall rules

## 🐛 Troubleshooting

### "Vertex AI requires GCLOUD_PROJECT..."
- Ensure `.env` file exists with `GCLOUD_PROJECT` set
- Or set `GCLOUD_PROJECT` environment variable
- Or provide service account JSON file path in `GOOGLE_APPLICATION_CREDENTIALS`

### Port 4000 already in use
```bash
lsof -i :4000  # Find process
kill -9 <PID>  # Kill process
```

### No response from Genkit
- Check internet connection
- Verify Vertex AI is enabled in GCP project
- Confirm credentials have required permissions
- Check logs for specific error messages

## 📞 Support

For issues or questions about Genkit integration:
- [Genkit Documentation](https://firebase.google.com/docs/genkit)
- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
- [Dart Documentation](https://dart.dev/guides)