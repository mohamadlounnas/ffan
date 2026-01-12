#!/bin/bash
# Build ffan for release distribution
# Usage: ./scripts/build-release.sh [version]

set -e

VERSION=${1:-"1.0.0"}
APP_NAME="ffan"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/release-build"
RELEASE_DIR="$PROJECT_DIR/releases"

echo "🔨 Building $APP_NAME v$VERSION..."

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

# Build the app
cd "$PROJECT_DIR"
xcodebuild \
    -project fan.xcodeproj \
    -scheme ffan \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    clean build \
    | grep -E "^(Build|Export)" || true

# Find the built app
BUILT_APP=$(find "$BUILD_DIR" -name "${APP_NAME}.app" -type d | head -n 1)

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Error: Built app not found!"
    exit 1
fi

echo "✅ Built: $BUILT_APP"

# Copy to release directory
RELEASE_APP="$RELEASE_DIR/${APP_NAME}.app"
rm -rf "$RELEASE_APP"
cp -R "$BUILT_APP" "$RELEASE_APP"

# Remove code signature (optional - allows users to run without warnings)
echo "🔓 Removing code signature..."
codesign --remove-signature "$RELEASE_APP" 2>/dev/null || true

# Create distributable archive
ARCHIVE_NAME="${APP_NAME}-v${VERSION}-macos"
cd "$RELEASE_DIR"

echo "📦 Creating archive: ${ARCHIVE_NAME}.zip"
zip -r "${ARCHIVE_NAME}.zip" "${APP_NAME}.app" -x "*.DS_Store"

# Calculate SHA256
echo "🔐 Calculating checksums..."
shasum -a 256 "${ARCHIVE_NAME}.zip" > "${ARCHIVE_NAME}.zip.sha256"

# Create DMG (optional - more professional)
echo "💿 Creating DMG..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "${APP_NAME}.app" \
    -ov -format UDZO \
    "${ARCHIVE_NAME}.dmg"

shasum -a 256 "${ARCHIVE_NAME}.dmg" > "${ARCHIVE_NAME}.dmg.sha256"

echo ""
echo "✨ Release build complete!"
echo "📍 Location: $RELEASE_DIR"
echo ""
echo "📦 Files created:"
ls -lh "$RELEASE_DIR" | grep -E "${ARCHIVE_NAME}\.(zip|dmg|sha256)"
echo ""
echo "🚀 Ready to upload to GitHub Releases!"
echo ""
echo "Next steps:"
echo "1. Create a new release on GitHub"
echo "2. Tag: v${VERSION}"
echo "3. Upload: ${ARCHIVE_NAME}.zip and ${ARCHIVE_NAME}.dmg"
echo "4. Include SHA256 checksums in release notes"
