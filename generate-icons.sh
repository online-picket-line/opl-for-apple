#!/bin/bash
# Generate iOS app icons from opl.svg
# Uses ImageMagick to convert SVG to PNG at all required sizes

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SVG_PATH="$SCRIPT_DIR/opl.svg"
ICON_DIR="$SCRIPT_DIR/OnlinePicketLine/OnlinePicketLine/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SVG_PATH" ]; then
    echo "Error: opl.svg not found at $SVG_PATH"
    exit 1
fi

mkdir -p "$ICON_DIR"

echo "Generating iOS app icons from opl.svg..."

# iOS requires a single 1024x1024 icon (Xcode handles scaling)
# The SVG is 300x400, so we center it in a square with padding
# Using a light background that matches the opal edge color

# Generate the 1024x1024 icon
# 1. Render SVG at high res maintaining aspect ratio
# 2. Center on a square canvas with subtle background
convert -background "#f0f4f8" -density 600 "$SVG_PATH" \
    -resize 820x1024 \
    -gravity center \
    -extent 1024x1024 \
    -flatten \
    "$ICON_DIR/AppIcon-1024.png"

echo "  Generated AppIcon-1024.png (1024x1024)"

# Update Contents.json to reference the generated icon
cat > "$ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "  Updated Contents.json"
echo "Done! iOS app icon generated from opl.svg"
