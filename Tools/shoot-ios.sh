#!/bin/bash
# 見本を iOS シミュレータへ入れて撮る（DESIGN.md §7.1）。
#
#   Tools/shoot-ios.sh <出力.png> [light|dark]
#
# 装置は DEVICE で選ぶ。既定は起動中のもの。
#
# 一時の場所へ置くと消える。実際に消えて二度組み直したので、repo に置いた。
set -e
cd "$(dirname "$0")/.."

OUT=${1:?使い方: Tools/shoot-ios.sh <出力.png> [light|dark]}
APPEARANCE=${2:-light}
DEVICE=${DEVICE:-booted}
BUNDLE=dev.stemcell.example
STAGE=.build-ios/Example.app

SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
TARGET=arm64-apple-ios26.0-simulator

swift build --product Example --scratch-path .build-ios \
  -Xswiftc -sdk -Xswiftc "$SDK" -Xswiftc -target -Xswiftc "$TARGET" \
  -Xcc -isysroot -Xcc "$SDK" -Xcc -target -Xcc "$TARGET" \
  -Xlinker -syslibroot -Xlinker "$SDK" 2>&1 | grep -Ev '^\[|^Building|warning: using sysroot' || true

# 束ねる。SPM は実行ファイルしか作らないので、Info.plist を添えて .app の形にする。
mkdir -p "$STAGE"
cp .build-ios/arm64-apple-macosx/debug/Example "$STAGE/Example"
cat > "$STAGE/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Example</string>
  <key>CFBundleIdentifier</key><string>${BUNDLE}</string>
  <key>CFBundleName</key><string>Example</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.0.1</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSRequiresIPhoneOS</key><true/>
  <key>MinimumOSVersion</key><string>26.0</string>
  <!-- iPad を iPhone の互換で走らせない。1 だけだと横幅が狭いまま出る -->
  <key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array>
  <key>UISupportedInterfaceOrientations</key><array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>
  <key>UILaunchScreen</key><dict/>
</dict></plist>
PLIST

xcrun simctl ui "$DEVICE" appearance "$APPEARANCE" >/dev/null 2>&1 || true
xcrun simctl terminate "$DEVICE" "$BUNDLE" >/dev/null 2>&1 || true
xcrun simctl install "$DEVICE" "$STAGE"
xcrun simctl launch "$DEVICE" "$BUNDLE" >/dev/null
sleep 4
xcrun simctl io "$DEVICE" screenshot "$OUT"
