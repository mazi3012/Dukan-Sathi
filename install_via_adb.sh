#!/bin/bash
# Script to install the Dukan Sathi release APK to the connected Android device via ADB.

set -e

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$APK_PATH" ]; then
    echo "❌ Error: Compiled APK not found at $APK_PATH"
    echo "Please build the APK first."
    exit 1
fi

echo "📱 Checking connected devices..."
DEVICES=$(adb devices | tail -n +2 | grep -v '^$')

if [ -z "$DEVICES" ]; then
    echo "❌ Error: No devices connected. Please connect your phone via USB and enable USB Debugging."
    exit 1
fi

if echo "$DEVICES" | grep -q "no permissions"; then
    echo "⚠️  USB Permission Error detected!"
    echo "To resolve this, please run the following command in your computer's terminal to start ADB as root:"
    echo ""
    echo "    sudo adb kill-server && sudo adb start-server"
    echo ""
    echo "Once you have run that command, run this script again."
    exit 1
fi

if echo "$DEVICES" | grep -q "unauthorized"; then
    echo "⚠️  Device is unauthorized! Please check your phone's screen and allow USB Debugging authorization."
    exit 1
fi

# Extract the device ID
DEVICE_ID=$(echo "$DEVICES" | head -n 1 | awk '{print $1}')
echo "✅ Found device: $DEVICE_ID"

echo "🚀 Installing $APK_PATH on device $DEVICE_ID..."
adb -s "$DEVICE_ID" install -r "$APK_PATH"

echo "🎉 Successfully updated and installed the application!"
