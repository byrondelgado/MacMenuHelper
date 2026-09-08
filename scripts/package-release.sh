#!/bin/bash
set -euo pipefail

menuhelper_repo="$(cd "$(dirname "$0")/.." && pwd)"
menuhelper_build="${MENUHELPER_BUILD_DIR:-$HOME/Library/Caches/MacMenuHelper/DerivedData}"
menuhelper_dist="${MENUHELPER_DIST_DIR:-$menuhelper_repo/dist}"

"$menuhelper_repo/scripts/build-local.sh" --universal
menuhelper_app="$menuhelper_build/Build/Products/Release/MenuHelper.app"
menuhelper_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$menuhelper_app/Contents/Info.plist")
menuhelper_name="FinderMenuTools-$menuhelper_version-macos-universal"
menuhelper_stage=$(mktemp -d "${TMPDIR:-/tmp}/macmenuhelper-release.XXXXXX")
trap 'rm -r "$menuhelper_stage"' EXIT

for menuhelper_binary in \
    "$menuhelper_app/Contents/MacOS/MenuHelper" \
    "$menuhelper_app/Contents/PlugIns/MenuHelperExtension.appex/Contents/MacOS/MenuHelperExtension"; do
    lipo "$menuhelper_binary" -verify_arch arm64 x86_64
done

mkdir -p "$menuhelper_dist" "$menuhelper_stage/$menuhelper_name"
ditto "$menuhelper_app" "$menuhelper_stage/$menuhelper_name/Finder Menu Tools.app"
cp "$menuhelper_repo/docs/INSTALL.md" "$menuhelper_stage/$menuhelper_name/INSTALL.md"
cp "$menuhelper_repo/LICENSE.txt" "$menuhelper_stage/$menuhelper_name/LICENSE.txt"
cp "$menuhelper_repo/NOTICE.md" "$menuhelper_stage/$menuhelper_name/NOTICE.md"
ditto "$menuhelper_repo/Licenses" "$menuhelper_stage/$menuhelper_name/Licenses"
codesign --verify --deep --strict "$menuhelper_stage/$menuhelper_name/Finder Menu Tools.app"
ditto -c -k --sequesterRsrc --keepParent \
    "$menuhelper_stage/$menuhelper_name" "$menuhelper_dist/$menuhelper_name.zip"
cd "$menuhelper_dist"
shasum -a 256 "$menuhelper_name.zip" > "$menuhelper_name.zip.sha256"
printf '\nUnnotarised release: %s/%s.zip\n' "$menuhelper_dist" "$menuhelper_name"
