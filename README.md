# Dukan Sathi Pro - AI Retail Assistant

An AI-powered shop companion and POS system built with Flutter, Dart, Genkit, Groq, and Supabase. Features a cutting-edge Glassmorphism UI and voice-activated intelligent billing.

## 🚀 Current Architecture

The application operates on a robust **Hybrid Offline-First (POS) and Strictly-Online (Voice AI)** architecture to support 50,000+ active users:
- **Offline-First POS Engine (Flutter & SQFlite):** All client-side product lookups, customer profiles, sales, and dashboard metrics operate completely offline-first using a local database cache with background auto-sync to Supabase.
- **Strictly-Online Voice AI (Genkit & Groq):** AI Chat features remain strictly online, hitting the backend server to transcribe audio (Groq Whisper) and reason through actions.
- **Automatic Sync Manager (`SyncManager`):** Tracks local database operations, queues mutations (INSERT, UPDATE, DELETE, ADJUST_STOCK), and flushes them to the cloud automatically in batches when network becomes available.
- **Initial Cache Warmup:** Seamlessly warms up the local SQFlite database with primary shop details right after login, signup, or app boot-up.
- **Conflict Policy:** Utilizes relative adjustments (`stock_quantity = stock_quantity + delta`) in background syncs and cloud RPCs instead of absolute updates to prevent overriding modifications from other terminals or voice commands.
- **Backend (Dart):** Powered by `bin/genkit_server.dart`. Handles Genkit workflows, tools integration, Groq Whisper transcription, and PDF invoice generation.
- **Database (Supabase):** PostgreSQL database managing shops, products, customers, sales, and draft invoices with multi-tenant architecture (RLS).
- **AI Integration:** Uses Google GenAI for reasoning and Groq Whisper for fast voice transcription.

## 🗺️ Scalability Roadmap Status

We have successfully completed **Phase 0 (Foundation Prep)** and **Phase 1 (Offline-First POS Engine)**! 

### Completed Milestones:
- ✅ Add local database schemas (SQLite / SQFlite) and initialization services.
- ✅ Implement global connectivity monitor (`ConnectivityService`).
- ✅ Build dynamic background queue sync service (`SyncManager`).
- ✅ Refactor Products, Sales, and Customers repositories to run offline-first.
- ✅ Refactor Dashboard page to use instant local SQL aggregations.
- ✅ Build initial cache warmup on login & onboarding.
- ✅ Enforce relative conflict-free updates for inventory stock level changes.

### Upcoming Milestones:
1. **Phase 2: Intent-Driven AI Refactor:** Decouple Genkit backend writes by outputting structured JSON intents which Flutter parses and executes locally.
2. **Phase 3: Performance & Scale Hardening:** Transition to explicit columns (remove `SELECT *`), paginated cloud views, and Supavisor connection pooling.
3. **Phase 4: Connectivity & UX Polish:** Add global offline banners, fallback error screens, and barcode scanner integration.
4. **Phase 5: Production Readiness:** Conduct load testing, hard RLS constraints, API rate limiting, and CI/CD pipelines.

*For the complete detailed roadmap, check the `scalability_roadmap.md` artifact.*

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