#!/bin/bash
set -euo pipefail
menuhelper_repo="$(cd "$(dirname "$0")/.." && pwd)"
menuhelper_build="${MENUHELPER_BUILD_DIR:-$HOME/Library/Caches/MacMenuHelper/DerivedData}"
menuhelper_products="$menuhelper_build/Build/Products/Release"
if [[ ! -f "$menuhelper_products/OrderedCollections.o" ]]; then
    "$menuhelper_repo/scripts/build-local.sh"
fi
menuhelper_testdir=$(mktemp -d "${TMPDIR:-/tmp}/finder-menu-security-tests.XXXXXX")
trap 'rm -r "$menuhelper_testdir"' EXIT
menuhelper_domain="com.byrondelgado.security-tests.$(uuidgen)"
cat > "$menuhelper_testdir/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>$menuhelper_domain.runner</string>
<key>MenuHelperPreferencesDomain</key><string>$menuhelper_domain</string>
</dict></plist>
PLIST
cd "$menuhelper_repo"
xcrun swiftc -swift-version 5 -parse-as-library -profile-generate \
    -I "$menuhelper_products" "$menuhelper_products/OrderedCollections.o" \
    -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker "$menuhelper_testdir/Info.plist" \
    Shared/ActionSafety.swift Shared/StringExtension.swift \
    Shared/Model/MenuItem.swift Shared/Model/AppMenuItem.swift Shared/Model/ActionMenuItem.swift \
    Shared/Model/FolderItem.swift Shared/Model/BookmarkFolderItem.swift \
    Shared/ViewModel/MenuItemStore.swift Tests/SecurityChecks.swift \
    -o "$menuhelper_testdir/security-checks"
LLVM_PROFILE_FILE="$menuhelper_testdir/security-%p.profraw" "$menuhelper_testdir/security-checks"
