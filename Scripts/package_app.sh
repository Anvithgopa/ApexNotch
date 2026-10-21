#!/usr/bin/env bash
set -e

echo "=== Packaging ApexNotch.app ==="

APP_NAME="ApexNotch"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "• Building release executable..."
swift build -c release

RELEASE_BIN="$(swift build -c release --show-bin-path)/${APP_NAME}"

echo "• Creating .app bundle structure..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "• Installing binary..."
cp "${RELEASE_BIN}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "• Installing Info.plist and PkgInfo..."
cp "Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

if [ -f "Resources/AppIcon.icns" ]; then
    echo "• Installing AppIcon.icns..."
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

echo "• Applying code signature and entitlements..."
codesign --force --deep --sign - --entitlements Resources/ApexNotch.entitlements "${APP_DIR}"

echo "=== Successfully built and packaged ${APP_DIR} ==="
ls -ld "${APP_DIR}"
codesign -dvvv "${APP_DIR}" 2>&1 | grep "Signature=" || true
