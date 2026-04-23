#!/bin/bash
# Dukan Sathi Pro - App Starter Script

# Ensure Dart is in PATH
for dart_dir in "/workspaces/dukansathi-new/.tooling/dart-sdk/bin" "$HOME/dart-sdk/bin" "/tmp/dart-sdk/bin" "/opt/flutter/bin/cache/dart-sdk/bin"; do
	if [ -x "$dart_dir/dart" ]; then
		export PATH="$dart_dir:$PATH"
		break
	fi
done

# Navigate to project root
cd "$(dirname "$0")"

echo "🚀 Starting Dukan Sathi Pro Services..."

# 1. Update dependencies
echo "📦 Updating dependencies..."
dart pub get

# 2. Kill existing processes if running
echo "🧹 Cleaning up old processes..."
[ -f genkit_dev.pid ] && kill $(cat genkit_dev.pid) 2>/dev/null
[ -f genkit_server.pid ] && kill $(cat genkit_server.pid) 2>/dev/null
[ -f telegram_bot.pid ] && kill $(cat telegram_bot.pid) 2>/dev/null
[ -f flutter_admin.pid ] && kill $(cat flutter_admin.pid) 2>/dev/null
fuser -k 4000/tcp 2>/dev/null
fuser -k 3100/tcp 2>/dev/null
fuser -k 5000/tcp 2>/dev/null

# 3. Start Genkit UI Server (Port 4000)
echo "📊 Starting Genkit UI Server (Port 4000)..."
if command -v stdbuf >/dev/null 2>&1; then
	nohup stdbuf -oL -eL dart bin/genkit_ui.dart > genkit_dev.log 2>&1 &
else
	nohup dart bin/genkit_ui.dart > genkit_dev.log 2>&1 &
fi
echo $! > genkit_dev.pid

# 4. Start Genkit Server (Port 3100)
echo "🌐 Starting API & Admin Dashboard (Port 3100)..."
if command -v stdbuf >/dev/null 2>&1; then
	nohup stdbuf -oL -eL dart bin/genkit_server.dart > genkit_server.log 2>&1 &
else
	nohup dart bin/genkit_server.dart > genkit_server.log 2>&1 &
fi
echo $! > genkit_server.pid

# 5. Start Telegram Bot
echo "🤖 Starting Telegram Bot..."
if command -v stdbuf >/dev/null 2>&1; then
	nohup stdbuf -oL -eL dart bin/telegram_bot.dart > telegram_bot.log 2>&1 &
else
	nohup dart bin/telegram_bot.dart > telegram_bot.log 2>&1 &
fi
echo $! > telegram_bot.pid

# 6. Start Flutter Admin Dashboard (Port 5000)
echo "📱 Starting Flutter Admin Dashboard (Port 5000)..."
if [ -d "flutter_admin_dashboard/build/web" ]; then
	nohup python3 flutter_admin_dashboard/serve_with_cors.py > flutter_admin.log 2>&1 &
	echo $! > flutter_admin.pid
else
	echo "⚠️  Flutter web build not found, skipping..."
fi

echo "✅ Services started!"
echo "   - Genkit UI: http://localhost:4000"
echo "   - API/Admin: http://localhost:3100"
echo "   - Flutter Dashboard: http://localhost:5000"
echo "   - Logs: genkit_dev.log, genkit_server.log, telegram_bot.log, flutter_admin.log"
echo "   - PIDs: genkit_dev.pid, genkit_server.pid, telegram_bot.pid, flutter_admin.pid"
