# Creating a GitHub release

This repository publishes Finder Menu Tools as a free, non-commercial maintenance
fork of MenuHelper by Kyle-Ye. Read [the licensing review](LICENSING.md) before
changing the distribution model. No Developer ID certificate is used; the app is
ad hoc signed and not notarised.

## Prepare the version

1. Update `MENUHELPER_APP_VERSION` in `Configs/Common.xcconfig` for a new release.
2. Check the README, installation guide, notices and dependency licences. Keep the
   upstream `LICENSE.txt` and original copyright notices intact. Use the fork's
   own display name and icon, and credit Kyle-Ye clearly.
3. Review and commit the source changes. Confirm `git status --short` is clean.
4. Build from that commit:

   ```sh
   ./scripts/package-release.sh
   ```

   The build uses the versions pinned in `Package.resolved`, compares their
   licences with the copies in `Licenses/`, embeds the notices inside the app,
   signs the final bundle and checks both architectures. The ZIP includes the app,
   installation guide, upstream licence, attribution notice and dependency licences.

## Verify

- Check the ZIP's SHA-256 checksum from the `dist` directory.
- Extract the ZIP into a temporary directory and run `codesign --verify --deep
  --strict` on the extracted app. Confirm the app and extension both contain
  `arm64` and `x86_64` using `lipo -archs`.
- Check that the embedded licence and notices match the source files.
- Test installation, extension activation, folder permissions, application
  toggles, individual folder removal and Copy Path. Record any limits in
  [VALIDATION.md](VALIDATION.md).
- A successful local ad hoc launch does not establish that a quarantined download
  works on another Mac. Ideally test the download on a clean Apple silicon Mac
  and an Intel Mac. Document missing coverage in the release notes.

## Publish

Push the reviewed commit and an annotated version tag to this fork. Verify that
the tag points to the commit used to build the assets. For example, for v4.0.1:

```sh
git tag -a v4.0.1 -m 'Finder Menu Tools 4.0.1'
git push origin main v4.0.1
gh release create v4.0.1 \
  dist/FinderMenuTools-4.0.1-macos-universal.zip \
  dist/FinderMenuTools-4.0.1-macos-universal.zip.sha256 \
  --repo byrondelgado/MacMenuHelper \
  --verify-tag \
  --title 'Finder Menu Tools 4.0.1 — maintenance fixes' \
  --notes-file docs/releases/v4.0.1.md
```

Use `--draft` when preparing a release that should not yet be public. Attach only
the matching versioned ZIP and checksum, not every file in `dist/`. Never replace
assets under an existing public version to hide a changed build; release a new
version for further fixes. Re-download published assets and verify their checksums.
