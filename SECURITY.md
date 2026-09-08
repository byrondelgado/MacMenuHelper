# Security

Finder Menu Tools is an unofficial maintenance fork of MenuHelper. Security fixes
are released in new versions; use the latest release. Version 4.0.2 addresses
unsafe file creation, shell-copy formatting, path logging and permission lifetime
issues found in the inherited code.

## Reporting a concern

Use this repository's **Security → Report a vulnerability** option to send a
private report to the maintainer. Include the version, macOS version and a minimal
reproduction using test files. Do not include personal files, credentials or full
private directory listings in a public issue.

## Security boundaries

- The app and Finder extension run as the current user in App Sandbox with the
  hardened runtime. The settings app requests read-only access to user-selected
  files; the extension can read and write user-selected files for its actions.
- New File uses exclusive creation and never overwrites an existing destination.
  It rejects path components and control characters in the configured name.
- The app does not invoke a shell to open files. It hands selected file URLs to
  the application the user configured through macOS Launch Services. Use trusted
  applications and review any custom arguments or environment variables.
- **Use origin path** copies literal text. **Escape for shell** and **Quote for
  shell** protect shell syntax; they do not stop a receiving program treating a
  leading-dash filename as an option. Use that program's `--` separator as needed.
- Settings are ordinary local preferences, not a secret store. The app and
  extension share their own preference domain through a narrowly scoped sandbox
  exception. This does not defend against malicious software already running
  outside the sandbox as the same macOS user.
- Removing a saved folder releases the app-managed bookmark scopes. It does not
  revoke macOS permissions granted independently, undo access already given to
  another application, or necessarily cancel the folder picker's process-lifetime
  grant. Restart the extension and adjust macOS privacy permissions when revoking
  access completely.
- The custom URL handler only opens Settings, and the extension targets its own
  containing app explicitly. Local distributed notifications refresh settings or
  request a folder picker; the picker still requires user approval to grant access.

## Distribution limits

Keep macOS up to date with security fixes. The free release is ad hoc signed and **not notarised**. A matching SHA-256 file
checks download integrity, not developer identity. Download only from this
repository's releases. macOS may require a per-app Open Anyway decision, and a
managed Mac may refuse installation. Never disable Gatekeeper globally to install
this app.

The review and regression tests are documented in
[docs/SECURITY-REVIEW.md](docs/SECURITY-REVIEW.md). They are not an independent
penetration test or a guarantee that no vulnerabilities remain.
