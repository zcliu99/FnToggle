#!/bin/bash
# Builds FnToggle.app (menu bar app, no Dock icon). Requires Xcode command line tools.
set -euo pipefail
cd "$(dirname "$0")"

APP="FnToggle.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

swiftc -O main.swift -o "$APP/Contents/MacOS/FnToggle" -framework Cocoa -framework IOKit

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>FnToggle</string>
  <key>CFBundleIdentifier</key><string>local.fntoggle</string>
  <key>CFBundleExecutable</key><string>FnToggle</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSUIElement</key><true/>
</dict></plist>
EOF

codesign --force --sign - "$APP"
echo "Built $APP — run: open $APP   (or drag to /Applications)"
