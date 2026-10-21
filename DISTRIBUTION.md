# ApexNotch: Distribution & Notarization Guide

This document describes how to sign, notarize, package, and distribute **ApexNotch** outside the Mac App Store as a verified, Gatekeeper-approved macOS application.

---

## 🔑 1. Prerequisites for Distribution

1. **Apple Developer Account:** Active membership in the Apple Developer Program.
2. **Developer ID Application Certificate:** Installed in your macOS Keychain.
3. **App-Specific Password or App Store Connect API Key:** For notarization submission.

---

## ✍️ 2. Production Code Signing

To sign `ApexNotch.app` with your Developer ID Application certificate and Hardened Runtime:

```bash
# 1. Build optimized release binary
swift build -c release

# 2. Package the .app bundle
./Scripts/package_app.sh

# 3. Sign with Developer ID Application certificate
IDENTITY="Developer ID Application: Your Name (TEAM_ID)"

codesign --force --deep --options runtime \
    --sign "$IDENTITY" \
    --entitlements Resources/ApexNotch.entitlements \
    ApexNotch.app

# 4. Verify signature
codesign --verify --deep --strict --verbose=2 ApexNotch.app
spctl --assess --type execute --verbose ApexNotch.app
```

---

## 🛡️ 3. Apple Notarization with `notarytool`

macOS Gatekeeper requires all distributed apps outside the Mac App Store to be notarized by Apple.

### Step 1: Store Notarization Credentials
```bash
xcrun notarytool store-credentials "apexnotch-notary" \
    --apple-id "your-apple-id@example.com" \
    --team-id "TEAM_ID" \
    --password "abcd-efgh-ijkl-mnop"
```

### Step 2: Compress Bundle for Submission
```bash
ditto -c -k --keepParent ApexNotch.app ApexNotch.zip
```

### Step 3: Submit for Notarization
```bash
xcrun notarytool submit ApexNotch.zip \
    --keychain-profile "apexnotch-notary" \
    --wait
```

### Step 4: Staple the Notarization Ticket
Once approved, staple the ticket to the app bundle so it can launch offline without Gatekeeper prompts:
```bash
xcrun stapler staple ApexNotch.app
```

---

## 💿 4. DMG Disk Image Packaging

To create a drag-and-drop DMG installer:

```bash
mkdir -p dist_dmg
cp -R ApexNotch.app dist_dmg/
ln -s /Applications dist_dmg/Applications

hdiutil create -volname "ApexNotch Installer" \
    -srcfolder dist_dmg \
    -ov -format UDZO \
    ApexNotch-1.0.0.dmg

# Sign the DMG installer itself
codesign --sign "$IDENTITY" ApexNotch-1.0.0.dmg
xcrun notarytool submit ApexNotch-1.0.0.dmg --keychain-profile "apexnotch-notary" --wait
xcrun stapler staple ApexNotch-1.0.0.dmg
```

Users can now download `ApexNotch-1.0.0.dmg`, drag `ApexNotch.app` into `/Applications`, and launch it without security warnings.
