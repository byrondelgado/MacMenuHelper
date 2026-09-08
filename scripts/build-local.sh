#!/bin/bash
set -euo pipefail

menuhelper_repo="$(cd "$(dirname "$0")/.." && pwd)"
menuhelper_build="${MENUHELPER_BUILD_DIR:-$HOME/Library/Caches/MacMenuHelper/DerivedData}"
menuhelper_destination="platform=macOS,arch=$(uname -m)"
menuhelper_architectures="$(uname -m)"
menuhelper_active_arch=YES
if [[ "${1:-}" == --universal && $# == 1 ]]; then
    menuhelper_destination="generic/platform=macOS"
    menuhelper_architectures="arm64 x86_64"
    menuhelper_active_arch=NO
elif [[ $# != 0 ]]; then
    printf 'Usage: %s [--universal]\n' "$0" >&2
    exit 2
fi

cd "$menuhelper_repo"
xcodebuild \
    -project MenuHelper.xcodeproj \
    -scheme MenuHelper \
    -configuration Release \
    -destination "$menuhelper_destination" \
    -derivedDataPath "$menuhelper_build" \
    -xcconfig Configs/Local.xcconfig \
    -disableAutomaticPackageResolution \
    ONLY_ACTIVE_ARCH="$menuhelper_active_arch" \
    ARCHS="$menuhelper_architectures" \
    build

menuhelper_app="$menuhelper_build/Build/Products/Release/MenuHelper.app"
# Keep required notices with the app even when it is moved out of the ZIP.
cmp "$menuhelper_repo/Licenses/AcknowKit-LICENSE.txt" "$menuhelper_build/SourcePackages/checkouts/AcknowKit/LICENSE.txt"
cmp "$menuhelper_repo/Licenses/swift-collections-LICENSE.txt" "$menuhelper_build/SourcePackages/checkouts/swift-collections/LICENSE.txt"
menuhelper_licences="$menuhelper_app/Contents/Resources/Licenses"
mkdir -p "$menuhelper_licences"
cp "$menuhelper_repo/LICENSE.txt" "$menuhelper_licences/LICENSE.txt"
cp "$menuhelper_repo/NOTICE.md" "$menuhelper_licences/NOTICE.md"
ditto "$menuhelper_repo/Licenses" "$menuhelper_licences/Licenses"
# Resource additions invalidate the containing app's previous signature.
codesign --force --sign - --options runtime --timestamp=none \
    --entitlements "$menuhelper_repo/Configs/Local.entitlements" "$menuhelper_app"
codesign --verify --deep --strict --verbose=2 "$menuhelper_app"
printf '\nBuilt local app: %s\n' "$menuhelper_app"
