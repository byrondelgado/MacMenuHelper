# Release validation

Environment: Xcode 26.5, macOS 26.6.2, Apple silicon. Validation performed on
8 September 2026 for the maintenance changes included in Finder Menu Tools 4.0.1.

## Checks

- The original licence matches upstream base `8ff129ea6a50574f8f2fd79d57a67b612472fd45`
  byte for byte. Dependency licences match the pinned versions.
- Both app and extension build for `arm64` and `x86_64`. Nested signatures,
  shared-preference configuration, embedded notices, ZIP contents and checksums
  are verified before release publication.
- Copy Path was exercised on a file with a space in its name and on a folder;
  clipboard values matched the expected absolute paths.
- The extension successfully opened Downloads in Visual Studio Code. MenuHelper's
  logs confirmed a successful handoff of Downloads to Warp.
- The first Finder menu after an extension restart contained the configured apps
  and Copy Path; saved home-folder permission survived restarts.
- Both folder lists show individual removal controls. A temporary Finder Sync
  entry was removed through its button: the other entries were preserved, the
  change persisted and the physical folder remained intact.
- Disabling Xcode through its switch persisted the disabled state and immediately
  removed its Finder command while Warp and Visual Studio Code remained. The
  original enabled setting was then restored and confirmed in saved preferences.
- The Finder menu's Settings command opened the actual Settings window both with
  the app initially closed and with it already running. The About screen was
  visually checked for the new name, original-author credit, fork link and notices.
- Shell syntax, property-list syntax and source whitespace checks passed.

## Coverage limits

- The build is ad hoc signed and not notarised. Local launch does not establish
  first-time Gatekeeper behaviour on a clean Mac. Installation of a quarantined
  download on another Mac and execution on Intel have not been tested.
- Warp's internal working directory was not independently inspected. Its handoff
  result was verified through the extension's logs.
- The permission-list removal control was visually checked; the removal test used
  a temporary Finder Sync entry so that existing home access was preserved.
- Upstream Swift concurrency warnings remain in Swift 5 language mode. An Xcode
  iOS Simulator version warning did not prevent native macOS builds.
- The inherited screenshot UI test suite was not run. This coverage concerns the
  requested maintenance workflows, not every inherited action.

## v4.0.2 security update

The production-helper regression suite passed for file collisions, symlinks,
hard links, traversal, invalid URLs, file modes, concurrent creation, shell
round-trips, scope lifetime, action identity and immutable menu snapshots.
The universal build succeeded, and the installed app and extension passed the
exact-entitlement and hardened-runtime verification.

The v4.0.2 candidate was installed for end-to-end verification. The Mac was locked
before the new Finder command dispatch and explicit Settings target could be
checked in the UI. Publication is held pending that final check. Earlier UI
coverage above refers to v4.0.1 and should not be read as new-version coverage.
