#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if [[ -n "${RESULT_BUNDLE_PATH:-}" ]]; then
  result_bundle_path="$RESULT_BUNDLE_PATH"
else
  result_directory="$(mktemp -d "${TMPDIR:-/tmp}/tether-ci.XXXXXX")"
  result_bundle_path="$result_directory/TetherCI.xcresult"
fi

cd "$REPO_ROOT"

echo "Xcode result bundle: $result_bundle_path"

xcodebuild clean test \
  -project Tether.xcodeproj \
  -scheme Tether \
  -destination "platform=iOS Simulator,OS=26.5,name=iPhone 17 Pro" \
  -resultBundlePath "$result_bundle_path" \
  CODE_SIGNING_ALLOWED=NO
