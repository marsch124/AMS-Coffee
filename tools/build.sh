#!/bin/bash
# Builds AMS Coffee for the iPhone simulator.   tools/build.sh [build|test]
#
# Two traps this script exists for:
#  1. Anything under ~/Documents picks up macOS extended attributes, and
#     codesign refuses them ("resource fork ... detritus not allowed").
#     So: clear them first — but never inside .git, whose objects are
#     read-only and would fail the sweep.
#  2. Derived data must land OUTSIDE ~/Documents for the same reason.
set -e
cd "$(dirname "$0")/.."
DD="${TMPDIR:-/tmp}/AMSCoffee-build"

find . -path ./.git -prune -o -print0 | xargs -0 xattr -c 2>/dev/null || true
xcodegen generate

xcodebuild \
  -project AMSCoffee.xcodeproj \
  -scheme AMSCoffee \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath "$DD" \
  "${1:-build}"

echo
echo "App: $DD/Build/Products/Debug-iphonesimulator/AMSCoffee.app"
