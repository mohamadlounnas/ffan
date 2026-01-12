#!/bin/bash
# SMC Helper Installation Script
# This installs smc-helper with root privileges so no password is needed afterwards

HELPER_NAME="smc-helper"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_PATH="$SCRIPT_DIR/$HELPER_NAME"
INSTALL_PATH="/usr/local/bin/$HELPER_NAME"

echo "🔧 SMC Helper Installer"
echo "======================"
echo ""

# Check if source exists
if [ ! -f "$SOURCE_PATH" ]; then
    echo "❌ Error: $SOURCE_PATH not found"
    echo "   Please build smc-helper first: make"
    exit 1
fi

echo "📦 Installing $HELPER_NAME to $INSTALL_PATH..."
echo "   This requires administrator privileges (one time only)."
echo ""

# Copy to /usr/local/bin with root ownership and setuid
sudo cp "$SOURCE_PATH" "$INSTALL_PATH" && \
sudo chown root:wheel "$INSTALL_PATH" && \
sudo chmod 4755 "$INSTALL_PATH"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "   The helper is now installed at: $INSTALL_PATH"
    echo "   Owner: root, Permissions: -rwsr-xr-x (setuid)"
    echo ""
    echo "   You will NOT need to enter your password again"
    echo "   when controlling fan speeds."
    echo ""
    ls -la "$INSTALL_PATH"
else
    echo ""
    echo "❌ Installation failed"
    exit 1
fi
