#!/usr/bin/env bash
# OPL for Apple - Test Runner
# Runs unit tests via xcodebuild

set -euo pipefail

cd "$(dirname "$0")"

echo "========================================="
echo "  OPL for Apple — Test Suite"
echo "========================================="
echo ""

# Check for xcodebuild
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "❌ xcodebuild not found. This must be run on macOS with Xcode installed." >&2
    exit 127
fi

PROJECT_DIR="OnlinePicketLine"
PROJECT_FILE="$PROJECT_DIR/OnlinePicketLine.xcodeproj"

if [[ ! -d "$PROJECT_FILE" ]]; then
    echo "❌ Xcode project not found at $PROJECT_FILE" >&2
    exit 1
fi

echo "Running unit tests..."
echo ""

xcodebuild test \
    -project "$PROJECT_FILE" \
    -scheme OnlinePicketLine \
    -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
    -quiet \
    2>&1

echo ""
echo "========================================="
echo "  Tests complete!"
echo "========================================="
