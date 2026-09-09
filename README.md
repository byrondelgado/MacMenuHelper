# Finder Menu Tools

Finder Menu Tools adds shortcuts to Finder's right-click menu and toolbar.
Open files and folders in apps such as Warp or Visual Studio Code, copy their
paths, or create a new file in the current folder.

This is a small, unofficial maintenance fork of [MenuHelper](https://github.com/Kyle-Ye/MenuHelper)
by [Kyle-Ye](https://github.com/Kyle-Ye). The original extension, design and core
functionality are his work. This fork fixes a few usability and reliability
issues and provides a free download through GitHub.

Maintained by [Byron Delgado](https://github.com/byrondelgado), independently of
the original author. The repository is called **MacMenuHelper**; the app is
called **Finder Menu Tools** and uses its own name and icon.

[Fork repository](https://github.com/byrondelgado/MacMenuHelper) ·
[Download](https://github.com/byrondelgado/MacMenuHelper/releases/latest) ·
[Report a problem](https://github.com/byrondelgado/MacMenuHelper/issues)

## Screenshots

The toolbar menu includes app shortcuts, file actions and Settings.

<p align="center">
  <a href="docs/screenshots/finder-toolbar-menu.png"><img src="docs/screenshots/finder-toolbar-menu.png" alt="Finder toolbar menu showing Warp, Visual Studio Code, Copy Path, file actions and Settings" width="1000"></a>
</p>

<table>
  <tr>
    <td width="50%" valign="top">
      <strong>Right-click menu</strong>
      <p>Open apps and run file commands without leaving Finder.</p>
      <a href="docs/screenshots/finder-context-menu.png"><img src="docs/screenshots/finder-context-menu.png" alt="Finder context menu with Open in Visual Studio Code highlighted, alongside Warp and file actions" width="420"></a>
    </td>
    <td width="50%" valign="top">
      <strong>Extension status</strong>
      <p>Check whether the extension is enabled and open its settings.</p>
      <a href="docs/screenshots/welcome.jpg"><img src="docs/screenshots/welcome.jpg" alt="Finder Menu Tools welcome window showing the enabled extension and links to settings" width="420"></a>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <strong>Application settings</strong>
      <p>Turn individual app shortcuts on or off.</p>
      <a href="docs/screenshots/application-settings.jpg"><img src="docs/screenshots/application-settings.jpg" alt="Application settings with Warp and Visual Studio Code enabled, and Terminal and Xcode disabled" width="420"></a>
    </td>
    <td width="50%" valign="top">
      <strong>Copy and new file settings</strong>
      <p>Choose a path format and the default name for new files.</p>
      <a href="docs/screenshots/copy-and-file-settings.jpg"><img src="docs/screenshots/copy-and-file-settings.jpg" alt="General settings for copying paths and choosing a new file name and extension" width="420"></a>
    </td>
  </tr>
</table>

Version 4.0.2 on macOS 26.

## Changes in this fork

- Open Settings from the Finder menu.
- Remove individual folders from either folder list.
- Turn individual app shortcuts on or off without deleting their configuration.
- Restore the folder permission controls in Settings.
- Detect Warp and Visual Studio Code when they are installed.
- Load app shortcuts on the first menu opening and update menus without restarting Finder.
- Provide a universal download for Apple silicon and Intel Macs.

## Install

**Requires macOS 15 or later.** You do not need Xcode or an Apple Developer
account to use the download.

1. Open [the latest release](https://github.com/byrondelgado/MacMenuHelper/releases/latest)
   and download **`FinderMenuTools-…-macos-universal.zip`**. The **Source code**
   archives do not contain the built app.
2. Extract the ZIP and move **Finder Menu Tools.app** to **Applications**.
   Quit and remove the App Store edition of MenuHelper or an older MacMenuHelper
   build first, if installed, to avoid duplicate extensions.
3. Open **Finder Menu Tools**. The app is **not notarised by Apple**. If macOS
   blocks it because the developer cannot be verified, go to **System Settings →
   Privacy & Security → Open Anyway** and confirm. Managed Macs may prohibit
   this. See [Apple's instructions](https://support.apple.com/en-us/102445).
4. Click **Open System Extension Panel…** and enable **Finder Menu Tools Extension**.
   On macOS 26, this is under **General → Login Items & Extensions → File Providers**.
5. In **Settings → Folder → User Selected Directories → Add Folders**, select
   your home folder (`~/`) or just the folders you want to use, then click **Open**.
6. In **Settings → Menu**, enable the apps and actions you want. They will appear
   in Finder's menu. Use **Finder Menu Tools Settings…** to change them later.

**User Selected Directories** grants access to folders. **Finder Sync Directories**
controls where the right-click menu appears; adding a folder there does not grant
access. The minus-circle button removes one folder from either list.

See the [installation guide](docs/INSTALL.md) for updates, checksums and troubleshooting.

## Credit and licence

The original project is [MenuHelper by Kyle-Ye](https://github.com/Kyle-Ye/MenuHelper).
Its **Copyright 2023-2024 Kyle-Ye** notice and source-file credits are preserved.
Upstream also credits [SwiftyMenu by Lex Tang](https://github.com/lexrus/SwiftyMenu)
as inspiration. This fork is not endorsed by the original author.

The original **FSL-1.1-MIT** licence is retained in [LICENSE.txt](LICENSE.txt),
and the fork's changes use the same terms. This is a free, non-commercial
project. The licence restricts competing commercial uses and reserves upstream
trademark rights. The MIT future grant applies on each version's second
anniversary. See the [licensing review](docs/LICENSING.md) for details.

The download includes the licence, [NOTICE.md](NOTICE.md) and the
[dependency licences](Licenses/): AcknowKit by Kyle-Ye (MIT) and Swift Collections
by Apple and its contributors (Apache 2.0 with Swift's Runtime Library Exception).

## Build from source

With Xcode installed and selected, run:

```sh
./scripts/build-local.sh
```

To build a universal app and package the ZIP with its SHA-256 checksum:

```sh
./scripts/package-release.sh
```

Local builds go to `~/Library/Caches/MacMenuHelper/DerivedData/Build/Products/Release/`;
release files go to `dist/`. Builds use ad hoc signing, so no signing certificate
is needed. See the [release guide](docs/RELEASING.md) and
[validation notes](docs/VALIDATION.md).

## Security

Both the app and extension are sandboxed. Version 4.0.2 includes fixes for file
creation, permissions, path copying and menu dispatch. New File refuses to
replace an existing file. Shell copy formats separate paths with spaces;
the custom separator applies only to literal copy.

The [security review](docs/SECURITY-REVIEW.md) describes what was checked and the
known limitations. Run `./scripts/test-security.sh` to check the safety helpers.
For reporting a vulnerability, see [SECURITY.md](SECURITY.md).
