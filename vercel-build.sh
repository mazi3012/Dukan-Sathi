#!/bin/bash
set -e

echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"

echo "Running pub get..."
flutter pub get

echo "Building web app..."
flutter build web --release --no-tree-shake-icons --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
