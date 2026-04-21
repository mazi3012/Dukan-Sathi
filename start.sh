#!/bin/bash
# Dukan Sathi Pro - App Starter Script

# Ensure Dart is in PATH
export PATH="$HOME/dart-sdk/bin:$PATH"

# Navigate to project root
cd "$(dirname "$0")"

echo "🚀 Starting Dukan Sathi Pro Services..."

# 1. Update dependencies
echo "📦 Updating dependencies..."
dart pub get

# 2. Kill existing processes if running
echo "🧹 Cleaning up old processes..."
[ -f genkit_dev.pid ] && kill $(cat genkit_dev.pid) 2>/dev/null
[ -f telegram_bot.pid ] && kill $(cat telegram_bot.pid) 2>/dev/null
fuser -k 4000/tcp 2>/dev/null

# 3. Start Genkit Dev Server
echo "📊 Starting Genkit Dev Server (Port 4000)..."
nohup dart bin/genkit_dev.dart > genkit_dev.log 2>&1 &
echo $! > genkit_dev.pid

# 4. Start Telegram Bot
echo "🤖 Starting Telegram Bot..."
nohup dart bin/telegram_bot.dart > telegram_bot.log 2>&1 &
echo $! > telegram_bot.pid

echo "✅ Services started!"
echo "   - Genkit UI: http://localhost:4000"
echo "   - Logs: genkit_dev.log, telegram_bot.log"
echo "   - PIDs: genkit_dev.pid, telegram_bot.pid"
