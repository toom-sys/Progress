#!/bin/bash

# Script to generate all required icon sizes from a master 1024x1024 image
# Usage: ./generate_icon_sizes.sh path/to/ProgressIcon-1024.png

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-1024x1024-icon>"
    echo "Example: $0 ProgressIcon-1024.png"
    exit 1
fi

MASTER_ICON="$1"
ICON_DIR="/Users/tom/Documents/Projects/TrackMyProgress/Progress/Progress/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$MASTER_ICON" ]; then
    echo "Error: Master icon file not found: $MASTER_ICON"
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "ImageMagick is required but not installed."
    echo "Install with: brew install imagemagick"
    exit 1
fi

echo "Generating icon sizes from: $MASTER_ICON"
echo "Output directory: $ICON_DIR"

# Extract base name without extension
BASE_NAME=$(basename "$MASTER_ICON" .png)

# Generate Mac icon sizes
convert "$MASTER_ICON" -resize 16x16 "$ICON_DIR/${BASE_NAME%%-1024}-16.png"
convert "$MASTER_ICON" -resize 32x32 "$ICON_DIR/${BASE_NAME%%-1024}-16@2x.png"
convert "$MASTER_ICON" -resize 32x32 "$ICON_DIR/${BASE_NAME%%-1024}-32.png"
convert "$MASTER_ICON" -resize 64x64 "$ICON_DIR/${BASE_NAME%%-1024}-32@2x.png"
convert "$MASTER_ICON" -resize 128x128 "$ICON_DIR/${BASE_NAME%%-1024}-128.png"
convert "$MASTER_ICON" -resize 256x256 "$ICON_DIR/${BASE_NAME%%-1024}-128@2x.png"
convert "$MASTER_ICON" -resize 256x256 "$ICON_DIR/${BASE_NAME%%-1024}-256.png"
convert "$MASTER_ICON" -resize 512x512 "$ICON_DIR/${BASE_NAME%%-1024}-256@2x.png"
convert "$MASTER_ICON" -resize 512x512 "$ICON_DIR/${BASE_NAME%%-1024}-512.png"
convert "$MASTER_ICON" -resize 1024x1024 "$ICON_DIR/${BASE_NAME%%-1024}-512@2x.png"

# Copy the master file to the icon directory
cp "$MASTER_ICON" "$ICON_DIR/"

echo "✅ Icon generation complete!"
echo ""
echo "Generated files:"
ls -la "$ICON_DIR"/*.png
