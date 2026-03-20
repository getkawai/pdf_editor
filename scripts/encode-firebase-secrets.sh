#!/bin/bash
# Script to encode Firebase config files to base64 for GitHub Secrets

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Firebase Config Encoder for GitHub Secrets ==="
echo ""

# Check if google-services.json exists
if [ -f "$PROJECT_ROOT/android/app/google-services.json" ]; then
    echo "✓ Found android/app/google-services.json"
    GOOGLE_SERVICES_B64=$(base64 -i "$PROJECT_ROOT/android/app/google-services.json" | tr -d '\n')
    echo "✓ Encoded google-services.json"
    echo ""
    echo "To set the secret, run:"
    echo "  gh secret set GOOGLE_SERVICES_JSON --body=\"$GOOGLE_SERVICES_B64\""
    echo ""
    echo "Or copy this base64 string:"
    echo "$GOOGLE_SERVICES_B64"
else
    echo "✗ android/app/google-services.json not found"
    echo "  Download from Firebase Console:"
    echo "  https://console.firebase.google.com/"
    echo ""
    exit 1
fi

# Check if GoogleService-Info.plist exists (for iOS)
if [ -f "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" ]; then
    echo "✓ Found ios/Runner/GoogleService-Info.plist"
    GOOGLE_SERVICE_B64=$(base64 -i "$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist" | tr -d '\n')
    echo "✓ Encoded GoogleService-Info.plist"
    echo ""
    echo "To set the secret, run:"
    echo "  gh secret set GOOGLE_SERVICE_INFO_PLIST --body=\"$GOOGLE_SERVICE_B64\""
    echo ""
    echo "Or copy this base64 string:"
    echo "$GOOGLE_SERVICE_B64"
else
    echo "ℹ ios/Runner/GoogleService-Info.plist not found (optional for iOS builds)"
fi

# Check if firebase_options.dart exists
if [ -f "$PROJECT_ROOT/lib/firebase_options.dart" ]; then
    echo ""
    echo "✓ Found lib/firebase_options.dart"
    FIREBASE_OPTIONS_B64=$(base64 -i "$PROJECT_ROOT/lib/firebase_options.dart" | tr -d '\n')
    echo "✓ Encoded firebase_options.dart"
    echo ""
    echo "To set the secret, run:"
    echo "  gh secret set FIREBASE_OPTIONS_DART --body=\"$FIREBASE_OPTIONS_B64\""
    echo ""
    echo "Or copy this base64 string:"
    echo "$FIREBASE_OPTIONS_B64"
else
    echo ""
    echo "ℹ lib/firebase_options.dart not found"
    echo "  Generate with: flutterfire configure"
fi
