# Dukan Sathi Pro - AI Retail Assistant

An AI-powered shop companion and POS system built with Flutter, Dart, Genkit, Groq, and Supabase. Features a cutting-edge Glassmorphism UI and voice-activated intelligent billing.

## 🚀 Current Architecture

The application is currently operating as a cloud-first application:
- **Frontend (Flutter):** Provides Dashboard, Inventory, Customers, Billing, and AI Chat interfaces. Currently reads/writes directly from Supabase.
- **Backend (Dart):** Powered by `bin/genkit_server.dart`. Handles Genkit workflows, tools integration, Groq Whisper transcription, and PDF invoice generation.
- **Database (Supabase):** PostgreSQL database managing shops, products, customers, sales, and draft invoices with multi-tenant architecture (RLS).
- **AI Integration:** Uses Google GenAI for reasoning and Groq Whisper for fast voice transcription.

## 🗺️ Scalability Roadmap (Upcoming)

We are transitioning to a **Hybrid Offline-First** architecture to support 50,000+ active users:

1. **Offline-First POS Engine:** 
   - Local Isar/SQLite caching for products, customers, and sales.
   - Background SyncManager to batch updates to Supabase when online.
   - Optimistic UI updates.
2. **Online-Only AI Lane:**
   - AI Voice Chat remains strictly online.
   - AI intents will return structured JSON, executing actions locally rather than server-side.
3. **Database Hardening:**
   - Transition to explicit `SELECT` columns (removing `SELECT *`).
   - Implementation of Supavisor connection pooling.
   - Robust indexing on `shop_id`, `owner_id`, `barcode`, etc.

*For the complete detailed roadmap, check the `scalability_roadmap.md` artifact in the knowledge base.*

## 💻 Tech Stack

- **App:** Flutter, Riverpod, Google Fonts, Iconsax
- **Backend Services:** Dart, Genkit, shelf, http
- **AI Models:** Gemini (via Genkit), Whisper Large v3 (via Groq)
- **Database:** Supabase (Postgres)
- **Hosting:** Vercel (API Proxies), Render (Dart Server)

## 🛠️ Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Environment Configuration
Create a `.env` file in the root directory (never commit this file):

```env
MODEL_ID=gemini-3.1-flash-lite-preview
GOOGLE_API_KEY=<your-google-genai-api-key>
GROQ_API_KEY=<your-groq-api-key>
SUPABASE_URL=<your-supabase-url>
SUPABASE_ANON_KEY=<your-supabase-anon-key>
```

### 3. Run the Backend Server
The server handles AI requests, transcription, and admin APIs.
```bash
dart run bin/genkit_server.dart
```
*(Runs on port 3100 by default)*

### 4. Run the Flutter App
```bash
flutter run
```

## 🔒 Security Notes
- Ensure `.env` and `.secrets/` are gitignored.
- Row Level Security (RLS) is heavily used to isolate shop data.
- Avoid committing any API keys or tokens.

## 🧹 Recent Updates
- Massive repository cleanup (removed old unused docs, separate admin dashboard, and scripts).
- Re-architected project for upcoming scalability phase.
- Voice TTS integration using `flutter_tts`.