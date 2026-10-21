#!/usr/bin/env bash
set -e

echo "=== Building macOS Installable Files for ApexNotch ==="

# 1. Ensure latest release build is packaged
./Scripts/package_app.sh

DMG_NAME="ApexNotch-1.0.0.dmg"
ZIP_NAME="ApexNotch-1.0.0.zip"
STAGING_DIR="dist_staging"

rm -rf "${STAGING_DIR}" "${DMG_NAME}" "${ZIP_NAME}"
mkdir -p "${STAGING_DIR}"

echo "• Preparing installer staging directory..."
cp -R "ApexNotch.app" "${STAGING_DIR}/"

# Add standard drag-and-drop Applications shortcut
ln -s /Applications "${STAGING_DIR}/Applications"

# Add README / Quick Instructions inside installer
cat << 'EOF' > "${STAGING_DIR}/INSTALL_INSTRUCTIONS.txt"
============================================================
           ApexNotch: Native macOS Super Utility
============================================================

Installation Instructions:
1. Drag "ApexNotch.app" into your "Applications" folder.
2. Open ApexNotch from Applications or Spotlight.
3. ApexNotch will appear in your screen notch and Menu Bar.
4. Press Option + Command + N (⌥⌘N) to toggle the Notch Hub anytime!

System Requirements:
- macOS 14.0 or later
- Apple Silicon or Intel Mac
============================================================
EOF

echo "• Generating ${DMG_NAME} disk image..."
hdiutil create \
    -volname "ApexNotch Installer" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_NAME}"

echo "• Generating ${ZIP_NAME} archive..."
ditto -c -k --keepParent "ApexNotch.app" "${ZIP_NAME}"

rm -rf "${STAGING_DIR}"

echo ""
echo "=== Installable files generated successfully! ==="
ls -lh "${DMG_NAME}" "${ZIP_NAME}"
