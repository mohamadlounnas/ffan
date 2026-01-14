#!/bin/bash
# ffan Quick Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/mohamadlounnas/ffan/main/scripts/install.sh | bash

set -e

echo "🌬️  ffan Installation"
echo "====================="
echo ""

# Determine latest version from GitHub API
LATEST_VERSION=$(curl -s https://api.github.com/repos/mohamadlounnas/ffan/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_VERSION" ]; then
    echo "❌ Failed to fetch latest version"
    exit 1
fi

echo "📥 Downloading ffan $LATEST_VERSION..."
curl -L "https://github.com/mohamadlounnas/ffan/releases/download/$LATEST_VERSION/ffan-$LATEST_VERSION-macos.zip" -o /tmp/ffan.zip

echo "📦 Extracting..."
cd /tmp
unzip -q ffan.zip

echo "🔄 Installing to /Applications..."
rm -rf /Applications/ffan.app
mv ffan.app /Applications/

echo "🔧 Installing helper tool (requires password)..."
sudo cp /Applications/ffan.app/Contents/Resources/smc-helper /usr/local/bin/
sudo chown root:wheel /usr/local/bin/smc-helper
sudo chmod 4755 /usr/local/bin/smc-helper

echo "🧹 Cleaning up..."
rm /tmp/ffan.zip

echo ""
echo "✅ Installation complete!"
echo "🚀 Launch ffan from your Applications folder"
echo ""
echo "   Or run: open /Applications/ffan.app"
