# 🛒 Dukan Sathi Pro — Premium AI POS & Retail Companion

[![Flutter](https://img.shields.io/badge/Flutter-v3.22+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Database-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Genkit](https://img.shields.io/badge/Google-Genkit-4285F4?logo=google&logoColor=white)](https://github.com/firebase/genkit)
[![Dart](https://img.shields.io/badge/Dart-Server-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Dukan Sathi Pro is a state-of-the-art, high-performance retail assistant and Point-of-Sale (POS) application built with **Flutter**, **Dart Server**, **Google Genkit**, and **Supabase**. It leverages a high-fidelity Glassmorphism UI, a hybrid offline-first architecture, and secure voice-activated artificial intelligence to deliver an unparalleled experience for retail shop owners.

---

## 🏛️ System & Workflow Architecture

The application operates on a robust **Hybrid Offline-First (POS Engine) and Strictly-Online (Voice AI)** architectural model built to handle high load (tested up to **100,000+ concurrent operations**). 

### 🔄 Architectural Data Flow Diagram

```mermaid
flowchart TB
    %% Nodes
    subgraph Client ["📱 Flutter POS Terminal (Offline-First)"]
        UI["Glassmorphic UI View"]
        Scan["Barcode Scanner / Input"]
        Repo["Product / Sale / Customer Repositories"]
        LocalDB[("Local SQFlite DB (SQLite)")]
        SyncQ["Sync Queue Manager"]
        ConnService["Connectivity Service"]
        IntExecutor["Intent Executor"]
        
        UI -->|Scans / Edits| Scan
        Scan -->|Optimistic Write| Repo
        Repo -->|Write & Aggregates| LocalDB
        Repo -->|Queue Change| SyncQ
        ConnService -->|Network Available| SyncQ
    end

    subgraph Backend ["⚡ Dart Backend & AI Orchestration"]
        GServer["Genkit Dart Server (shelf)"]
        RateLimit["API Rate Limiter"]
        GenkitFlow["AI Voice Billing Workflow"]
        GroqWhisper["Groq Whisper Audio Transcription"]
        GeminiReason["Gemini AI Reasoning Engine"]
    end

    subgraph Cloud [("☁️ Supabase Cloud (Multi-Tenant Postgres)")]
        SConnection["Supavisor Connection Pool (Port 6543)"]
        Tables[("Database Tables (RLS Secured)")]
        Indexes["High-Load Performance Indexes"]
    end

    %% Client Connection Flows
    SyncQ -->|Batch JSON Sync| SConnection
    SConnection --> Tables
    Tables --> Indexes

    %% AI Interaction Flows
    UI -->|Voice / Text Request| RateLimit
    RateLimit -->|Forward Request| GServer
    GServer -->|Audio Payload| GroqWhisper
    GroqWhisper -->|Text Script| GenkitFlow
    GenkitFlow -->|Contextual Prompts| GeminiReason
    GeminiReason -->|Structured Intent JSON| GServer
    GServer -->|Return Intent Payload| IntExecutor
    IntExecutor -->|Instant Execute & Commit| Repo
```

---

## ⚡ Core Systems & High-Scale Innovations

### 📦 1. Offline-First POS Engine
*   **SQFlite Caching**: All product search directories, customer list views, sales invoices, and analytics dashboards are executed offline-first using raw SQL query aggregates against a local SQLite database.
*   **Initial Cache Warmup**: During login, sign-up, or initial boot-up, the system fetches active tenant details from Supabase to automatically populate and warm up the local SQLite database.
*   **Optimistic UI Updates**: Inventory stock updates and billing actions trigger instant state updates (16ms frames) while persistence queues commit in the background, offering fluid feedback even under spotty network connections.

### 🌐 2. Resilient Connectivity & Syncing
*   **ConnectivityService**: A global reactive stream monitors cellular, WiFi, and offline network state changes.
*   **ConnectivityBanner & Sync Badge**: Includes a beautiful glassmorphic status bar at the top of the interface and a dynamic badge highlighting pending mutations.
*   **SyncManager Queue**: Safely queues local changes (`INSERT`, `UPDATE`, `DELETE`, `ADJUST_STOCK`) while offline. Upon reconnection, they are flushed in transaction blocks to Supabase.
*   **Relative Stock Adjustments**: Employs delta calculations (e.g., `stock_quantity = stock_quantity + delta`) inside backend sync blocks to eliminate race conditions and keep inventory consistent across multi-terminal setups.

### 🎙️ 3. Decoupled Voice AI Intent Engine
*   **AI Chat Screen Offline Guard**: An elegant glassmorphic alert blocks voice assistant initialization while offline, preventing client crashes and preserving system API limits.
*   **Structured Intent Outputs**: Rather than directly writing to the database, `genkit_server.dart` leverages Groq Whisper and Gemini models to reason and return structured JSON intents (`ADD_PRODUCT`, `CREATE_INVOICE`).
*   **Client-Side IntentExecutor**: Once received, the local client processes, parses, and executes these database writes on the device, maintaining a clear separation of concerns.

### 🔒 4. Production Hardening & High Scale
*   **100K Concurrent Load Testing**: Simulated 100,000 parallel operations committing to SQLite. Throughput peaked at **43,252.60 inserts/second**, validating system stability under enterprise-level load.
*   **Supabase Row-Level Security (RLS)**: Enforced strict database security policies on all active tables (including `products`, `draft_invoices`, and `expenses`), completely isolating tenant-specific data to authenticated owners matching their active `shop_id`.
*   **Supavisor Connection Pooling**: Database traffic utilizes port `6543` to handle high connection scaling gracefully.
*   **High-Performance Indexes**: Optimized lookup filters on frequently searched columns like `barcode`, `email`, and `google_id`.
*   **API Rate Limiting**: Embedded an IP-based memory bucket rate limiter in the server:
    *   *Groq Whisper transcription*: `10 req/min` limit.
    *   *AI Reasoning Flow*: `20 req/min` limit.
    *   *Standard server APIs*: `60 req/min` limit.

---

## 🛠️ Quick Start & Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Environment Configuration
Create a `.env` file in the root directory (make sure this is never committed):

```env
MODEL_ID=gemini-3.1-flash-lite-preview
GOOGLE_API_KEY=<your-google-genai-api-key>
GROQ_API_KEY=<your-groq-api-key>
SUPABASE_URL=<your-supabase-url>
SUPABASE_ANON_KEY=<your-supabase-anon-key>
```

### 3. Run the Backend Server
The server manages Whisper voice transcriptions, Genkit workflows, and PDF invoice generation.
```bash
dart run bin/genkit_server.dart
```
*(Runs on `http://localhost:3100` by default)*

### 4. Run the Load Benchmarks
```bash
/home/mazidur/flutter/bin/flutter test test/load_test_sync.dart
```

### 5. Launch the POS App
```bash
flutter run
```

---

## 🚀 Benchmark Performance Stats
Under our rigorous **100,000 concurrent sync operations** load test, Dukan Sathi Pro registered top-tier transactional marks:
*   **Payload Generation (100K JSONs)**: `1234 ms`
*   **Transaction DB Commit**: `2312 ms`
*   **Write Throughput**: 📈 **43,252.60 inserts per second**
*   **Local Read Iteration**: `9286 ms`
*   **Result**: ✅ **100% Passed (All records verified without memory leaks or race conditions)**

---

## 🔒 Security Policy
*   Row-Level Security (RLS) is active across all cloud tables.
*   Always load API credentials from `.env` to prevent credential exposure.
*   IP-based rate limits block API misuse and spam attempts.