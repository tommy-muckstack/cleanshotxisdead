#!/bin/bash
# write-plist.sh <Info.plist path> <version> <build>
set -euo pipefail
cat > "$1" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>CleanShotXIsDead</string>
    <key>CFBundleIdentifier</key><string>com.muckstack.cleanshotxisdead</string>
    <key>CFBundleName</key><string>CleanShotXIsDead</string>
    <key>CFBundleDisplayName</key><string>CleanShotXIsDead</string>
    <key>CFBundleShortVersionString</key><string>$2</string>
    <key>CFBundleVersion</key><string>$3</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>14.2</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>CFBundleDocumentTypes</key>
    <array><dict><key>CFBundleTypeName</key><string>Image</string><key>CFBundleTypeRole</key><string>Editor</string>
      <key>LSItemContentTypes</key><array><string>public.png</string><string>public.jpeg</string><string>public.tiff</string></array></dict></array>
    <key>NSScreenCaptureUsageDescription</key>
    <string>CleanShotXIsDead captures your screen for screenshots and recordings.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>CleanShotXIsDead records your microphone in screen recordings when you turn that on.</string>
    <key>NSAudioCaptureUsageDescription</key>
    <string>CleanShotXIsDead records computer audio in screen recordings when you turn that on.</string>
    <key>SUFeedURL</key>
    <string>https://ihvfw4x5q9iy9zx1.public.blob.vercel-storage.com/cleanshotxisdead-appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>5TLTqSxXFn7CqvHWR58jEy9uAKQdfbtHdZJNPeZw4kk=</string>
    <key>SUEnableAutomaticChecks</key><true/>
</dict>
</plist>
PLIST
