#!/bin/zsh
# Like shoot.sh, on a private iPad simulator in landscape.
NAME="TimeMachine-Test-iPad"
UDID=$(xcrun simctl list devices | grep "$NAME (" | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
[ -z "$UDID" ] && UDID=$(xcrun simctl create "$NAME" "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M5-12GB" com.apple.CoreSimulator.SimRuntime.iOS-27-0)
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
APP=$(ls -td /Users/terran/Library/Bitrig/Users/24709/Builds/6c074621-5dbe-49d8-9479-77e952292e29/BuildProducts/*/jpex-simulator-iphone-Debug-*/Debug-iphonesimulator/jpex.app | head -1)
OUT=$1; WAIT=$2; shift 2
xcrun simctl install "$UDID" "$APP"
BUNDLE=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$APP/Info.plist")
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1
xcrun simctl launch "$UDID" "$BUNDLE" -TimeMachineAutoOpen ${OPEN:-YES} "$@" >/dev/null
sleep "$WAIT"
xcrun simctl io "$UDID" screenshot "$OUT" >/dev/null 2>&1
echo "$UDID"
