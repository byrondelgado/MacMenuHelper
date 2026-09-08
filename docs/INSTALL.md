# Install Finder Menu Tools

Requires macOS 15 or later. The universal app includes Apple silicon and Intel
executables. This free build is ad hoc signed and is **not notarised by Apple**.
You do not need Xcode, a developer account or a subscription to use it.

1. Open [the releases page](https://github.com/byrondelgado/MacMenuHelper/releases/latest)
   and download **FinderMenuTools-…-macos-universal.zip** from **Assets**. Extract
   it and move **Finder Menu Tools.app** to **Applications**. Quit and remove the
   App Store MenuHelper app or an earlier MacMenuHelper build if installed, to
   avoid duplicate extensions. The **Source code** archives are for building.
2. Open Finder Menu Tools. If macOS blocks the app because the developer cannot be
   verified, follow Apple's **System Settings → Privacy & Security → Open Anyway**
   flow for this app. A managed Mac may prohibit this. Do not disable Gatekeeper.
3. Click **Open System Extension Panel…** and enable **Finder Menu Tools Extension**. On macOS 26 this
   opens **General → Login Items & Extensions → File Providers**. The extension
   is listed as Finder Menu Tools Extension.
4. Open **Settings → Folder → User Selected Directories → Add Folders**. Choose
   your home folder (`~/`) or only the folders you want the extension to access.
   Confirm with **Open** in the folder picker.
5. In **Settings → Menu**, enable **Warp**, **Visual Studio Code** and **Copy Path**.
   Warp and Visual Studio Code are detected automatically on a fresh setup when
   they are installed. Use the plus button to add an application manually.

Right-click a file or folder in Finder to use these commands. Right-click the
window background to act on the current folder. Choose **Finder Menu Tools
Settings…** from the same menu to open the app’s Settings window. **Copy Path** copies an absolute
path; the copy style and separator for multiple selections are configurable in
**Settings → General**.

**Finder Sync Directories** determines where the menu appears. **User Selected
Directories** grants permission to open files and folders. Adding a Finder Sync
directory alone does not grant permission.

To remove one entry from either folder list, click the minus-circle button at the
right of its row. **Remove All** clears the whole list.

Each application in **Settings → Menu** has an on/off switch. Turning it off hides
its Finder command while retaining the application's configuration; turn it on
to show the command again.

If replacing the App Store app leaves a missing or unresponsive menu, relaunch
Finder or sign out and back in. If an update loses folder access, reselect the
folder in Settings. Separate macOS privacy restrictions can still apply to
protected locations beneath your home folder.

The app and extension are sandboxed. They share only their own preference domain;
the release does not contain the publisher's menu settings or folder permissions.

[Apple's guidance on opening downloaded apps](https://support.apple.com/en-us/102445)

## Optional checksum verification

Download the matching `.zip.sha256` asset into the same folder as the ZIP. In
Terminal, change to that folder and run (substituting the version downloaded):

```sh
shasum -a 256 -c FinderMenuTools-4.0.1-macos-universal.zip.sha256
```

The result should be `OK`. The checksum checks that the file matches the release;
it is not Apple notarisation or independent verification of the publisher.

## Updating

Quit the app, replace the copy in Applications with the new release and reopen it.
If Finder still shows the previous version's menu, relaunch Finder. Re-grant folder
access if prompted. Internal bundle identifiers remain stable to preserve this
fork's settings; old App Store permissions are not automatically transferred.

## Original project and licence

Finder Menu Tools is an unofficial maintenance fork of
[MenuHelper by Kyle-Ye](https://github.com/Kyle-Ye/MenuHelper), offered under
FSL-1.1-MIT. The download includes `LICENSE.txt`, `NOTICE.md` and dependency
licences. Copies also travel with the app in **Contents → Resources → Licenses**.
