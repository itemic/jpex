#!/bin/zsh
# Screenshots Time Machine on a private simulator: shoot.sh <out.png> <wait seconds> [launch args...]
set -e
NAME="TimeMachine-Test"
UDID=$(xcrun simctl list devices | grep "$NAME (" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
if [ -z "$UDID" ]; then
  UDID=$(xcrun simctl create "$NAME" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro com.apple.CoreSimulator.SimRuntime.iOS-27-0)
fi
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
APP=$(ls -td /Users/terran/Library/Bitrig/Users/24709/Builds/6c074621-5dbe-49d8-9479-77e952292e29/BuildProducts/*/jpex-simulator-iphone-Debug-*/Debug-iphonesimulator/jpex.app | head -1)
OUT=$1; WAIT=$2; shift 2
xcrun simctl install "$UDID" "$APP"
BUNDLE=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$APP/Info.plist")
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
xcrun simctl launch "$UDID" "$BUNDLE" -TimeMachineAutoOpen ${OPEN:-YES} "$@" >/dev/null
sleep "$WAIT"
xcrun simctl io "$UDID" screenshot "$OUT" >/dev/null 2>&1
echo "$UDID $OUT"
