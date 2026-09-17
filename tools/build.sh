#!/bin/bash
# Builds AMS Coffee for the iPhone simulator and runs the suite.
#
# Two things this script exists for:
#  1. Anything living under ~/Documents picks up macOS extended attributes,
#     and codesign refuses them ("resource fork ... detritus not allowed").
#     So: clear them first.
#  2. Derived data must land OUTSIDE ~/Documents for the same reason.
set -e
cd "$(dirname "$0")/.."
DD="${TMPDIR:-/tmp}/AMSCoffee-build"

xattr -cr .
xcodegen generate

xcodebuild \
  -project AMSCoffee.xcodeproj \
  -scheme AMSCoffee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath "$DD" \
  "${1:-build}"

echo
echo "App: $DD/Build/Products/Debug-iphonesimulator/AMSCoffee.app"
