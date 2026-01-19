#!/bin/bash
# clickterm build-app.sh - Build the clickterm macOS app
# Usage: ./build-app.sh [release]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR/build"
APP_NAME="clickterm"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo -e "\033[0;34mBuilding $APP_NAME.app...\033[0m"

# Create build directory
mkdir -p "$BUILD_DIR"

# Create app bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources/scripts"

# Compile Swift
echo -e "\033[0;33mCompiling Swift...\033[0m"
SWIFT_FLAGS="-O"
if [[ "$1" == "release" ]]; then
    SWIFT_FLAGS="-O -whole-module-optimization"
fi

swiftc $SWIFT_FLAGS \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -framework Cocoa \
    "$SCRIPT_DIR/clickterm/main.swift"

# Copy Info.plist
cp "$SCRIPT_DIR/clickterm/Info.plist" "$APP_BUNDLE/Contents/"

# Bundle scripts
echo -e "\033[0;33mBundling scripts...\033[0m"
for script in dispatch.sh split.sh close.sh exit.sh launch.sh help-viewer.sh welcome.sh shell-init.sh; do
    if [[ -f "$PROJECT_ROOT/$script" ]]; then
        cp "$PROJECT_ROOT/$script" "$APP_BUNDLE/Contents/Resources/scripts/"
    fi
done

# Copy theme files
for theme in tmux-theme.conf theme.json; do
    if [[ -f "$PROJECT_ROOT/$theme" ]]; then
        cp "$PROJECT_ROOT/$theme" "$APP_BUNDLE/Contents/Resources/scripts/"
    fi
done

# Copy tmux.conf
if [[ -f "$PROJECT_ROOT/configs/tmux.conf" ]]; then
    cp "$PROJECT_ROOT/configs/tmux.conf" "$APP_BUNDLE/Contents/Resources/"
fi

# Generate app icon
if [[ -f "$PROJECT_ROOT/assets/clickterm.icns" ]]; then
    cp "$PROJECT_ROOT/assets/clickterm.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo -e "\033[0;32mIcon bundled.\033[0m"
elif [[ -d "$PROJECT_ROOT/assets/clickterm.iconset" ]] && ls "$PROJECT_ROOT/assets/clickterm.iconset"/*.png &>/dev/null; then
    iconutil -c icns -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" "$PROJECT_ROOT/assets/clickterm.iconset"
    echo -e "\033[0;32mIcon generated from iconset.\033[0m"
elif [[ -f "$PROJECT_ROOT/assets/logo.svg" ]] && command -v rsvg-convert &>/dev/null; then
    # Generate icon from SVG using rsvg-convert
    echo -e "\033[0;33mGenerating icon from SVG...\033[0m"
    ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"
    
    rsvg-convert -w 16 -h 16 "$PROJECT_ROOT/assets/logo.svg" -o "$ICONSET_DIR/icon_16x16.png"
    rsvg-convert -w 32 -h 32 "$PROJECT_ROOT/assets/logo.svg" -o "$ICONSET_DIR/icon_16x16@2x.png"
    rsvg-convert -w 32 -h 32 "$PROJECT_ROOT/assets/logo.svg" -o "$ICONSET_DIR/icon_32x32.png"
    rsvg-convert -w 64 -h 64 "$PROJECT_ROOT/assets/logo.svg" -o "$ICONSET_DIR/icon_32x32@2x.png"
    rsvg-convert -w 128 -h 128 "$PROJECT_ROOT/assets/logo.svg" -o "$ICONSET_DIR/icon_128x128.png"
    rsvg-convert -w 256 -h 256 "$PROJECT_ROOT/assets/logo.svg" -o "$ICONSET_DIR/icon_128x128@2x.png"
    rsvg-convert -w 256 -h 256 "$PROJECT_ROOT/assets/logo.svg" -o "$ICONSET_DIR/icon_256x256.png"
    rsvg-convert -w 512 -h 512 "$PROJECT_ROOT/assets/logo.svg" -o "$ICONSET_DIR/icon_256x256@2x.png"
    rsvg-convert -w 512 -h 512 "$PROJECT_ROOT/assets/logo.svg" -o "$ICONSET_DIR/icon_512x512.png"
    rsvg-convert -w 1024 -h 1024 "$PROJECT_ROOT/assets/logo.svg" -o "$ICONSET_DIR/icon_512x512@2x.png"
    
    iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    rm -rf "$ICONSET_DIR"
    echo -e "\033[0;32mIcon generated from SVG.\033[0m"
else
    echo -e "\033[0;33mNo icon found, using system default.\033[0m"
fi

# Sign the app (ad-hoc for local development)
echo -e "\033[0;33mSigning app (ad-hoc)...\033[0m"
codesign --force --deep --sign - "$APP_BUNDLE"

echo -e "\033[0;32mBuild complete!\033[0m"
echo "App bundle: \033[0;34m$APP_BUNDLE\033[0m"
echo ""
echo "To install:"
echo "  cp -r \"$APP_BUNDLE\" /Applications/"
echo ""
echo "To run:"
echo "  open \"$APP_BUNDLE\""
