#!/bin/bash
# Create GitHub Release using GitHub CLI
# Prerequisites: brew install gh
# Usage: ./scripts/create-release.sh [version]

set -e

VERSION=${1:-"1.0.0"}
REPO="USERNAME/ffan"  # Replace with your GitHub username
TAG="v${VERSION}"

echo "🚀 Creating GitHub Release: $TAG"

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found!"
    echo "Install with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "🔐 Please authenticate with GitHub:"
    gh auth login
fi

# Create release notes
RELEASE_NOTES="releases/RELEASE_NOTES_${VERSION}.md"
mkdir -p releases

cat > "$RELEASE_NOTES" << 'EOF'
## 🌬️ ffan v${VERSION} - macOS Fan Control

### ✨ Features
- 🌡️ Real-time CPU/GPU temperature monitoring
- 💨 Manual and automatic fan speed control  
- 📊 Animated menu bar icon showing fan activity
- 🚀 Launch at login support
- 🎨 Beautiful liquid glass UI design
- 🔒 Privacy-first: all processing happens locally

### 📦 Installation

#### Method 1: Quick Install (Recommended)
```bash
# Download and install
curl -L https://github.com/${REPO}/releases/download/${TAG}/ffan-v${VERSION}-macos.zip -o ffan.zip
unzip ffan.zip
mv ffan.app /Applications/
rm ffan.zip

# Install SMC helper for fan control
cd /Applications/ffan.app/Contents/Resources/tools/smc-helper
sudo make install
```

#### Method 2: Manual Install
1. Download **ffan-v${VERSION}-macos.zip** or **ffan-v${VERSION}-macos.dmg**
2. Unzip/Mount and move `ffan.app` to `/Applications`
3. **First launch**: Right-click → Open (to bypass Gatekeeper)
4. **Enable fan control**: 
   ```bash
   cd /Applications/ffan.app/Contents/Resources/tools/smc-helper
   sudo ./install.sh
   ```

### 📋 Requirements
- macOS 11.0 (Big Sur) or later
- Intel or Apple Silicon Mac
- Admin privileges for fan control

### 🔐 Verification
```bash
# Verify download integrity (optional)
shasum -a 256 ffan-v${VERSION}-macos.zip
# Should match: [CHECKSUM_HERE]
```

### ⚠️ Important Notes
- **Fan control requires root access** to write to SMC (System Management Controller)
- Temperature reading works without special privileges
- First launch may show Gatekeeper warning - use Right-click → Open

### 🐛 Known Issues
- Some Apple Silicon Macs have limited SMC sensor exposure
- External GPU temperature monitoring not yet supported
- See full list: [Issues](https://github.com/${REPO}/issues)

### 📚 Documentation
- [User Guide](https://github.com/${REPO}/blob/main/docs/README.md)
- [FAQ](https://github.com/${REPO}/blob/main/docs/README.md#-faq)
- [Troubleshooting](https://github.com/${REPO}/issues)

### 🤝 Contributing
We welcome contributions! Please see our [Contributing Guide](https://github.com/${REPO}/blob/main/docs/README.md#-contributing).

### 📄 License
MIT License - see [LICENSE](https://github.com/${REPO}/blob/main/LICENSE)

---

**Full Changelog**: https://github.com/${REPO}/compare/v0.9.0...${TAG}

**⭐ If you find ffan useful, please star the repo!**
EOF

# Replace template variables
sed -i '' "s/\${VERSION}/$VERSION/g" "$RELEASE_NOTES"
sed -i '' "s/\${TAG}/$TAG/g" "$RELEASE_NOTES"
sed -i '' "s/\${REPO}/$REPO/g" "$RELEASE_NOTES"

# Calculate and insert checksum
if [ -f "releases/ffan-v${VERSION}-macos.zip" ]; then
    CHECKSUM=$(shasum -a 256 "releases/ffan-v${VERSION}-macos.zip" | awk '{print $1}')
    sed -i '' "s/\[CHECKSUM_HERE\]/$CHECKSUM/g" "$RELEASE_NOTES"
fi

echo "📝 Release notes created: $RELEASE_NOTES"

# Create the release
echo "🎉 Creating release on GitHub..."
gh release create "$TAG" \
    --repo "$REPO" \
    --title "ffan v${VERSION} - macOS Fan Control" \
    --notes-file "$RELEASE_NOTES" \
    releases/ffan-v${VERSION}-macos.zip* \
    releases/ffan-v${VERSION}-macos.dmg* 2>/dev/null || true

echo ""
echo "✅ Release created successfully!"
echo "🔗 View at: https://github.com/${REPO}/releases/tag/${TAG}"
echo ""
echo "📤 Users can now download directly from:"
echo "   https://github.com/${REPO}/releases/latest/download/ffan-v${VERSION}-macos.zip"
